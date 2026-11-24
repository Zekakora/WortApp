import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/algorithms/check_in.dart';
import 'package:wortapp/algorithms/review_scheduler.dart';
import 'package:wortapp/algorithms/sm2_algorithm.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/providers/study_provider.dart';

/// 算法层不变量审计：这些断言描述的“应当成立”的性质，
/// 失败即说明实现与文档（memory/ALGORITHM.md）不一致。
void main() {
  group('SM-2 不变量', () {
    test('任意评分下间隔 ≥ 1 天、EF ≥ 1.3、下次复习严格晚于今天', () {
      final today = DateTime(2026, 11, 20);
      for (var q = 0; q <= 5; q++) {
        for (final n in [0, 1, 2, 3, 10]) {
          for (final interval in [0.0, 1.0, 6.0, 15.0, 100.0]) {
            for (final ef in [1.3, 2.5, 3.0]) {
              final r = SM2Algorithm.calculate(
                quality: q,
                currentN: n,
                currentInterval: interval,
                currentEF: ef,
              );
              final tag = 'q=$q n=$n i=$interval ef=$ef';
              expect(r.intervalDays, greaterThanOrEqualTo(1),
                  reason: '间隔不得 < 1 天（否则当天立即到期）$tag');
              expect(r.easeFactor, greaterThanOrEqualTo(1.3), reason: tag);
              expect(r.repetitionN, greaterThanOrEqualTo(0), reason: tag);
              // nextReview 用「今天 00:00 + 间隔」构造，必须严格晚于今天 00:00
              expect(
                r.nextReview.isAfter(today),
                isTrue,
                reason: '下次复习必须晚于今天 $tag → ${r.nextReview}',
              );
            }
          }
        }
      }
    });

    test('间隔随重复次数单调增长（同类评分连续作答）', () {
      var n = 0;
      var interval = 0.0;
      var ef = 2.5;
      var last = 0.0;
      for (var i = 0; i < 8; i++) {
        final r = SM2Algorithm.calculate(
          quality: 4,
          currentN: n,
          currentInterval: interval,
          currentEF: ef,
        );
        expect(r.intervalDays, greaterThan(last),
            reason: '第 ${i + 1} 次答对后间隔应增长');
        last = r.intervalDays;
        n = r.repetitionN;
        interval = r.intervalDays;
        ef = r.easeFactor;
      }
    });

    test('q=2（模糊）保留 n 但把间隔压回 1 天', () {
      final r = SM2Algorithm.calculate(
        quality: 2,
        currentN: 5,
        currentInterval: 30,
        currentEF: 2.5,
      );
      expect(r.repetitionN, 5);
      expect(r.intervalDays, 1);
    });
  });

  group('连续打卡', () {
    final now = DateTime(2026, 11, 20, 9, 30);

    test('今天已打卡：含今天向前连续计数', () {
      final dates = [
        DateTime(2026, 11, 20, 8),
        DateTime(2026, 11, 19, 22),
        DateTime(2026, 11, 18, 1),
      ];
      expect(calculateCheckInStreak(dates, now), 3);
    });

    test('今天未打卡但昨天有：从昨天起算，不算断签', () {
      final dates = [DateTime(2026, 11, 19), DateTime(2026, 11, 18)];
      expect(calculateCheckInStreak(dates, now), 2);
    });

    test('只在前天打卡：断签返回 0', () {
      expect(calculateCheckInStreak([DateTime(2026, 11, 18)], now), 0);
    });

    test('跨月连续打卡', () {
      final dates = [
        DateTime(2026, 11, 1),
        DateTime(2026, 10, 31),
        DateTime(2026, 10, 30),
      ];
      expect(calculateCheckInStreak(dates, DateTime(2026, 11, 1, 12)), 3);
    });

    test('跨年连续打卡', () {
      final dates = [
        DateTime(2027, 1, 1),
        DateTime(2026, 12, 31),
        DateTime(2026, 12, 30),
      ];
      expect(calculateCheckInStreak(dates, DateTime(2027, 1, 1, 8)), 3);
    });

    test('夏令时切换期间逐日仍算连续（2026-03-29 欧洲切换）', () {
      final d = DateTime(2026, 3, 29, 10); // 切换当天
      final dates = [
        d,
        DateTime(2026, 3, 28, 10),
        DateTime(2026, 3, 27, 10),
      ];
      expect(calculateCheckInStreak(dates, d), 3);
    });

    test('重复与乱序输入不影响结果', () {
      final dates = [
        DateTime(2026, 11, 18, 3),
        DateTime(2026, 11, 18, 20),
        DateTime(2026, 11, 20, 1),
        DateTime(2026, 11, 19, 5),
      ];
      expect(calculateCheckInStreak(dates, now), 3);
    });

    test('空集合返回 0', () {
      expect(calculateCheckInStreak(const [], now), 0);
    });

    test('只有未来的打卡记录（时钟回拨）不算连续', () {
      expect(calculateCheckInStreak([DateTime(2026, 11, 25)], now), 0);
    });
  });

  group('复习调度', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      final now = DateTime(2026, 1, 1);
      await db.deckDao.createDeck(
        DecksCompanion.insert(name: 'A', createdAt: now, updatedAt: now),
      );
    });

    tearDown(() async {
      await db.close();
    });

    /// 建词并写入 SM-2 状态（nextReview 指定）
    Future<int> addWord(String german, DateTime nextReview,
        {int n = 2, double interval = 6}) async {
      final now = DateTime.now();
      final id = await db.wordDao.createWord(WordsCompanion.insert(
        deckId: 1,
        german: german,
        chinese: '释义$german',
        createdAt: now,
        updatedAt: now,
      ));
      await db.sm2Dao.createState(Sm2StatesCompanion.insert(
        wordId: id,
        nextReview: nextReview,
        repetitionN: drift.Value(n),
        intervalDays: drift.Value(interval),
        createdAt: now,
        updatedAt: now,
      ));
      return id;
    }

    test('到期复习词应按 next_review 升序返回（先复习最逾期的）', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      // id 顺序与逾期程度相反：id1 最晚、id3 最逾期
      final id1 = await addWord('spaet', today.subtract(const Duration(days: 1)));
      final id2 = await addWord('mittel', today.subtract(const Duration(days: 5)));
      final id3 = await addWord('alt', today.subtract(const Duration(days: 9)));

      final words = await ReviewScheduler(db)
          .getDueReviewWords(deckId: 1, limit: 3);
      expect(words.map((w) => w.id).toList(), [id3, id2, id1],
          reason: '调度器文档承诺按 next_review 升序；截断前必须是最逾期的在前');
    });

    test('新词与到期词都为空时返回今日已学单词（循环复习兜底）', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      // 一个今天学过的词：有 SM-2 状态且 next_review 在未来
      final id = await addWord('heute', today.add(const Duration(days: 3)));
      await db.wordDao.updateLearningProgress(wordId: id, proficiency: 2);

      final plan = await ReviewScheduler(db).getTodayPlan(deckId: 1);
      expect(plan.newWords, isEmpty);
      expect(plan.reviewWords, isEmpty);
      expect(plan.todayWords.map((w) => w.id), [id]);
    });
  });

  group('学习会话抓词', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      final now = DateTime(2026, 1, 1);
      await db.deckDao.createDeck(
        DecksCompanion.insert(name: 'A', createdAt: now, updatedAt: now),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('收藏优先（非循环）会把收藏词在同一会话内加入两次（已知取舍）', () async {
      final now = DateTime(2026, 1, 1);
      var favoriteId = 0;
      for (final g in ['eins', 'zwei', 'drei']) {
        final id = await db.wordDao.createWord(WordsCompanion.insert(
          deckId: 1,
          german: g,
          chinese: '释义$g',
          createdAt: now,
          updatedAt: now,
        ));
        if (g == 'eins') {
          await db.wordDao.updateFavorite(id, true);
          favoriteId = id;
        }
      }

      final notifier = StudySessionNotifier(db);
      await notifier.startSession(
        deckId: 1,
        pickMode: WordPickMode.favoriteBoost,
      );

      final ids = notifier.state.words.map((w) => w.id).toList();
      // 现状（memory/ALGORITHM.md §7.1）：非循环模式收藏词重复加入，
      // 以此提高「被抓到」的概率。副作用是同一会话内同一词会被答两次，
      // 于是 SM-2 连记两笔（重复次数 +2、间隔按两步增长）。
      expect(ids, hasLength(4), reason: '3 个词 + 收藏词重复 1 次');
      expect(ids.where((id) => id == favoriteId), hasLength(2));
    });
  });
}
