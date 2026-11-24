import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/algorithms/sm2_algorithm.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/providers/study_provider.dart';

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

  /// 模拟今天已学的新词（sm2 状态 createdAt = 今天 + 上次学习日期 = 今天）
  Future<void> markStudiedToday(int wordId) async {
    final now = DateTime.now();
    await db.sm2Dao.createState(Sm2StatesCompanion.insert(
      wordId: wordId,
      repetitionN: const drift.Value(1),
      intervalDays: const drift.Value(1),
      easeFactor: const drift.Value(2.5),
      nextReview: DateTime.now().add(const Duration(days: 1)),
      createdAt: now,
      updatedAt: now,
    ));
    await db.wordDao.updateLastStudyDate(wordId);
  }

  test('循环模式每次进入只发一批（每轮单词数），分批覆盖全部，覆盖后进入下一大轮', () async {
    final ids = <int>[];
    for (var i = 0; i < 40; i++) {
      ids.add(await addWord('wort$i'));
    }
    for (final id in ids) {
      await markStudiedToday(id);
    }

    // 第 1 次进入：只发一批“每轮单词数”（10 个）
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 10,
    );
    var s = notifier.state;
    expect(s.error, isNull);
    expect(s.isLooping, isTrue);
    expect(s.words, hasLength(10),
        reason: '每次进入只学“每轮单词数”个，不再多抽');
    expect(s.loopCount, 1);
    expect(s.loopTotal, 40, reason: '大轮覆盖今天全部 40 个已学单词');
    expect(s.loopLearned, 0);
    expect(s.loopPendingIds, hasLength(40),
        reason: '本轮剩余词含已发放未作答的词');
    expect(s.words.map((w) => w.id).toSet(), hasLength(10),
        reason: '同批内每个单词至多出现一次');
    final batch1 = s.words.map((w) => w.id).toSet();

    // 学完本批 → 会话结束，不自动加载下一批
    for (var i = 0; i < 10; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }
    s = notifier.state;
    expect(s.isCompleted, isTrue, reason: '一批学完会话即结束');
    expect(s.loopCount, 1, reason: '批次之间不递增轮数');
    expect(s.loopPendingIds, hasLength(30), reason: '已答词从本轮剩余中移除');

    // 第 2 次进入：学下一批，与上一批不重复
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 10,
    );
    s = notifier.state;
    expect(s.words, hasLength(10));
    expect(s.loopCount, 1);
    expect(s.loopLearned, 10, reason: '本轮已学 10 个，进度延续');
    expect(s.words.map((w) => w.id).toSet().intersection(batch1), isEmpty,
        reason: '跨会话批次不重复');
    final batch2 = s.words.map((w) => w.id).toSet();
    for (var i = 0; i < 10; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }

    // 第 3、4 次进入学完剩余 20 个 → 覆盖全部 40 个
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 10,
    );
    expect(notifier.state.loopLearned, 20);
    final batch3 = notifier.state.words.map((w) => w.id).toSet();
    expect(batch3.intersection(batch1.union(batch2)), isEmpty);
    for (var i = 0; i < 10; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }

    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 10,
    );
    s = notifier.state;
    expect(s.loopLearned, 30);
    expect(s.words.map((w) => w.id).toSet().intersection(
        batch1.union(batch2).union(batch3)), isEmpty);
    for (var i = 0; i < 10; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }
    expect(notifier.state.loopPendingIds, isEmpty, reason: '大轮覆盖完毕');

    // 第 5 次进入：自动开启下一大轮（重新打乱，轮数 +1）
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 10,
    );
    s = notifier.state;
    expect(s.loopCount, 2, reason: '覆盖完毕后自动开启下一大轮');
    expect(s.loopLearned, 0);
    expect(s.loopTotal, 40);
    expect(s.words, hasLength(10));
    expect(s.words.map((w) => w.id).toSet(), hasLength(10),
        reason: '新一轮仍不重复');
  });

  test('循环模式中途退出后再次进入不重复已学单词', () async {
    for (var i = 0; i < 25; i++) {
      await markStudiedToday(await addWord('wort$i'));
    }

    // 第 1 次进入：10 个，只答 3 个就退出
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 10,
    );
    final answered = notifier.state.words.take(3).map((w) => w.id).toSet();
    for (var i = 0; i < 3; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }
    expect(notifier.state.loopPendingIds, hasLength(22),
        reason: '已答 3 个从本轮剩余中移除');

    // 第 2 次进入：10 个新词，不包含已答的 3 个
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 10,
    );
    final s = notifier.state;
    expect(s.words, hasLength(10));
    expect(s.loopLearned, 3);
    expect(s.words.map((w) => w.id).toSet().intersection(answered), isEmpty,
        reason: '中途退出后不重复已学单词');
  });

  test('循环进度跨会话持久化：重建 notifier 后仍不重复', () async {
    for (var i = 0; i < 25; i++) {
      await markStudiedToday(await addWord('wort$i'));
    }

    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 10,
    );
    final answered = notifier.state.words.take(5).map((w) => w.id).toSet();
    for (var i = 0; i < 5; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }

    // 重建 notifier（模拟退出后重新进入学习页），进度仍在
    notifier = StudySessionNotifier(db);
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 10,
    );
    final s = notifier.state;
    expect(s.isLooping, isTrue);
    expect(s.words, hasLength(10));
    expect(s.loopCount, 1);
    expect(s.loopLearned, 5, reason: '上一会话已答 5 个');
    expect(s.words.map((w) => w.id).toSet().intersection(answered), isEmpty,
        reason: '持久化进度保证不重复已学单词');
  });

  test('大轮覆盖完毕后自动开启下一大轮，轮数无上限', () async {
    for (var i = 0; i < 10; i++) {
      await markStudiedToday(await addWord('wort$i'));
    }

    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 5,
    );
    expect(notifier.state.words, hasLength(5));
    expect(notifier.state.loopCount, 1);
    for (var i = 0; i < 5; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }
    expect(notifier.state.isCompleted, isTrue);
    expect(notifier.state.loopPendingIds, hasLength(5));

    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 5,
    );
    expect(notifier.state.loopCount, 1, reason: '第 1 大轮内第 2 批');
    expect(notifier.state.loopLearned, 5);
    for (var i = 0; i < 5; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }
    expect(notifier.state.loopPendingIds, isEmpty, reason: '大轮覆盖完毕');

    // 第 3 次进入：开启第 2 大轮，轮数递增
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 5,
    );
    expect(notifier.state.loopCount, 2);
    expect(notifier.state.loopLearned, 0);
    expect(notifier.state.words, hasLength(5));
  });

  test('收藏优先循环模式：收藏词排在本轮前部优先出现', () async {
    for (var i = 0; i < 10; i++) {
      final id = await addWord('wort$i');
      if (i < 3) {
        await db.wordDao.updateFavorite(id, true);
      }
      await markStudiedToday(id);
    }

    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 3,
      pickMode: WordPickMode.favoriteBoost,
    );
    final s = notifier.state;
    expect(s.isLooping, isTrue);
    expect(s.words, hasLength(3));
    expect(s.loopTotal, 10);
    expect(s.words.every((w) => w.isFavorite), isTrue,
        reason: '循环模式每词每轮至多一次，收藏词排前优先出现');
  });

  test('只抓收藏循环模式：只学收藏词，跨批覆盖收藏词后开启下一大轮', () async {
    final ids = <int>[];
    for (var i = 0; i < 12; i++) {
      final id = await addWord('wort$i');
      if (i < 4) {
        await db.wordDao.updateFavorite(id, true);
      }
      ids.add(id);
    }
    for (final id in ids) {
      await markStudiedToday(id);
    }

    // 第 1 批：只发收藏词，大轮总数 = 收藏词数
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 3,
      pickMode: WordPickMode.favoriteOnly,
    );
    var s = notifier.state;
    expect(s.isLooping, isTrue);
    expect(s.words, hasLength(3));
    expect(s.words.every((w) => w.isFavorite), isTrue,
        reason: '只抓收藏模式不出现非收藏词');
    expect(s.loopTotal, 4, reason: '大轮只覆盖收藏词');
    final batch1 = s.words.map((w) => w.id).toSet();
    for (var i = 0; i < 3; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }
    expect(notifier.state.loopPendingIds, hasLength(1));

    // 第 2 批：剩余 1 个收藏词，与第 1 批不重复
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 3,
      pickMode: WordPickMode.favoriteOnly,
    );
    s = notifier.state;
    expect(s.words, hasLength(1));
    expect(s.words.single.isFavorite, isTrue);
    expect(batch1.contains(s.words.single.id), isFalse,
        reason: '跨批不重复已学收藏词');
    await notifier.submitFeedback(FeedbackLevel.good);
    expect(notifier.state.loopPendingIds, isEmpty,
        reason: '收藏词全部覆盖完毕');

    // 第 3 次进入：开启下一大轮，仍只学收藏词
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 3,
      pickMode: WordPickMode.favoriteOnly,
    );
    s = notifier.state;
    expect(s.loopCount, 2);
    expect(s.loopLearned, 0);
    expect(s.words, hasLength(3));
    expect(s.words.every((w) => w.isFavorite), isTrue);
  });

  test('收藏优先循环模式：收藏词跨批持续排前，学完后进入普通词', () async {
    final ids = <int>[];
    for (var i = 0; i < 12; i++) {
      final id = await addWord('wort$i');
      if (i < 5) {
        await db.wordDao.updateFavorite(id, true);
      }
      ids.add(id);
    }
    for (final id in ids) {
      await markStudiedToday(id);
    }

    // 第 1 批：前 3 个全是收藏词
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 3,
      pickMode: WordPickMode.favoriteBoost,
    );
    var s = notifier.state;
    expect(s.isLooping, isTrue);
    expect(s.loopTotal, 12, reason: '收藏优先循环模式大轮覆盖全部词');
    expect(s.words, hasLength(3));
    expect(s.words.every((w) => w.isFavorite), isTrue,
        reason: '第 1 批全是收藏词');
    for (var i = 0; i < 3; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }

    // 第 2 批：剩余 2 个收藏词排前，与第 1 批不重复
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 3,
      pickMode: WordPickMode.favoriteBoost,
    );
    s = notifier.state;
    expect(s.words, hasLength(3));
    expect(s.words.take(2).every((w) => w.isFavorite), isTrue,
        reason: '收藏词未学完，下一批仍优先出现');
    expect(s.words.last.isFavorite, isFalse,
        reason: '收藏词仅剩 2 个，补足 1 个普通词');
    for (var i = 0; i < 3; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }

    // 第 3 批：5 个收藏词已全部学完，本批全为普通词
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 3,
      pickMode: WordPickMode.favoriteBoost,
    );
    s = notifier.state;
    expect(s.words.every((w) => !w.isFavorite), isTrue,
        reason: '收藏词已覆盖完毕，本批进入普通词');
    expect(s.loopCount, 1, reason: '仍在第 1 大轮内');
  });

  test('正常模式仍受每轮单词数限制，学完计划内单词即完成', () async {
    for (var i = 0; i < 30; i++) {
      await addWord('wort$i');
    }
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 10,
    );

    final session = notifier.state;
    expect(session.error, isNull);
    expect(session.isLooping, isFalse);
    expect(session.words, hasLength(10), reason: '正常模式应受 roundLimit 限制');
    expect(session.loopTotal, 0);

    for (var i = 0; i < 10; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }
    expect(notifier.state.isCompleted, isTrue,
        reason: '正常模式学完计划内单词后会话结束');
    expect(notifier.state.loopCount, 1);
  });

  test('只抓今日错词模式：只抓今天答错过的词，大轮只覆盖错词', () async {
    for (var i = 0; i < 8; i++) {
      await markStudiedToday(await addWord('wort$i'));
    }
    // 词 1：今天答错 1 次 → 错词
    await db.studyStatDao.recordAttempt(wordId: 1, isError: true);
    // 词 2：答错 2 次，即使后来答对 3 次仍是错词（答对不挤出列表）
    await db.studyStatDao.recordAttempt(wordId: 2, isError: true);
    await db.studyStatDao.recordAttempt(wordId: 2, isError: true);
    await db.studyStatDao.recordAttempt(wordId: 2, isError: false);
    await db.studyStatDao.recordAttempt(wordId: 2, isError: false);
    await db.studyStatDao.recordAttempt(wordId: 2, isError: false);
    // 词 3：只答对、从未答错 → 不是错词
    await db.studyStatDao.recordAttempt(wordId: 3, isError: false);
    await db.studyStatDao.recordAttempt(wordId: 3, isError: false);
    // 词 4：今日无答题记录 → 不是错词

    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 5,
      pickMode: WordPickMode.wrongTodayOnly,
    );
    final s = notifier.state;
    expect(s.error, isNull);
    expect(s.isLooping, isTrue);
    expect(s.words.map((w) => w.id).toSet(), {1, 2},
        reason: '只抓今天答错过（忘记/模糊）的词');
    expect(s.loopTotal, 2, reason: '大轮只覆盖今日错词');
  });

  test('只抓今日错词模式：无错词时提示切换模式', () async {
    for (var i = 0; i < 3; i++) {
      await markStudiedToday(await addWord('wort$i'));
    }
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 5,
      pickMode: WordPickMode.wrongTodayOnly,
    );
    expect(notifier.state.words, isEmpty);
    expect(notifier.state.error, contains('错词'));
  });

  test('只抓今日错词模式：即使每日新词额度未用尽，错词也照常复习', () async {
    // 词 1、2：今天学过且答错过（有 SM-2 状态，不在每日到期计划里）
    for (var i = 0; i < 3; i++) {
      final id = await addWord('wort$i');
      await markStudiedToday(id);
    }
    await db.studyStatDao.recordAttempt(wordId: 1, isError: true);
    await db.studyStatDao.recordAttempt(wordId: 2, isError: true);
    // 词 4、5：新词（无 SM-2 状态）→ 每日新词额度未用尽，计划非空
    await addWord('neu4');
    await addWord('neu5');

    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 20,
      dailyReviewLimit: 50,
      roundLimit: 10,
      pickMode: WordPickMode.wrongTodayOnly,
    );
    final s = notifier.state;
    expect(s.error, isNull);
    expect(s.isLooping, isTrue, reason: '今日错词不受每日额度影响');
    expect(s.words.map((w) => w.id).toSet(), {1, 2},
        reason: '错词复习不依赖到期计划，答错过的词都能进入');
  });

  test('只抓今日错词模式：连续 3 轮首次答对才毕业，答错清零并排到队尾', () async {
    for (var i = 0; i < 6; i++) {
      await markStudiedToday(await addWord('wort$i'));
    }
    // 词 1、2 今天答错过（错误 > 0）→ 错词
    await db.studyStatDao.recordAttempt(wordId: 1, isError: true);
    await db.studyStatDao.recordAttempt(wordId: 2, isError: true);

    Future<void> enterRound() async {
      await notifier.startSession(
        deckId: 1,
        dailyNewLimit: 10,
        dailyReviewLimit: 20,
        roundLimit: 5,
        pickMode: WordPickMode.wrongTodayOnly,
      );
      expect(notifier.state.error, isNull);
    }

    // 第 1 轮：两个都首次答对 → streak 1
    await enterRound();
    expect(notifier.state.words, hasLength(2));
    for (var i = 0; i < 2; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }
    expect(notifier.state.loopPendingIds, isEmpty, reason: '第 1 轮覆盖完毕');
    expect(notifier.state.loopStreak[1], 1);
    expect(notifier.state.loopStreak[2], 1);

    // 第 2 轮：词 A 首次答错 → streak 清零并排到队尾；词 B 首对 → streak 2
    await enterRound();
    expect(notifier.state.words, hasLength(2));
    final a = notifier.state.words.first.id;
    final b = notifier.state.words.last.id;
    await notifier.submitFeedback(FeedbackLevel.forgot);
    await notifier.submitFeedback(FeedbackLevel.good);
    expect(notifier.state.loopStreak[a], 0, reason: '答错清零');
    expect(notifier.state.loopStreak[b], 2);
    expect(notifier.state.loopPendingIds, [a], reason: '答错的 A 排到队尾待复习');

    // 继续本批：重排的 A 再次出现；即使答对，本轮已失败，streak 不变
    await enterRound();
    expect(notifier.state.words.single.id, a, reason: '重排词再次出现');
    await notifier.submitFeedback(FeedbackLevel.good);
    expect(notifier.state.loopStreak[a], 0, reason: '重排后答对不计干净轮数');
    expect(notifier.state.loopPendingIds, isEmpty, reason: '第 2 轮覆盖完毕');

    // 第 3 轮：B 首对 → streak 3 毕业；A 首对 → streak 1
    await enterRound();
    expect(notifier.state.words, hasLength(2));
    for (var i = 0; i < 2; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }
    expect(notifier.state.loopStreak[b], 3, reason: 'B 连续 3 轮首对毕业');
    expect(notifier.state.loopStreak[a], 1);

    // 第 4 轮：已毕业的 B 不再出现，只剩 A
    await enterRound();
    expect(notifier.state.words, hasLength(1));
    expect(notifier.state.words.single.id, a, reason: '毕业词被剔除');
    await notifier.submitFeedback(FeedbackLevel.good);
    expect(notifier.state.loopStreak[a], 2);

    // 第 5 轮：A 首对 → streak 3 毕业
    await enterRound();
    expect(notifier.state.words.single.id, a);
    await notifier.submitFeedback(FeedbackLevel.good);
    expect(notifier.state.loopStreak[a], 3);

    // 第 6 轮：全部毕业 → 提示无错词
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 5,
      pickMode: WordPickMode.wrongTodayOnly,
    );
    expect(notifier.state.words, isEmpty);
    expect(notifier.state.error, contains('错词'));
  });

  test('只抓今日错词模式：答错重排每轮最多 2 次，超限后当轮不再出现', () async {
    for (var i = 0; i < 6; i++) {
      await markStudiedToday(await addWord('wort$i'));
    }
    // 只有词 1 是今日错词
    await db.studyStatDao.recordAttempt(wordId: 1, isError: true);

    Future<void> enterWrongReview() async {
      await notifier.startSession(
        deckId: 1,
        dailyNewLimit: 10,
        dailyReviewLimit: 20,
        roundLimit: 1,
        pickMode: WordPickMode.wrongTodayOnly,
      );
      expect(notifier.state.error, isNull);
      expect(notifier.state.words.single.id, 1);
    }

    // 第 1 次答错 → 重排（count 1），本轮队尾待复习
    await enterWrongReview();
    await notifier.submitFeedback(FeedbackLevel.forgot);
    expect(notifier.state.loopReQueueCount[1], 1);
    expect(notifier.state.loopPendingIds, [1], reason: '排到队尾');

    // 重进：再次出现；第 2 次答错 → 重排（count 2）
    await enterWrongReview();
    await notifier.submitFeedback(FeedbackLevel.forgot);
    expect(notifier.state.loopReQueueCount[1], 2);
    expect(notifier.state.loopPendingIds, [1]);

    // 重进：第 3 次答错 → 已达上限，不再重排，本轮覆盖完毕
    await enterWrongReview();
    await notifier.submitFeedback(FeedbackLevel.forgot);
    expect(notifier.state.loopReQueueCount[1], 2, reason: '上限封顶');
    expect(notifier.state.loopPendingIds, isEmpty, reason: '当轮不再出现');

    // 下一大轮：仍未毕业（连续 0 轮首对），重新出现；重排计数清零
    await enterWrongReview();
    expect(notifier.state.loopCount, 2);
    expect(notifier.state.loopReQueueCount, isEmpty, reason: '新轮重排计数清零');
  });

  test('只抓今日错词模式：在其他模式答错会清零干净轮数', () async {
    for (var i = 0; i < 6; i++) {
      await markStudiedToday(await addWord('wort$i'));
    }
    await db.studyStatDao.recordAttempt(wordId: 1, isError: true);
    await db.studyStatDao.recordAttempt(wordId: 2, isError: true);

    // 错词复习第 1 轮：两个都首对 → streak 1
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 5,
      pickMode: WordPickMode.wrongTodayOnly,
    );
    for (var i = 0; i < 2; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }
    expect(notifier.state.loopStreak[1], 1);
    expect(notifier.state.loopStreak[2], 1);

    // 正常模式（循环）复习中答错词 1 → 清零其在错词复习里的干净轮数
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 10,
      pickMode: WordPickMode.normal,
    );
    final idx1 = notifier.state.words.indexWhere((w) => w.id == 1);
    expect(idx1, greaterThanOrEqualTo(0), reason: '词 1 在正常复习会话中');
    for (var i = 0; i < idx1; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }
    await notifier.submitFeedback(FeedbackLevel.forgot);

    // 回到错词复习第 2 轮：词 1 streak 已清零，词 2 保持 1
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
      roundLimit: 5,
      pickMode: WordPickMode.wrongTodayOnly,
    );
    expect(notifier.state.error, isNull);
    expect(notifier.state.loopCount, 2);
    expect(notifier.state.loopStreak[1], 0, reason: '别处答错清零');
    expect(notifier.state.loopStreak[2], 1, reason: '词 2 未受影响');
  });
}
