import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:flutter/foundation.dart';

/// Web 平台数据库实现
DatabaseConnection openConnection() {
  debugPrint('Initializing web database...');

  return DatabaseConnection.delayed(Future(() async {
    try {
      final result = await WasmDatabase.open(
        databaseName: 'wortapp_db',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );

      // 诊断信息：确认当前浏览器实际使用的存储实现。
      // 若为 inMemory（内存模式），数据不会持久化，刷新/重启后全部丢失！
      debugPrint('Web database initialized successfully, '
          'storage: ${result.chosenImplementation}, '
          'missing features: ${result.missingFeatures}');
      return result.resolvedExecutor;
    } catch (e) {
      debugPrint('Web database initialization failed: $e');
      rethrow;
    }
  }));
}
