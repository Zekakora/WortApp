import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/services/sync/onedrive_sync_service.dart';

/// 同步载荷压缩兼容性：云端备份可能是 gzip 压缩的新格式，
/// 也可能是旧版本上传的未压缩 JSON，两者都必须能正常解析。
void main() {
  group('OneDrive 同步载荷兼容', () {
    Uint8List plainBytes(Map<String, dynamic> obj) =>
        Uint8List.fromList(utf8.encode(jsonEncode(obj)));
    Uint8List gzipBytes(Map<String, dynamic> obj) =>
        Uint8List.fromList(gzip.encode(utf8.encode(jsonEncode(obj))));

    test('parseExportedAt 同时支持未压缩与 gzip 压缩载荷', () {
      final obj = {'exportedAt': '2026-01-02T03:04:05.000'};
      final gz = gzipBytes(obj);
      expect(gz[0], 0x1f, reason: 'gzip 魔数首字节');
      expect(gz[1], 0x8b, reason: 'gzip 魔数次字节');

      for (final bytes in [plainBytes(obj), gz]) {
        expect(
          OneDriveSyncResult.parseExportedAt(bytes)?.toIso8601String(),
          '2026-01-02T03:04:05.000',
        );
      }
    });

    test('parseCloudInfo 同时支持未压缩与 gzip 压缩载荷', () {
      final obj = {
        'exportedAt': '2026-01-02T03:04:05.000',
        'deckCount': 3,
        'wordCount': 42,
      };
      for (final bytes in [plainBytes(obj), gzipBytes(obj)]) {
        final info = OneDriveSyncService.parseCloudInfo(bytes);
        expect(info, isNotNull);
        expect(info!.deckCount, 3);
        expect(info.wordCount, 42);
        expect(info.exportedAt, DateTime(2026, 1, 2, 3, 4, 5));
      }
    });

    test('空/损坏字节返回 null 而非抛异常', () {
      expect(OneDriveSyncResult.parseExportedAt(Uint8List(0)), isNull);
      expect(OneDriveSyncService.parseCloudInfo(Uint8List(0)), isNull);
    });
  });
}
