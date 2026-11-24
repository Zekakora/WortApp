import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/services/import_export/export_service.dart';
import 'package:wortapp/services/sync/backup_merger.dart';

/// 复现并修复：批量 AI 规范化德语（改名）与词书内去重（删重复）后同步，
/// 云端旧词形/重复条不应被"并回来"。
void main() {
  Future<Map<String, dynamic>> exportJson(AppDatabase db) async {
    final r = await ExportService(db).exportBackup(fileName: 'x.json');
    return jsonDecode(utf8.decode(r.data!.bytes)) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> syncOnce(
    AppDatabase db,
    Map<String, dynamic> cloud,
  ) async {
    final local = await exportJson(db);
    final outcome = BackupMerger.merge(local: local, cloud: cloud);
    await BackupMerger.applyToDatabase(
      db,
      outcome.mergedBackup,
      unchangedWordKeys: outcome.unchangedWordKeys,
      unchangedAiCacheKeys: outcome.unchangedAiCacheKeys,
    );
    await db.replaceAllDeletions(
      (outcome.mergedBackup['deletions'] as List).cast<Map<String, dynamic>>(),
    );
    return outcome.mergedBackup;
  }

  List<String> germansOf(Map<String, dynamic> backup) {
    final decks = backup['decks'] as List;
    if (decks.isEmpty) return const [];
    return (decks.first['words'] as List)
        .map((w) => (w as Map<String, dynamic>)['german'] as String)
        .toList();
  }

  Future<AppDatabase> makeDb(List<String> germans) async {
    final db = AppDatabase(NativeDatabase.memory());
    final t0 = DateTime(2026, 1, 1);
    await db.deckDao.createDeck(DecksCompanion.insert(
      name: 'A1',
      createdAt: t0,
      updatedAt: t0,
    ));
    for (final g in germans) {
      await db.wordDao.createWord(WordsCompanion.insert(
        deckId: 1,
        german: g,
        chinese: '释义',
        createdAt: t0,
        updatedAt: t0,
      ));
    }
    return db;
  }

  test('AI 规范化改名后同步：旧词形不应被并回来', () async {
    final db = await makeDb(['Hunde']);
    addTearDown(db.close);

    // 云端 = 规范化前的状态（含旧词形 Hunde）
    var cloud = await exportJson(db);

    // 本地执行"AI 规范化"：Hunde -> Hund（写旧词形墓碑）
    final id = (await db.wordDao.findWordByGerman(1, 'Hunde'))!.id;
    await db.renameWordGerman(id, 'Hund');

    cloud = await syncOnce(db, cloud);

    final local = await db.wordDao.getWordsByDeck(1);
    expect(local.map((w) => w.german), ['Hund']);
    expect(germansOf(cloud), ['Hund'],
        reason: '云端旧词形 Hunde 应被墓碑剔除，不能并回来');
    // 墓碑保留以继续传播
    expect((cloud['deletions'] as List), hasLength(1));
  });

  test('词书内去重后同步：被删重复条不应被并回来', () async {
    final db = await makeDb(['der Hund', 'Hund']);
    addTearDown(db.close);

    var cloud = await exportJson(db); // 含重复的两条

    // 规范化去重：保留 der Hund，删除 Hund（写墓碑）
    final keepId = (await db.wordDao.findWordByGerman(1, 'der Hund'))!.id;
    final dupId = (await db.wordDao.findWordByGerman(1, 'Hund'))!.id;
    final removed = await db.mergeDuplicateGroup(
      keepWordId: keepId,
      removeWordIds: [dupId],
    );
    expect(removed, [dupId]);
    expect((await db.getAllDeletions()).single.german, 'Hund');

    cloud = await syncOnce(db, cloud);

    expect(germansOf(cloud), ['der Hund'],
        reason: '被删的重复条 Hund 不应被并回来');
  });

  test('精确同名词去重后同步：保留词不应被自己的墓碑误删', () async {
    final db = await makeDb(['Hund', 'Hund']); // 两条完全相同的同名词
    addTearDown(db.close);

    var cloud = await exportJson(db);

    final ids = (await db.wordDao.getWordsByDeck(1)).map((w) => w.id).toList();
    await db.mergeDuplicateGroup(
      keepWordId: ids.first,
      removeWordIds: [ids.last],
    );

    // 拼写（忽略大小写）相同 → 不写墓碑（否则会连保留词一起删）
    expect(await db.getAllDeletions(), isEmpty);

    cloud = await syncOnce(db, cloud);

    expect((await db.wordDao.getWordsByDeck(1)).map((w) => w.german), ['Hund']);
    expect(germansOf(cloud), ['Hund'], reason: '保留词不应被误删');
  });
}
