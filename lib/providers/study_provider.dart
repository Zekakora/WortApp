import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../algorithms/check_in.dart';
import '../algorithms/review_scheduler.dart';
import '../algorithms/sm2_algorithm.dart';
import '../data/database/app_database.dart';
import 'database_provider.dart';
import 'settings_provider.dart';

/// 复习调度器 Provider
final reviewSchedulerProvider = Provider<ReviewScheduler?>((ref) {
  final db = ref.watch(databaseProvider);
  if (db == null) return null;
  return ReviewScheduler(db);
});

/// 当前学习计划 Provider
///
/// - 监听 [studySessionProvider]：每次答题提交反馈后自动重新计算计划，
///   主页学习进度随之实时刷新
/// - 使用设置中的每日新词/复习上限（而非默认值）
final studyPlanProvider = FutureProvider.family<StudyPlan?, int>((ref, deckId) async {
  final scheduler = ref.watch(reviewSchedulerProvider);
  if (scheduler == null) return null;
  // 监听学习会话：提交反馈（state 变化）后重新计算，驱动主页进度刷新
  ref.watch(studySessionProvider);
  final settings = ref.watch(settingsProvider);
  return scheduler.getTodayPlan(
    deckId: deckId,
    dailyNewLimit: settings.dailyNewLimit,
    dailyReviewLimit: settings.dailyReviewLimit,
  );
});

/// 抓词模式
///
/// - [normal]：正常抓词（新词 + 到期复习词，上限用尽后兜底今日已学）
/// - [favoriteBoost]：收藏优先——非循环模式收藏词重复加入（概率更高）；
///   循环模式每词每轮至多一次，仅将收藏词排在轮内靠前优先出现
/// - [favoriteOnly]：只抓今天该学单词中的收藏词汇
/// - [wrongTodayOnly]：只抓今日错词——今天该学单词中有今日答题记录
///   且正确次数（出现次数 - 错误次数）少于 3 次的词汇
enum WordPickMode { normal, favoriteBoost, favoriteOnly, wrongTodayOnly }

/// 获取词书中所有单词（用于学习模式）
final allWordsForStudyProvider = FutureProvider.family<List<Word>, int>((ref, deckId) async {
  final db = ref.watch(databaseProvider);
  if (db == null) return [];
  return db.wordDao.getWordsByDeck(deckId);
});

/// 学习会话状态
class StudySession {
  final List<Word> words;
  /// 干扰项选项池：会话启动时从所有词库随机抽取（每轮单词数 × 5），
  /// 供四选一模式整个会话使用，每道题的干扰项从池中同步抽取
  final List<Word> distractorPool;
  final int currentIndex;
  final int completedCount;
  final int correctCount;
  final bool isCompleted;
  final bool isLoading;
  final String? error;
  /// 是否为循环复习模式（今日新词/复习上限均用尽，兜底复习今日已学单词）
  ///
  /// 循环模式下每一大轮按伪随机顺序覆盖全部计划单词（每词每轮至多出现
  /// 一次），并按“每轮单词数”分批发放：每次进入学习只发一批，学完即
  /// 结束会话；进度持久化（settings 表），下次进入接着学下一批（不重复
  /// 不遗漏），大轮内全部覆盖完毕后自动开启下一大轮，轮数无上限
  final bool isLooping;
  /// 当前大轮数（从 1 开始；仅循环模式有意义，无上限）
  final int loopCount;
  /// 循环复习模式：当前大轮总词数
  final int loopTotal;
  /// 循环复习模式：进入本次会话前，当前大轮已学词数
  final int loopLearned;
  /// 循环复习模式：当前大轮尚未答过的单词 id（保持本轮伪随机顺序；
  /// 已发放未作答的词仍在其中，答完一个移除一个并持久化）
  final List<int> loopPendingIds;
  /// 循环复习模式：当前大轮创建日期（yyyy-MM-dd），跨天自动开启新一轮
  final String loopDate;
  /// 今日错词模式：每个词连续「首次答对」的轮数（毕业判定，达到
  /// [StudySessionNotifier.wrongWordGraduateStreak] 后移出错词列表）
  final Map<int, int> loopStreak;
  /// 今日错词模式：当前轮内每个词已重排次数（答错排到队尾，上限防死循环）
  final Map<int, int> loopReQueueCount;
  /// 错词重考队列：答错（忘记/模糊）的单词 id，主列表学完后按先进先出重考。
  /// 答对移出；循环复习模式不使用重考（每大轮本就覆盖全部单词）
  final List<int> redoQueue;
  /// 各单词本轮内重考次数（达到上限后放弃重考，避免无限循环）
  final Map<int, int> redoRetries;

  const StudySession({
    required this.words,
    this.distractorPool = const [],
    this.currentIndex = 0,
    this.completedCount = 0,
    this.correctCount = 0,
    this.isCompleted = false,
    this.isLoading = false,
    this.error,
    this.isLooping = false,
    this.loopCount = 1,
    this.loopTotal = 0,
    this.loopLearned = 0,
    this.loopPendingIds = const [],
    this.loopDate = '',
    this.loopStreak = const {},
    this.loopReQueueCount = const {},
    this.redoQueue = const [],
    this.redoRetries = const {},
  });

  /// 是否处于错词重考阶段（主列表已学完，正在重考答错的单词）
  bool get isRedoPhase =>
      !isLooping && currentIndex >= words.length && redoQueue.isNotEmpty;

  /// 当前单词：主列表按序推进；重考阶段取重考队列队首
  Word? get currentWord {
    if (isRedoPhase && redoQueue.isNotEmpty) {
      final id = redoQueue.first;
      for (final w in words) {
        if (w.id == id) return w;
      }
      return null;
    }
    return currentIndex < words.length ? words[currentIndex] : null;
  }

  double get progress {
    if (words.isEmpty) return 0;
    if (isRedoPhase) return 1.0;
    return currentIndex / words.length;
  }

  double get accuracy =>
      completedCount == 0 ? 0 : correctCount / completedCount;

  /// 标题进度：正常模式 "x/y"；重考阶段 "重考 N 词"；循环模式 "第N轮 x/y"
  String get progressTitle {
    if (isLooping) {
      return '第$loopCount轮 ${loopLearned + currentIndex + 1}/$loopTotal';
    }
    if (isRedoPhase) {
      return '重考 ${redoQueue.length} 词';
    }
    return '${currentIndex + 1}/${words.length}';
  }

  StudySession copyWith({
    List<Word>? words,
    List<Word>? distractorPool,
    int? currentIndex,
    int? completedCount,
    int? correctCount,
    bool? isCompleted,
    bool? isLoading,
    String? error,
    bool? isLooping,
    int? loopCount,
    int? loopTotal,
    int? loopLearned,
    List<int>? loopPendingIds,
    String? loopDate,
    Map<int, int>? loopStreak,
    Map<int, int>? loopReQueueCount,
    List<int>? redoQueue,
    Map<int, int>? redoRetries,
  }) {
    return StudySession(
      words: words ?? this.words,
      distractorPool: distractorPool ?? this.distractorPool,
      currentIndex: currentIndex ?? this.currentIndex,
      completedCount: completedCount ?? this.completedCount,
      correctCount: correctCount ?? this.correctCount,
      isCompleted: isCompleted ?? this.isCompleted,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLooping: isLooping ?? this.isLooping,
      loopCount: loopCount ?? this.loopCount,
      loopTotal: loopTotal ?? this.loopTotal,
      loopLearned: loopLearned ?? this.loopLearned,
      loopPendingIds: loopPendingIds ?? this.loopPendingIds,
      loopDate: loopDate ?? this.loopDate,
      loopStreak: loopStreak ?? this.loopStreak,
      loopReQueueCount: loopReQueueCount ?? this.loopReQueueCount,
      redoQueue: redoQueue ?? this.redoQueue,
      redoRetries: redoRetries ?? this.redoRetries,
    );
  }
}

/// 学习会话 StateNotifier
class StudySessionNotifier extends StateNotifier<StudySession> {
  final AppDatabase? _db;
  /// 当前会话所属词书（循环复习进度持久化用）
  int? _sessionDeckId;
  /// 当前会话抓词模式（非循环会话进度快照持久化用）
  WordPickMode? _sessionPickMode;

  StudySessionNotifier(this._db)
      : super(const StudySession(words: []));

  /// 开始学习会话
  ///
  /// 按每日新词/复习上限从调度器抽取单词（已扣除今日已学数量，
  /// 多次进入不会超限）；新词与复习上限均用尽时，自动进入循环复习
  /// 模式——每一大轮按伪随机顺序覆盖今天全部计划单词（每词每轮至多
  /// 出现一次），并按“每轮单词数”分批发放：每次进入学习只发一批，
  /// 学完即结束会话，进度持久化到 settings 表，下次进入接着学下一批
  /// （不重复不遗漏），大轮内全部覆盖完毕后自动开启下一大轮（轮数
  /// 无上限）；非循环模式直接受 [roundLimit]（每轮单词数）截断。
  ///
  /// [pickMode] 控制抓词策略：
  /// - 收藏优先：非循环模式收藏词重复加入（概率翻倍）；循环模式
  ///   保证每词每轮至多一次，仅将收藏词排在轮内靠前位置优先出现
  /// - 只抓收藏：仅保留计划中收藏的单词
  Future<void> startSession({
    required int deckId,
    int dailyNewLimit = 20,
    int dailyReviewLimit = 100,
    int? roundLimit,
    WordPickMode pickMode = WordPickMode.normal,
  }) async {
    if (_db == null) {
      state = const StudySession(words: [], error: '数据库未就绪');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      _sessionDeckId = deckId;
      _sessionPickMode = pickMode;
      final today = _dateKey(DateTime.now());
      final scheduler = ReviewScheduler(_db);
      final plan = await scheduler.getTodayPlan(
        deckId: deckId,
        dailyNewLimit: dailyNewLimit,
        dailyReviewLimit: dailyReviewLimit,
      );

      // 今日错词模式：与每日额度无关，始终按循环复习处理；
      // 词池 = 今天答错过（忘记/模糊）且未毕业的词。
      // 因为答错的词 SM-2 下次复习被推到明天、不再是今日到期词，
      // 若依赖每日额度抽取会导致「有错词却提示没有」的冲突
      final wrongMode = pickMode == WordPickMode.wrongTodayOnly;
      final isLooping = plan.todayWords.isNotEmpty || wrongMode;

      // 非循环模式：优先恢复同一天被中断的会话（答词后中途退出会持久化
      // 快照），从上次位置续学，不重复已学单词；循环模式或恢复失败时
      // 清除残留快照并重新抓词
      var resumedFromSnapshot = false;
      var resumeCurrentIndex = 0;
      var resumeCompletedCount = 0;
      var resumeCorrectCount = 0;
      var resumeRedoQueue = <int>[];
      var resumeRedoRetries = <int, int>{};
      var words = <Word>[];
      if (wrongMode) {
        final wrongIds = await _db.studyStatDao.getTodayWrongWordIds(
          deckId: deckId,
        );
        final allWords = await _db.wordDao.getWordsByDeck(deckId);
        words = allWords.where((w) => wrongIds.contains(w.id)).toList();
        if (words.isEmpty) {
          state = const StudySession(
            words: [],
            error: '今天没有需要复习的错词，请先练习或切换抓词模式',
          );
          return;
        }
      } else if (!isLooping) {
        final resumed = await _tryResumeSession(
          deckId: deckId,
          pickMode: pickMode,
          today: today,
        );
        if (resumed != null) {
          words = resumed.words;
          resumeCurrentIndex = resumed.currentIndex;
          resumeCompletedCount = resumed.completedCount;
          resumeCorrectCount = resumed.correctCount;
          resumeRedoQueue = resumed.redoQueue;
          resumeRedoRetries = resumed.redoRetries;
          resumedFromSnapshot = true;
        }
      }
      if (!resumedFromSnapshot) {
        await _clearSessionSnapshot(deckId);

        if (!wrongMode) {
          // 新词 + 复习 + （上限均用尽时）今日已学单词
          words = <Word>[
            ...plan.newWords,
            ...plan.reviewWords,
            ...plan.todayWords,
          ];

          if (words.isEmpty) {
            final hasWords = await _db.wordDao.getWordCount(deckId) > 0;
            state = StudySession(
              words: [],
              error: hasWords ? '今日没有待学习的单词' : '词书中没有单词，请先导入单词',
            );
            return;
          }

          // 按抓词模式调整：收藏优先 / 只抓收藏
          switch (pickMode) {
            case WordPickMode.favoriteBoost:
              final favorites = words.where((w) => w.isFavorite).toList();
              final others = words.where((w) => !w.isFavorite).toList();
              if (isLooping) {
                // 循环模式：每词每轮至多出现一次，收藏词仅排前优先出现
                favorites.shuffle();
                others.shuffle();
                words = [...favorites, ...others];
              } else {
                // 非循环模式：收藏词重复加入（共 2 次）提高被抓中概率，
                // roundLimit 截断时收藏词优先保留
                words = [...favorites, ...favorites, ...others];
              }
              break;
            case WordPickMode.favoriteOnly:
              words = words.where((w) => w.isFavorite).toList();
              if (words.isEmpty) {
                state = const StudySession(
                  words: [],
                  error: '今天该学的单词中没有收藏的词汇，请先收藏或切换抓词模式',
                );
                return;
              }
              break;
            case WordPickMode.wrongTodayOnly:
              // 不会到达：wrongTodayOnly 已在上方独立处理
              break;
            case WordPickMode.normal:
              break;
          }
        }
      }

      // 伪随机打乱：正常模式按“每轮单词数”截断；循环模式分批发放，
      // 进度持久化到 settings 表——每次进入只发一批，答完一个词即从
      // 本轮剩余中移除，下次进入接着学下一批（不重复不遗漏）
      var loopCount = 1;
      var loopTotal = 0;
      var loopLearned = 0;
      var loopPendingIds = <int>[];
      var loopDate = '';
      var loopStreak = <int, int>{};
      var loopReQueueCount = <int, int>{};
      if (isLooping) {
        final progress = await _readLoopProgress(deckId, pickMode);
        final batchSize = (roundLimit != null && roundLimit > 0)
            ? roundLimit
            : words.length;
        final sameDay = progress != null && progress.date == today;
        // 今日错词模式：本轮池 = 今日答错过的词中尚未毕业（连续干净轮数
        // 未达上限）的词；其余模式不额外过滤。毕业计数仅同日延续，跨天清零
        final wrongIds = pickMode == WordPickMode.wrongTodayOnly
            ? await _db.studyStatDao.getTodayWrongWordIds(deckId: deckId)
            : null;
        loopStreak = sameDay ? progress.streak : const <int, int>{};
        loopReQueueCount =
            sameDay ? progress.reQueueCount : const <int, int>{};

        bool validForRound(Word w) {
          if (pickMode == WordPickMode.favoriteOnly && !w.isFavorite) {
            return false;
          }
          if (wrongIds != null) {
            if (!wrongIds.contains(w.id)) return false;
            if ((loopStreak[w.id] ?? 0) >= wrongWordGraduateStreak) return false;
          }
          return true;
        }

        List<Word> buildRoundOrder() {
          final order = words.where(validForRound).toList();
          if (pickMode != WordPickMode.favoriteBoost) order.shuffle();
          return order;
        }

        if (progress != null && sameDay && progress.pendingIds.isNotEmpty) {
          // 继续本轮：按本轮伪随机顺序取下一批（已学词不在剩余列表中）
          final allWords = await _db.wordDao.getWordsByDeck(deckId);
          final byId = {for (final w in allWords) w.id: w};
          final pending = <Word>[];
          for (final id in progress.pendingIds) {
            final w = byId[id];
            if (w != null && validForRound(w)) pending.add(w);
          }
          if (pending.isEmpty) {
            // 剩余词已失效（词被删除/收藏过滤/全部毕业）：直接开启新一轮
            final order = buildRoundOrder();
            if (order.isEmpty) {
              state = const StudySession(
                words: [],
                error: '今天没有需要复习的错词，请先练习或切换抓词模式',
              );
              return;
            }
            words = order.take(batchSize).toList();
            loopCount = progress.loopCount + 1;
            loopTotal = order.length;
            loopLearned = 0;
            loopPendingIds = order.map((w) => w.id).toList();
            loopDate = today;
            loopReQueueCount = const {};
          } else {
            words = pending.take(batchSize).toList();
            loopCount = progress.loopCount;
            loopTotal = progress.total;
            loopLearned = progress.total - pending.length;
            loopPendingIds = pending.map((w) => w.id).toList();
            loopDate = progress.date;
          }
        } else {
          // 开启新一轮（首次进入，或上一轮已覆盖完毕）：
          // 收藏优先模式保持“收藏词在前”的顺序，其余模式整体打乱；
          // 今日错词模式剔除已毕业的词，重排计数清零
          final order = buildRoundOrder();
          if (order.isEmpty) {
            state = const StudySession(
              words: [],
              error: '今天没有需要复习的错词，请先练习或切换抓词模式',
            );
            return;
          }
          words = order.take(batchSize).toList();
          loopCount = sameDay ? progress.loopCount + 1 : 1;
          loopTotal = order.length;
          loopLearned = 0;
          loopPendingIds = order.map((w) => w.id).toList();
          loopDate = today;
          loopReQueueCount = const {};
        }
        await _saveLoopProgress(
          deckId,
          pickMode,
          _LoopProgress(
            date: loopDate,
            loopCount: loopCount,
            total: loopTotal,
            pendingIds: loopPendingIds,
            streak: loopStreak,
            reQueueCount: loopReQueueCount,
          ),
        );
      } else if (!resumedFromSnapshot &&
          roundLimit != null &&
          roundLimit > 0 &&
          words.length > roundLimit) {
        words = words.take(roundLimit).toList();
      }

      // 干扰项选项池：从所有词库随机抽取“每轮单词数 × 5”个单词，
      // 四选一模式整个会话只从这个池子里抽干扰项（纯同步，不会二次刷新）
      final poolSize = words.length * 5;
      final distractorPool = await _db.wordDao.getRandomWords(poolSize);

      state = StudySession(
        words: words,
        distractorPool: distractorPool,
        currentIndex: resumeCurrentIndex,
        completedCount: resumeCompletedCount,
        correctCount: resumeCorrectCount,
        isLooping: isLooping,
        loopCount: loopCount,
        loopTotal: loopTotal,
        loopLearned: loopLearned,
        loopPendingIds: loopPendingIds,
        loopDate: loopDate,
        loopStreak: loopStreak,
        loopReQueueCount: loopReQueueCount,
        redoQueue: resumeRedoQueue,
        redoRetries: resumeRedoRetries,
      );
    } catch (e) {
      state = StudySession(words: [], error: '加载单词失败: $e');
    }
  }

  /// 开始复习会话（使用 SM-2 调度）
  Future<void> startReviewSession({
    required int deckId,
    int newLimit = 20,
    int reviewLimit = 100,
  }) async {
    if (_db == null) {
      state = const StudySession(words: [], error: '数据库未就绪');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final scheduler = ReviewScheduler(_db);
      final plan = await scheduler.getTodayPlan(
        deckId: deckId,
        dailyNewLimit: newLimit,
        dailyReviewLimit: reviewLimit,
      );

      final words = <Word>[];
      words.addAll(plan.newWords);
      words.addAll(plan.reviewWords);

      if (words.isEmpty) {
        state = const StudySession(words: [], error: '今日无待复习单词');
        return;
      }

      // 打乱顺序
      words.shuffle();

      // 干扰项选项池：从所有词库随机抽取会话词量 × 5 个单词
      final poolSize = words.length * 5;
      final distractorPool = await _db.wordDao.getRandomWords(poolSize);

      state = StudySession(words: words, distractorPool: distractorPool);
    } catch (e) {
      state = StudySession(words: [], error: '加载复习单词失败: $e');
    }
  }

  /// 错词重考上限：同一单词在本轮内最多重考次数（超过后放弃，避免无限循环）
  static const int maxRedoRetries = 2;
  /// 今日错词：连续多少轮「首次答对」后才算练熟毕业（移出错词列表）。
  /// 一轮 = 覆盖全部错词的一次完整复习，天然有时间间隔，抗短时记忆。
  static const int wrongWordGraduateStreak = 3;
  /// 今日错词：答错后每轮最多重排到队尾的次数（防无限循环）
  static const int maxReQueuePerRound = 2;

  /// 提交反馈并进入下一题
  ///
  /// - SM-2 状态落库与刷新上次学习日期收敛到 [AppDatabase.submitStudyFeedback]
  /// - 答错（忘记/模糊）的单词进入错词重考队列：主列表学完后按先进先出重考，
  ///   答对移出、再错回到队尾（受 [maxRedoRetries] 上限约束）；
  ///   循环复习模式不使用重考（每大轮本就覆盖全部单词）
  Future<void> submitFeedback(FeedbackLevel feedback) async {
    final word = state.currentWord;
    if (word == null || _db == null) return;

    final quality = SM2Algorithm.feedbackToQuality(feedback);

    // 更新 SM-2 状态 + 上次学习日期（共享逻辑）
    await _db.submitStudyFeedback(wordId: word.id, quality: quality);

    // 记录错误统计（忘记/模糊计为错误，用于错误统计排行榜）
    await _db.studyStatDao.recordAttempt(
      wordId: word.id,
      isError: quality < 3,
    );

    final isCorrect = quality >= 3;
    final isLooping = state.isLooping;
    final isRedo = state.isRedoPhase;
    final nextIndex = state.currentIndex + 1;

    // 任何模式答错都清零该词在「今日错词」中的连续干净轮数。
    // 今日错词循环分支自身会重置，这里跳过避免重复读写
    if (!isCorrect &&
        _sessionDeckId != null &&
        !(isLooping && _sessionPickMode == WordPickMode.wrongTodayOnly)) {
      await _resetWrongReviewStreak(_sessionDeckId!, word.id);
    }

    // 循环复习模式：答完一个词即从本轮剩余中移除并持久化进度，
    // 中途退出或下次进入均不会重复学到；一批学完后会话结束
    // （不自动加载下一批），剩余词留待下次进入继续，
    // 全部覆盖后下次进入自动开启下一大轮（轮数无上限）。
    // 今日错词模式特殊处理：答错清零「连续干净轮数」并排到本轮队尾
    // （同轮后面批次再次复习，每轮上限 [maxReQueuePerRound] 次防死循环）；
    // 首次答对则累计干净轮数，达到 [wrongWordGraduateStreak] 后移出错词列表
    if (isLooping && _sessionDeckId != null) {
      var remaining = List<int>.of(state.loopPendingIds)..remove(word.id);
      var loopStreak = Map<int, int>.of(state.loopStreak);
      var loopReQueueCount = Map<int, int>.of(state.loopReQueueCount);
      if (_sessionPickMode == WordPickMode.wrongTodayOnly) {
        if (!isCorrect) {
          loopStreak[word.id] = 0;
          final requeues = loopReQueueCount[word.id] ?? 0;
          if (requeues < maxReQueuePerRound) {
            // 排到本轮队尾，学完其余词后再出现
            loopReQueueCount[word.id] = requeues + 1;
            remaining.add(word.id);
          }
        } else if ((loopReQueueCount[word.id] ?? 0) == 0) {
          // 首次答对才累计干净轮数；答错后重排再答对不计（本轮已算失败）
          loopStreak[word.id] = (loopStreak[word.id] ?? 0) + 1;
        }
      }
      state = state.copyWith(
        currentIndex: nextIndex,
        completedCount: state.completedCount + 1,
        correctCount: state.correctCount + (isCorrect ? 1 : 0),
        isCompleted: nextIndex >= state.words.length,
        loopPendingIds: remaining,
        loopStreak: loopStreak,
        loopReQueueCount: loopReQueueCount,
      );
      await _saveLoopProgress(
        _sessionDeckId!,
        _sessionPickMode ?? WordPickMode.normal,
        _LoopProgress(
          date: state.loopDate,
          loopCount: state.loopCount,
          total: state.loopTotal,
          pendingIds: remaining,
          streak: loopStreak,
          reQueueCount: loopReQueueCount,
        ),
      );
      return;
    }

    // 错词重考：主列表正常推进，答错的词进入重考队列（FIFO，队尾加入）
    var redoQueue = List<int>.of(state.redoQueue);
    final redoRetries = Map<int, int>.of(state.redoRetries);

    // 正在重考该词（当前词来自重考队列队首）：答完先移出队列
    if (isRedo && redoQueue.isNotEmpty && redoQueue.first == word.id) {
      redoQueue.removeAt(0);
    }

    if (!isCorrect) {
      final tries = (redoRetries[word.id] ?? 0) + 1;
      if (tries <= maxRedoRetries) {
        // 未达重考上限：加入队尾等待重考（重考阶段再次答错也回到队尾）
        redoQueue.add(word.id);
        redoRetries[word.id] = tries;
      } else {
        // 重考超过上限：放弃该词，避免无限循环
        redoRetries.remove(word.id);
      }
    } else if (isRedo) {
      // 重考答对：清除重考次数记录
      redoRetries.remove(word.id);
    }

    final isCompleted = nextIndex >= state.words.length && redoQueue.isEmpty;

    state = state.copyWith(
      currentIndex: nextIndex,
      completedCount: state.completedCount + 1,
      correctCount: state.correctCount + (isCorrect ? 1 : 0),
      isCompleted: isCompleted,
      redoQueue: redoQueue,
      redoRetries: redoRetries,
    );

    // 非循环模式：持久化会话快照（中途退出后可续学，不重复已学单词）；
    // 会话完成时清除，下次进入重新抓词
    if (!isLooping && _sessionDeckId != null && _sessionPickMode != null) {
      if (isCompleted) {
        await _clearSessionSnapshot(_sessionDeckId!);
      } else {
        await _saveSessionSnapshot(
          _sessionDeckId!,
          _SessionSnapshot(
            date: _dateKey(DateTime.now()),
            pickMode: _sessionPickMode!.name,
            wordIds: state.words.map((w) => w.id).toList(),
            currentIndex: state.currentIndex,
            redoQueue: state.redoQueue,
            redoRetries: state.redoRetries,
            completedCount: state.completedCount,
            correctCount: state.correctCount,
          ),
        );
      }
    }
  }

  /// 任意模式答错时清零该词在「今日错词」复习中的连续干净轮数，
  /// 避免在其他模式复习中遗忘后，错词列表仍把它误判为已毕业。
  Future<void> _resetWrongReviewStreak(int deckId, int wordId) async {
    if (_db == null) return;
    try {
      final progress =
          await _readLoopProgress(deckId, WordPickMode.wrongTodayOnly);
      if (progress == null ||
          progress.streak.isEmpty ||
          !progress.streak.containsKey(wordId)) {
        return;
      }
      final streak = Map<int, int>.of(progress.streak)..[wordId] = 0;
      await _saveLoopProgress(
        deckId,
        WordPickMode.wrongTodayOnly,
        _LoopProgress(
          date: progress.date,
          loopCount: progress.loopCount,
          total: progress.total,
          pendingIds: progress.pendingIds,
          streak: streak,
          reQueueCount: progress.reQueueCount,
        ),
      );
    } catch (_) {
      // 清零失败不影响学习
    }
  }

  /// 切换收藏：落库并同步当前会话内单词的收藏状态（用于学习页即时刷新星星）
  Future<void> toggleFavorite(int wordId) async {
    if (_db == null) return;
    Word? target;
    for (final w in state.words) {
      if (w.id == wordId) {
        target = w;
        break;
      }
    }
    if (target == null) return;

    await _db.wordDao.updateFavorite(wordId, !target.isFavorite);
    final updated = await _db.wordDao.getWordById(wordId);
    if (updated == null) return;
    state = state.copyWith(
      words: [
        for (final w in state.words) w.id == wordId ? updated : w,
      ],
    );
  }

  /// 重置会话（不影响已持久化的循环复习进度；清除未完成的非循环会话快照）
  Future<void> reset() async {
    if (_sessionDeckId != null) {
      await _clearSessionSnapshot(_sessionDeckId!);
    }
    _sessionDeckId = null;
    _sessionPickMode = null;
    state = const StudySession(words: []);
  }

  /// 读取词书循环复习进度（无/损坏时返回 null，由调用方开启新一轮）
  Future<_LoopProgress?> _readLoopProgress(
      int deckId, WordPickMode mode) async {
    if (_db == null) return null;
    final raw = await _db.getSetting(_loopProgressKey(deckId, mode));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _LoopProgress(
        date: map['date'] as String? ?? '',
        loopCount: (map['loopCount'] as num?)?.toInt() ?? 1,
        total: (map['total'] as num?)?.toInt() ?? 0,
        pendingIds: (map['pendingIds'] as List? ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        streak: _readIntMap(map['streak']),
        reQueueCount: _readIntMap(map['reQueueCount']),
      );
    } catch (_) {
      return null;
    }
  }

  /// 保存词书循环复习进度（失败不影响学习）
  Future<void> _saveLoopProgress(
      int deckId, WordPickMode mode, _LoopProgress progress) async {
    if (_db == null) return;
    try {
      await _db.setSetting(
        _loopProgressKey(deckId, mode),
        jsonEncode({
          'date': progress.date,
          'loopCount': progress.loopCount,
          'total': progress.total,
          'pendingIds': progress.pendingIds,
          'streak': progress.streak.map((k, v) => MapEntry('$k', v)),
          'reQueueCount':
              progress.reQueueCount.map((k, v) => MapEntry('$k', v)),
        }),
      );
    } catch (_) {
      // 持久化失败不影响学习
    }
  }

  /// 将 JSON 中的字符串键 int 值映射解码为 `Map<int,int>`
  static Map<int, int> _readIntMap(Object? raw) {
    final map = raw;
    if (map is! Map) return const {};
    return map.map(
      (k, v) => MapEntry(int.parse('$k'), (v as num).toInt()),
    );
  }

  static String _loopProgressKey(int deckId, WordPickMode mode) =>
      'loop_progress_${mode.name}_$deckId';

  /// 尝试恢复同一词书、同抓词模式、同一天被中断的非循环学习会话。
  ///
  /// 快照保存了完整词表 + 游标 + 错词重考队列。重进后从上次位置续学，
  /// 不重复已学单词。返回 null 表示没有可恢复的会话（由调用方重新抓词）。
  Future<_ResumedSession?> _tryResumeSession({
    required int deckId,
    required WordPickMode pickMode,
    required String today,
  }) async {
    if (_db == null) return null;
    final snap = await _readSessionSnapshot(deckId);
    if (snap == null ||
        snap.date != today ||
        snap.pickMode != pickMode.name ||
        snap.wordIds.isEmpty) {
      return null;
    }

    final allWords = await _db.wordDao.getWordsByDeck(deckId);
    final byId = {for (final w in allWords) w.id: w};
    final restored = <Word>[];
    for (final id in snap.wordIds) {
      final w = byId[id];
      // 词表有变化（单词被删除）时放弃恢复，由调用方重新抓词
      if (w == null) return null;
      restored.add(w);
    }

    // 重考词始终保留（重考队列不能悬空），其余词按抓词模式过滤有效性：
    // 今日错词剔除已不是「今日答错过」的词、只抓收藏剔除取消收藏的词
    final wrongIds = pickMode == WordPickMode.wrongTodayOnly
        ? await _db.studyStatDao.getTodayWrongWordIds(deckId: deckId)
        : null;
    final redoSet = snap.redoQueue.toSet();
    final words = <Word>[];
    var keptBeforeCursor = 0;
    for (var i = 0; i < restored.length; i++) {
      final w = restored[i];
      final valid = redoSet.contains(w.id) ||
          (pickMode != WordPickMode.favoriteOnly || w.isFavorite) &&
              (wrongIds == null || wrongIds.contains(w.id));
      if (!valid) continue;
      words.add(w);
      if (i < snap.currentIndex) keptBeforeCursor++;
    }

    final redoQueue = [
      for (final id in snap.redoQueue)
        if (byId.containsKey(id)) id,
    ];

    // 剩余已无任何可学内容（如全部待学词在其他会话练熟）：
    // 视为无可恢复的会话，避免进入即完成的空会话
    if (words.isEmpty ||
        (keptBeforeCursor >= words.length && redoQueue.isEmpty)) {
      return null;
    }

    final redoRetries = <int, int>{
      for (final e in snap.redoRetries.entries)
        if (byId.containsKey(e.key)) e.key: e.value,
    };

    return _ResumedSession(
      words: words,
      currentIndex: keptBeforeCursor,
      completedCount: snap.completedCount,
      correctCount: snap.correctCount,
      redoQueue: redoQueue,
      redoRetries: redoRetries,
    );
  }

  /// 读取词书非循环会话快照（无/损坏时返回 null）
  Future<_SessionSnapshot?> _readSessionSnapshot(int deckId) async {
    if (_db == null) return null;
    final raw = await _db.getSetting(_sessionProgressKey(deckId));
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return _SessionSnapshot(
        date: map['date'] as String? ?? '',
        pickMode: map['pickMode'] as String? ?? '',
        wordIds: (map['wordIds'] as List? ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        currentIndex: (map['currentIndex'] as num?)?.toInt() ?? 0,
        redoQueue: (map['redoQueue'] as List? ?? const [])
            .map((e) => (e as num).toInt())
            .toList(),
        redoRetries: (map['redoRetries'] as Map? ?? const {})
            .map((k, v) => MapEntry(int.parse('$k'), (v as num).toInt())),
        completedCount: (map['completedCount'] as num?)?.toInt() ?? 0,
        correctCount: (map['correctCount'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  /// 保存词书非循环会话快照（失败不影响学习）
  Future<void> _saveSessionSnapshot(
      int deckId, _SessionSnapshot snapshot) async {
    if (_db == null) return;
    try {
      await _db.setSetting(
        _sessionProgressKey(deckId),
        jsonEncode({
          'date': snapshot.date,
          'pickMode': snapshot.pickMode,
          'wordIds': snapshot.wordIds,
          'currentIndex': snapshot.currentIndex,
          'redoQueue': snapshot.redoQueue,
          'redoRetries': snapshot.redoRetries
              .map((k, v) => MapEntry('$k', v)),
          'completedCount': snapshot.completedCount,
          'correctCount': snapshot.correctCount,
        }),
      );
    } catch (_) {
      // 持久化失败不影响学习
    }
  }

  /// 清除词书非循环会话快照
  Future<void> _clearSessionSnapshot(int deckId) async {
    if (_db == null) return;
    try {
      await _db.deleteSetting(_sessionProgressKey(deckId));
    } catch (_) {
      // 清理失败不影响学习
    }
  }

  static String _sessionProgressKey(int deckId) => 'session_progress_$deckId';
}

/// 非循环学习会话恢复结果
class _ResumedSession {
  final List<Word> words;
  final int currentIndex;
  final int completedCount;
  final int correctCount;
  final List<int> redoQueue;
  final Map<int, int> redoRetries;

  const _ResumedSession({
    required this.words,
    required this.currentIndex,
    required this.completedCount,
    required this.correctCount,
    required this.redoQueue,
    required this.redoRetries,
  });
}

/// 非循环学习会话进度快照（持久化到 settings 表，key: session_progress_{deckId}）
///
/// 与循环复习进度（按“未答词”分批）不同，非循环模式保留完整词表 + 游标 +
/// 错词重考队列，中途退出后重进同一词书同一天可直接续学，不重复已学单词。
class _SessionSnapshot {
  /// 会话创建日期（yyyy-MM-dd），跨天自动失效重新抓词
  final String date;
  /// 抓词模式（仅同模式重进可续学，避免不同会话串场）
  final String pickMode;
  /// 会话完整词表（按原顺序）
  final List<int> wordIds;
  /// 主列表游标（已答词在游标之前）
  final int currentIndex;
  /// 错词重考队列（先进先出）
  final List<int> redoQueue;
  /// 各单词重考次数
  final Map<int, int> redoRetries;
  /// 已完成词数（含已答过的词）
  final int completedCount;
  /// 答对词数
  final int correctCount;

  const _SessionSnapshot({
    required this.date,
    required this.pickMode,
    required this.wordIds,
    required this.currentIndex,
    required this.redoQueue,
    required this.redoRetries,
    required this.completedCount,
    required this.correctCount,
  });
}

/// 循环复习进度（持久化到 settings 表，key: loop_progress_{deckId}）
class _LoopProgress {
  /// 大轮创建日期（yyyy-MM-dd），跨天自动开启新一轮
  final String date;
  final int loopCount;
  final int total;
  /// 本轮尚未答过的单词 id（保持本轮伪随机顺序）
  final List<int> pendingIds;
  /// 每个词连续「首次答对」的轮数（今日错词模式毕业判定用）
  final Map<int, int> streak;
  /// 当前轮内每个词已重排次数（答错排到队尾，上限防死循环）
  final Map<int, int> reQueueCount;

  const _LoopProgress({
    required this.date,
    required this.loopCount,
    required this.total,
    required this.pendingIds,
    this.streak = const {},
    this.reQueueCount = const {},
  });
}

/// 日期键（本地时区，与“今日已学”口径一致）
String _dateKey(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

/// 学习会话 Provider
final studySessionProvider =
    StateNotifierProvider<StudySessionNotifier, StudySession>((ref) {
  final db = ref.watch(databaseProvider);
  return StudySessionNotifier(db);
});

/// 连续打卡天数 Provider
///
/// 判定：study_stats 表中存在答题记录的日期视为已打卡（任何学习模式
/// 提交反馈都会写入记录）。从今天开始向前数连续天数；今天尚未打卡时
/// 从昨天开始数，当天未学习不算断签。监听学习会话，答题后自动刷新。
final checkInStreakProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  if (db == null) return 0;
  // 监听学习会话：提交反馈（state 变化）后重新计算，主页打卡数实时刷新
  ref.watch(studySessionProvider);
  final dates = await db.studyStatDao.getDistinctStudyDates();
  return calculateCheckInStreak(dates, DateTime.now());
});
