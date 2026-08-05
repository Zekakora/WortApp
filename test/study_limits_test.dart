import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/algorithms/review_scheduler.dart';
import 'package:wortapp/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.deckDao.createDeck(DecksCompanion.insert(
      name: '测试词书',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
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

  test('首次进入按每日上限抽取新词', () async {
    for (var i = 0; i < 30; i++) {
      await addWord('wort$i');
    }
    final plan = await ReviewScheduler(db).getTodayPlan(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
    );
    expect(plan.newWords, hasLength(10));
    expect(plan.reviewWords, isEmpty);
    expect(plan.todayWords, isEmpty);
  });

  test('今日已学满新词上限后不再抽取新词，兜底复习今日已学单词', () async {
    final ids = <int>[];
    for (var i = 0; i < 30; i++) {
      ids.add(await addWord('wort$i'));
    }
    final now = DateTime.now();
    // 模拟今天已学习 10 个新词（sm2 状态 createdAt = 今天）
    for (var i = 0; i < 10; i++) {
      await db.sm2Dao.createState(Sm2StatesCompanion.insert(
        wordId: ids[i],
        repetitionN: const drift.Value(1),
        intervalDays: const drift.Value(1),
        easeFactor: const drift.Value(2.5),
        nextReview: DateTime.now().add(const Duration(days: 1)),
        createdAt: now,
        updatedAt: now,
      ));
      await db.wordDao.updateLastStudyDate(ids[i]);
    }

    final plan = await ReviewScheduler(db).getTodayPlan(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
    );
    expect(plan.todayNewStudiedCount, 10);
    expect(plan.newWords, isEmpty, reason: '新词上限已用尽，不应再抽新词');
    expect(plan.reviewWords, isEmpty, reason: '今天没有到期的复习词');
    expect(plan.todayWords, hasLength(10),
        reason: '新词用尽且无到期复习词时，应兜底复习今日已学的单词，保证能继续学习');
  });

  test('新词与复习上限均用尽后，兜底复习今日已学单词', () async {
    final ids = <int>[];
    for (var i = 0; i < 30; i++) {
      ids.add(await addWord('wort$i'));
    }
    final now = DateTime.now();
    // 今日学 10 个新词
    for (var i = 0; i < 10; i++) {
      await db.sm2Dao.createState(Sm2StatesCompanion.insert(
        wordId: ids[i],
        repetitionN: const drift.Value(1),
        intervalDays: const drift.Value(1),
        easeFactor: const drift.Value(2.5),
        nextReview: DateTime.now().add(const Duration(days: 1)),
        createdAt: now,
        updatedAt: now,
      ));
      await db.wordDao.updateLastStudyDate(ids[i]);
    }
    // 今日复习 20 个旧词（复习后下次复习推后）
    for (var i = 10; i < 30; i++) {
      await db.sm2Dao.createState(Sm2StatesCompanion.insert(
        wordId: ids[i],
        repetitionN: const drift.Value(3),
        intervalDays: const drift.Value(7),
        easeFactor: const drift.Value(2.5),
        nextReview: DateTime.now().add(const Duration(days: 7)),
        lastReview: drift.Value(now),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: now,
      ));
      await db.wordDao.updateLastStudyDate(ids[i]);
    }

    final plan = await ReviewScheduler(db).getTodayPlan(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 20,
    );
    expect(plan.todayNewStudiedCount, 10);
    expect(plan.todayReviewStudiedCount, 20);
    expect(plan.newWords, isEmpty);
    expect(plan.reviewWords, isEmpty);
    expect(plan.todayWords, hasLength(30),
        reason: '上限均用尽后应兜底复习今日已学的全部单词');
  });

  test('今日已复习数量计入复习上限扣除', () async {
    final ids = <int>[];
    for (var i = 0; i < 30; i++) {
      ids.add(await addWord('wort$i'));
    }
    final now = DateTime.now();
    // 10 个旧词今天到期但尚未复习
    for (var i = 0; i < 10; i++) {
      await db.sm2Dao.createState(Sm2StatesCompanion.insert(
        wordId: ids[i],
        repetitionN: const drift.Value(3),
        intervalDays: const drift.Value(7),
        easeFactor: const drift.Value(2.5),
        // 生产数据中 SM-2 的 next_review 为日期零点（不带时间），今天到期的词即 next_review = 今日零点
        nextReview: DateTime(now.year, now.month, now.day),
        lastReview: drift.Value(DateTime.now().subtract(const Duration(days: 7))),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now().subtract(const Duration(days: 7)),
      ));
    }
    // 另外 5 个旧词今天已复习
    for (var i = 10; i < 15; i++) {
      await db.sm2Dao.createState(Sm2StatesCompanion.insert(
        wordId: ids[i],
        repetitionN: const drift.Value(3),
        intervalDays: const drift.Value(7),
        easeFactor: const drift.Value(2.5),
        nextReview: DateTime.now().add(const Duration(days: 7)),
        lastReview: drift.Value(now),
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: now,
      ));
      await db.wordDao.updateLastStudyDate(ids[i]);
    }

    final plan = await ReviewScheduler(db).getTodayPlan(
      deckId: 1,
      dailyNewLimit: 10,
      dailyReviewLimit: 12,
    );
    // 复习上限 12 - 今日已复习 5 = 剩余 7 个额度
    expect(plan.todayReviewStudiedCount, 5);
    expect(plan.reviewWords, hasLength(7));
  });
}
