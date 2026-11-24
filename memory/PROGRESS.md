# WortApp 项目进度文档

## 📅 更新日期
2026-08-07 (最新)

---

## ✅ 已完成功能

### 核心架构
- [x] Flutter 项目初始化 (Flutter 3.44.8 + Dart 3.12.2)
- [x] Material Design 3 主题系统
- [x] 德语冠词颜色系统 (der蓝/die红/das绿/复数黄)
- [x] Riverpod 状态管理
- [x] drift 数据库 ORM (支持 Android/iOS/Web)

### 数据库设计
- [x] `decks` 表 - 词书管理
- [x] `words` 表 - 单词存储（含动词三态、名词变格、形容词比较级）
- [x] `sm2_states` 表 - SM-2 算法状态
- [x] `conjugation_cache` 表 - 变位数据缓存
- [x] `ai_lookup_cache` 表 - AI 查词缓存（(word, engine) 唯一键）
- [x] `ai_request_status` 表 - AI 请求状态记录（成功/失败/错误信息，数据管理用）
- [x] `study_stats` 表 - 每日学习统计（wordId+date 唯一键，记录出现/错误次数）
- [x] `settings` 表 - 应用设置存储（使用数据库，非 SharedPreferences）

### 算法实现
- [x] SM-2 间隔重复算法
- [x] 复习队列调度器
- [x] 干扰项生成器（选择题）
- [x] 德语词形解析器（冠词提取、词性判断、宽容拼写）

### 词书管理
- [x] 词书 CRUD（创建、重命名、删除）
- [x] 词书切换
- [x] 单词列表（搜索、筛选、熟练度标记）
- [x] **规范化词形去重**：`der Hund` 与 `Hund` 归为同一词（`GermanParser.canonicalKey`，保留大小写语义）；CSV/Excel 导入全局去重、手动加词/查词入库/编辑改词形全局防重复，备份导入/复制到词书按词书内规范化去重
- [x] **去重扫描工具**：单词列表「去重扫描」FAB，扫描词书内重复分组、逐组选择保留记录，其余 SM-2/统计/变位缓存合并后删除（修复已存在的重复）
- [x] 单词三点菜单删除（确认对话框，删除后自动清理 SM2/变位缓存；无其他词书引用时释放 AI 释义缓存与请求状态）
- [x] 重置学习进度按钮（新建单词上方，黄色警告弹窗二次确认，清空全部 SM2 状态并归零熟练度）
- [x] Excel/CSV 导入服务
- [x] Excel/CSV 导出服务

### 学习模式
- [x] 经典翻牌模式（Flip Mode）
- [x] 看德语选中文
- [x] 看中文选德语
- [x] 听德语选单词
- [x] 德语拼写模式（含特殊字符键盘）
- [x] SM-2 反馈按钮（忘记/模糊/熟悉/简单）
- [x] 学习完成统计
- [x] 快闪卡模式（Flash Card，全屏卡片左右滑动评分，iOS 风格动效）
- [x] 每轮词量与每日上限控制（新词/复习独立限额）+ 抽词兜底循环复习
- [x] 抓词模式（正常抓词 / 收藏优先 / 只抓收藏）
- [x] 四选一干扰项全词库随机抽取（池化机制）
- [x] 错词重考：答错（忘记/模糊）的单词主列表学完后按先进先出重考，答对移出，重考次数超限放弃（循环复习模式除外）
- [x] 学习统计：study_stats 表 + 底部错误统计排行榜（今日/历史，独立二级页面）

### AI 集成
- [x] 可配置 AI 服务（支持 OpenAI 兼容格式）
- [x] 自定义 AI 配置（API Key / API 地址 / 模型名称）
- [x] 快速预设（MiMo / DeepSeek / OpenAI / Gemini / 通义千问 / 阿里云百炼）
- [x] AI 查词引擎
- [x] AI 变位数据生成
- [x] Wiktionary 查词引擎
- [x] 查词结果展示（释义/例句/AI分析）
- [x] AI 查词结果缓存到数据库（ai_lookup_cache 表）
- [x] 单词本多选 AI 批量更新词义（后台任务 + 进度查看）
- [x] AI 批量更新防数据丢失（空释义跳过、overwrite 生效、坏缓存自愈）
- [x] AI 结果字段落库（复数 nounPlural、名词类型 nounType、词性）
- [x] AI 词性/名词类型解析源头规范化（兼容 "Verb"/"动词" 等不规范值）
- [x] 词书页“数据管理”入口（新建单词按钮上方）
- [x] 数据管理页：单词 AI 释义状态列表（已有释义/请求失败/无释义）+ 筛选 + 一键选择重试
- [x] AI 请求状态自动记录（引擎真实请求时写入 ai_request_status，缓存命中不记录）
- [x] 共享批量更新进度对话框组件（BatchUpdateDialog，wordIds/deckId 双模式）
- [x] 备份 JSON v3：导出/导入含 aiStatus 状态信息（wipe 覆盖模式同步清理）

### 词性标注系统
- [x] 词性颜色系统（WordTypeColors）
  - 动词 Verb: 紫色系
  - 可分动词 trennbar: 深紫色
  - 不可分动词 untrennbar: 浅紫色
  - 形容词 Adjektiv: 橙色系
  - 副词 Adverb: 青色系
  - 介词 Präposition: 粉色系
  - 连词 Konjunktion: 棕色系
  - 名词 Substantiv: 使用冠词颜色
- [x] WordTypeChip 组件（词性标签）
- [x] VerbSeparabilityChip 组件（可分性标签）
- [x] PrepositionChip 组件（介词搭配标签，显示支配三格/四格）

### 单词详情页面
- [x] 完整单词信息展示
- [x] 动词变位（现在时/过去时/完成时）
- [x] 名词变格（第二格/复数）
- [x] 形容词比较级/最高级
- [x] 学习状态（复习次数、连续正确、简易度、下次复习）
- [x] 标签显示
- [x] TTS 发音
- [x] 单词编辑对话框（优先 AI 缓存初始化，保存后同步写回缓存）
- [x] 释义/例句完整列表展示（与查词界面一致）
- [x] 动词搭配、AI 解析展示（来自缓存）

### 其他功能
- [x] TTS 德语发音
- [x] 加词入库（选择词书/新建词书）
- [x] 设置页面（AI配置、每日上限、TTS语速、宽容拼写、主题模式）
- [x] 词书列表显示词性标签
- [x] 夜间模式（跟随系统/日间/夜间，Material 3 暗色配色）
- [x] 单词收藏标记（words.isFavorite）
- [x] 备份 JSON v4：导出/导入兼容收藏标记与错误统计
- [x] 平板分屏双栏布局（StudySplitLayout）
- [x] 单词详情页下滑关闭（SwipeDownDetailRoute）
- [x] APK 仅打包 64 位架构（arm64-v8a / x86_64），排除 32 位减小体积
- [x] 完整备份：gradle-wrapper.jar / gradlew 等关键构建文件纳入版本控制

---

## 🐛 已知问题

### Web 平台问题
1. **数据库初始化不稳定** - sql.js 在某些浏览器环境下会报错
2. **WASM 加载问题** - 需要手动复制 sql-wasm.wasm 文件到 build 目录
3. **页面刷新后数据丢失** - 如果 sql.js 初始化失败，会使用内存数据库

### 功能限制
1. **AI JSON 解析** - 部分 AI 响应格式不标准导致解析失败
2. **Web 平台设置** - 数据库写入可能失败，设置可能不持久

### 解决方案建议
- **Android 平台**：不会有上述 Web 问题，使用原生 SQLite
- **Web 调试**：仅用于界面调试，数据持久化在 Android 上测试

---

## 📋 待实现功能

### 中优先级
- [ ] 学习统计图表（连续打卡、掌握率趋势）
- [ ] 批量删除单词

### 低优先级
- [ ] 手写识别功能
- [ ] 德语助手网页解析引擎
- [ ] 暗色主题优化
- [ ] 多语言界面支持
- [ ] 单元测试覆盖
- [ ] 名词第二格变格练习
- [x] 数据备份/恢复功能（JSON v4：含收藏与错误统计）

---

## 🛠️ 技术说明

### 平台差异
| 功能 | Android | Web |
|------|---------|-----|
| 数据库 | 原生 SQLite (稳定) | sql.js WASM (不稳定) |
| 设置存储 | 数据库 | 数据库 (可能失败) |
| TTS | 系统 TTS | 浏览器 TTS |
| 文件导入 | 文件选择器 | 文件选择器 |

### 建议开发流程
1. **界面开发**：可在 Web 平台调试
2. **数据持久化**：在 Android 平台测试
3. **最终发布**：构建 Android APK

---

## 📁 关键文件路径

```
lib/
├── core/constants/
│   └── app_colors.dart          # 颜色系统（冠词+词性）
├── providers/
│   ├── database_provider.dart   # 数据库状态
│   ├── settings_provider.dart   # 设置（含 AI 配置）
│   ├── study_provider.dart      # 学习会话
│   └── deck_provider.dart       # 词书状态
├── data/database/
│   ├── app_database.dart        # 数据库定义
│   ├── app_database_web.dart    # Web 平台实现
│   └── tables/                  # 数据表
├── services/
│   ├── ai/ai_service.dart       # 可配置 AI 服务
│   └── dictionary/              # 查词引擎
├── ui/widgets/
│   └── word_type_chip.dart      # 词性标签组件
└── ui/screens/
    ├── deck/
    │   ├── word_list_screen.dart   # 单词列表
    │   └── word_detail_screen.dart # 单词详情
    ├── study/widgets/              # 学习模式
    ├── search/search_screen.dart   # 查词
    └── settings/settings_screen.dart # 设置
```

---

## 🧪 构建命令

```bash
# 安装依赖
flutter pub get

# 生成数据库代码
dart run build_runner build

# Web 调试构建
flutter build web --release

# 复制 WASM 文件（Web 平台需要）
cp web/sqljs/sql-wasm.wasm build/web/
cp web/sqljs/sql-wasm.js build/web/

# 启动本地服务器
cd build/web && python -m http.server 8080

# Android 构建（需要 Android SDK；Windows 下 Flutter 未配置 PATH，需用绝对路径）
C:\flutter\bin\flutter build apk --release

# 详细日志模式（建议重定向到文件，避免终端日志淹没）
C:\flutter\bin\flutter build apk --release -v > build\flutter_build.log 2>&1

# 输出文件
# build/app/outputs/flutter-apk/app-release.apk
```

---

## 🏗️ Android 构建版本组合（2026-08-05 验证成功）

| 组件 | 版本 | 配置位置 | 说明 |
|------|------|---------|------|
| Gradle | 9.1.0 | `android/gradle/wrapper/gradle-wrapper.properties` | Flutter 3.44 官方默认，**勿随意升级**（Flutter 工具支持范围 9.0~9.3.1） |
| AGP | 8.13.1 | `android/settings.gradle.kts` | 原 9.0.1 与旧插件不兼容，已降级 |
| Kotlin | 2.2.20 | `android/settings.gradle.kts` | 原 2.3.20 已降级，匹配 AGP |
| compileSdk | flutter 默认 (36) | `android/app/build.gradle.kts` | 跟随 Flutter 默认值 |
| Maven 镜像 | 阿里云 | `android/settings.gradle.kts` | 国内加速 |
| Gradle 分发 | 腾讯云 | `gradle-wrapper.properties` | 国内加速 |
| VFS 监控 | 已恢复默认启用 | `android/gradle.properties` | 项目已迁出 OneDrive（现位于 `D:\Project Data\WortApp`），2026-08-05 移除 `org.gradle.vfs.watch=false` |

**构建失败修复经验（2026-08-05）**：
1. OneDrive 同步目录 → Gradle VFS 缓存失效风暴（构建"卡住"）→ `gradle.properties` 禁用 VFS 监控（**项目已迁出 OneDrive，该配置已于 2026-08-05 移除**）
2. file_picker 8.3.7 等旧插件与 AGP 9 不兼容（`MissingValueException`）→ 升级 file_picker 至 11.0.3 并迁移 API
3. 多个旧插件均不兼容 AGP 9 → **AGP 降级 9.0.1 → 8.13.1、Kotlin 2.3.20 → 2.2.20**
4. `Failed to find target 'android-34'` → Android Studio 重装 Android 14 SDK（需确认 `android.jar` 与 `source.properties` 存在）
5. 最终组合验证：`BUILD SUCCESSFUL in 2m 13s`，产出 `app-release.apk` (61.2MB)

---

## 📝 开发日志

### 2026-10-11 (学习算法审查与修复)
- [x] **熟练度死字段修复**：`words.proficiency`（熟练度 0-5）此前无任何写入方（星标恒不显示）；`submitStudyFeedback` 现按 `clamp(repetition_n, 0, 5)` 同步更新，`WordDao.updateProficiency` 重构为 `updateLearningProgress`（同时刷新 `lastStudyDate`，仍不更新 `updated_at` 以免同步误判为内容编辑）；新增 `test/proficiency_test.dart` 5 个用例
- [x] **删除死代码**：`lib/algorithms/distractor_generator.dart`（`DistractorGenerator`/`ChoiceQuestion`）全项目无引用，四选一实际用 `DistractorPool`（既有去重与选项池），已移除并同步 PROJECT.md 结构
- [x] **拼写模式防重入**：`spell_mode_screen._onFeedback` 改为 `await` + `_submitting` 守卫（与其余 5 个模式一致），避免极快双击重复提交与异常被吞
- [x] **新增「只复习」开关**（学习页）：开启后不抽新词，只复习到期词；无到期词时循环复习今日已学单词。`StudySessionNotifier.startSession` 新增 `reviewOnly` 参数（新词额度置 0），并纳入非循环会话快照区分（与随机开关同口径）；新增 `test/review_only_test.dart` 4 个用例
- [x] **新增 App 内「评分说明」入口**：通用 `StudyRatingHelpButton`（`lib/ui/widgets/study_rating_help.dart`）加到学习页与 6 个学习模式的 AppBar，弹窗讲解四个评分的含义、常见情况（含"知道词义但忘记冠词/词性"）与如实评分建议
- [x] 新增 `memory/ALGORITHM.md`（学习算法说明）与 `memory/USER_GUIDE.md`（学习使用指引）
- [x] 验证：`flutter analyze` 无 issue，测试全部通过

### 2026-08-07 (动效优化：页面转场去缩放 + 微动画非线性)
- [x] **全局页面转场改为 FadeForwards**：`app_theme.dart` 亮/暗主题新增 `pageTransitionsTheme`，全部平台统一 `FadeForwardsPageTransitionsBuilder`，替代 Windows/Linux 默认 `ZoomPageTransitionsBuilder` 与 Android 默认 `PredictiveBackPageTransitionsBuilder`（二者均会让下层页面缩放/缩小，返回与滑动手势观感突兀）。现在导航为轻量淡入淡出。
- [x] **线性微动画改非线性**：翻牌模式冠词选择 `AnimatedContainer`、变位练习选项 `AnimatedContainer` 补 `curve: Curves.easeOut`；分屏模糊层 `AnimatedSwitcher` 补 `switchInCurve: easeOut / switchOutCurve: easeIn`
- [x] 学习页动画（翻牌/快闪卡/下滑详情）原已使用 easeOutCubic 等曲线，未改动
- [x] `flutter analyze` 无 issue，158 个测试全部通过
- ⚠️ 若观感不佳需撤回：删除两处 `pageTransitionsTheme`（app_theme.dart 亮/暗主题）、回退三处 `AnimatedContainer`/`AnimatedSwitcher` 的 curve 参数

### 2026-08-07 (学习模式进度条：透明轨道 + 贯穿分屏)
- [x] 6 个学习模式（翻牌/快闪/看德选中/看中选德/听音/拼写）的 `LinearProgressIndicator` 从 body 顶部移到 `AppBar.bottom`：进度条贯穿全宽（横屏分屏时跨越左侧答题区与右侧单词详情区），轨道改透明（进度为 0 时不可见，避免"灰色粗线"），`minHeight: 4`
- [x] 验证：`flutter analyze` 无 issue，177 个测试全部通过

### 2026-08-07 (编辑缓存迁移 / 展开式FAB / 对话框controller释放)
- [x] **编辑德语词形后 AI 缓存 key 迁移**：`_EditWordDialog` 保存时若词形变化，把 `ai_lookup_cache` 从旧 key 迁移到新 key（更新 word/释义/例句后存新 key、删旧 key），避免详情页按新词形查不到缓存而重复请求 AI 或显示旧数据
- [x] **单词列表 FAB 收进展开式菜单（无遮罩）**：新增通用 `ExpandingFab` 组件；「重置进度/数据管理/批量AI规范化/去重扫描」收进展开菜单（主按钮 `tune` 图标、无半透明遮罩、点主按钮再次收起），「新建单词」保留为底部主按钮（extended FAB），列表底部留白适配两行按钮
- [x] **对话框 TextEditingController 释放**：为 7 处临时创建的 controller 补 dispose（await 后 dispose 或 `.whenComplete`）——新建单词、重命名词书、AI 配置(3)、API Key、每日上限、新建词书(2)；不再泄漏
- [x] 验证：`flutter analyze` 无 issue，177 个测试全部通过

### 2026-08-07 (全量审查高危/中危修复)
- [x] **H1 AI/变格结果未落库**：`word_detail_screen` 两处 `updateWord` 缺 `id`（`Value.absent().value` 抛错被吞，AI 结果从未写回 words 表）；补 `id` + `word_dao.updateWord` 缺 id 时抛 `ArgumentError`
- [x] **H2 重命名取消激活**：`updateDeck` 由 `replace` 改 `write`（缺席列不再写回默认值），重命名激活词书不再静默取消激活
- [x] **H3 数据库重试**：`DatabaseNotifier` 新增公开 `retry()`（失败时释放实例），初始化失败页「重试」按钮接线
- [x] **H5 变位后台生成 ref-after-dispose**：`_GenerateProgressDialog` 改为父级 `onDone` 回调刷新缓存，不再误标任务失败
- [x] **H6 复习队列跨词书串扰**：`getDueReviewWordIds` 下推 deckId JOIN words 再 LIMIT；`getWordsByIds` 批量取词消除 N+1
- [x] **M settings 门控**：设置逐 key 独立加载，未配 AI Key 不再丢其它设置
- [x] **M 重复入库**：`batch_ai_service` 入库前按 `result.word` 规范化二次查重
- [x] **M 变位重生成丢数据**：`regenerateWord` 先生成后 upsert 覆盖，AI 失败保留旧缓存
- [x] **M 损坏缓存自愈**：`ai_dictionary_engine.lookup` 缓存解析失败时跳过并重新查询
- [x] **M 导入卡死/崩溃**：三处导入流程 try/catch 关 loading；`import_dialog`/`word_detail` 多处 await 后补 `mounted`
- [x] **M 批量任务**：`completeTask` 空任务列表 RangeError + 死三元清理
- [x] **M 输入/状态**：每日上限校验 >0；`onedrive_provider` 四方法 try/catch 复位 isBusy
- [x] **M 去重扫描 N 查询**：批量 `getStatesForWords` 一次取回 SM-2 状态
- [x] **L 死代码/依赖**：删除未使用的 `generateBatch`/`deleteConjugationData`/`deleteWordsByDeck`/`getWordTypes`/`getDeckCount`/`deleteByDeckId`、`VerbSeparabilityChip`/`PrepositionChip`、`GenderColorExtension`；pubspec 移除无引用的 `js`/`sqlite3`/`sqflite_common_ffi_web`/`cupertino_icons`
- [x] 验证：`flutter analyze` 无 issue，177 个测试全部通过

### 2026-08-07 (OneDrive 增量同步代码审查与修复)- [x] **修复冲突检测锚点不对称**（数据静默覆盖）：`backup_merger._mergeWord` 本地侧原用 `cloudExportedAt` 做锚点、云端侧用 `lastSyncAt`，导致"对端在我编辑后先上传"时漏判冲突、本地编辑被 LWW 静默覆盖不弹窗；改为两侧统一用 `lastSyncAt`（`lastSyncAt ?? cloudExportedAt`），首次同步退化为纯 LWW 不误报；新增 2 个回归测试（漏判场景 / 首次同步）
- [x] **词书名不区分大小写**：`_indexDecks` 原按精确大小写匹配，与 applyToDatabase/墓碑（小写）不一致，两端仅大小写不同的词书会被并出两本；改为小写 key，冲突提示仍保留原始大小写
- [x] **激活词书兜底对新词书生效**：`applyToDatabase` 原用合并前构建的 `deckByName` 查激活词书，本次新建的词书查不到导致可能多本激活；改为 `deckIdByName` 并在创建时写入，同时让墓碑删除也能命中本批新建词书
- [x] **wordsUpdated 统计不虚高**：`_mergeWord` 原对每对共同单词都返回 true（一致也计"更新"）；改为合并结果与本地深度比较（先剥离 null/空串/空列表/空 Map/false/0 默认值），仅真实变化才计数
- [x] 新增 backup_merger_apply_test（大小写合并 / wordsUpdated 计数 / 新建激活词书）；`flutter analyze` 无 issue，156 个测试全部通过

### 2026-08-07 (错词重考 / 规范化去重 / 代码健康度)
- [x] **错词重考**：答错（忘记/模糊）的单词进入重考队列，主列表学完后按先进先出重考，答对移出、再错回到队尾，重考次数上限 2 次（超过放弃）；循环复习模式不使用重考（每大轮本就覆盖全部单词）；新增 redo_queue_test 6 个用例
- [x] **规范化词形去重（替代 UUID）**：新增 `GermanParser.canonicalKey`（剥离冠词/复数后缀、**保留大小写**——德语 `Lernen` 与 `lernen` 是不同词）；`WordDao` 新增 `findWordByCanonicalKey`（全局）与 `findWordByCanonicalKeyInDeck`
  - CSV/Excel 导入（完整+智能）：**全局去重**，跨词书已有单词跳过并提示所在词书
  - 手动加词 / 查词入库 / AI 批量补词 / 编辑改词形：全局去重（排除自身），阻止重复
  - 备份导入 / 复制到词书 / 同步合并写库：词书内规范化去重（忠实还原备份、保留复制功能），修复「der Hund 与 Hund」误判为两个词的漏洞
- [x] **去重扫描工具**（修复已有重复）：单词列表右下新增「去重扫描」FAB；按规范化词形扫描词书内重复并分组，逐组勾选保留记录（默认推荐有 SM-2 状态/熟练度高/更新时间新者），其余记录的 SM-2 状态、每日错误统计、变位缓存合并进保留词后删除（不写墓碑、不释放共享 AI 缓存）；新增 `AppDatabase.findDeckDuplicateGroups` / `mergeDuplicateGroup` 与 word_dedup_test 6 个用例
- [x] SM-2 提交逻辑去重：抽取 `AppDatabase.submitStudyFeedback`（事务），`ReviewScheduler.submitFeedback` 与 `StudySessionNotifier.submitFeedback` 共用
- [x] 修复 `StudyPlan.progressPercent` 恒返回 0 的死代码（连同未使用的 hasMoreToStudy 一并移除）
- [x] 修复 `dueReviewCount` 未按词书过滤（progress_card「待复习」显示全库虚高），改为按 deckId JOIN 统计
- [x] **`flutter analyze` 从 67 个问题降到 0**：`analysis_options` 排除 `third_party/**`；修掉 lib 内全部 warning（多余 `!`、未用变量、`withOpacity`→`withValues`、`Radio`→`RadioGroup`、`DropdownButtonFormField value`→`initialValue`、6 处 use_build_context_synchronously、wiktionary `print`→`debugPrint`）与 info 级 lint
- [x] 测试：更新 import_dedup_test（跨词书导入改为全局跳过）、新增冠词变体去重与大小写不合并用例、新增 redo_queue_test 与 word_dedup_test；`flutter analyze` 无 issue，146 个测试全部通过

### 2026-08-07 (变位练习练习范围)
- [x] 变位练习练习参数新增“练习范围”选项：随机练习 / 只练今日单词（持久化到 settings 表）
- [x] conjugation_provider 新增 ConjugationPickMode 枚举，loadDrill 按范围选取单词来源（今日 = lastStudyDate 为今天，与学习模式口径一致）
- [x] 只练今日单词且今日未学习时给出引导提示（请先在学习模式学习）
- [x] 新增 conjugation_drill_test 两个用例（仅抽今日单词 / 今日未学习不出题），22 个测试全部通过

### 2026-08-07 (AI 规范化德语)
- [x] 单词列表新增「AI规范化德语」：从 AI 查词缓存解析规范词形（result.word），写回 words.german 与 baseForm，修复 OCR 导入单词未规范化问题
- [x] 单词语义三点菜单保留「AI规范化德语」入口（auto_fix_high 图标）
- [x] 批量「AI规范化德语」移到右下方 FAB（数据管理按钮下方，auto_fix_high 图标），一键扫描词书中所有单词
- [x] 缓存查找兼容两种键：详情页更新按原词缓存、批量 AI 更新按 result.word 缓存（回退 baseForm 查找）
- [x] 规范化前确认对话框（展示旧词 → 新词），无 AI 缓存时提示先使用 AI 更新词义
- [x] 数据管理页新增「英文释义」筛选与一键选择（translate 图标）：检测中文释义为英文的单词（含拉丁字母且无 CJK 字符），选中后批量 AI 更新为中文释义
- [x] 数据管理底部提示文案同步更新（覆盖无 AI 释义 / 请求失败 / 英文释义三种场景）

### 2026-08-03 (上午)
- 完成项目基础架构搭建
- 实现 SM-2 算法和 5 种学习模式
- 集成 MiMo AI API
- 发现 Web 平台数据库兼容性问题

### 2026-08-03 (下午)
- [x] 添加自定义 AI 配置功能（支持 DeepSeek/OpenAI/MiMo）
- [x] 添加词性色块标注系统（动词/形容词/副词/介词/连词）
- [x] 添加单词详情页面（显示完整信息、变位、学习状态）
- [x] 添加动词可分性标签（trennbar/untrennbar）
- [x] 添加介词搭配标签（支配三格/四格）
- [x] 更新词书列表显示词性标签
- [x] 优化 Web 平台数据库实现
- [x] 将设置存储从 SharedPreferences 改为数据库

### 2026-08-05 (Android 构建修复与 APK 发布)
- [x] 修复 OneDrive 同步目录导致的 Gradle VFS 缓存失效风暴（禁用文件监控）
- [x] 升级 file_picker 8.3.7 → 11.0.3 并迁移 pickFiles API（AGP 9 兼容）
- [x] AGP 9.0.1 → 8.13.1、Kotlin 2.3.20 → 2.2.20（修复旧插件 MissingValueException）
- [x] 修复 android-34 SDK 平台不完整问题（Android Studio 重装 Android 14 SDK）
- [x] Gradle 保持 9.1.0（Flutter 3.44 官方默认，与 AGP 8.13.1 组合验证成功）
- [x] **APK 构建成功**：`build/app/outputs/flutter-apk/app-release.apk` (61.2MB，BUILD SUCCESSFUL 2m 13s)

### 2026-08-05 (AI 数据管理)
- [x] 新增 `ai_request_status` 表 + AiStatusDao（schemaVersion 2→3，自动迁移创建新表）
- [x] AI 引擎接入 statusCallback：真实请求时记录成功/失败状态（缓存命中不重复记录）
- [x] 词书页添加上方“数据管理”按钮（新建单词 FAB 上方，多选模式隐藏）
- [x] 数据管理页：状态统计卡片（总单词/已有AI释义/请求失败/无AI释义）+ 筛选 + 勾选重试
- [x] 一键选择需重试单词（通过 AI 缓存检测已有释义，已更新的单词不会重复请求）
- [x] 抽取共享 BatchUpdateDialog（word_list/deck_list/data_management 三处复用）
- [x] 备份 JSON 升级 v3：aiStatus 全表导出/导入恢复，wipe 覆盖时同步清空
- [x] 测试更新：备份导出/导入/wipe 均验证 aiStatus；`flutter analyze` 无 error，55 个测试全部通过

### 2026-08-05 (单词删除与缓存释放)
- [x] 单词三点菜单新增“删除单词”（红色确认对话框，提示 AI 缓存释放规则）
- [x] AppDatabase.deleteWordWithCleanup 事务：删 SM2 状态 + 变位缓存 + 单词记录
- [x] 跨词书引用检测（忽略大小写，与词书内查重规则一致）：无其他词书引用时释放 ai_lookup_cache 与 ai_request_status
- [x] 新增 delete_word_cleanup_test.dart（唯一词释放缓存 / 多词书保留缓存 / 大小写差异保留 / 删除不存在不报错）
- [x] 验证：flutter analyze 无 error，68 个测试全部通过

### 2026-08-05 (重置学习进度)
- [x] 词书页新建单词上方添加“重置学习进度”按钮（restart_alt 图标）
- [x] 黄色警告弹窗二次确认（amber 背景 + 警告图标，提示不可恢复）
- [x] AppDatabase.resetAllLearningProgress 事务：清空全部 sm2_states，proficiency 归零、lastStudyDate 置空，所有单词变回新词
- [x] 重置后 invalidate studyPlanProvider 全家（主页进度卡与学习计划同步刷新）
- [x] 新增 reset_progress_test.dart（重置清空 / 变回新词可抽取 / 空库不报错）
- [x] 验证：flutter analyze 无 error，74 个测试全部通过

### 2026-08-05 (v1.1.0 发布：夜间模式 / 完整备份 / AI 预设扩充)
- [x] 项目迁移出 OneDrive 至 `D:\Project Data\WortApp`，移除 `org.gradle.vfs.watch=false`（VFS 监控恢复默认）
- [x] 完整备份：gradle-wrapper.jar / gradlew / gradlew.bat 纳入版本控制（.gitignore 移除相关项）
- [x] 夜间模式：app_theme.dart 新增 darkTheme()，设置页主题切换（跟随系统/日间/夜间）
- [x] AI 预设扩充：新增 Gemini / 通义千问 / 阿里云百炼，DeepSeek 模型更新为 deepseek-v4-flash
- [x] APK 仅打包 64 位架构（abiFilters arm64-v8a/x86_64 + packaging 排除 32 位 .so）
- [x] 应用图标更新
- [x] 发布版本：v1.1.0+1，生成 RELEASE_NOTES.md

### 2026-08-04
- [x] 修复 AI 批量更新词义后释义未保存问题（空释义覆盖、overwrite 无效、坏缓存命中、提示词截断）
- [x] 修复 AI 结果复数（nounPlural）不落库、名词类型（nounType）"null" 字符串污染导致标签不显示
- [x] 新增缓存污染检测（_isPollutedCache）与防御性解析（_asNullableString）
- [x] 修复导入单词 AI 识别与查词界面展示不一致（详情页释义/例句优先展示缓存完整列表）
- [x] 编辑对话框数据源与详情页同步（优先 AI 缓存初始化，保存后写回缓存）
- [x] 修复编辑对话框 DropdownButton 断言崩溃（AI 词性 "Verb"/"名词" 等不规范值导致）
- [x] AI 词性/名词类型解析源头规范化（_normalizePartOfSpeech/_normalizeNounType）

### 待解决
- [ ] Web 平台数据库稳定性（建议直接在 Android 测试）

---

## 💡 下次开发建议

1. **优先在 Android 平台测试**
   - Web 平台的数据库问题在 Android 上不存在
   - 构建 APK 后安装到手机测试

2. **完善 AI 功能**
   - 缓存查词结果到数据库
   - 添加动词介词搭配详细信息

3. **添加学习统计**
   - 连续打卡天数
   - 掌握率趋势图表

4. **优化用户体验**
   - 单词编辑功能
   - 批量操作

---

*文档最后更新: 2026-08-05*
