import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/services/sync/backup_merger.dart';

/// 删除墓碑（跨端删除传播）测试：
/// - 删除传播：对端词/词书在删除后无活动 → 从合并结果剔除
/// - 删除驳回：对端在删除后仍复习/编辑/重建 → 词保留，墓碑作废
/// - 两端墓碑合并去重，词书级墓碑（german 空串）整本剔除
/// - v4 老备份（无 deletions 字段）行为不变
void main() {
  // 时间线：T0 创建 → T1.5 云端导出 → T2 删除 → T3 对端活动
  const t0 = '2026-01-01T08:00:00.000Z';
  const t15 = '2026-01-03T08:00:00.000Z';
  const t2 = '2026-01-04T08:00:00.000Z';
  const t3 = '2026-01-05T08:00:00.000Z';

  Map<String, dynamic> makeBackup({
    List<Map<String, dynamic>>? words,
    String deckName = 'A1',
    String? exportedAt,
    List<Map<String, dynamic>>? deletions,
    bool includeDeletions = true,
  }) {
    final decks = (words == null || words.isEmpty)
        ? <Map<String, dynamic>>[]
        : [
            {
              'name': deckName,
              'description': '',
              'createdAt': t0,
              'updatedAt': t0,
              'words': words,
            },
          ];
    return {
      'version': 5,
      'exportedAt': exportedAt,
      'deckCount': decks.length,
      'wordCount': words?.length ?? 0,
      'decks': decks,
      if (includeDeletions) 'deletions': deletions ?? [],
    };
  }

  Map<String, dynamic> makeWord({
    required String chinese,
    String? updatedAt,
    String? createdAt,
    String? sm2UpdatedAt,
    int repetitionN = 0,
  }) {
    return {
      'german': 'Haus',
      'chinese': chinese,
      'proficiency': 0,
      'isFavorite': false,
      'createdAt': createdAt ?? t0,
      'updatedAt': updatedAt ?? t0,
      if (sm2UpdatedAt != null)
        'sm2': {
          'repetitionN': repetitionN,
          'intervalDays': 1.0,
          'easeFactor': 2.5,
          'nextReview': t3,
          'lastReview': sm2UpdatedAt,
          'totalReviews': repetitionN,
          'correctStreak': repetitionN,
          'createdAt': t0,
          'updatedAt': sm2UpdatedAt,
        },
    };
  }

  Map<String, dynamic> makeDeletion({
    String deck = 'A1',
    String german = 'Haus',
    String deletedAt = t2,
  }) {
    return {'deck': deck, 'german': german, 'deletedAt': deletedAt};
  }

  List<Map<String, dynamic>> mergedWords(BackupMergeResult result) {
    final decks = result.mergedBackup['decks'] as List;
    if (decks.isEmpty) return [];
    return (decks.first['words'] as List).cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> mergedDeletions(BackupMergeResult result) {
    return (result.mergedBackup['deletions'] as List)
        .cast<Map<String, dynamic>>();
  }

  group('词级删除传播', () {
    test('对端词在删除后无活动 → 从合并结果剔除，墓碑保留传播', () {
      final local = makeBackup(
        words: const [],
        exportedAt: t15,
        deletions: [makeDeletion()],
      );
      final cloud = makeBackup(
        words: [makeWord(chinese: '房子')],
        exportedAt: t15,
      );

      final result = BackupMerger.merge(
        local: local,
        cloud: cloud,
        lastSyncAt: DateTime.parse(t0),
      );

      expect(mergedWords(result), isEmpty, reason: '无活动的词应被墓碑剔除');
      expect(mergedDeletions(result), hasLength(1),
          reason: '墓碑应保留，继续向其他设备传播');
    });

    test('删除后对端复习（sm2 更新晚于删除）→ 词保留，墓碑作废', () {
      final local = makeBackup(
        words: const [],
        exportedAt: t15,
        deletions: [makeDeletion()],
      );
      final cloud = makeBackup(
        words: [makeWord(chinese: '房子', sm2UpdatedAt: t3, repetitionN: 5)],
        exportedAt: t15,
      );

      final result = BackupMerger.merge(
        local: local,
        cloud: cloud,
        lastSyncAt: DateTime.parse(t0),
      );

      expect(mergedWords(result), hasLength(1),
          reason: '删除后对端仍在复习，词应保留');
      expect(mergedDeletions(result), isEmpty,
          reason: '被驳回的墓碑应作废，不再传播');
    });

    test('删除后对端重建同名词（createdAt 晚于删除）→ 词保留，墓碑作废', () {
      final local = makeBackup(
        words: const [],
        exportedAt: t15,
        deletions: [makeDeletion()],
      );
      final cloud = makeBackup(
        words: [makeWord(chinese: '房子', createdAt: t3)],
        exportedAt: t15,
      );

      final result = BackupMerger.merge(
        local: local,
        cloud: cloud,
        lastSyncAt: DateTime.parse(t0),
      );

      expect(mergedWords(result), hasLength(1),
          reason: '删除后重建的同名词不应被误删');
      expect(mergedDeletions(result), isEmpty);
    });

    test('两端都有同一墓碑 → 合并去重，取删除时间较晚者', () {
      final local = makeBackup(
        words: const [],
        exportedAt: t15,
        deletions: [makeDeletion(deletedAt: t2)],
      );
      final cloud = makeBackup(
        words: const [],
        exportedAt: t15,
        deletions: [makeDeletion(deletedAt: t3)],
      );

      final result = BackupMerger.merge(
        local: local,
        cloud: cloud,
        lastSyncAt: DateTime.parse(t0),
      );

      expect(mergedDeletions(result), hasLength(1));
      expect(mergedDeletions(result).single['deletedAt'], t3);
    });
  });

  group('词书级删除传播', () {
    test('整词书删除后两端无活动 → 整本词书剔除，词书墓碑保留', () {
      final local = makeBackup(
        words: const [],
        exportedAt: t15,
        deletions: [makeDeletion(german: '')],
      );
      final cloud = makeBackup(
        words: [makeWord(chinese: '房子')],
        exportedAt: t15,
      );

      final result = BackupMerger.merge(
        local: local,
        cloud: cloud,
        lastSyncAt: DateTime.parse(t0),
      );

      expect(result.mergedBackup['decks'] as List, isEmpty,
          reason: '无活动的词书应被词书级墓碑整本剔除');
      expect(mergedDeletions(result), hasLength(1));
      expect(mergedDeletions(result).single['german'], '');
    });

    test('词书删除后对端仍有学习活动 → 词书保留，词书墓碑作废', () {
      final local = makeBackup(
        words: const [],
        exportedAt: t15,
        deletions: [makeDeletion(german: '')],
      );
      final cloud = makeBackup(
        words: [makeWord(chinese: '房子', sm2UpdatedAt: t3, repetitionN: 2)],
        exportedAt: t15,
      );

      final result = BackupMerger.merge(
        local: local,
        cloud: cloud,
        lastSyncAt: DateTime.parse(t0),
      );

      expect(result.mergedBackup['decks'] as List, hasLength(1),
          reason: '对端仍在学习该词书，应整本保留');
      expect(mergedDeletions(result), isEmpty);
    });
  });

  group('兼容性', () {
    test('v4 老备份（无 deletions 字段）合并行为不变，输出空墓碑列表', () {
      final local = makeBackup(
        words: [makeWord(chinese: '房子')],
        exportedAt: t15,
        includeDeletions: false,
      );
      final cloud = makeBackup(
        words: [makeWord(chinese: '房子')],
        exportedAt: t15,
        includeDeletions: false,
      );

      final result = BackupMerger.merge(
        local: local,
        cloud: cloud,
        lastSyncAt: DateTime.parse(t0),
      );

      expect(mergedWords(result), hasLength(1));
      expect(mergedDeletions(result), isEmpty);
      expect(result.hasConflicts, isFalse);
    });
  });

  group('数据库集成', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      await db.deckDao.createDeck(DecksCompanion.insert(
        name: 'A1',
        createdAt: DateTime.parse(t0),
        updatedAt: DateTime.parse(t0),
      ));
    });

    tearDown(() async {
      await db.close();
    });

    test('deleteWordWithCleanup 写词级墓碑，deleteDeck 写词书级墓碑', () async {
      final wordId = await db.wordDao.createWord(WordsCompanion.insert(
        deckId: 1,
        german: 'Haus',
        chinese: '房子',
        createdAt: DateTime.parse(t0),
        updatedAt: DateTime.parse(t0),
      ));
      await db.deleteWordWithCleanup(wordId);

      var deletions = await db.getAllDeletions();
      expect(deletions, hasLength(1));
      expect(deletions.single.deckName, 'A1');
      expect(deletions.single.german, 'Haus');

      await db.deckDao.deleteDeck(1);
      deletions = await db.getAllDeletions();
      expect(deletions, hasLength(2));
      final deckTomb = deletions.last;
      expect(deckTomb.deckName, 'A1');
      expect(deckTomb.german, '', reason: '词书级墓碑 german 应为空串');
    });

    test('applyToDatabase 应用 deletions 删除本地词书中的词', () async {
      await db.wordDao.createWord(WordsCompanion.insert(
        deckId: 1,
        german: 'Haus',
        chinese: '房子',
        createdAt: DateTime.parse(t0),
        updatedAt: DateTime.parse(t0),
      ));

      // 云端已剔除该词（decks 无词），合并结果带墓碑
      final merged = makeBackup(
        words: const [],
        exportedAt: t15,
        deletions: [
          {
            'deck': 'A1',
            'german': 'Haus',
            'deletedAt': '2099-01-01T08:00:00.000Z',
          },
        ],
      );

      await BackupMerger.applyToDatabase(db, merged);

      final remaining = await db.wordDao.findWordByGerman(1, 'Haus');
      expect(remaining, isNull, reason: '墓碑命中的本地词应被删除');
      final deck = await db.deckDao.getDeckById(1);
      expect(deck, isNotNull, reason: '词书本身应保留');
    });

    test('applyToDatabase 应用词书级墓碑删除整本词书', () async {
      await db.wordDao.createWord(WordsCompanion.insert(
        deckId: 1,
        german: 'Haus',
        chinese: '房子',
        createdAt: DateTime.parse(t0),
        updatedAt: DateTime.parse(t0),
      ));

      final merged = makeBackup(
        words: const [],
        exportedAt: t15,
        deletions: [
          {'deck': 'A1', 'german': '', 'deletedAt': '2099-01-01T08:00:00.000Z'},
        ],
      );

      await BackupMerger.applyToDatabase(db, merged);

      final deck = await db.deckDao.getDeckById(1);
      expect(deck, isNull, reason: '词书级墓碑应删除整本词书');
      final words = await db.wordDao.getWordsByDeck(1);
      expect(words, isEmpty);
    });
  });
}
