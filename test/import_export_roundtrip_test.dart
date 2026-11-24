import 'dart:convert';
import 'dart:typed_data';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/services/import_export/export_service.dart';
import 'package:wortapp/services/import_export/import_service.dart';

void main() {
  group('导出服务', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db.deckDao.createDeck(DecksCompanion.insert(
        name: '测试词书',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      final wordId = await db.wordDao.createWord(WordsCompanion.insert(
        deckId: 1,
        german: 'gehen',
        article: const drift.Value(''),
        baseForm: const drift.Value('gehen'),
        wordType: const drift.Value('verb'),
        chinese: '去，走',
        example: const drift.Value('Ich gehe nach Hause.'),
        isFavorite: const drift.Value(true),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      // SM-2 状态
      await db.sm2Dao.createState(Sm2StatesCompanion.insert(
        wordId: wordId,
        repetitionN: const drift.Value(3),
        intervalDays: const drift.Value(7),
        easeFactor: const drift.Value(2.3),
        nextReview: DateTime(2026, 1, 10),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 8),
      ));
      // 变位缓存
      await db.conjugationDao.upsert(
        wordId,
        '{"type":"verb","praesens":{"er_sie_es":"geht"}}',
      );
      // AI 查词缓存
      await db.aiCacheDao.saveToCache(
        word: 'gehen',
        resultJson: '{"word":"gehen","definitions":["去，走"],"article":""}',
      );
      // 应用设置
      await db.setSetting('ttsSpeed', '0.5');
      await db.setSetting('aiConcurrency', '2');
      // AI 请求状态记录（数据管理用）
      await db.aiStatusDao.record(word: 'gehen', success: true);
      await db.aiStatusDao.record(
        word: 'laufen',
        success: false,
        error: 'API 超时',
      );
      // 每日错误统计（出现 3 次、错误 2 次）
      await db.studyStatDao.recordAttempt(wordId: wordId, isError: true);
      await db.studyStatDao.recordAttempt(wordId: wordId, isError: false);
      await db.studyStatDao.recordAttempt(wordId: wordId, isError: true);
    });

    tearDown(() async {
      await db.close();
    });

    test('CSV 导出带 BOM 且包含表头与数据', () async {
      final result = await ExportService(db).exportToCsv(deckId: 1);
      expect(result.success, isTrue);
      // utf8.decode 会剥离 BOM，需检查原始字节（EF BB BF）
      expect(result.data!.bytes.take(3), [0xEF, 0xBB, 0xBF],
          reason: 'CSV 应带 UTF-8 BOM');
      final text = utf8.decode(result.data!.bytes);
      expect(text, contains('德语单词'));
      expect(text, contains('gehen'));
      expect(result.data!.fileName, endsWith('.csv'));
    });

    test('Excel 导出生成有效字节', () async {
      final result = await ExportService(db).exportToExcel(deckId: 1);
      expect(result.success, isTrue);
      expect(result.data!.bytes, isNotEmpty);
      // xlsx 是 zip 格式，魔数 PK
      expect(result.data!.bytes.take(2), [0x50, 0x4B]);
      expect(result.data!.fileName, endsWith('.xlsx'));
    });

    test('备份导出包含全部字段、SM2 与变位缓存', () async {
      final result = await ExportService(db).exportBackup(deckIds: [1]);
      expect(result.success, isTrue);

      final json = jsonDecode(utf8.decode(result.data!.bytes));
      expect(json['type'], 'wortapp-backup');
      expect(json['app'], 'WortApp');
      expect(json['deckCount'], 1);

      final deckJson = (json['decks'] as List).first as Map<String, dynamic>;
      expect(deckJson['name'], '测试词书');

      final wordJson = (deckJson['words'] as List).first as Map<String, dynamic>;
      expect(wordJson['german'], 'gehen');
      expect(wordJson['chinese'], '去，走');
      expect(wordJson['wordType'], 'verb');
      expect(wordJson['example'], 'Ich gehe nach Hause.');

      final sm2 = wordJson['sm2'] as Map<String, dynamic>;
      expect(sm2['repetitionN'], 3);
      expect(sm2['intervalDays'], 7.0);
      expect(sm2['easeFactor'], 2.3);

      final conj = wordJson['conjugation'] as Map<String, dynamic>;
      expect(conj['json'], contains('er_sie_es'));
      expect(conj['source'], 'ai');

      // 收藏标记与每日错误统计
      expect(wordJson['isFavorite'], isTrue);
      final stats = wordJson['stats'] as List;
      expect(stats, hasLength(1));
      final stat = stats.first as Map<String, dynamic>;
      expect(stat['appearances'], 3);
      expect(stat['errors'], 2);
    });

    test('备份导出包含 AI 缓存与设置', () async {
      final result = await ExportService(db).exportBackup(deckIds: [1]);
      expect(result.success, isTrue);

      final json = jsonDecode(utf8.decode(result.data!.bytes));
      expect(json['version'], 5);

      final aiCache = json['aiCache'] as List;
      expect(aiCache, hasLength(1));
      final cacheEntry = aiCache.first as Map<String, dynamic>;
      expect(cacheEntry['word'], 'gehen');
      expect(cacheEntry['resultJson'], contains('去，走'));
      expect(cacheEntry['engine'], 'ai');

      // AI 请求状态（设备本地日志）不再参与备份 / 同步
      expect(json.containsKey('aiStatus'), isFalse);
      expect(json.containsKey('aiStatusCount'), isFalse);

      final settings = json['settings'] as List;
      expect(settings, hasLength(2));
      final settingKeys = settings
          .map((s) => (s as Map<String, dynamic>)['key'])
          .toSet();
      expect(settingKeys, containsAll(['ttsSpeed', 'aiConcurrency']));
    });
  });

  group('备份导入服务', () {
    late AppDatabase sourceDb;
    late AppDatabase targetDb;

    setUp(() async {
      sourceDb = AppDatabase(NativeDatabase.memory());
      await sourceDb.deckDao.createDeck(DecksCompanion.insert(
        name: 'A1词汇',
        description: const drift.Value('歌德A1'),
        isActive: const drift.Value(true),
        createdAt: DateTime(2026, 2, 1),
        updatedAt: DateTime(2026, 2, 1),
      ));
      final wordId = await sourceDb.wordDao.createWord(WordsCompanion.insert(
        deckId: 1,
        german: 'der Hund',
        chinese: '狗',
        wordType: const drift.Value('noun'),
        nounGenitive: const drift.Value('des Hundes'),
        nounPlural: const drift.Value('Hunde'),
        isFavorite: const drift.Value(true),
        createdAt: DateTime(2026, 2, 1),
        updatedAt: DateTime(2026, 2, 2),
      ));
      await sourceDb.sm2Dao.createState(Sm2StatesCompanion.insert(
        wordId: wordId,
        repetitionN: const drift.Value(5),
        intervalDays: const drift.Value(21),
        easeFactor: const drift.Value(2.1),
        nextReview: DateTime(2026, 2, 22),
        createdAt: DateTime(2026, 2, 1),
        updatedAt: DateTime(2026, 2, 2),
      ));
      await sourceDb.conjugationDao.upsert(
        wordId,
        '{"type":"noun","genitiv":"des Hundes","plural":"Hunde"}',
        source: 'manual',
      );
      // AI 查词缓存
      await sourceDb.aiCacheDao.saveToCache(
        word: 'der Hund',
        resultJson:
            '{"word":"der Hund","definitions":["狗"],"article":"der"}',
      );
      // 应用设置
      await sourceDb.setSetting('ttsSpeed', '0.7');
      // AI 请求状态记录（数据管理用）
      await sourceDb.aiStatusDao.record(
        word: 'der Hund',
        success: false,
        error: '连接失败',
      );
      // 每日错误统计（出现 2 次、错误 1 次）
      await sourceDb.studyStatDao.recordAttempt(wordId: wordId, isError: true);
      await sourceDb.studyStatDao.recordAttempt(wordId: wordId, isError: false);

      targetDb = AppDatabase(NativeDatabase.memory());
    });

    tearDown(() async {
      await sourceDb.close();
      await targetDb.close();
    });

    Future<Uint8List> exportBytes() async {
      final result = await ExportService(sourceDb).exportBackup();
      expect(result.success, isTrue);
      return result.data!.bytes;
    }

    test('导入后完整恢复词书、单词、SM2 与变位缓存', () async {
      final service = ImportService(targetDb);
      final bytes = await exportBytes();
      final result = await service.importBackup(
        fileBytes: bytes,
        fileName: 'backup.json',
      );

      expect(result.errors, isEmpty);
      expect(result.deckCount, 1);
      expect(result.wordCount, 1);

      // 词书恢复
      final decks = await targetDb.deckDao.getAllDecks();
      expect(decks, hasLength(1));
      expect(decks.first.name, 'A1词汇');
      expect(decks.first.description, '歌德A1');

      // 单词恢复（含全字段）
      final words = await targetDb.wordDao.getWordsByDeck(decks.first.id);
      expect(words, hasLength(1));
      expect(words.first.german, 'der Hund');
      expect(words.first.chinese, '狗');
      expect(words.first.wordType, 'noun');
      expect(words.first.nounGenitive, 'des Hundes');
      expect(words.first.nounPlural, 'Hunde');
      expect(words.first.createdAt, DateTime(2026, 2, 1));
      expect(words.first.updatedAt, DateTime(2026, 2, 2));

      // SM-2 恢复
      final sm2 = await targetDb.sm2Dao.getStateByWordId(words.first.id);
      expect(sm2, isNotNull);
      expect(sm2!.repetitionN, 5);
      expect(sm2.intervalDays, 21.0);
      expect(sm2.easeFactor, 2.1);
      expect(sm2.nextReview, DateTime(2026, 2, 22));

      // 变位缓存恢复
      final cache = await targetDb.conjugationDao.getByWordId(words.first.id);
      expect(cache, isNotNull);
      expect(cache!.conjugationJson, contains('des Hundes'));
      expect(cache.source, 'manual');

      // 备份中激活的词书应在空库中恢复激活
      final active = await targetDb.deckDao.getActiveDeck();
      expect(active, isNotNull);

      // 词书时间戳恢复为备份值
      expect(decks.first.createdAt, DateTime(2026, 2, 1));
      expect(decks.first.updatedAt, DateTime(2026, 2, 1));

      // AI 查词缓存恢复：详情页可直接命中缓存，不再重复调用 AI
      final aiCache = await targetDb.aiCacheDao.getCachedResult('der Hund');
      expect(aiCache, isNotNull);
      expect(aiCache!.resultJson, contains('狗'));

      // AI 请求状态是设备本地日志，不从备份恢复
      expect(await targetDb.aiStatusDao.getStatus('der Hund'), isNull);

      // 设置恢复
      expect(await targetDb.getSetting('ttsSpeed'), '0.7');

      // 收藏标记恢复
      expect(words.first.isFavorite, isTrue);

      // 每日错误统计恢复（出现 2 次、错误 1 次）
      final stats = await targetDb.studyStatDao
          .getStats(deckId: decks.first.id, todayOnly: false);
      expect(stats, hasLength(1));
      expect(stats.first.appearances, 2);
      expect(stats.first.errors, 1);
    });

    test('空库恢复时完整还原跨词书重复单词', () async {
      // 第二个词书包含与第一个词书相同的单词
      await sourceDb.deckDao.createDeck(DecksCompanion.insert(
        name: 'A2词汇',
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 1),
      ));
      await sourceDb.wordDao.createWord(WordsCompanion.insert(
        deckId: 2,
        german: 'der Hund',
        chinese: '狗',
        createdAt: DateTime(2026, 3, 1),
        updatedAt: DateTime(2026, 3, 1),
      ));

      final service = ImportService(targetDb);
      final bytes = await exportBytes();
      final result = await service.importBackup(
        fileBytes: bytes,
        fileName: 'backup.json',
      );
      expect(result.deckCount, 2);
      expect(result.wordCount, 2);
      expect(result.skipCount, 0);

      final decks = await targetDb.deckDao.getAllDecks();
      expect(decks, hasLength(2));
      for (final deck in decks) {
        final words = await targetDb.wordDao.getWordsByDeck(deck.id);
        expect(words.map((w) => w.german), contains('der Hund'));
      }
    });

    test('同名词书自动加序号，跨词书允许重复单词', () async {
      final service = ImportService(targetDb);
      final bytes = await exportBytes();
      // 第一次导入
      final first = await service.importBackup(
        fileBytes: bytes,
        fileName: 'backup.json',
      );
      expect(first.deckCount, 1);
      expect(first.wordCount, 1);

      // 第二次导入：词书重名加 (1)；
      // 同一单词允许在不同词书中同时存在（共享 AI 查词缓存），不再跳过
      final second = await service.importBackup(
        fileBytes: bytes,
        fileName: 'backup.json',
      );
      expect(second.deckCount, 1);
      expect(second.wordCount, 1);
      expect(second.skipCount, 0);

      final decks = await targetDb.deckDao.getAllDecks();
      expect(decks.map((d) => d.name), containsAll(['A1词汇', 'A1词汇(1)']));

      // 两个词书中均包含同一单词
      for (final deck in decks) {
        final words = await targetDb.wordDao.getWordsByDeck(deck.id);
        expect(words.map((w) => w.german), contains('der Hund'));
      }
    });

    test('wipeExisting 完全覆盖：清空旧数据并完整还原备份', () async {
      // 目标库先造旧数据（词书、单词、设置）
      final oldDeckId = await targetDb.deckDao.createDeck(
        DecksCompanion.insert(
          name: '旧词书',
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      );
      await targetDb.wordDao.createWord(WordsCompanion.insert(
        deckId: oldDeckId,
        german: 'alt',
        chinese: '旧的',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      ));
      await targetDb.setSetting('oldKey', 'oldValue');
      // 旧 AI 请求状态（应在 wipe 时被清除）
      await targetDb.aiStatusDao.record(word: 'alt', success: false);
      // 旧每日错误统计（应在 wipe 时被清除，否则外键约束导致清空失败）
      final oldWordId = (await targetDb.wordDao
              .findWordByGerman(oldDeckId, 'alt'))!
          .id;
      await targetDb.studyStatDao.recordAttempt(
        wordId: oldWordId,
        isError: true,
      );

      final service = ImportService(targetDb);
      final bytes = await exportBytes();
      final result = await service.importBackup(
        fileBytes: bytes,
        fileName: 'backup.json',
        wipeExisting: true,
      );

      expect(result.errors, isEmpty);
      expect(result.deckCount, 1);
      expect(result.wordCount, 1);
      expect(result.skipCount, 0);

      // 旧数据被完全清除，仅剩备份内容
      final decks = await targetDb.deckDao.getAllDecks();
      expect(decks, hasLength(1));
      expect(decks.first.name, 'A1词汇');
      expect(decks.first.createdAt, DateTime(2026, 2, 1));

      final words = await targetDb.wordDao.getWordsByDeck(decks.first.id);
      expect(words, hasLength(1));
      expect(words.first.german, 'der Hund');

      // 旧设置被清除，备份设置已恢复
      expect(await targetDb.getSetting('oldKey'), isNull);
      expect(await targetDb.getSetting('ttsSpeed'), '0.7');

      // AI 缓存完整还原
      final aiCache = await targetDb.aiCacheDao.getCachedResult('der Hund');
      expect(aiCache, isNotNull);

      // wipe 时旧 AI 状态被清除；备份已不含 AI 状态，恢复后仍为空
      expect(await targetDb.aiStatusDao.getStatus('alt'), isNull);
      expect(await targetDb.aiStatusDao.getStatus('der Hund'), isNull);
    });

    test('非法备份文件返回错误', () async {
      final service = ImportService(targetDb);
      final result = await service.importBackup(
        fileBytes: utf8.encode('{"type":"other"}'),
        fileName: 'bad.json',
      );
      expect(result.deckCount, 0);
      expect(result.errors, isNotEmpty);
    });
  });
}
