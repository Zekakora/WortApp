import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../data/database/app_database.dart';

/// 数据库初始化状态
class DatabaseState {
  final AppDatabase? database;
  final bool isLoading;
  final String? error;

  const DatabaseState({
    this.database,
    this.isLoading = true,
    this.error,
  });

  static const _sentinel = Object();

  DatabaseState copyWith({
    Object? database = _sentinel,
    bool? isLoading,
    String? error,
  }) {
    return DatabaseState(
      database: database == _sentinel ? this.database : database as AppDatabase?,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 数据库 StateNotifier
class DatabaseNotifier extends StateNotifier<DatabaseState> {
  DatabaseNotifier() : super(const DatabaseState()) {
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    AppDatabase? database;
    try {
      debugPrint('Starting database initialization...');
      database = AppDatabase();

      // 等待数据库就绪，添加超时
      await database.customSelect('SELECT 1').getSingle().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('数据库初始化超时');
        },
      );

      debugPrint('Database initialized successfully');
      if (mounted) {
        state = DatabaseState(
          database: database,
          isLoading: false,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Database initialization failed: $e');
      debugPrint('Stack trace: $stackTrace');
      // 失败时释放本次创建的数据库实例，避免每次重试泄漏连接
      try {
        await database?.close();
      } catch (_) {}
      if (mounted) {
        state = DatabaseState(
          isLoading: false,
          error: '数据库初始化失败: $e',
        );
      }
    }
  }

  /// 重新初始化数据库（供初始化失败页的「重试」按钮调用）
  Future<void> retry() async {
    if (state.isLoading) return;
    state = const DatabaseState(isLoading: true);
    await _initDatabase();
  }

  @override
  void dispose() {
    state.database?.close();
    super.dispose();
  }
}

/// 数据库 Provider
final databaseStateProvider =
    StateNotifierProvider<DatabaseNotifier, DatabaseState>((ref) {
  return DatabaseNotifier();
});

/// 数据库实例 Provider (便捷访问)
final databaseProvider = Provider<AppDatabase?>((ref) {
  final dbState = ref.watch(databaseStateProvider);
  return dbState.database;
});
