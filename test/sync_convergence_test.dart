import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/services/import_export/export_service.dart';
import 'package:wortapp/services/import_export/import_service.dart';
import 'package:wortapp/services/sync/backup_merger.dart';

/// 回归：同步必须"收敛"——第一次同步后，后续同步不应再报告新增/更新
/// （否则界面会一直提示"新词 1 个 / 更新 3 个"）。
///
/// 根因是 upload 前直接上传内存合并结果，而 applyToDatabase 会规范化字段
/// （去空白、保留本地词形拼写），云端与本地库产生细微差异，永不收敛。
void main() {
  test('同步收敛：第二次起不再有新增/更新', () async {
    final bytes =
        Uint8List.fromList(await File('WortApp备份_20261011.json').readAsBytes());
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    await ImportService(db).importBackup(
        fileBytes: bytes, fileName: 'x.json', wipeExisting: true);

    Map<String, dynamic> decode(Uint8List b) =>
        jsonDecode(utf8.decode(b)) as Map<String, dynamic>;

    var cloud = decode(bytes);

    Future<BackupMergeResult> sync() async {
      final local = decode((await ExportService(db).exportBackup()).data!.bytes);
      final outcome = BackupMerger.merge(local: local, cloud: cloud);
      await BackupMerger.applyToDatabase(
        db,
        outcome.mergedBackup,
        unchangedWordKeys: outcome.unchangedWordKeys,
        unchangedAiCacheKeys: outcome.unchangedAiCacheKeys,
      );
      await db.replaceAllDeletions(
        (outcome.mergedBackup['deletions'] as List)
            .cast<Map<String, dynamic>>(),
      );
      // 修复点：上传前从本地库重新导出，使「云端 == 本地库」
      cloud = decode((await ExportService(db).exportBackup()).data!.bytes);
      return outcome;
    }

    final first = await sync();
    expect(first.wordsAdded, anyOf(0, 1, 2)); // 首次可能有少量差异

    final second = await sync();
    final third = await sync();

    expect(second.wordsAdded, 0, reason: '第二次不应再报告新词');
    expect(second.wordsUpdated, 0, reason: '第二次不应再报告更新');
    expect(third.wordsAdded, 0);
    expect(third.wordsUpdated, 0);
  }, timeout: const Timeout(Duration(minutes: 10)));
}
