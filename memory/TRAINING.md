# WertApp 训练模块（AI Training）实现说明

> 对应任务书：`WortApp_AI_Training_Agent_Brief.md`（v1.0）
> 落地版本：schemaVersion **6**（新增 3 张表）

## 1. 产品结构

主导航新增 **训练** 一级入口（第 5 个 tab），进入后是三张并列卡片：

| 技能 | 德语名 | 已实现题型 |
|---|---|---|
| 听力 | Hören | 听力理解、听写 |
| 阅读 | Lesen | 阅读理解、完形填空 |
| 写作 | Schreiben | 句子构造、语法改错 |

其余 10 个题型已在 `ExerciseType` 中占位（`implemented: false`），
列表里显示「后续」，点击不可进入——避免出现点进去却做不了的入口。

## 2. 数据模型（仅本地）

| 表 | 职责 |
|---|---|
| `exercises` | 一套练习：技能、题型、CEFR、难度、主题、材料、状态、总分、耗时、schema/prompt 版本、模型名 |
| `exercise_questions` | 题目：题干类型、题干、选项 JSON、**答案 JSON**、解析、分值、Rubric JSON |
| `exercise_attempts` | 逐题答题记录：用户答案、得分、是否正确/部分正确、判分方式、结构化反馈 |

要点：

- **答案与展示数据在模型层分离**：`ExerciseDao.getPlayback()` 返回 `PlaybackQuestion`
  （无答案字段），`getSolutions()` / `getResultView()` 只在提交后才被调用。
- **练习历史不参与备份与 OneDrive 同步**（用户决策）。`export_service` 与
  `backup_merger` 只处理 `decks/words/sm2/conjugation`，因此不会带上训练数据，
  也不会污染 SM-2。代价：换设备后练习历史不带过去，UI 上已明确「仅本地」。
- 迁移：`schemaVersion 5 → 6`，仅 `createTable`，不动既有表，用户数据无损。
- 删除练习时手工级联删除题目与答题记录（与项目既有写法一致，未启用外键）。

## 3. 生成链路

`ExercisePrompts`（提示词）→ `AIService.chat` → `ai_json.decodeJsonObject`（容错解析）
→ `ExerciseSchema.parse`（字段/题数/选项/答案引用/分值校验）→ 落库 → 答题页。

- 各题型共用一套 JSON 骨架，只有「题型说明」段落不同，避免六套提示词漂移。
- 提示词里显式给出 `maxTokens` 估算（`ExercisePrompts.maxTokensFor`），
  因为 `AIService` 的默认 `maxTokens` 只有 2048，整套题目会被截断成坏 JSON。
- 首次尝试开启 `response_format: json_object`（`jsonMode`），失败后降级为普通请求 +
  更低温度重试一次；两次都失败会写一条 `status = 'failed'` 记录（不进历史列表）。
- 校验会把「选择题答案是字母 A/B/C」解析成 0 基下标，并拒绝越界引用；
  排序题要求答案必须是完整排列；填空题要求 `acceptedAnswers` 非空。

## 4. 判分策略

| 题型 | 判分 | 说明 |
|---|---|---|
| 单选 / 多选 / 判断 / 排序 | 程序 | 多选支持部分分：`(命中 - 错选) / 正确答案数` |
| 填空 | 程序 | 多可接受答案，标准化后比较 |
| 听写 | 程序 | LCS 对齐出 漏写/写错/多写/大小写/拼写，按命中率给分 |
| 句子构造 / 语法改错 / 翻译 / 情景 / 自由写作 | AI Rubric | 先比对参考答案，命中则直接满分，省一次调用 |

- **`AnswerNormalizer` 不复用 `GermanParser.compareSpelling`**：后者默认
  `tolerant: true`，会把 `ae→ä`、`ss→ß` 折叠，用于学习模式的"拼写宽容"是对的，
  但听写里 `Masse` / `Maße` 是两个词。训练模块默认严格，只有显式
  `allowUmlautFolding` 才接受替代写法。
- AI 评分失败 → `QuestionGrade.unavailable`，分数记 0 并标记
  `graderType = 'unavailable'`，UI 显示"本题评分暂不可用，已保留你的答案"，
  **绝不伪造分数**。用户答案已先落库。
- Rubric 维度分会被 clamp 到 `[0, maxScore]`；维度集合为空时视为评分失败。

## 5. 语音

`SpeechPlaybackService` 封装 `flutter_tts`：

- 初始化时 `isLanguageAvailable('de-DE')` 检测德语语音，不可用时整个播放控件
  替换成说明文字（不显示无效按钮）。
- 提供整段播放、逐句播放（`awaitSpeakCompletion` 逐句串行）、停止、重播。
- **不提供 pause**：`flutter_tts` 在 Android 上的 pause 是基于 `onRangeStart` 的
  workaround，仅 API ≥ 26 有效，而本项目 `minSdk` 走 Flutter 默认值。
  统一用「停止 + 重播」，并把语速交给设置里的 `ttsSpeed`。

## 6. 长按查词（与词书联动）

- `DictionaryEngine.lookup(word, {forceRefresh, LookupContext? context})`：
  新增可选语境参数，`LookupContext` 携带选中文本、所在句子、前后文、CEFR 等级。
- 只有 AI 引擎使用语境；**语境查询不读也不写 `ai_lookup_cache`**
  （缓存以单词为键，写入会把"某句子里"的解释覆盖成通用解释），
  也不写 `ai_request_status`，避免污染「数据管理」列表。
- 阅读材料用 `SelectableText.contextMenuBuilder` 拦截长按，做「查词 / 复制」；
  选区偏移通过 `StimulusView.sentenceAt` 映射回句子边界，短语不会被切碎。
- 入库统一走 `WordIntakeService`（从 `search_screen` 的私有方法提取）：
  按 `GermanParser.canonicalKey` 全局查重、纯词典来源只写词形、
  AI 结果补写 `conjugation_cache` 与 `ai_lookup_cache`，**不触碰 `sm2_states`**。

## 7. 已知限制

1. 练习历史只存本地，不随备份/同步迁移（用户决策）。
2. 逐句播放没有"卡拉 OK"式的词级高亮：`setProgressHandler` 在 Web 与部分
   Android TTS 引擎上不可靠，故未实现。
3. 句子构造/语法改错依赖 AI 评分，属概率性质量；`corrections` 里用
   `certain: true/false` 区分"确定错误"与"改进建议"。
4. 生成一次性完成整套题（不做分页增量生成），题量大时需要更高 `maxTokens`；
   已被 `maxTokensFor` 限制在 2048–8192。

## 8. 验证

```bash
dart run build_runner build        # schema v6 代码生成（已入库）
flutter analyze                    # No issues found
flutter test                       # 299 tests, All tests passed
flutter build apk --debug          # Android 编译验证
```

训练模块相关测试：

- `test/training_core_test.dart`：标准化、听写差异、Schema 校验、程序判分、DAO 持久化
- `test/training_flow_test.dart`：假 AI 的生成→答题→提交→结果全链路（含重试与失败）
- `test/training_i18n_test.dart`：扫描源码里的 `tr('…')`，要求中/英/德三语齐全
