import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
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
/// - [favoriteBoost]：收藏优先——今天该学的单词中，收藏词汇重复加入
///   会话（被抓中概率更高，同轮可多次出现）
/// - [favoriteOnly]：只抓今天该学单词中的收藏词汇
enum WordPickMode { normal, favoriteBoost, favoriteOnly }

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

  const StudySession({
    required this.words,
    this.distractorPool = const [],
    this.currentIndex = 0,
    this.completedCount = 0,
    this.correctCount = 0,
    this.isCompleted = false,
    this.isLoading = false,
    this.error,
  });

  Word? get currentWord =>
      currentIndex < words.length ? words[currentIndex] : null;

  double get progress =>
      words.isEmpty ? 0 : currentIndex / words.length;

  double get accuracy =>
      completedCount == 0 ? 0 : correctCount / completedCount;

  StudySession copyWith({
    List<Word>? words,
    List<Word>? distractorPool,
    int? currentIndex,
    int? completedCount,
    int? correctCount,
    bool? isCompleted,
    bool? isLoading,
    String? error,
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
    );
  }
}

/// 学习会话 StateNotifier
class StudySessionNotifier extends StateNotifier<StudySession> {
  final AppDatabase? _db;

  StudySessionNotifier(this._db)
      : super(const StudySession(words: []));

  /// 开始学习会话
  ///
  /// 按每日新词/复习上限从调度器抽取单词（已扣除今日已学数量，
  /// 多次进入不会超限）；新词与复习上限均用尽时，自动改为复习
  /// 今日已学过的单词，不再抽取新词；最终受 [roundLimit]（每轮单词数）约束。
  ///
  /// [pickMode] 控制抓词策略：
  /// - 收藏优先：收藏词重复加入（概率翻倍），同轮可被多次复习
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
      final scheduler = ReviewScheduler(_db);
      final plan = await scheduler.getTodayPlan(
        deckId: deckId,
        dailyNewLimit: dailyNewLimit,
        dailyReviewLimit: dailyReviewLimit,
      );

      // 新词 + 复习 + （上限均用尽时）今日已学单词
      var words = <Word>[
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
          // 收藏词放在前面并重复加入一次（共 2 次），提高被抓中概率，
          // 同轮内允许多次复习；roundLimit 截断时收藏词优先保留
          words = [...favorites, ...favorites, ...others];
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
        case WordPickMode.normal:
          break;
      }

      // 打乱顺序
      words.shuffle();

      // 每轮单词数限制
      if (roundLimit != null && roundLimit > 0 && words.length > roundLimit) {
        words = words.take(roundLimit).toList();
      }

      // 干扰项选项池：从所有词库随机抽取“每轮单词数 × 5”个单词，
      // 四选一模式整个会话只从这个池子里抽干扰项（纯同步，不会二次刷新）
      final poolSize =
          (roundLimit ?? 0) > 0 ? roundLimit! * 5 : words.length * 5;
      final distractorPool = await _db.wordDao.getRandomWords(poolSize);

      state = StudySession(words: words, distractorPool: distractorPool);
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

  /// 提交反馈并进入下一题
  Future<void> submitFeedback(FeedbackLevel feedback) async {
    final word = state.currentWord;
    if (word == null || _db == null) return;

    final quality = SM2Algorithm.feedbackToQuality(feedback);

    // 更新 SM-2 状态
    final now = DateTime.now();
    final sm2State = await _db.sm2Dao.getStateByWordId(word.id);

    if (sm2State == null) {
      final result = SM2Algorithm.calculate(
        quality: quality,
        currentN: 0,
        currentInterval: 0,
        currentEF: 2.5,
      );

      await _db.sm2Dao.createState(
        Sm2StatesCompanion(
          wordId: drift.Value(word.id),
          repetitionN: drift.Value(result.repetitionN),
          intervalDays: drift.Value(result.intervalDays),
          easeFactor: drift.Value(result.easeFactor),
          nextReview: drift.Value(result.nextReview),
          lastReview: drift.Value(now),
          totalReviews: const drift.Value(1),
          correctStreak: drift.Value(quality >= 3 ? 1 : 0),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );
    } else {
      final result = SM2Algorithm.calculate(
        quality: quality,
        currentN: sm2State.repetitionN,
        currentInterval: sm2State.intervalDays,
        currentEF: sm2State.easeFactor,
      );

      await _db.sm2Dao.updateState(
        Sm2StatesCompanion(
          id: drift.Value(sm2State.id),
          wordId: drift.Value(word.id),
          repetitionN: drift.Value(result.repetitionN),
          intervalDays: drift.Value(result.intervalDays),
          easeFactor: drift.Value(result.easeFactor),
          nextReview: drift.Value(result.nextReview),
          lastReview: drift.Value(now),
          totalReviews: drift.Value(sm2State.totalReviews + 1),
          correctStreak: drift.Value(
            quality >= 3 ? sm2State.correctStreak + 1 : 0,
          ),
          createdAt: drift.Value(sm2State.createdAt),
          updatedAt: drift.Value(now),
        ),
      );
    }

    // 更新单词的上次学习日期
    await _db.wordDao.updateLastStudyDate(word.id);

    // 记录错误统计（忘记/模糊计为错误，用于错误统计排行榜）
    await _db.studyStatDao.recordAttempt(
      wordId: word.id,
      isError: quality < 3,
    );

    // 移动到下一题
    final isCorrect = quality >= 3;
    final nextIndex = state.currentIndex + 1;
    final isCompleted = nextIndex >= state.words.length;

    state = state.copyWith(
      currentIndex: nextIndex,
      completedCount: state.completedCount + 1,
      correctCount: state.correctCount + (isCorrect ? 1 : 0),
      isCompleted: isCompleted,
    );
  }

  /// 重置会话
  void reset() {
    state = const StudySession(words: []);
  }
}

/// 学习会话 Provider
final studySessionProvider =
    StateNotifierProvider<StudySessionNotifier, StudySession>((ref) {
  final db = ref.watch(databaseProvider);
  return StudySessionNotifier(db);
});
