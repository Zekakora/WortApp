import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/services/import_export/export_service.dart';
import 'package:wortapp/services/sync/backup_merger.dart';

/// 端到端复现：本地删除单词后连续多次同步，单词不应被"复活"。
void main() {
  Future<Map<String, dynamic>> exportJson(AppDatabase db) async {
    final r = await ExportService(db).exportBackup(fileName: 'x.json');
    return jsonDecode(utf8.decode(r.data!.bytes)) as Map<String, dynamic>;
  }

  /// 模拟 OneDriveSyncService.syncNow 的本地部分（导出→合并→写库→对齐墓碑）
  Future<Map<String, dynamic>> syncOnce(
    AppDatabase db,
    Map<String, dynamic> cloud,
  ) async {
    final local = await exportJson(db);
    final lastSyncAtRaw = await db.getSetting('onedrive_lastSyncAt');
    final lastSyncAt =
        lastSyncAtRaw == null ? null : DateTime.tryParse(lastSyncAtRaw);
    final outcome = BackupMerger.merge(
      local: local,
      cloud: cloud,
      lastSyncAt: lastSyncAt,
    );
    await BackupMerger.applyToDatabase(db, outcome.mergedBackup);
    await db.replaceAllDeletions(
      (outcome.mergedBackup['deletions'] as List).cast<Map<String, dynamic>>(),
    );
    await db.setSetting(
        'onedrive_lastSyncAt', DateTime.now().toIso8601String());
    return outcome.mergedBackup;
  }

  test('删除的单词在多次同步后不应复活', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final t0 = DateTime(2026, 1, 1);
    await db.deckDao.createDeck(DecksCompanion.insert(
      name: 'A1',
      createdAt: t0,
      updatedAt: t0,
    ));
    await db.wordDao.createWord(WordsCompanion.insert(
      deckId: 1,
      german: 'Haus',
      chinese: '房子',
      createdAt: t0,
      updatedAt: t0,
    ));

    // 云端 = 删除前的状态
    var cloud = await exportJson(db);

    // 本地删除（写入墓碑）
    final wordId = (await db.wordDao.findWordByGerman(1, 'Haus'))!.id;
    await db.deleteWordWithCleanup(wordId);
    expect(await db.wordDao.findWordByGerman(1, 'Haus'), isNull);
    expect((await db.getAllDeletions()), hasLength(1));

    // 连续同步 4 次
    for (var i = 0; i < 4; i++) {
      cloud = await syncOnce(db, cloud);
      final back = await db.wordDao.findWordByGerman(1, 'Haus');
      expect(back, isNull, reason: '第 ${i + 1} 次同步后单词又复活了');
    }
    expect((await db.getAllDeletions()), hasLength(1),
        reason: '墓碑应一直保留用于传播');
  });
}
