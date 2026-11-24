import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/services/sync/backup_merger.dart';

/// 同步优化：合并阶段标记「与本地一致、无需写库」的单词，
/// applyToDatabase 据此跳过写入，避免每次同步全量重写单词。
void main() {
  Map<String, dynamic> word(
    String german,
    String chinese, {
    String updatedAt = '2026-01-01T00:00:00.000Z',
  }) =>
      {
        'german': german,
        'chinese': chinese,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': updatedAt,
        'stats': <Object>[],
        'sm2': null,
        'conjugation': null,
      };

  Map<String, dynamic> cache(
    String word,
    String resultJson, {
    String updatedAt = '2026-01-01T00:00:00.000Z',
  }) =>
      {
        'word': word,
        'resultJson': resultJson,
        'engine': 'ai',
        'createdAt': '2026-01-01T00:00:00.000Z',
        'updatedAt': updatedAt,
      };

  Map<String, dynamic> backup(
    List<Map<String, dynamic>> words, {
    List<Map<String, dynamic>> aiCache = const [],
    String exportedAt = '2026-01-01T00:00:00.000Z',
  }) =>
      {
        'version': 5,
        'exportedAt': exportedAt,
        'decks': [
          {
            'name': 'D',
            'description': '',
            'isActive': true,
            'createdAt': '2026-01-01T00:00:00.000Z',
            'updatedAt': '2026-01-01T00:00:00.000Z',
            'words': words,
          },
        ],
        'aiCache': aiCache,
        'settings': <Object>[],
        'deletions': <Object>[],
      };

  test('本地与云端完全一致时，全部单词标记为无需写库', () {
    final local = backup([word('Hund', '狗'), word('Katze', '猫')]);
    final cloud = backup([word('Hund', '狗'), word('Katze', '猫')]);

    final res = BackupMerger.merge(local: local, cloud: cloud);

    expect(res.conflicts, isEmpty);
    expect(res.wordsUpdated, 0);
    expect(res.unchangedWordKeys, hasLength(2));
    expect(res.unchangedWordKeys, containsAll(['d|hund', 'd|katze']));
  });

  test('内容变化的单词不进入跳过集合，其余仍跳过', () {
    final local = backup([word('Hund', '狗'), word('Katze', '猫')]);
    final cloud = backup(
      [word('Hund', '犬', updatedAt: '2026-02-01T00:00:00.000Z'), word('Katze', '猫')],
      exportedAt: '2026-02-01T00:00:00.000Z',
    );

    final res = BackupMerger.merge(local: local, cloud: cloud);

    expect(res.unchangedWordKeys, contains('d|katze'));
    expect(res.unchangedWordKeys, isNot(contains('d|hund')));
  });

  test('applyToDatabase 携带跳过集合时结果依然正确（单词 + AI 缓存）', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final cached = [cache('Hund', '{"definitions":["狗"]}')];

    // 首次：云端有词与缓存、本地空 → 全部写入
    final first = BackupMerger.merge(
      local: backup(<Map<String, dynamic>>[]),
      cloud: backup([word('Hund', '狗')], aiCache: cached),
    );
    await BackupMerger.applyToDatabase(
      db,
      first.mergedBackup,
      unchangedWordKeys: first.unchangedWordKeys,
      unchangedAiCacheKeys: first.unchangedAiCacheKeys,
    );
    expect(await db.aiCacheDao.getCachedResult('Hund'), isNotNull);

    // 再次同步：两端一致 → 全部跳过，但数据完好
    final second = BackupMerger.merge(
      local: backup([word('Hund', '狗')], aiCache: cached),
      cloud: backup([word('Hund', '狗')], aiCache: cached),
    );
    expect(second.unchangedWordKeys, contains('d|hund'));
    expect(second.unchangedAiCacheKeys, contains('Hund|ai'));
    await BackupMerger.applyToDatabase(
      db,
      second.mergedBackup,
      unchangedWordKeys: second.unchangedWordKeys,
      unchangedAiCacheKeys: second.unchangedAiCacheKeys,
    );

    final words = await db.wordDao.getWordsByDeck(1);
    expect(words, hasLength(1));
    expect(words.single.german, 'Hund');
    expect(words.single.chinese, '狗');
    expect(await db.aiCacheDao.getCachedResult('Hund'), isNotNull);
  });

  test('AI 缓存内容变化时不进入跳过集合', () {
    final local = backup(
      [word('Hund', '狗')],
      aiCache: [cache('Hund', '{"definitions":["狗"]}')],
    );
    final cloud = backup(
      [word('Hund', '狗')],
      aiCache: [
        cache('Hund', '{"definitions":["犬"]}',
            updatedAt: '2026-02-01T00:00:00.000Z'),
      ],
      exportedAt: '2026-02-01T00:00:00.000Z',
    );

    final res = BackupMerger.merge(local: local, cloud: cloud);

    expect(res.unchangedAiCacheKeys, isNot(contains('Hund|ai')));
  });
}
