import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.deckDao.createDeck(DecksCompanion.insert(
      name: '词书A',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ));
    await db.deckDao.createDeck(DecksCompanion.insert(
      name: '词书B',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  /// 创建带完整关联数据的单词（SM2 状态 + 变位缓存 + AI 查词缓存 + AI 请求状态）
  Future<int> createWordWithAllData(String german, {int deckId = 1}) async {
    final wordId = await db.wordDao.createWord(WordsCompanion.insert(
      deckId: deckId,
      german: german,
      chinese: '测试释义',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ));
    await db.sm2Dao.createState(Sm2StatesCompanion.insert(
      wordId: wordId,
      repetitionN: const drift.Value(1),
      intervalDays: const drift.Value(1),
      easeFactor: const drift.Value(2.5),
      nextReview: DateTime(2026, 1, 2),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ));
    await db.conjugationDao.upsert(
      wordId,
      '{"type":"verb","praesens":{"ich":"gehe"}}',
    );
    await db.aiCacheDao.saveToCache(
      word: german,
      resultJson: '{"word":"$german","definitions":["测试释义"]}',
    );
    await db.aiStatusDao.record(word: german, success: true);
    return wordId;
  }

  test('删除唯一单词后释放 AI 缓存、请求状态、SM2 与变位缓存', () async {
    final wordId = await createWordWithAllData('gehen');

    await db.deleteWordWithCleanup(wordId);

    // 单词记录已删除
    expect(await db.wordDao.getWordById(wordId), isNull);
    // wordId 级关联数据已清理
    expect(await db.sm2Dao.getStateByWordId(wordId), isNull);
    expect(await db.conjugationDao.getByWordId(wordId), isNull);
    // 无其他词书引用 → 释放共享 AI 缓存与请求状态
    expect(await db.aiCacheDao.getCachedResult('gehen'), isNull);
    expect(await db.aiStatusDao.getStatus('gehen'), isNull);
  });

  test('其他词书仍存在相同单词时保留 AI 缓存与请求状态', () async {
    final wordIdA = await createWordWithAllData('laufen', deckId: 1);
    final wordIdB = await createWordWithAllData('laufen', deckId: 2);

    await db.deleteWordWithCleanup(wordIdA);

    // 词书A 的单词及其关联数据已删除
    expect(await db.wordDao.getWordById(wordIdA), isNull);
    expect(await db.sm2Dao.getStateByWordId(wordIdA), isNull);
    expect(await db.conjugationDao.getByWordId(wordIdA), isNull);
    // 词书B 的单词不受影响
    expect(await db.wordDao.getWordById(wordIdB), isNotNull);
    // 仍被其他词书引用 → 共享 AI 缓存与请求状态保留
    expect(await db.aiCacheDao.getCachedResult('laufen'), isNotNull);
    expect(await db.aiStatusDao.getStatus('laufen'), isNotNull);
  });

  test('删除后仅剩大小写不同的单词时按查重规则保留缓存', () async {
    final wordIdA = await createWordWithAllData('Der Hund', deckId: 1);
    final wordIdB = await createWordWithAllData('der Hund', deckId: 2);

    await db.deleteWordWithCleanup(wordIdA);

    // 词书B 存在 "der Hund"（忽略大小写视为相同单词）→ 缓存保留
    expect(await db.wordDao.getWordById(wordIdB), isNotNull);
    expect(await db.aiCacheDao.getCachedResult('Der Hund'), isNotNull);
  });

  test('删除不存在的单词不报错', () async {
    await expectLater(db.deleteWordWithCleanup(999), completes);
  });
}
