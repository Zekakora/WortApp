import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/services/sync/onedrive_sync_service.dart';

void main() {
  group('archiveFileNameFor', () {
    test('生成 wortapp-backup-<时间戳>-<设备名>.json 格式', () {
      final name = OneDriveSyncService.archiveFileNameFor(
        DateTime.utc(2026, 8, 6, 18, 30, 5),
        'DESKTOP-ABC',
      );
      expect(name, 'wortapp-backup-20260806-183005-DESKTOP-ABC.json');
    });

    test('月/日/时/分/秒补零', () {
      final name = OneDriveSyncService.archiveFileNameFor(
        DateTime.utc(2026, 1, 2, 3, 4, 5),
        'pc',
      );
      expect(name, 'wortapp-backup-20260102-030405-pc.json');
    });

    test('设备名安全清洗：空格/斜杠替换为下划线，中文保留', () {
      final name = OneDriveSyncService.archiveFileNameFor(
        DateTime.utc(2026, 8, 6),
        'My PC / 台式机:测试!',
      );
      expect(name, 'wortapp-backup-20260806-000000-My_PC_台式机_测试.json');
    });

    test('设备名超长截断到 30 字符', () {
      final name = OneDriveSyncService.archiveFileNameFor(
        DateTime.utc(2026, 8, 6),
        'a' * 50,
      );
      // 前缀+时间戳+分隔符 + 30 字符 + .json
      expect(name, 'wortapp-backup-20260806-000000-${'a' * 30}.json');
    });

    test('设备名清洗后为空时回退 device', () {
      final name = OneDriveSyncService.archiveFileNameFor(
        DateTime.utc(2026, 8, 6),
        '///',
      );
      expect(name, 'wortapp-backup-20260806-000000-device.json');
    });
  });

  group('parseArchiveStamp', () {
    test('正确解析归档文件名时间戳（UTC）', () {
      final t = OneDriveSyncService.parseArchiveStamp(
        'wortapp-backup-20260806-183005-DESKTOP.json',
      );
      expect(t, DateTime.utc(2026, 8, 6, 18, 30, 5));
    });

    test('与 archiveFileNameFor 回环一致（UTC 基准）', () {
      final t = DateTime.utc(2026, 12, 31, 23, 59, 59);
      final name = OneDriveSyncService.archiveFileNameFor(t, 'pc');
      expect(OneDriveSyncService.parseArchiveStamp(name), t);
    });

    test('本地时间转 UTC 后生成与解析一致', () {
      final t = DateTime(2026, 7, 1, 12, 0, 0); // 任意时区的本地时间
      final name = OneDriveSyncService.archiveFileNameFor(t, 'pc');
      expect(OneDriveSyncService.parseArchiveStamp(name), t.toUtc());
    });

    test('主备份文件与非归档文件返回 null', () {
      expect(
        OneDriveSyncService.parseArchiveStamp('wortapp-backup.json'),
        isNull,
      );
      expect(
        OneDriveSyncService.parseArchiveStamp('notes.txt'),
        isNull,
      );
    });

    test('无设备名后缀或格式错误返回 null', () {
      expect(
        OneDriveSyncService.parseArchiveStamp('wortapp-backup-20260806.json'),
        isNull,
      );
      expect(
        OneDriveSyncService.parseArchiveStamp('wortapp-backup-20260806-1830-pc.json'),
        isNull,
      );
    });
  });

  group('pickArchivesToDelete', () {
    List<String> archiveNames(int count) {
      return List.generate(
        count,
        (i) => OneDriveSyncService.archiveFileNameFor(
          DateTime.utc(2026, 1, 1).add(Duration(minutes: i)),
          'pc',
        ),
      );
    }

    test('不超过上限不删除', () {
      final names = [
        ...archiveNames(5),
        'wortapp-backup.json',
        'notes.txt',
      ];
      expect(OneDriveSyncService.pickArchivesToDelete(names, 10), isEmpty);
    });

    test('正好 10 个不删除', () {
      final names = archiveNames(10);
      expect(OneDriveSyncService.pickArchivesToDelete(names, 10), isEmpty);
    });

    test('11 个时删除最旧的 1 个', () {
      final names = archiveNames(11);
      final toDelete = OneDriveSyncService.pickArchivesToDelete(names, 10);
      expect(toDelete.length, 1);
      expect(toDelete.single, names.first);
    });

    test('13 个时删除最旧的 3 个', () {
      final names = archiveNames(13);
      final toDelete = OneDriveSyncService.pickArchivesToDelete(names, 10);
      expect(toDelete.length, 3);
      expect(toDelete, names.take(3).toList());
    });

    test('非归档文件不影响计数与排序', () {
      final old = archiveNames(3);
      final names = [
        ...old,
        'notes.txt',
        'wortapp-backup.json',
        ...archiveNames(8),
      ];
      final toDelete = OneDriveSyncService.pickArchivesToDelete(names, 10);
      expect(toDelete.length, 1);
      expect(toDelete.single, old.first);
    });

    test('maxKeep 参数生效', () {
      final names = archiveNames(6);
      final toDelete = OneDriveSyncService.pickArchivesToDelete(names, 3);
      expect(toDelete.length, 3);
      expect(toDelete, names.take(3).toList());
    });
  });
}
