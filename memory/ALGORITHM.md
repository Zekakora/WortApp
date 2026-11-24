# WortApp 学习算法说明

> 本文档介绍 WortApp 背单词功能的间隔重复算法与学习调度逻辑。
> 核心基于 **SuperMemo-2（SM-2）**，并针对本项目做了少量工程化扩展
> （每日额度、循环复习、错词重考、连续打卡等）。

---

## 1. 总览

一次学习的最小闭环：

```
抽词（每日计划）→ 展示题目 → 用户反馈（忘记/模糊/熟悉/简单）
        → 反馈映射为 0-5 评分 → SM-2 计算新状态并落库
        → 决定 next_review（下次复习日期）→ 计入本日统计
```

- **算法核心**：`lib/algorithms/sm2_algorithm.dart`（纯函数，无副作用）
- **落库/事务**：`AppDatabase.submitStudyFeedback`（唯一写入入口）
- **调度抽词**：`lib/algorithms/review_scheduler.dart`
- **会话编排**：`lib/providers/study_provider.dart`（`StudySessionNotifier`）
- **打卡统计**：`lib/algorithms/check_in.dart`
- **干扰项**：`lib/ui/screens/study/widgets/distractor_pool_mixin.dart`

---

## 2. 模块索引

| 文件 | 职责 |
|------|------|
| `lib/algorithms/sm2_algorithm.dart` | SM-2 公式、反馈→评分映射、下次复习日期计算 |
| `lib/algorithms/review_scheduler.dart` | 每日计划：新词 / 到期复习 / 兜底「今日已学」 |
| `lib/algorithms/check_in.dart` | 连续打卡天数计算（纯函数） |
| `lib/providers/study_provider.dart` | 学习会话状态机：抽词、抓词模式、循环分批、错词重考、进度持久化 |
| `lib/data/database/app_database.dart` | `submitStudyFeedback` 事务（SM-2 落库 + 熟练度 + 上次学习日期） |
| `lib/data/database/daos/sm2_dao.dart` | SM-2 状态读写、到期/新词计数与查询 |
| `lib/data/database/daos/study_stat_dao.dart` | 每日答题统计（出现/错误）、今日错词查询、打卡日期 |
| `lib/data/database/daos/word_dao.dart` | 单词读写、熟练度/上次学习日期更新、干扰项随机池 |
| `lib/ui/screens/study/widgets/distractor_pool_mixin.dart` | 四选一干扰项抽取（会话池 + 文本去重） |

---

## 3. 数据模型

### 3.1 `sm2_states`（SM-2 复习状态，每词一条）

| 字段 | 含义 |
|------|------|
| `repetition_n` | 重复次数 n（连续答对的次数；答错清零） |
| `interval_days` | 当前复习间隔（天） |
| `ease_factor` | 简易度因子 EF（初始 2.5，下限 1.3） |
| `next_review` | 下次复习日期（本地时区当天 00:00 + 间隔） |
| `last_review` | 上次复习时间 |
| `total_reviews` | 总复习次数（每次提交 +1） |
| `correct_streak` | 连续答对次数（quality < 3 清零） |
| `created_at` / `updated_at` | 创建/更新时间（`created_at` 用于判定「今日新词」） |

### 3.2 `words` 的学习字段

| 字段 | 含义 |
|------|------|
| `proficiency` | 熟练度 0-5，= `clamp(repetition_n, 0, 5)`，用于单词列表星标 |
| `last_study_date` | 上次学习日期，用于「今日已学」兜底与「今日单词」范围 |

> 学习活动（SM-2 / 熟练度 / 上次学习日期）**不更新 `words.updated_at`**，
> 以免同步时被误判为「词义内容编辑」而触发冲突（学习通道时间戳由
> `sm2_states.updated_at` 记录）。

### 3.3 `study_stats`（每日每题一行，`word_id + date` 唯一）

| 字段 | 含义 |
|------|------|
| `appearances` | 当天出现（答题）次数 |
| `errors` | 当天错误次数（忘记/模糊） |

---

## 4. SM-2 核心算法

### 4.1 反馈 → 评分（quality）

| 界面按钮 | 枚举 | quality |
|---------|------|---------|
| 忘记 | `FeedbackLevel.forgot` | 0 |
| 模糊 | `FeedbackLevel.hard` | 2 |
| 熟悉 | `FeedbackLevel.good` | 4 |
| 简单 | `FeedbackLevel.easy` | 5 |

### 4.2 简易度因子 EF

```
EF' = EF + (0.1 - (5 - q) × (0.08 + (5 - q) × 0.02))
EF' = max(1.3, EF')
```

各评分对应的 EF 增量：

| q | 0 | 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| ΔEF | −0.80 | −0.54 | −0.32 | −0.14 | 0 | +0.10 |

（本项目 UI 只产生 q = 0/2/4/5，q = 1、3 仅用于完整性。）

### 4.3 间隔与重复次数

```
q < 3（答错）：
  q == 2（模糊）： n 不变，interval = 1 天
  其余（忘记）  ： n = 0，  interval = 1 天

q ≥ 3（答对）：
  n' = n + 1
  n' == 1 → interval = 1 天
  n' == 2 → interval = 6 天
  n' ≥ 3  → interval = round(当前 interval × EF')
```

- 下次复习日期：`next_review = 本地当天 00:00 + interval 天`
  （用 `DateTime(y, m, d + interval)` 构造，自动跨月/跨年）。

### 4.4 与标准 SM-2 的差异（有意设计）

标准 SM-2 中任何 `q < 3` 都会把 n 清零。本项目对 **「模糊」(q = 2)**
做了特殊处理：**保留重复次数 n，仅把间隔压回 1 天**，用于「部分遗忘
（如只记错冠词）」的场景；「忘记」(q = 0) 仍完全重置。此行为有专门的
单元测试（`test/sm2_algorithm_test.dart`）。

---

## 5. 反馈提交（`AppDatabase.submitStudyFeedback`）

单次答题用一个事务完成，是学习状态的**唯一写入入口**：

1. 读取该词的 SM-2 状态；
2. **首次学习**（无状态）：以 `n=0, interval=0, EF=2.5` 计算并插入新状态，
   `created_at = now`（用于「今日新词」计数）；
3. **已有状态**：按当前状态更新 `repetition_n / interval_days / ease_factor /
   next_review / last_review / total_reviews(+1) / correct_streak`；
4. 更新 `words.proficiency = clamp(repetition_n, 0, 5)` 与
   `words.last_study_date = now`（`updateLearningProgress`）。

`correct_streak`：`quality ≥ 3 ? 上次 + 1 : 0`。

调用方：`ReviewScheduler.submitFeedback` 与
`StudySessionNotifier.submitFeedback` 共用此方法，避免重复实现。

---

## 6. 每日计划（`ReviewScheduler.getTodayPlan`）

### 6.1 额度扣减

| 项 | 规则 |
|----|------|
| 今日新词已学 | 今天创建 `sm2_states` 的行数（`created_at ≥ 今日 00:00`） |
| 今日复习已学 | `created_at < 今日` 且 `last_review ≥ 今日` 的行数 |
| 剩余新词额度 | `max(0, dailyNewLimit − 今日新词已学)` |
| 剩余复习额度 | `max(0, dailyReviewLimit − 今日复习已学)` |

> 额度按「今日已学」扣减，因此**同一天多次进入学习模式不会超限抽词**。
> 默认 `dailyNewLimit = 20`、`dailyReviewLimit = 100`（设置页可改）。

### 6.2 抽词

- **新词**：`words LEFT JOIN sm2_states WHERE sm2.id IS NULL`
  （从未学过，即没有 SM-2 状态），数量和为剩余新词额度。
- **到期复习词**：`next_review ≤ 今日 00:00`，按 `next_review` 升序，
  数量为剩余复习额度。
  - 词书过滤下推到 SQL（`JOIN words ON deck_id`），避免跨词书串扰。

### 6.3 兜底：循环复习

当新词与到期复习词**都为空**（额度用尽或没有到期词）时，返回
`todayWords = last_study_date ≥ 今日` 的**今日已学全部单词**，
让学习模式总能开始，进入「循环复习」而不是提示没有单词。

---

## 7. 学习会话与抓词模式

### 7.1 抓词模式（`WordPickMode`）

| 模式 | 行为 |
|------|------|
| `normal` | 新词 + 到期复习词（正常） |
| `favoriteBoost` | 收藏优先：非循环模式收藏词重复加入（更易被抓到）；循环模式每词每轮至多一次，收藏词排前 |
| `favoriteOnly` | 只抓计划中收藏的词 |
| `wrongTodayOnly` | 只抓「今日答错过」且未毕业的词（见 §8） |

### 7.2 每轮单词数与随机

- `roundLimit`（学习页「每轮单词数」，默认 20）：非循环模式直接截断词表；
  循环模式作为「每批发放量」。
- `randomPick`：在截断前打乱词池，使**抽取对象与顺序都随机**。

### 7.3 循环复习（额度用尽后）

每一「大轮」按伪随机顺序覆盖今日全部计划单词（每词每轮至多一次），
按每轮单词数分批发放：**每次进入只发一批，学完即结束**，进度持久化到
`settings` 表（key：`loop_progress_{mode}_{deckId}`），下次进入接着学下一批
（不重复、不遗漏），大轮覆盖完毕后自动开启下一大轮（轮数无上限）。
跨天或损坏的进度自动作废并重开一轮。

### 7.4 非循环会话快照（中途退出续学）

非循环会话在每次答题后把「完整词表 + 游标 + 错词重考队列」持久化到
`settings`（key：`session_progress_{deckId}`）。当天重进同一词书、同一
抓词模式（含随机开关）时，从断点续学，不重复已学单词；完成会话或跨天
自动清除。

### 7.5 错词重考（非循环）

答错（忘记/模糊）的词进入 **FIFO 重考队列**，主列表学完后依次重考：
答对移出、再错回到队尾，单轮最多重考 `maxRedoRetries = 2` 次，超限放弃，
避免无限循环。循环复习模式不使用重考（每大轮本就覆盖全部单词）。

---

## 8. 今日错词毕业机制（`wrongTodayOnly`）

- 词池 = `study_stats` 中「今日 `errors > 0`」的词。
  （答对不会把错词挤出列表；只有真答错过才算错词。）
- **毕业**：连续 `wrongWordGraduateStreak = 3` 轮「首次答对」后移出错词列表。
  一轮 = 覆盖全部错词的一次完整复习，天然有时间间隔，抗短时记忆。
- 答错：清零该词干净轮数，并排到本轮队尾，单轮最多重排
  `maxReQueuePerRound = 2` 次。
- 在**其他模式**答错同词，也会清零其在错词复习里的干净轮数
  （避免别处遗忘后仍被误判为已毕业）。

---

## 9. 连续打卡（`calculateCheckInStreak`）

- 判定依据：`study_stats` 中**存在任意答题记录**的日期即视为已打卡。
- 规则：
  - 今天已打卡 → 从今天向前连续计数；
  - 今天未打卡但昨天已打卡 → 从昨天开始计数（当天尚未学习不算断签）；
  - 最近打卡日早于昨天 → 断签，返回 0。
- 输入自动去重并按日期归一（跨月/跨年用 `DateTime(y, m, d - 1)` 处理）。

---

## 10. 四选一干扰项（`DistractorPool`）

- 会话启动时从**全词库**随机抽取「每轮单词数 × 5」个单词组成选项池，
  整个会话复用（纯同步，避免每题查库）。
- 每题从池中抽取：排除正确词本身、按选项文本去重（避免同释义/同词形重复）。
- 候选不足时返回可用的全部。

---

## 11. 关键常量与配置

| 名称 | 默认值 | 位置 |
|------|-------|------|
| `dailyNewLimit` | 20 | `settingsProvider` / `settings` 表 |
| `dailyReviewLimit` | 100 | 同上 |
| 每轮单词数 `roundLimit` | 20 | 学习页 `study_screen.dart` |
| `maxRedoRetries` | 2 | `StudySessionNotifier` |
| `wrongWordGraduateStreak` | 3 | `StudySessionNotifier` |
| `maxReQueuePerRound` | 2 | `StudySessionNotifier` |
| EF 初始 / 下限 | 2.5 / 1.3 | `sm2_algorithm.dart` |

---

## 12. 测试覆盖

| 测试文件 | 覆盖点 |
|---------|--------|
| `test/sm2_algorithm_test.dart` | 模糊（q=2）保留序列、忘记重置、EF 变化、模糊后答对延续 |
| `test/proficiency_test.dart` | 熟练度随重复次数更新、封顶、答错归零、重置归零 |
| `test/study_limits_test.dart` | 每日新词/复习额度扣减、额度用尽兜底 |
| `test/review_scheduler` 相关 | 到期词/新词抽取 |
| `test/study_loop_pick_test.dart` | 循环分批、跨批不重复、下一大轮、收藏优先/只抓收藏、今日错词毕业与重排 |
| `test/redo_queue_test.dart` | 错词重考 FIFO、重考上限 |
| `test/session_resume_test.dart` | 非循环会话断点续学、模式切换 |
| `test/random_pick_test.dart` | 随机背词 |
| `test/check_in_test.dart` | 连续打卡判定与统计落库 |
| `test/distractor_pool_test.dart` | 干扰项去重与排除正确项 |
| `test/favorite_toggle_test.dart` | 收藏抓词 |
| `test/reset_progress_test.dart` | 重置学习进度 |

---

## 13. 参考

- [SuperMemo — Two-component model of memory](https://supermemo.guru/wiki/SuperMemo_Algorithm:_Two-component_model_of_memory)
- [SM-2 算法说明（Wikipedia）](https://en.wikipedia.org/wiki/SuperMemo#Description_of_SM-2_algorithm)

---

*文档创建：2026-10-11*
