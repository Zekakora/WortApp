import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/services/sync/backup_merger.dart';

/// 合并边界修复测试：
/// - 词书名不区分大小写合并（A1 / a1 视为同一词书）
/// - wordsUpdated 只统计真正变化的词
/// - applyToDatabase 激活词书兜底对本次新建的词书生效
void main() {
  const t0 = '2026-01-01T08:00:00.000Z';

  Map<String, dynamic> makeBackup({
    required String deckName,
    required List<Map<String, dynamic>> words,
    bool isActive = false,
    String? exportedAt,
  }) {
    return {
      'version': 5,
      'exportedAt': exportedAt ?? t0,
      'decks': [
        {
          'name': deckName,
          'description': '',
          'isActive': isActive,
          'createdAt': t0,
          'updatedAt': t0,
          'words': words,
        },
      ],
      'aiCache': <Object>[],
      'aiStatus': <Object>[],
      'settings': <Object>[],
      'deletions': <Object>[],
    };
  }

  Map<String, dynamic> makeWord(String chinese, {String? updatedAt}) {
    return {
      'german': 'Haus',
      'chinese': chinese,
      'article': 'das',
      'createdAt': t0,
      'updatedAt': updatedAt ?? t0,
    };
  }

  group('词书名大小写不敏感', () {
    test('本地 A1 与云端 a1 合并为一本词书', () {
      final local =
          makeBackup(deckName: 'A1', words: [makeWord('房子')]);
      final cloud =
          makeBackup(deckName: 'a1', words: [makeWord('房子')]);

      final result = BackupMerger.merge(
        local: local,
        cloud: cloud,
        lastSyncAt: DateTime.parse(t0),
      );

      expect(result.hasConflicts, isFalse);
      final decks = result.mergedBackup['decks'] as List;
      expect(decks, hasLength(1),
          reason: '两端词书名仅大小写不同应合并为同一词书，而非并出两本');
    });
  });

  group('wordsUpdated 只统计真实变化', () {
    test('两端单词完全一致 → wordsUpdated 为 0', () {
      final result = BackupMerger.merge(
        local: makeBackup(deckName: 'A1', words: [makeWord('房子')]),
        cloud: makeBackup(deckName: 'A1', words: [makeWord('房子')]),
        lastSyncAt: DateTime.parse(t0),
      );
      expect(result.wordsUpdated, 0,
          reason: '一致的词不应计为“更新”');
    });

    test('一端编辑过词义 → wordsUpdated 为 1', () {
      final result = BackupMerger.merge(
        local: makeBackup(deckName: 'A1', words: [makeWord('房子')]),
        cloud: makeBackup(
          deckName: 'A1',
          words: [makeWord('房子（修订）', updatedAt: '2026-01-02T08:00:00.000Z')],
          exportedAt: '2026-01-03T08:00:00.000Z',
        ),
        lastSyncAt: DateTime.parse(t0),
      );
      expect(result.wordsUpdated, 1,
          reason: '云端编辑过的词被并入本地，应计为“更新”');
    });
  });

  group('applyToDatabase 激活词书兜底', () {
    test('合并结果中的激活词书为本次新建 → 应用后成为唯一激活词书', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      // 本地已有一本激活词书
      final oldDeckId = await db.deckDao.createDeck(DecksCompanion.insert(
        name: '旧词书',
        isActive: const drift.Value(true),
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      ));
      expect((await db.deckDao.getActiveDeck())?.id, oldDeckId);

      // 合并结果：新词书（本地不存在）且标记为激活
      final merged = makeBackup(
        deckName: '新词书',
        isActive: true,
        words: [makeWord('房子')],
      );

      await BackupMerger.applyToDatabase(db, merged);

      final active = await db.deckDao.getActiveDeck();
      expect(active, isNotNull);
      expect(active!.name, '新词书',
          reason: '本次新建的激活词书应被设为唯一激活词书');

      // 新建词书中的单词也成功写入
      final words = await db.wordDao.getWordsByDeck(active.id);
      expect(words, hasLength(1));
      expect(words.first.german, 'Haus');
    });
  });
}
