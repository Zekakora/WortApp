import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';

/// 去重扫描与合并测试
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final now = DateTime(2026, 1, 1);
    await db.deckDao.createDeck(DecksCompanion.insert(
      name: '词书A',
      createdAt: now,
      updatedAt: now,
    ));
    await db.deckDao.createDeck(DecksCompanion.insert(
      name: '词书B',
      createdAt: now,
      updatedAt: now,
    ));
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> addWord(int deckId, String german, {String chinese = '释义'}) {
    return db.wordDao.createWord(WordsCompanion.insert(
      deckId: deckId,
      german: german,
      chinese: chinese,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ));
  }

  test('按规范化词形识别词书内重复（der Hund 与 Hund 归为同一词）', () async {
    await addWord(1, 'der Hund', chinese: '狗');
    await addWord(1, 'Hund', chinese: '狗');
    await addWord(1, 'laufen');
    await addWord(2, 'Hund', chinese: '狗'); // 另一词书不算词书内重复

    final groups = await db.findDeckDuplicateGroups(1);
    expect(groups, hasLength(1));
    expect(groups.first.canonicalKey, 'Hund');
    expect(groups.first.words, hasLength(2));
  });

  test('大小写不同的词不视为重复（lernen vs Lernen）', () async {
    await addWord(1, 'lernen');
    await addWord(1, 'Lernen');

    final groups = await db.findDeckDuplicateGroups(1);
    expect(groups, isEmpty);
  });

  test('合并：保留词继承被删词的 SM-2 状态、变位缓存与每日统计', () async {
    final keepId = await addWord(1, 'Hund', chinese: '狗');
    final dupId = await addWord(1, 'der Hund', chinese: '狗');
    await db.sm2Dao.createState(Sm2StatesCompanion.insert(
      wordId: dupId,
      repetitionN: const drift.Value(3),
      intervalDays: const drift.Value(7),
      easeFactor: const drift.Value(2.1),
      nextReview: DateTime(2026, 1, 20),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ));
    await db.conjugationDao.upsert(
      dupId,
      '{"type":"noun","plural":"Hunde"}',
      source: 'manual',
    );
    await db.studyStatDao.recordAttempt(wordId: dupId, isError: true);

    final removed = await db.mergeDuplicateGroup(
      keepWordId: keepId,
      removeWordIds: [dupId],
    );

    expect(removed, [dupId]);
    final words = await db.wordDao.getWordsByDeck(1);
    expect(words, hasLength(1));
    expect(words.first.id, keepId);

    final sm2 = await db.sm2Dao.getStateByWordId(keepId);
    expect(sm2, isNotNull);
    expect(sm2!.repetitionN, 3, reason: 'SM-2 状态已继承');

    final conj = await db.conjugationDao.getByWordId(keepId);
    expect(conj, isNotNull);
    expect(conj!.conjugationJson, contains('Hunde'));
    expect(conj.source, 'manual');

    final stats = await db.studyStatDao.getStats(deckId: 1, todayOnly: false);
    expect(stats, hasLength(1));
    expect(stats.first.appearances, 1);
    expect(stats.first.errors, 1);
  });

  test('合并：保留词已有 SM-2 状态时不被被删词覆盖', () async {
    final keepId = await addWord(1, 'Hund');
    final dupId = await addWord(1, 'der Hund');
    await db.sm2Dao.createState(Sm2StatesCompanion.insert(
      wordId: keepId,
      repetitionN: const drift.Value(5),
      intervalDays: const drift.Value(21),
      easeFactor: const drift.Value(2.5),
      nextReview: DateTime(2026, 2, 1),
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    ));

    await db.mergeDuplicateGroup(keepWordId: keepId, removeWordIds: [dupId]);

    final sm2 = await db.sm2Dao.getStateByWordId(keepId);
    expect(sm2!.repetitionN, 5, reason: '保留词已有状态不被覆盖');
  });

  test('合并后同词的共享 AI 查词缓存不被释放', () async {
    final keepId = await addWord(1, 'Hund');
    final dupId = await addWord(1, 'Hund');
    await db.aiCacheDao.saveToCache(
      word: 'Hund',
      resultJson: '{"word":"Hund","definitions":["狗"]}',
    );

    await db.mergeDuplicateGroup(keepWordId: keepId, removeWordIds: [dupId]);

    final cache = await db.aiCacheDao.getCachedResult('Hund');
    expect(cache, isNotNull, reason: '同词仍保留在词书中，AI 缓存不释放');
  });

  test('合并后该词书内不再有重复组', () async {
    final keepId = await addWord(1, 'Hund');
    final dupId = await addWord(1, 'der Hund');

    await db.mergeDuplicateGroup(keepWordId: keepId, removeWordIds: [dupId]);

    final groups = await db.findDeckDuplicateGroups(1);
    expect(groups, isEmpty);
  });

  test('回归：同词超过 2 条时合并不再抛 Too many elements', () async {
    // words.german 无唯一约束：批量 AI 规范化后同一词可能出现 3+ 条。
    // 旧实现 deleteWordInternal 用 getSingleOrNull 查"是否还有同名词"，
    // 删除 1 条后仍剩 2 条即抛 StateError: Too many elements。
    final keepId = await addWord(1, 'Hund');
    final dupId1 = await addWord(1, 'Hund');
    final dupId2 = await addWord(1, 'Hund');

    final removed = await db.mergeDuplicateGroup(
      keepWordId: keepId,
      removeWordIds: [dupId1, dupId2],
    );

    expect(removed, hasLength(2));
    final words = await db.wordDao.getWordsByDeck(1);
    expect(words.where((w) => w.german == 'Hund'), hasLength(1));
  });

  test('回归：另一词书存在同名词时删除也不抛错', () async {
    final keepId = await addWord(1, 'Hund');
    final dupId = await addWord(1, 'Hund');
    await addWord(2, 'Hund'); // 另一词书同名词 → 删除后仍剩 2 条同名

    final removed = await db.mergeDuplicateGroup(
      keepWordId: keepId,
      removeWordIds: [dupId],
    );

    expect(removed, hasLength(1));
    // 仍有其他词书引用该词，AI 缓存不应被释放
    await db.aiCacheDao.saveToCache(
      word: 'Hund',
      resultJson: '{"word":"Hund","definitions":["狗"]}',
    );
    final stillThere = await db.wordDao.getWordsByDeck(2);
    expect(stillThere.where((w) => w.german == 'Hund'), hasLength(1));
  });
}
