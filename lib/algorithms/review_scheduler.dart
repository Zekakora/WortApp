import 'dart:math' show max;
import '../data/database/app_database.dart';

/// 复习队列调度器
class ReviewScheduler {
  final AppDatabase _db;

  ReviewScheduler(this._db);

  /// 获取今日待复习的单词
  Future<List<Word>> getDueReviewWords({
    required int deckId,
    int? limit,
  }) async {
    final wordIds = await _db.sm2Dao.getDueReviewWordIds(
      deckId: deckId,
      limit: limit,
    );
    return _db.wordDao.getWordsByIds(wordIds);
  }

  /// 获取新词（未学习过的单词）
  Future<List<Word>> getNewWords({
    required int deckId,
    int? limit,
  }) async {
    final wordIds = await _db.sm2Dao.getNewWordIds(deckId, limit: limit);
    return _db.wordDao.getWordsByIds(wordIds);
  }

  /// 获取今日学习计划
  ///
  /// - 新词与复习数量受每日上限约束，并扣除今日已学数量，
  ///   多次进入学习模式不会超限抽取
  /// - 新词与复习均无可学内容时（额度用尽或没有到期单词），返回今日已学过的
  ///   全部单词（[StudyPlan.todayWords]，含新词与已复习的），
  ///   保证学习模式总能开始，用于循环复习今日单词而不抽取新词
  Future<StudyPlan> getTodayPlan({
    required int deckId,
    int dailyNewLimit = 20,
    int dailyReviewLimit = 100,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // 今日已学新词/复习词数量（确保每日上限在多次进入学习模式后仍然有效）
    final todayNewStudied = await _db.sm2Dao.getTodayNewStudiedCount(deckId);
    final todayReviewStudied =
        await _db.sm2Dao.getTodayReviewStudiedCount(deckId);

    final remainingNew = max(0, dailyNewLimit - todayNewStudied);
    final remainingReview = max(0, dailyReviewLimit - todayReviewStudied);

    // 获取待复习单词（扣除今日已学后剩余的额度）
    final dueReviewWords = remainingReview == 0
        ? <Word>[]
        : await getDueReviewWords(
            deckId: deckId,
            limit: remainingReview,
          );

    // 获取新词（扣除今日已学后剩余的额度）
    final newWords = remainingNew == 0
        ? <Word>[]
        : await getNewWords(
            deckId: deckId,
            limit: remainingNew,
          );

    // 新词与复习均无可学内容时（额度用尽或没有到期词）：
    // 兜底复习今日已学过的全部单词（含新词与已复习的），不再抽取新词
    final todayWords = (newWords.isEmpty && dueReviewWords.isEmpty)
        ? await _db.wordDao.getTodayStudiedWords(deckId)
        : <Word>[];

    // 获取统计信息
    final totalWords = await _db.wordDao.getWordCount(deckId);
    final dueCount = await _db.sm2Dao.getDueReviewCount(deckId: deckId);

    return StudyPlan(
      date: today,
      newWords: newWords,
      reviewWords: dueReviewWords,
      todayWords: todayWords,
      todayNewStudiedCount: todayNewStudied,
      todayReviewStudiedCount: todayReviewStudied,
      totalWords: totalWords,
      dueReviewCount: dueCount,
      dailyNewLimit: dailyNewLimit,
      dailyReviewLimit: dailyReviewLimit,
    );
  }

  /// 提交学习反馈（SM-2 状态落库 + 刷新上次学习日期）
  ///
  /// 实际逻辑收敛在 [AppDatabase.submitStudyFeedback]，避免与
  /// [StudySessionNotifier.submitFeedback] 重复实现。
  Future<void> submitFeedback({
    required int wordId,
    required int quality,
  }) {
    return _db.submitStudyFeedback(wordId: wordId, quality: quality);
  }
}

/// 学习计划
class StudyPlan {
  final DateTime date;
  final List<Word> newWords;
  final List<Word> reviewWords;
  /// 今日已学过的单词（新词与复习均无可学内容时，用于循环复习今日单词）
  final List<Word> todayWords;
  /// 今日已学新词数量（用于展示学习进度）
  final int todayNewStudiedCount;
  /// 今日已复习数量（用于展示学习进度）
  final int todayReviewStudiedCount;
  final int totalWords;
  final int dueReviewCount;
  final int dailyNewLimit;
  final int dailyReviewLimit;

  const StudyPlan({
    required this.date,
    required this.newWords,
    required this.reviewWords,
    required this.todayWords,
    required this.todayNewStudiedCount,
    required this.todayReviewStudiedCount,
    required this.totalWords,
    required this.dueReviewCount,
    required this.dailyNewLimit,
    required this.dailyReviewLimit,
  });

  /// 今日总学习数
  int get totalStudyCount =>
      newWords.length + reviewWords.length + todayWords.length;
}
