import 'dart:convert';
import 'dart:io' show Platform, gzip;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_onedrive/flutter_onedrive.dart';
import '../../core/constants/onedrive_config.dart';
import '../../core/i18n/app_localizations.dart';
import '../../data/database/app_database.dart';
import '../import_export/export_service.dart';
import '../import_export/import_service.dart';
import 'backup_merger.dart';

/// 云端备份信息（从备份 JSON 解析）
class CloudBackupInfo {
  /// 备份生成时间
  final DateTime exportedAt;

  /// 备份中的词书数
  final int deckCount;

  /// 备份中的单词数
  final int wordCount;

  const CloudBackupInfo({
    required this.exportedAt,
    required this.deckCount,
    required this.wordCount,
  });
}

/// OneDrive 同步操作结果
class OneDriveSyncResult {
  final bool success;

  /// 错误信息（成功时为 null）
  final String? error;

  /// 本次同步涉及的备份时间
  final DateTime? exportedAt;

  /// 云端存在更新的备份（需要用户确认后强制覆盖）
  final bool cloudHasNewer;

  /// 云端备份信息（[cloudHasNewer] 时非空）
  final CloudBackupInfo? cloudInfo;

  /// 下载恢复的结果统计
  final int? deckCount;
  final int? wordCount;
  final int? skipCount;

  /// 差异同步检测到的数据冲突（需要用户选择方向后重试）
  final List<SyncConflict> conflicts;

  /// 差异同步的合并统计
  final int decksAdded;
  final int decksUpdated;
  final int wordsAdded;
  final int wordsUpdated;

  const OneDriveSyncResult({
    this.success = false,
    this.error,
    this.exportedAt,
    this.cloudHasNewer = false,
    this.cloudInfo,
    this.deckCount,
    this.wordCount,
    this.skipCount,
    this.conflicts = const [],
    this.decksAdded = 0,
    this.decksUpdated = 0,
    this.wordsAdded = 0,
    this.wordsUpdated = 0,
  });

  /// 解析云端备份时间戳
  static DateTime? parseExportedAt(Uint8List bytes) {
    try {
      final json =
          jsonDecode(utf8.decode(OneDriveSyncService._decompressIfNeeded(bytes)))
              as Map<String, dynamic>;
      final raw = json['exportedAt'];
      if (raw == null) return null;
      return DateTime.tryParse(raw.toString());
    } catch (_) {
      return null;
    }
  }
}

/// OneDrive 云同步服务
///
/// 以现有「备份 JSON v5」为同步载体，文件存放在用户 OneDrive 的
/// App 专用文件夹（Apps/WortApp，由 Microsoft Graph 自动创建），
/// 应用无法访问用户的其他文件。
///
/// 历史归档：每次备份前将云端当前备份归档为
/// `wortapp-backup-<上次同步时间戳>-<设备名>.json`，
/// 云端最多保留最近 [maxHistoryCount] 次归档，超出自动删除最旧的。
///
/// 冲突策略（防误覆盖）：
/// - 上传前先拉取云端备份，若云端 `exportedAt` 比本次导出的时间新，
///   返回 [OneDriveSyncResult.cloudHasNewer]，由调用方确认后强制覆盖。
/// - 下载是整体覆盖恢复操作，调用方需弹窗二次确认。
class OneDriveSyncService {
  /// 云端备份文件名（App 专用文件夹根目录）
  static const String remoteFileName = 'wortapp-backup.json';

  /// 历史归档文件名前缀：`wortapp-backup-<时间戳>-<设备名>.json`
  static const String archivePrefix = 'wortapp-backup-';

  /// 云端保留的历史归档最大数量（不含当前主备份文件）
  static const int maxHistoryCount = 10;

  /// 归档文件名解析：`wortapp-backup-(yyyyMMdd-HHmmss)-(设备名).json`
  static final RegExp _archiveNamePattern = RegExp(
    r'^wortapp-backup-(\d{8}-\d{6})-(.+)\.json$',
  );

  /// 本地记录上次成功同步时间的 settings 键
  static const String lastSyncKey = 'onedrive_lastSyncAt';

  /// gzip 魔数（1f 8b）：用于识别云端备份是否为压缩载荷
  static const int _gzipMagic0 = 0x1f;
  static const int _gzipMagic1 = 0x8b;

  /// 压缩同步载荷。
  ///
  /// 备份 JSON 以中文文本为主、重复度高，实测 6.35 MB 可压到约 0.81 MB
  /// （约 8 倍），显著降低每次同步的上传/下载流量。
  static Uint8List _compress(Uint8List raw) =>
      Uint8List.fromList(gzip.encode(raw));

  /// 解压同步载荷（若非 gzip 则原样返回）。
  ///
  /// 兼容旧版本上传的未压缩 JSON：无 gzip 魔数时不解压，直接使用。
  static Uint8List _decompressIfNeeded(Uint8List bytes) {
    if (bytes.length >= 2 &&
        bytes[0] == _gzipMagic0 &&
        bytes[1] == _gzipMagic1) {
      return Uint8List.fromList(gzip.decode(bytes));
    }
    return bytes;
  }

  final AppDatabase _db;
  late final OneDrive _onedrive;

  OneDriveSyncService(this._db) {
    _onedrive = OneDrive(
      clientID: OneDriveConfig.clientId,
      redirectURL: OneDriveConfig.redirectUrl,
      scopes: OneDriveConfig.scopes,
    );
  }

  /// 生成历史归档文件名：`wortapp-backup-<时间戳>-<设备名>.json`
  ///
  /// 时间戳为 UTC 时间的 `yyyyMMdd-HHmmss`（无冒号，跨平台文件系统安全），
  /// 字典序即时间序，便于排序清理；UTC 基准保证跨设备/跨时区一致。
  /// 设备名做安全清洗（最长 30 字符）。
  static String archiveFileNameFor(DateTime time, String deviceName) {
    final t = time.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    final stamp = '${t.year}${two(t.month)}${two(t.day)}-'
        '${two(t.hour)}${two(t.minute)}${two(t.second)}';
    return '$archivePrefix$stamp-${_sanitizeDeviceName(deviceName)}.json';
  }

  /// 从归档文件名解析时间戳（UTC），无法解析时返回 null
  static DateTime? parseArchiveStamp(String fileName) {
    final m = _archiveNamePattern.firstMatch(fileName);
    if (m == null) return null;
    final raw = m.group(1)!; // 形如 20260806-183000
    int p(int start, int end) => int.tryParse(raw.substring(start, end)) ?? 0;
    return DateTime.utc(
      p(0, 4),
      p(4, 6),
      p(6, 8),
      p(9, 11),
      p(11, 13),
      p(13, 15),
    );
  }

  /// 挑选需要删除的历史归档：超出 [maxKeep] 时返回最旧的若干（时间升序）
  static List<String> pickArchivesToDelete(
    List<String> fileNames,
    int maxKeep,
  ) {
    final dated = <(DateTime, String)>[];
    for (final n in fileNames) {
      final t = parseArchiveStamp(n);
      if (t != null) dated.add((t, n));
    }
    dated.sort((a, b) => a.$1.compareTo(b.$1));
    final excess = dated.length - maxKeep;
    if (excess <= 0) return const [];
    return dated.take(excess).map((e) => e.$2).toList();
  }

  /// 清洗设备名为安全文件名字段：保留字母数字（含中文等 Unicode 字母）与 .-_ ，
  /// 其余替换为下划线（`\w` 在 ECMAScript 语义下不匹配中文，故用 `\p{L}`/`\p{N}`）
  static String _sanitizeDeviceName(String name) {
    var cleaned = name
        .trim()
        .replaceAll(RegExp(r'[^\p{L}\p{N}.\-]', unicode: true), '_');
    cleaned = cleaned.replaceAll(RegExp(r'_+'), '_');
    if (cleaned.length > 30) cleaned = cleaned.substring(0, 30);
    cleaned = cleaned.replaceAll(RegExp(r'[._\-]$'), '');
    return cleaned.isEmpty ? 'device' : cleaned;
  }

  /// 当前设备名（Web 环境固定 'web'，桌面/移动端取主机名）
  String _deviceName() {
    if (kIsWeb) return 'web';
    try {
      final name = Platform.localHostname;
      return name.isEmpty ? 'device' : name;
    } catch (_) {
      return 'device';
    }
  }

  /// 将云端当前备份归档为历史文件。
  ///
  /// 采用 **服务端复制**（Graph 异步 `copy`）：不再「先下载整包、再作为归档
  /// 整包上传」，因此归档不产生任何文件内容的下载/上传流量，只多 1 个元数据
  /// 查询 + 1 个 copy 请求。
  ///
  /// 时间戳优先取上次同步时间（[lastSyncKey]），无记录时回退云端文件的
  /// `lastModifiedDateTime`、再回退当前时间。归档失败只记日志、不阻断主同步。
  Future<void> _archiveCloudBackup({DateTime? fallbackTime}) async {
    try {
      // 主备份的元数据：id + 父目录 id + driveId（服务端复制所需）
      final item = await _onedrive.getItem(remoteFileName, isAppFolder: true);
      if (item == null) return;

      final itemId = item['id'] as String?;
      final parent = item['parentReference'] as Map<String, dynamic>?;
      final parentId = parent?['id'] as String?;
      final driveId = parent?['driveId'] as String?;
      if (itemId == null || parentId == null || driveId == null) {
        debugPrint('# OneDrive 归档跳过：缺少 item/parent 标识');
        return;
      }

      final lastSyncAt = await getLastSyncAt();
      final stampTime = lastSyncAt ??
          DateTime.tryParse(item['lastModifiedDateTime']?.toString() ?? '') ??
          fallbackTime ??
          DateTime.now();
      final archiveName = archiveFileNameFor(stampTime, _deviceName());

      final resp = await _onedrive.copyItem(
        itemId: itemId,
        name: archiveName,
        parentId: parentId,
        driveId: driveId,
      );
      if (!resp.isSuccess) {
        debugPrint('# OneDrive 归档失败($archiveName): ${resp.message}');
      }
    } catch (e) {
      debugPrint('# OneDrive 归档异常: $e');
    }
  }

  /// 清理超出保留上限的历史归档（保留最近 [maxHistoryCount] 次）
  ///
  /// 单个文件删除失败只记日志，不影响其余清理与主同步。
  Future<void> _pruneHistory() async {
    try {
      final files = await _onedrive.listFiles('', isAppFolder: true);
      final names = files
          .where((f) => !f.isFolder)
          .map((f) => f.name)
          .toList();
      final toDelete = pickArchivesToDelete(names, maxHistoryCount);
      for (final name in toDelete) {
        final resp = await _onedrive.deleteFile(name, isAppFolder: true);
        if (!resp.isSuccess) {
          debugPrint('# OneDrive 历史清理失败($name): ${resp.message}');
        }
      }
    } catch (e) {
      debugPrint('# OneDrive 历史清理异常: $e');
    }
  }


  /// 是否已登录（access token 有效）
  Future<bool> isConnected() => _onedrive.isConnected();

  /// 登录 OneDrive（应用内 WebView 完成授权）
  Future<bool> connect(BuildContext context) => _onedrive.connect(context);

  /// 退出登录（清除本地令牌）
  Future<void> disconnect() => _onedrive.disconnect();

  /// 上次成功同步的备份时间（本地记录）
  Future<DateTime?> getLastSyncAt() async {
    final raw = await _db.getSetting(lastSyncKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  /// 从备份字节解析云端备份信息（解析失败返回 null）
  static CloudBackupInfo? parseCloudInfo(Uint8List bytes) {
    try {
      final json =
          jsonDecode(utf8.decode(_decompressIfNeeded(bytes)))
              as Map<String, dynamic>;
      final exportedAt =
          DateTime.tryParse(json['exportedAt']?.toString() ?? '');
      if (exportedAt == null) return null;
      return CloudBackupInfo(
        exportedAt: exportedAt,
        deckCount: json['deckCount'] ?? 0,
        wordCount: json['wordCount'] ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  /// 拉取云端备份文件（不存在或解析失败时返回 null）
  Future<CloudBackupInfo?> fetchCloudBackup() async {
    final resp = await _onedrive.pull(
      remoteFileName,
      isAppFolder: true,
    );
    if (!resp.isSuccess || resp.bodyBytes == null) return null;
    return parseCloudInfo(resp.bodyBytes!);
  }

  /// 上传本地备份到 OneDrive
  ///
  /// [force] 为 true 时跳过冲突检查直接覆盖云端。
  /// 未强制且云端存在更新的备份时，返回 [OneDriveSyncResult.cloudHasNewer]。
  /// 上传前将云端旧备份归档为历史文件（时间戳+设备名），并清理
  /// 超出保留上限的历史归档（保留最近 [maxHistoryCount] 次）。
  Future<OneDriveSyncResult> uploadBackup({bool force = false}) async {
    // 1. 生成本地备份
    final export = await ExportService(_db).exportBackup(
      fileName: remoteFileName,
    );
    if (!export.success || export.data == null) {
      return OneDriveSyncResult(
        error: export.error ?? AppLocale.tr('备份生成失败'),
      );
    }
    final bytes = export.data!.bytes;
    final localTime = DateTime.now();

    // 2. 拉取云端备份（冲突检查 + 归档素材）
    Uint8List? cloudBytes;
    if (!force) {
      final pullResp = await _onedrive.pull(
        remoteFileName,
        isAppFolder: true,
      );
      if (pullResp.isSuccess &&
          pullResp.bodyBytes != null &&
          pullResp.bodyBytes!.isNotEmpty) {
        cloudBytes = pullResp.bodyBytes;
        final cloudInfo = parseCloudInfo(cloudBytes!);
        if (cloudInfo != null && cloudInfo.exportedAt.isAfter(localTime)) {
          return OneDriveSyncResult(
            cloudHasNewer: true,
            cloudInfo: cloudInfo,
          );
        }
      }
    }

    // 3. 归档云端旧备份（服务端复制，时间戳+设备名；失败不阻断）
    await _archiveCloudBackup(fallbackTime: localTime);

    // 4. 上传新备份（gzip 压缩；App 专用文件夹不存在时会自动创建）
    final resp = await _onedrive.push(
      _compress(bytes),
      remoteFileName,
      isAppFolder: true,
    );
    if (!resp.isSuccess) {
      return OneDriveSyncResult(error: resp.message ?? AppLocale.tr('上传失败'));
    }

    // 5. 清理超出上限的历史归档（保留最近 10 次）
    await _pruneHistory();

    // 6. 记录上次同步时间
    await _db.setSetting(lastSyncKey, localTime.toIso8601String());

    return OneDriveSyncResult(
      success: true,
      exportedAt: localTime,
    );
  }

  /// 从 OneDrive 下载备份并恢复本地数据
  ///
  /// [wipeExisting] 为 true 时完全覆盖当前数据（默认，恢复语义），
  /// 调用方必须先弹窗确认。
  Future<OneDriveSyncResult> downloadBackup({
    bool wipeExisting = true,
  }) async {
    // 1. 下载
    final resp = await _onedrive.pull(
      remoteFileName,
      isAppFolder: true,
    );
    if (!resp.isSuccess || resp.bodyBytes == null) {
      final msg = resp.statusCode == 404
          ? AppLocale.tr('云端还没有备份，请先执行上传')
          : (resp.message ?? AppLocale.tr('下载失败'));
      return OneDriveSyncResult(error: msg);
    }
    if (resp.bodyBytes!.isEmpty) {
      return OneDriveSyncResult(error: AppLocale.tr('云端备份文件为空'));
    }

    // 云端可能是 gzip 压缩载荷，先解压再解析 / 恢复（旧未压缩文件原样使用）
    final backupBytes = _decompressIfNeeded(resp.bodyBytes!);
    final cloudTime = OneDriveSyncResult.parseExportedAt(backupBytes);

    // 2. 整体恢复
    final importResult = await ImportService(_db).importBackup(
      fileBytes: backupBytes,
      fileName: remoteFileName,
      wipeExisting: wipeExisting,
    );

    // 3. 记录上次同步时间
    if (cloudTime != null) {
      await _db.setSetting(lastSyncKey, cloudTime.toIso8601String());
    }

    if (importResult.errors.isNotEmpty) {
      return OneDriveSyncResult(
        error: AppLocale.trArgs(
          '恢复完成，但有 {0} 条错误',
          [importResult.errors.length],
        ),
        exportedAt: cloudTime,
        deckCount: importResult.deckCount,
        wordCount: importResult.wordCount,
        skipCount: importResult.skipCount,
      );
    }
    return OneDriveSyncResult(
      success: true,
      exportedAt: cloudTime,
      deckCount: importResult.deckCount,
      wordCount: importResult.wordCount,
      skipCount: importResult.skipCount,
    );
  }

  /// 差异同步：合并本地与云端备份，只同步有差异的部分
  ///
  /// 执行流程：
  /// 1. 生成本地备份 → 拉取云端备份
  /// 2. 三向合并（新增并入、时间戳新者胜、收藏并集、统计按天取大）
  /// 3. 检测到真冲突且未指定方向时：不写库不上传，返回冲突列表由调用方弹窗
  /// 4. 无冲突（或已指定方向）：合并结果写入本地并上传云端，两端最终一致
  ///
  /// [resolution] 为 null 时只检测冲突；冲突项需 UI 弹窗后带方向重试。
  Future<OneDriveSyncResult> syncNow({
    ConflictResolution? resolution,
  }) async {
    // 1. 生成本地备份
    final export = await ExportService(_db).exportBackup(
      fileName: remoteFileName,
    );
    if (!export.success || export.data == null) {
      return OneDriveSyncResult(
        error: export.error ?? AppLocale.tr('备份生成失败'),
      );
    }
    final localJson =
        jsonDecode(utf8.decode(export.data!.bytes)) as Map<String, dynamic>;

    // 2. 拉取云端备份
    final resp = await _onedrive.pull(
      remoteFileName,
      isAppFolder: true,
    );

    // 云端还没有备份（首次同步）：直接上传本地备份
    if (resp.statusCode == 404) {
      final pushResp = await _onedrive.push(
        _compress(export.data!.bytes),
        remoteFileName,
        isAppFolder: true,
      );
      if (!pushResp.isSuccess) {
        return OneDriveSyncResult(
          error: pushResp.message ?? AppLocale.tr('上传失败'),
        );
      }
      // 云端可能残留历史归档（如主文件被手动删除），顺带清理一次
      await _pruneHistory();
      await _db.setSetting(lastSyncKey, DateTime.now().toIso8601String());
      return OneDriveSyncResult(success: true);
    }
    if (!resp.isSuccess || resp.bodyBytes == null) {
      return OneDriveSyncResult(
        error: resp.message ?? AppLocale.tr('下载失败'),
      );
    }
    if (resp.bodyBytes!.isEmpty) {
      return OneDriveSyncResult(error: AppLocale.tr('云端备份文件为空'));
    }

    // 3. 解析云端备份并三向合并
    Map<String, dynamic> cloudJson;
    try {
      cloudJson = BackupCodec.decode(_decompressIfNeeded(resp.bodyBytes!));
    } catch (e) {
      return OneDriveSyncResult(
        error: AppLocale.trArgs('云端备份解析失败: {0}', [e]),
      );
    }

    // 3.1 版本兼容检查：云端备份来自更高版本应用时阻断并提示更新
    final cloudVersion = cloudJson['version'];
    if (cloudVersion is int && cloudVersion > BackupCodec.currentVersion) {
      return OneDriveSyncResult(
        error: AppLocale.trArgs(
          '云端备份由更新版本的 WortApp 生成（备份 v{0}），'
              '请先更新应用后再同步，以免数据格式不兼容',
          [cloudVersion],
        ),
      );
    }

    final lastSyncAt = await getLastSyncAt();
    final outcome = BackupMerger.merge(
      local: localJson,
      cloud: cloudJson,
      lastSyncAt: lastSyncAt,
      resolution: resolution,
    );

    // 4. 检测到冲突且尚未指定方向：不写库、不上传，交由调用方弹窗
    if (outcome.hasConflicts && resolution == null) {
      return OneDriveSyncResult(conflicts: outcome.conflicts);
    }

    // 5. 合并结果写入本地（增量 upsert，不清空现有数据；跳过与本地一致的单词）
    try {
      await BackupMerger.applyToDatabase(
        _db,
        outcome.mergedBackup,
        unchangedWordKeys: outcome.unchangedWordKeys,
        unchangedAiCacheKeys: outcome.unchangedAiCacheKeys,
      );
      // 5.1 墓碑表对齐为合并结果（删除传播状态两端一致）
      final mergedDeletions = outcome.mergedBackup['deletions'];
      if (mergedDeletions is List) {
        await _db.replaceAllDeletions(
          mergedDeletions.cast<Map<String, dynamic>>(),
        );
      }
    } catch (e) {
      return OneDriveSyncResult(
        error: AppLocale.trArgs('合并写入本地失败: {0}', [e]),
      );
    }

    // 6. 归档云端旧备份（服务端复制）后上传
    await _archiveCloudBackup();

    // 6.1 从本地库重新导出后再上传，保证「云端 == 本地库」。
    //
    // 不能直接上传内存中的合并结果：applyToDatabase 会对字段做规范化
    // （如 chinese 去首尾空白、保留本地既有的德语词形拼写），与内存合并结果
    // 存在细微差异，会让下一轮同步再次判定为「新增/更新」，永远无法收敛
    // （表现为每次同步都提示"新词 1 个 / 更新 3 个"）。
    final finalExport = await ExportService(_db).exportBackup(
      fileName: remoteFileName,
    );
    if (!finalExport.success || finalExport.data == null) {
      return OneDriveSyncResult(
        error: finalExport.error ?? AppLocale.tr('合并后导出失败'),
      );
    }
    final pushResp = await _onedrive.push(
      _compress(finalExport.data!.bytes),
      remoteFileName,
      isAppFolder: true,
    );
    if (!pushResp.isSuccess) {
      return OneDriveSyncResult(
        error: pushResp.message ?? AppLocale.tr('上传失败'),
      );
    }

    // 6.1 清理超出上限的历史归档（保留最近 10 次）
    await _pruneHistory();

    // 7. 记录上次同步时间
    await _db.setSetting(lastSyncKey, DateTime.now().toIso8601String());

    return OneDriveSyncResult(
      success: true,
      exportedAt: DateTime.now(),
      decksAdded: outcome.decksAdded,
      decksUpdated: outcome.decksUpdated,
      wordsAdded: outcome.wordsAdded,
      wordsUpdated: outcome.wordsUpdated,
    );
  }
}
