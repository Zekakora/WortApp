import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.deckDao.createDeck(DecksCompanion.insert(
      name: '测试词书',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  /// 创建带学习进度（SM2 状态 + 熟练度 + 上次学习日期）的单词
  Future<int> createWordWithProgress(String german) async {
    final wordId = await db.wordDao.createWord(WordsCompanion.insert(
      deckId: 1,
      german: german,
      chinese: '测试释义',
      proficiency: const drift.Value(3),
      lastStudyDate: drift.Value(DateTime(2026, 1, 5)),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 5),
    ));
    await db.sm2Dao.createState(Sm2StatesCompanion.insert(
      wordId: wordId,
      repetitionN: const drift.Value(5),
      intervalDays: const drift.Value(21),
      easeFactor: const drift.Value(2.1),
      nextReview: DateTime(2026, 2, 22),
      lastReview: drift.Value(DateTime(2026, 2, 1)),
      totalReviews: const drift.Value(12),
      correctStreak: const drift.Value(6),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 2, 1),
    ));
    return wordId;
  }

  test('重置后 SM-2 状态全部清空，熟练度与上次学习日期归零', () async {
    final wordId1 = await createWordWithProgress('gehen');
    final wordId2 = await createWordWithProgress('laufen');

    await db.resetAllLearningProgress();

    // SM-2 状态全部删除
    expect(await db.sm2Dao.getStateByWordId(wordId1), isNull);
    expect(await db.sm2Dao.getStateByWordId(wordId2), isNull);

    // 单词本身保留，学习字段归零
    final word1 = await db.wordDao.getWordById(wordId1);
    expect(word1, isNotNull);
    expect(word1!.german, 'gehen');
    expect(word1.chinese, '测试释义');
    expect(word1.proficiency, 0);
    expect(word1.lastStudyDate, isNull);

    final word2 = await db.wordDao.getWordById(wordId2);
    expect(word2!.proficiency, 0);
    expect(word2.lastStudyDate, isNull);
  });

  test('重置后单词变回新词（可被新词队列抽取）', () async {
    final wordId = await createWordWithProgress('schwimmen');

    // 重置前：有 SM-2 状态，不是新词
    expect(await db.sm2Dao.getNewWordIds(1), isEmpty);

    await db.resetAllLearningProgress();

    // 重置后：无 SM-2 状态，进入新词队列
    final newWordIds = await db.sm2Dao.getNewWordIds(1);
    expect(newWordIds, contains(wordId));
  });

  test('空库重置不报错', () async {
    await expectLater(db.resetAllLearningProgress(), completes);
  });
}
