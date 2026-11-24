import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/algorithms/sm2_algorithm.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/providers/study_provider.dart';

/// 非循环学习会话恢复测试：答词后中途退出会持久化会话快照
/// （settings 表 session_progress_{deckId}），重进同一词书同一抓词模式
/// 会从上次位置续学，不重复已学单词；完成后清除快照。
void main() {
  late AppDatabase db;
  late StudySessionNotifier notifier;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.deckDao.createDeck(DecksCompanion.insert(
      name: '测试词书',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    notifier = StudySessionNotifier(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> addWord(String german) async {
    return db.wordDao.createWord(WordsCompanion.insert(
      deckId: 1,
      german: german,
      chinese: '释义',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  /// 模拟旧词今天到期（进入复习队列）
  Future<void> markDueReviewToday(int wordId) async {
    final now = DateTime.now();
    await db.sm2Dao.createState(Sm2StatesCompanion.insert(
      wordId: wordId,
      repetitionN: const drift.Value(3),
      intervalDays: const drift.Value(7),
      easeFactor: const drift.Value(2.5),
      nextReview: DateTime(now.year, now.month, now.day),
      lastReview: drift.Value(now.subtract(const Duration(days: 7))),
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now.subtract(const Duration(days: 7)),
    ));
  }

  Future<void> start({
    WordPickMode pickMode = WordPickMode.normal,
    int roundLimit = 10,
  }) {
    return notifier.startSession(
      deckId: 1,
      dailyNewLimit: 20,
      dailyReviewLimit: 50,
      roundLimit: roundLimit,
      pickMode: pickMode,
    );
  }

  test('非循环模式中途退出后重进：从上次位置续学，不重复已学单词', () async {
    for (var i = 0; i < 6; i++) {
      await addWord('wort$i');
    }
    await start();
    var s = notifier.state;
    expect(s.error, isNull);
    expect(s.isLooping, isFalse);
    expect(s.words, hasLength(6));
    final answered = s.words.take(3).map((w) => w.id).toList();

    for (var i = 0; i < 3; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }
    s = notifier.state;
    expect(s.currentIndex, 3);
    expect(s.completedCount, 3);

    // 模拟退出后重新进入（重建 notifier 相当于重启应用）
    notifier = StudySessionNotifier(db);
    await start();
    s = notifier.state;
    expect(s.error, isNull);
    expect(s.isLooping, isFalse);
    expect(s.currentIndex, 3, reason: '从上次位置续学');
    expect(s.completedCount, 3);
    expect(answered.contains(s.currentWord?.id), isFalse,
        reason: '当前题不是已答过的词');
    final pendingIds = s.words.sublist(s.currentIndex).map((w) => w.id).toSet();
    expect(pendingIds.intersection(answered.toSet()), isEmpty,
        reason: '待学词不含已答过的词');

    // 续学剩余 3 词后完成
    for (var i = 0; i < 3; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }
    s = notifier.state;
    expect(s.isCompleted, isTrue);
    expect(s.completedCount, 6, reason: '3 首轮 + 3 续学');
  });

  test('今日错词始终按循环复习：答错排到队尾，重进后续学', () async {
    final ids = <int>[];
    for (var i = 0; i < 4; i++) {
      final id = await addWord('wort$i');
      await markDueReviewToday(id);
      // 全部为今日错词（各答错 1 次）
      await db.studyStatDao.recordAttempt(wordId: id, isError: true);
      ids.add(id);
    }

    await start(pickMode: WordPickMode.wrongTodayOnly);
    var s = notifier.state;
    expect(s.error, isNull);
    expect(s.isLooping, isTrue, reason: '今日错词始终按循环复习，与每日额度无关');
    expect(s.words.map((w) => w.id).toSet(), ids.toSet());
    expect(s.redoQueue, isEmpty, reason: '循环模式不使用重考队列');
    final order = s.words.map((w) => w.id).toList();

    // 首词答错 → 清零并排到本轮队尾；次词答对 → 累计干净轮数
    await notifier.submitFeedback(FeedbackLevel.forgot);
    await notifier.submitFeedback(FeedbackLevel.good);
    s = notifier.state;
    expect(s.loopStreak[order[0]], 0, reason: '答错清零');
    expect(s.loopStreak[order[1]], 1);
    expect(s.loopPendingIds, [order[2], order[3], order[0]],
        reason: '答错的词排到本轮队尾');

    // 中途退出后重进：从本轮剩余第 3 词续学，答错的词仍在队尾
    notifier = StudySessionNotifier(db);
    await start(pickMode: WordPickMode.wrongTodayOnly);
    s = notifier.state;
    expect(s.error, isNull);
    expect(s.isLooping, isTrue);
    expect(s.currentWord?.id, order[2], reason: '继续本轮剩余第 3 词');
    expect(s.loopLearned, 1, reason: '本轮已学 1 词');
    expect(s.loopPendingIds, [order[2], order[3], order[0]]);

    // 学完剩余词 + 队尾的错词 → 本轮覆盖完毕
    for (var i = 0; i < 3; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }
    s = notifier.state;
    expect(s.isCompleted, isTrue);
    expect(s.loopPendingIds, isEmpty);
    expect(s.loopStreak[order[0]], 0, reason: '重排后再答对不计干净轮数');
  });

  test('完成会话后清除快照：再次进入重新抓词', () async {
    for (var i = 0; i < 6; i++) {
      await addWord('wort$i');
    }
    await start(roundLimit: 3);
    expect(notifier.state.words, hasLength(3));
    for (var i = 0; i < 3; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }
    expect(notifier.state.isCompleted, isTrue);

    // 重新进入：新会话重新抓词，不续学已完成会话
    notifier = StudySessionNotifier(db);
    await start(roundLimit: 3);
    final s = notifier.state;
    expect(s.error, isNull);
    expect(s.currentIndex, 0);
    expect(s.completedCount, 0);
    expect(s.words, hasLength(3), reason: '重新抓一批新词');
  });

  test('抓词模式切换后不恢复旧会话快照', () async {
    for (var i = 0; i < 4; i++) {
      final id = await addWord('wort$i');
      await markDueReviewToday(id);
      await db.studyStatDao.recordAttempt(wordId: id, isError: true);
    }

    await start(pickMode: WordPickMode.wrongTodayOnly);
    await notifier.submitFeedback(FeedbackLevel.good);
    expect(notifier.state.completedCount, 1, reason: '已产生进度快照');

    // 切到正常抓词：不恢复今日错词会话，重新抓词
    await start(pickMode: WordPickMode.normal);
    final s = notifier.state;
    expect(s.error, isNull);
    expect(s.completedCount, 0, reason: '新模式不续学旧会话');
    expect(s.currentIndex, 0);
  });

  test('今日错词：别处答对再多不影响错词资格，重进后仍在', () async {
    final ids = <int>[];
    for (var i = 0; i < 4; i++) {
      final id = await addWord('wort$i');
      await markDueReviewToday(id);
      await db.studyStatDao.recordAttempt(wordId: id, isError: true);
      ids.add(id);
    }

    await start(pickMode: WordPickMode.wrongTodayOnly);
    final order = notifier.state.words.map((w) => w.id).toList();
    expect(order.toSet(), ids.toSet());

    // 答完前 2 词后退出
    await notifier.submitFeedback(FeedbackLevel.good);
    await notifier.submitFeedback(FeedbackLevel.good);

    // 第 3 个待学词在其他会话被答对很多次（今天答错过就仍是错词，
    // 短时记忆答对不会把它挤出列表）
    for (var i = 0; i < 5; i++) {
      await db.studyStatDao.recordAttempt(wordId: order[2], isError: false);
    }

    // 重进：续学仍含第 3 词（错词资格不受答对影响）
    await start(pickMode: WordPickMode.wrongTodayOnly);
    final s = notifier.state;
    expect(s.error, isNull);
    expect(s.isLooping, isTrue);
    expect(s.currentWord?.id, order[2], reason: '答对多次仍是错词，继续复习');
    expect(s.words.map((w) => w.id).toSet().contains(order[2]), isTrue);
  });
}
