import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/algorithms/check_in.dart';
import 'package:wortapp/data/database/app_database.dart';

void main() {
  group('calculateCheckInStreak', () {
    // 固定一个"今天"作为参照（周五）
    final now = DateTime(2026, 8, 7, 15, 30);
    DateTime daysAgo(int n) => DateTime(now.year, now.month, now.day - n);

    test('无学习记录返回 0', () {
      expect(calculateCheckInStreak(const [], now), 0);
    });

    test('仅今天打卡返回 1', () {
      expect(calculateCheckInStreak([daysAgo(0)], now), 1);
    });

    test('今天 + 昨天连续返回 2', () {
      expect(calculateCheckInStreak([daysAgo(0), daysAgo(1)], now), 2);
    });

    test('连续多天（含重复与乱序）返回正确天数', () {
      final dates = [daysAgo(3), daysAgo(0), daysAgo(2), daysAgo(1), daysAgo(1)];
      expect(calculateCheckInStreak(dates, now), 4);
    });

    test('今天未打卡但昨天打卡：从昨天开始连续计数，不断签', () {
      expect(calculateCheckInStreak([daysAgo(1), daysAgo(2), daysAgo(3)], now), 3);
    });

    test('最近打卡日早于昨天（断签）返回 0', () {
      expect(calculateCheckInStreak([daysAgo(2)], now), 0);
      expect(calculateCheckInStreak([daysAgo(2), daysAgo(3)], now), 0);
    });

    test('今天打卡但前天断档：只计今天', () {
      expect(calculateCheckInStreak([daysAgo(0), daysAgo(2)], now), 1);
    });

    test('跨月连续天数正确', () {
      // 今天 8 月 7 日，连续覆盖 7 月底到 8 月初
      final dates = [
        DateTime(2026, 8, 7),
        DateTime(2026, 8, 6),
        DateTime(2026, 8, 5),
        DateTime(2026, 8, 1),
        DateTime(2026, 7, 31),
        DateTime(2026, 7, 30),
      ];
      // 8/7、8/6、8/5 连续，8/4 缺失断档 → 3 天
      expect(calculateCheckInStreak(dates, now), 3);
    });
  });

  group('StudyStatDao 打卡数据', () {
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

    test('当天任意答题即写入打卡日期，getDistinctStudyDates 返回去重日期', () async {
      final wordId = await addWord('wort');
      await db.studyStatDao.recordAttempt(wordId: wordId, isError: false);
      await db.studyStatDao.recordAttempt(wordId: wordId, isError: true);

      final dates = await db.studyStatDao.getDistinctStudyDates();
      expect(dates, hasLength(1));
      final today = DateTime.now();
      expect(dates.single, DateTime(today.year, today.month, today.day));
      expect(calculateCheckInStreak(dates, today), 1);
    });

    test('多次答题只产生一个打卡日期，连续天数统计不受影响', () async {
      final id1 = await addWord('wort1');
      final id2 = await addWord('wort2');
      for (var i = 0; i < 5; i++) {
        await db.studyStatDao.recordAttempt(wordId: id1, isError: false);
        await db.studyStatDao.recordAttempt(wordId: id2, isError: true);
      }

      final dates = await db.studyStatDao.getDistinctStudyDates();
      expect(dates, hasLength(1));
    });

    test('无任何答题记录时返回空列表', () async {
      await addWord('wort');
      final dates = await db.studyStatDao.getDistinctStudyDates();
      expect(dates, isEmpty);
    });
  });
}
