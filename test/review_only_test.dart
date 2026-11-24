import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/providers/study_provider.dart';

/// 「只复习」开关：开启后不抽取新词，只复习到期词；无到期词时进入循环
/// 复习今日已学单词。
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

  Future<int> addWord(String german) {
    return db.wordDao.createWord(WordsCompanion.insert(
      deckId: 1,
      german: german,
      chinese: '释义',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  /// 造一个「今天到期」的旧词 SM-2 状态
  Future<void> markDueToday(int wordId) async {
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

  /// 造一个「今天已学」的词（状态今天创建，下次复习明天，不再到期）
  Future<void> markStudiedToday(int wordId) async {
    final now = DateTime.now();
    await db.sm2Dao.createState(Sm2StatesCompanion.insert(
      wordId: wordId,
      repetitionN: const drift.Value(1),
      intervalDays: const drift.Value(1),
      easeFactor: const drift.Value(2.5),
      nextReview: now.add(const Duration(days: 1)),
      createdAt: now,
      updatedAt: now,
    ));
    await db.wordDao.updateLastStudyDate(wordId);
  }

  test('只复习：无到期词时不抽新词（词书有词 → 提示无待学习）', () async {
    for (var i = 0; i < 5; i++) {
      await addWord('wort$i'); // 全是新词
    }

    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 20,
      dailyReviewLimit: 100,
      roundLimit: 10,
      reviewOnly: true,
    );

    expect(notifier.state.words, isEmpty, reason: '只复习不应抽取新词');
    expect(notifier.state.error, isNotNull);
  });

  test('只复习：只抽到期复习词，不抽新词', () async {
    // 3 个新词
    for (var i = 0; i < 3; i++) {
      await addWord('neu$i');
    }
    // 2 个今天到期的旧词
    final dueIds = <int>[];
    for (var i = 0; i < 2; i++) {
      final id = await addWord('alt$i');
      await markDueToday(id);
      dueIds.add(id);
    }

    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 20,
      dailyReviewLimit: 100,
      roundLimit: 10,
      reviewOnly: true,
    );

    final s = notifier.state;
    expect(s.error, isNull);
    expect(s.isLooping, isFalse);
    expect(s.words, hasLength(2), reason: '只有 2 个到期复习词');
    expect(s.words.map((w) => w.id).toSet(), dueIds.toSet());
  });

  test('只复习：无到期词但今日已学非空 → 循环复习今日单词，仍不抽新词', () async {
    final studiedIds = <int>[];
    for (var i = 0; i < 4; i++) {
      final id = await addWord('heute$i');
      await markStudiedToday(id);
      studiedIds.add(id);
    }
    // 还有新词，但只复习模式下不应出现
    for (var i = 0; i < 3; i++) {
      await addWord('neu$i');
    }

    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 20,
      dailyReviewLimit: 100,
      roundLimit: 10,
      reviewOnly: true,
    );

    final s = notifier.state;
    expect(s.error, isNull);
    expect(s.isLooping, isTrue, reason: '无到期词时兜底循环复习今日已学');
    expect(s.words.map((w) => w.id).toSet(), studiedIds.toSet());
  });

  test('关闭只复习（默认）仍会抽取新词', () async {
    for (var i = 0; i < 5; i++) {
      await addWord('wort$i');
    }

    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 20,
      dailyReviewLimit: 100,
      roundLimit: 10,
    );

    expect(notifier.state.words, hasLength(5));
  });
}
