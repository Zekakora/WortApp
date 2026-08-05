import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';

void main() {
  group('ConjugationDao 变位数据管理', () {
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

    Future<Word> addWord(String german, String wordType) async {
      final id = await db.wordDao.createWord(WordsCompanion.insert(
        deckId: 1,
        german: german,
        chinese: '中文释义',
        wordType: drift.Value(wordType),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      return (await db.wordDao.getWordById(id))!;
    }

    test('getCachedByDeck 返回词书中所有单词的缓存', () async {
      final w1 = await addWord('gehen', 'verb');
      final w2 = await addWord('machen', 'verb');
      await db.conjugationDao.upsert(w1.id, '{"type":"verb","praesens":{}}');
      await db.conjugationDao.upsert(w2.id, '{"type":"verb","praesens":{}}');

      final cache = await db.conjugationDao.getCachedByDeck(1);
      expect(cache, hasLength(2));
      expect(cache[w1.id]!.wordId, w1.id);
      expect(cache[w1.id]!.conjugationJson, contains('praesens'));
      expect(cache[w1.id]!.source, 'ai');
      expect(cache[w2.id], isNotNull);
    });

    test('getCachedByDeck 不包含无缓存单词与其他词书数据', () async {
      final w1 = await addWord('gehen', 'verb');
      await addWord('laufen', 'verb'); // 无缓存
      await db.conjugationDao.upsert(w1.id, '{"type":"verb"}');

      final cache = await db.conjugationDao.getCachedByDeck(1);
      expect(cache, hasLength(1));
      expect(cache.keys.single, w1.id);

      // 另一词书中的单词缓存不应出现在当前词书结果中
      await db.deckDao.createDeck(DecksCompanion.insert(
        name: '词书2',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      final w2 = await db.wordDao.createWord(WordsCompanion.insert(
        deckId: 2,
        german: 'lernen',
        chinese: '学习',
        wordType: drift.Value('verb'),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      await db.conjugationDao.upsert(w2, '{"type":"verb"}');

      expect(await db.conjugationDao.getCachedByDeck(1), hasLength(1));
      expect(await db.conjugationDao.getCachedByDeck(2), hasLength(1));
    });

    test('upsert 支持手动编辑保存（source=manual）', () async {
      final w1 = await addWord('gehen', 'verb');
      await db.conjugationDao.upsert(
        w1.id,
        '{"type":"verb","praesens":{"ich":"gehe"}}',
        source: 'manual',
      );
      final cache = await db.conjugationDao.getByWordId(w1.id);
      expect(cache, isNotNull);
      expect(cache!.source, 'manual');
      expect(cache.conjugationJson, contains('"ich":"gehe"'));

      // 手动编辑覆盖已有 AI 数据后，来源同样标记为手动
      await db.conjugationDao.upsert(w1.id, '{"type":"verb"}');
      expect((await db.conjugationDao.getByWordId(w1.id))!.source, 'ai');
      await db.conjugationDao.upsert(
        w1.id,
        '{"type":"verb","praesens":{"du":"gehst"}}',
        source: 'manual',
      );
      final edited = await db.conjugationDao.getByWordId(w1.id);
      expect(edited!.source, 'manual');
      expect(edited.conjugationJson, contains('"du":"gehst"'));
    });

    test('deleteByWordIds 批量删除指定单词缓存', () async {
      final w1 = await addWord('gehen', 'verb');
      final w2 = await addWord('machen', 'verb');
      await db.conjugationDao.upsert(w1.id, '{"type":"verb"}');
      await db.conjugationDao.upsert(w2.id, '{"type":"verb"}');

      final deleted = await db.conjugationDao.deleteByWordIds([w1.id]);
      expect(deleted, 1);
      expect(await db.conjugationDao.getByWordId(w1.id), isNull);
      expect(await db.conjugationDao.getByWordId(w2.id), isNotNull);
    });

    test('deleteByWordIds 空列表安全返回 0', () async {
      expect(await db.conjugationDao.deleteByWordIds([]), 0);
    });

    test('upsert 覆盖更新缓存并刷新 updatedAt', () async {
      final w1 = await addWord('gehen', 'verb');
      await db.conjugationDao.upsert(w1.id, '{"type":"verb","v":1}');
      final first = await db.conjugationDao.getByWordId(w1.id);
      expect(first!.conjugationJson, '{"type":"verb","v":1}');

      // drift 按秒存储 DateTime，等待跨越秒边界确保 updatedAt 可区分
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await db.conjugationDao.upsert(w1.id, '{"type":"verb","v":2}');
      final second = await db.conjugationDao.getByWordId(w1.id);
      expect(second!.conjugationJson, '{"type":"verb","v":2}');
      expect(second.updatedAt.isAfter(first.updatedAt), isTrue);
    });
  });
}
