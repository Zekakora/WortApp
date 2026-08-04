import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import '../algorithms/review_scheduler.dart';
import '../algorithms/sm2_algorithm.dart';
import '../data/database/app_database.dart';
import 'database_provider.dart';

/// 复习调度器 Provider
final reviewSchedulerProvider = Provider<ReviewScheduler?>((ref) {
  final db = ref.watch(databaseProvider);
  if (db == null) return null;
  return ReviewScheduler(db);
});

/// 当前学习计划 Provider
final studyPlanProvider = FutureProvider.family<StudyPlan?, int>((ref, deckId) async {
  final scheduler = ref.watch(reviewSchedulerProvider);
  if (scheduler == null) return null;
  return scheduler.getTodayPlan(deckId: deckId);
});

/// 获取词书中所有单词（用于学习模式）
final allWordsForStudyProvider = FutureProvider.family<List<Word>, int>((ref, deckId) async {
  final db = ref.watch(databaseProvider);
  if (db == null) return [];
  return db.wordDao.getWordsByDeck(deckId);
});

/// 学习会话状态
class StudySession {
  final List<Word> words;
  final int currentIndex;
  final int completedCount;
  final int correctCount;
  final bool isCompleted;
  final bool isLoading;
  final String? error;

  const StudySession({
    required this.words,
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
    int? currentIndex,
    int? completedCount,
    int? correctCount,
    bool? isCompleted,
    bool? isLoading,
    String? error,
  }) {
    return StudySession(
      words: words ?? this.words,
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

  /// 开始学习会话（使用所有单词）
  Future<void> startSession({
    required int deckId,
    int? limit,
  }) async {
    if (_db == null) {
      state = const StudySession(words: [], error: '数据库未就绪');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // 获取词书中所有单词
      var words = await _db!.wordDao.getWordsByDeck(deckId);

      if (words.isEmpty) {
        state = const StudySession(words: [], error: '词书中没有单词，请先导入单词');
        return;
      }

      // 打乱顺序
      words.shuffle();

      // 如果有数量限制
      if (limit != null && limit > 0 && words.length > limit) {
        words = words.take(limit).toList();
      }

      state = StudySession(words: words);
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
      final scheduler = ReviewScheduler(_db!);
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

      state = StudySession(words: words);
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
    final sm2State = await _db!.sm2Dao.getStateByWordId(word.id);

    if (sm2State == null) {
      final result = SM2Algorithm.calculate(
        quality: quality,
        currentN: 0,
        currentInterval: 0,
        currentEF: 2.5,
      );

      await _db!.sm2Dao.createState(
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

      await _db!.sm2Dao.updateState(
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
    await _db!.wordDao.updateLastStudyDate(word.id);

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
