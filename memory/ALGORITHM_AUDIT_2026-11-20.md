# WortApp 算法层审查报告（2026-11-20）

分支：`fix/search-deck-flow`（`master` 未改动）
审查范围：`lib/algorithms/*`、`lib/providers/study_provider.dart`、
`lib/data/database/app_database.dart#submitStudyFeedback`、`daos/sm2_dao.dart`、
`daos/study_stat_dao.dart`、`ui/screens/study/widgets/distractor_pool_mixin.dart`。
规格基准：`memory/ALGORITHM.md`。

新增回归测试：`test/algorithm_audit_test.dart`（16 个用例）。

---

## 一、已确认并修复的缺陷

### 1. 到期复习词的顺序被丢掉（调度与实际抽取不一致）

**位置**：`lib/algorithms/review_scheduler.dart:19,28`（`getDueReviewWords` / `getNewWords`）

SQL 层 `getDueReviewWordIds` 明确 `ORDER BY next_review ASC`，但拿到 id 后又用
`wordDao.getWordsByIds(ids)` 取词 —— 那是 `WHERE id IN (...)`，返回**表顺序**
（`word_dao.dart:40` 注释自己写着「顺序不保证」）。

后果：计划里「最逾期的在前」不成立。开启「每轮单词数」后只截前 N 条时，
抽到的是**任意 N 个到期词**，而不是最该复习的那几个。

**复现**（修复前失败）：三个词 next_review 分别为 -9/-5/-1 天，期望 `[id3,id2,id1]`，
实际 `[id1,id2,id3]`。

**修复**：按 id 序列重排后再返回（`_wordsInOrder`）。

### 2. SM-2 可能产出 0 天间隔，把单词卡死在「今天到期」

**位置**：`lib/algorithms/sm2_algorithm.dart:64`

`n ≥ 3` 分支用 `interval = currentInterval × EF'`。若数据里存在
`interval_days = 0` 且 `repetition_n ≥ 2`（导入 Excel / 备份 JSON / 同步合并 /
历史版本都可能产生），则 `0 × EF = 0`，`next_review` 落在**今天 00:00**。
而「到期」判定是 `next_review <= 今天 00:00`，于是该词当天反复出现在到期列表，
每次作答仍然 ×EF 得 0 —— 间隔永远不增长，词被永久卡住。

**复现**（修复前失败）：参数扫描中 `q=4, n=2, interval=0` → `intervalDays == 0.0`，
`nextReview == 今天 00:00`。

**修复**：计算末尾兜底 `if (newInterval < 1) newInterval = 1;`。

---

## 二、确认符合规格、未发现问题的部分

| 项目 | 结论 |
|---|---|
| EF 公式与下限 1.3；q=2 保留 n；q=0 重置 n | 与 `ALGORITHM.md` §4.2–4.4 一致 |
| 间隔单调增长（q≥3 连续作答） | 8 次连续「熟悉」间隔严格递增 |
| `next_review` 跨月/跨年 | 用 `DateTime(y, m, d+interval)` 构造，自动归一 |
| 首次/后续落库（`submitStudyFeedback`） | 事务、`totalReviews`、`correctStreak`、熟练度 clamp 均正确；学习活动不碰 `words.updated_at` |
| 每日额度扣减（新词用 `created_at`、复习用 `created_at < today && last_review >= today`） | 与 §6.1 一致，多次进入不超限 |
| 循环复习分批 / 进度持久化 / 跨天作废 | 一致（含跨批不重复） |
| 错词重考 FIFO 与上限 | 初次答错 + 最多 2 次重考，与「最多重考 2 次」一致 |
| 今日错词毕业（连续 3 轮首次答对） | 一致；其他模式答错会清零干净轮数 |
| 连续打卡（含跨月、跨年、夏令时、重复/乱序、未来日期、空集合） | 9 个边界用例全部通过 |
| 四选一干扰项（排除正确项、按文本去重、候选不足返回全部） | 一致 |

---

## 三、需要产品决策 / 未改动的问题

### 1. 「收藏优先」让同一个词在一节会话里被答两次，SM-2 连记两笔

**位置**：`lib/providers/study_provider.dart:340`

```dart
words = [...favorites, ...favorites, ...others];  // 非循环模式
```

这是 `ALGORITHM.md` §7.1 写明的设计（「重复加入，更易被抓到」），但副作用是：
同一会话内该词被答两遍 → SM-2 连算两次 → 重复次数 +2、间隔按两步增长
（例：n=1/间隔 1 天，连答两次「熟悉」直接跳到 n=3/间隔 15 天），
且 `completedCount` / 准确率也会被重复计入。

建议二选一：① 允许重复出现但只记一次 SM-2；② 保持只出现一次，
用「排前」而不是「复制」来提高曝光。测试已把当前行为固化为
`test/algorithm_audit_test.dart` 中的用例，改动前会先红。

### 2. 间隔没有上限，「简单」连点几次就把词送到几十年后

纯 SM-2 行为，但实际体验偏差很大。按当前公式与 q=5：

| 连续第 k 次「简单」 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| 间隔（天） | 1 | 6 | 17 | 49 | 147 | 456 | 1459 | 4815 | 16371 | **57300** |

第 10 次即约 157 年，反馈按钮上会显示「57300 天后复习」。
主流实现（Anki）会把间隔封顶（如 36500 天）。建议加 `maxIntervalDays` 常量。

### 3. 次要展示问题

- `study_provider.dart:440`：`loopLearned = total - pending.length`。
  今日错词模式下答错会把词重新加回 pending（长度不变），于是「第 N 轮 x/y」
  的 x 会少算（答了 2 个仍显示 1/5）。
- `study_provider.dart:143`：非循环 `progressTitle` 用 `currentIndex + 1`，
  会话完成那一帧会显示成 `N+1/N`。
- `StudySession.accuracy` 把重考答对也算进正确数，准确率偏高。

### 4. 死代码

- `study_provider.dart:511 startReviewSession()`：无任何调用方，且绕过每日额度、
  循环分批与断点快照。留着容易被误用，建议删除。
- `study_stat_dao.dart:133 getTodayWeakWordIds()`：无调用方（今日错词已改用
  `getTodayWrongWordIds`，判定口径不同：前者按「正确次数 < 3」，后者按「错误 > 0」）。

### 5. 性能

- `study_stat_dao.dart:186 getDistinctStudyDates()` 把整张 `study_stats` 全查回来
  再在 Dart 侧去重排序；历史数据多时会明显变慢。建议
  `SELECT DISTINCT date FROM study_stats ORDER BY date DESC`。
- `wordDao.getRandomWords(poolSize)` 用 `ORDER BY RANDOM()` 全表排序，词库上万时每次
  开课时会有一次明显卡顿。

---

## 四、拼写模式：键盘一收起就自动提交（同日追加）

**位置**：`lib/ui/screens/study/widgets/spell_mode_screen.dart`

拼写模式的「自动确认」被实现为**停止输入 800ms 后自动判定**（`_scheduleAutoCheck`）。
而键盘收起、输入法把候选词上屏时，都会再触发一次 `onChanged` / `_scheduleAutoCheck`，
防抖计时器照常跑完 → 用户还没输完的词被判错。这正是「输入法消失就自动提交」。

**修复**：

1. 给输入框加 `FocusNode`；**失焦（键盘收起）时取消待触发的判定**，
   且 `_scheduleAutoCheck` 只在「键盘打开」时才调度；计时器回调里再确认一次。
2. 输入法**仍在组词**（`TextEditingValue.composing.isValid`）时不判定，
   等上屏后再算 —— 否则在输入法里选词就等于交卷。
3. 顺带修掉一个会崩溃的缺陷：德语特殊字符键盘（ä/ö/ü/ß…）在输入框从未聚焦时
   读取到的 selection 是无效值 `-1`，`replaceRange(-1, -1, 'ä')` 直接抛
   `RangeError (start): Invalid value: Only valid value is 0: -1`，页面被打红。
   现在无效 selection 时追加到文本末尾。

**回归测试**：`test/spell_mode_auto_submit_test.dart`（4 个用例）
—— 键盘收起不提交、组词中不提交、保持焦点时自动确认仍生效、未聚焦点特殊字符不崩溃。
前两条与第四条在修复前均为红。

## 五、验证

```
dart analyze lib test                       → No issues found!
flutter test test/algorithm_audit_test.dart → 16 tests, All tests passed!
flutter test test/spell_mode_auto_submit_test.dart → 4 tests, All tests passed!
flutter test                               → 263 tests, All tests passed!
```
