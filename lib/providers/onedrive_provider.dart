import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/i18n/app_localizations.dart';
import '../data/database/app_database.dart';
import '../services/sync/backup_merger.dart';
import '../services/sync/onedrive_sync_service.dart';
import 'database_provider.dart';

/// OneDrive 同步状态
class OneDriveSyncState {
  /// 是否已登录 OneDrive
  final bool isConnected;

  /// 是否有同步操作进行中
  final bool isBusy;

  /// 上次成功同步的备份时间
  final DateTime? lastSyncAt;

  /// 最近一次错误信息
  final String? error;

  const OneDriveSyncState({
    this.isConnected = false,
    this.isBusy = false,
    this.lastSyncAt,
    this.error,
  });

  OneDriveSyncState copyWith({
    bool? isConnected,
    bool? isBusy,
    DateTime? lastSyncAt,
    String? error,
    bool clearError = false,
  }) {
    return OneDriveSyncState(
      isConnected: isConnected ?? this.isConnected,
      isBusy: isBusy ?? this.isBusy,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// OneDrive 同步状态管理
class OneDriveSyncNotifier extends StateNotifier<OneDriveSyncState> {
  final AppDatabase? _db;
  OneDriveSyncService? _service;
  bool _initialized = false;

  OneDriveSyncNotifier(this._db) : super(const OneDriveSyncState()) {
    _init();
  }

  Future<void> _init() async {
    final db = _db;
    if (db == null || _initialized) return;
    _initialized = true;
    final service = OneDriveSyncService(db);
    _service = service;

    try {
      final connected = await service.isConnected();
      final lastSyncAt = await service.getLastSyncAt();
      state = state.copyWith(
        isConnected: connected,
        lastSyncAt: lastSyncAt,
      );
    } catch (e) {
      debugPrint('OneDrive init failed: $e');
    }
  }

  /// 登录 OneDrive（应用内 WebView 授权）
  Future<bool> connect(BuildContext context) async {
    final service = _service;
    if (service == null) return false;

    state = state.copyWith(isBusy: true, clearError: true);
    bool ok = false;
    try {
      ok = await service.connect(context);
    } catch (e) {
      debugPrint('OneDrive 登录异常: $e');
      ok = false;
    }
    state = state.copyWith(
      isBusy: false,
      isConnected: ok,
      error: ok ? null : AppLocale.tr('登录失败或已取消'),
    );
    return ok;
  }

  /// 退出登录
  Future<void> disconnect() async {
    state = state.copyWith(isBusy: true);
    try {
      await _service?.disconnect();
      state = state.copyWith(isBusy: false, isConnected: false);
    } catch (e) {
      state = state.copyWith(
        isBusy: false,
        error: AppLocale.trArgs('退出登录失败: {0}', [e]),
      );
    }
  }

  /// 上传本地备份到 OneDrive
  Future<OneDriveSyncResult> uploadBackup({bool force = false}) async {
    final service = _service;
    if (service == null) {
      return OneDriveSyncResult(error: AppLocale.tr('服务未初始化'));
    }

    state = state.copyWith(isBusy: true, clearError: true);
    OneDriveSyncResult result;
    try {
      result = await service.uploadBackup(force: force);
    } catch (e) {
      debugPrint('OneDrive 上传异常: $e');
      state = state.copyWith(
        isBusy: false,
        error: AppLocale.trArgs('上传失败: {0}', [e]),
      );
      return OneDriveSyncResult(error: AppLocale.trArgs('上传失败: {0}', [e]));
    }
    state = state.copyWith(
      isBusy: false,
      error: result.success ? null : result.error,
    );
    if (result.success) {
      final lastSyncAt = await service.getLastSyncAt();
      state = state.copyWith(lastSyncAt: lastSyncAt);
    }
    return result;
  }

  /// 差异同步：合并本地与云端备份（静默执行）
  ///
  /// 检测到真冲突且未指定方向时返回带 [OneDriveSyncResult.conflicts]
  /// 的结果（不写库不上传），由 UI 弹窗选择方向后带 [resolution] 重试。
  Future<OneDriveSyncResult> syncNow({
    ConflictResolution? resolution,
  }) async {
    final service = _service;
    if (service == null) {
      return OneDriveSyncResult(error: AppLocale.tr('服务未初始化'));
    }

    state = state.copyWith(isBusy: true, clearError: true);
    OneDriveSyncResult result;
    try {
      result = await service.syncNow(resolution: resolution);
    } catch (e) {
      debugPrint('OneDrive 同步异常: $e');
      state = state.copyWith(
        isBusy: false,
        error: AppLocale.trArgs('同步失败: {0}', [e]),
      );
      return OneDriveSyncResult(error: AppLocale.trArgs('同步失败: {0}', [e]));
    }
    state = state.copyWith(
      isBusy: false,
      error: result.success ? null : result.error,
    );
    if (result.success) {
      final lastSyncAt = await service.getLastSyncAt();
      state = state.copyWith(lastSyncAt: lastSyncAt);
    }
    return result;
  }

  /// 从 OneDrive 下载并恢复
  Future<OneDriveSyncResult> downloadBackup({
    bool wipeExisting = true,
  }) async {
    final service = _service;
    if (service == null) {
      return OneDriveSyncResult(error: AppLocale.tr('服务未初始化'));
    }

    state = state.copyWith(isBusy: true, clearError: true);
    OneDriveSyncResult result;
    try {
      result = await service.downloadBackup(wipeExisting: wipeExisting);
    } catch (e) {
      debugPrint('OneDrive 下载异常: $e');
      state = state.copyWith(
        isBusy: false,
        error: AppLocale.trArgs('下载恢复失败: {0}', [e]),
      );
      return OneDriveSyncResult(
        error: AppLocale.trArgs('下载恢复失败: {0}', [e]),
      );
    }
    state = state.copyWith(
      isBusy: false,
      error: result.success ? null : result.error,
    );
    if (result.exportedAt != null) {
      state = state.copyWith(lastSyncAt: result.exportedAt);
    }
    return result;
  }

  /// 拉取云端备份信息（用于展示/确认）
  Future<CloudBackupInfo?> fetchCloudBackup() async {
    try {
      return await _service?.fetchCloudBackup();
    } catch (e) {
      debugPrint('fetchCloudBackup failed: $e');
      return null;
    }
  }
}

/// OneDrive 同步 Provider
final onedriveSyncProvider =
    StateNotifierProvider<OneDriveSyncNotifier, OneDriveSyncState>((ref) {
  final db = ref.watch(databaseProvider);
  return OneDriveSyncNotifier(db);
});
