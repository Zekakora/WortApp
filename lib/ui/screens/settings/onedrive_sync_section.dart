import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/constants/onedrive_config.dart';
import '../../../providers/onedrive_provider.dart';
import '../../../providers/sync_refresh.dart';
import '../../../services/sync/onedrive_sync_service.dart';
import '../../widgets/onedrive_sync_actions.dart';

/// OneDrive 云同步设置区块
///
/// 支持登录微软账号后，将备份上传到用户 OneDrive 的 App 专用文件夹
/// （Apps/WortApp），或从云端下载恢复，实现词书与学习进度跨设备同步。
/// Web 平台暂不支持（flutter_onedrive 无 Web 实现），自动隐藏。
class OneDriveSyncSection extends ConsumerStatefulWidget {
  const OneDriveSyncSection({super.key});

  @override
  ConsumerState<OneDriveSyncSection> createState() =>
      _OneDriveSyncSectionState();
}

class _OneDriveSyncSectionState extends ConsumerState<OneDriveSyncSection> {
  @override
  Widget build(BuildContext context) {
    // Web 平台不支持 OneDrive 登录与文件操作，隐藏入口
    if (kIsWeb) return const SizedBox.shrink();

    final syncState = ref.watch(onedriveSyncProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            context.tr('OneDrive 同步'),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (!OneDriveConfig.isConfigured)
          _buildNotConfigured(context)
        else if (!syncState.isConnected)
          _buildNotConnected(context, syncState)
        else
          _buildConnected(context, syncState),
        const Divider(),
      ],
    );
  }

  /// 未填入 Azure Client ID 时的占位提示
  Widget _buildNotConfigured(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(
                '尚未配置 Azure 应用（Client ID）。\n在 Azure 门户注册应用并填写 Client ID 后，即可启用 OneDrive 同步。'),
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('配置位置: lib/core/constants/onedrive_config.dart'),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 未登录状态：说明 + 登录按钮
  Widget _buildNotConnected(
    BuildContext context,
    OneDriveSyncState syncState,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr(
                '登录微软账号后，可在你的 OneDrive 专属文件夹（Apps/WortApp）中同步词书与学习进度，应用无法访问你的其他文件。'),
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: syncState.isBusy ? null : () => _handleLogin(),
            icon: syncState.isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload),
            label: Text(context.tr('登录 OneDrive')),
          ),
        ],
      ),
    );
  }

  /// 已登录状态：同步信息 + 上传/下载按钮
  Widget _buildConnected(
    BuildContext context,
    OneDriveSyncState syncState,
  ) {
    final theme = Theme.of(context);
    final lastSync = syncState.lastSyncAt;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 18, color: Colors.green),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  lastSync == null
                      ? context.tr('已连接 OneDrive（尚未同步）')
                      : context.trArgs('已连接 OneDrive · 上次同步: {0}',
                          [_formatTime(lastSync)]),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: syncState.isBusy
                      ? null
                      : () => _handleSync(),
                  icon: const Icon(Icons.sync),
                  label: Text(context.tr('立即同步')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: syncState.isBusy
                      ? null
                      : () => _handleDownload(),
                  icon: const Icon(Icons.download),
                  label: Text(context.tr('从云端恢复')),
                ),
              ),
            ],
          ),
          if (syncState.isBusy) ...[
            const SizedBox(height: 8),
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            context.tr(
                '同步为双向差异合并：只合并有变化的词书、单词、学习进度与收藏，不删除任何数据；同一单词两端都修改过时才会弹窗选择方向。「从云端恢复」将用云端备份完全覆盖当前设备的数据，需二次确认。'),
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: syncState.isBusy ? null : () => _handleDisconnect(),
            child: Text(context.tr('退出登录')),
          ),
        ],
      ),
    );
  }

  /// 登录 OneDrive
  Future<void> _handleLogin() async {
    final ok = await ref.read(onedriveSyncProvider.notifier).connect(context);
    if (!mounted) return;
    _showSnack(ok ? context.tr('已连接到 OneDrive') : context.tr('登录失败或已取消'));
  }

  /// 退出登录
  Future<void> _handleDisconnect() async {
    await ref.read(onedriveSyncProvider.notifier).disconnect();
    if (!mounted) return;
    _showSnack(context.tr('已退出 OneDrive 登录'));
  }

  /// 立即同步（双向差异合并，检测到冲突时弹窗选择方向后重试）
  Future<void> _handleSync() async {
    final result = await runOneDriveSync(context, ref);
    if (!mounted) return;
    showOneDriveSyncResult(context, result);
  }

  /// 从 OneDrive 下载并覆盖恢复（黄色警告二次确认）
  Future<void> _handleDownload() async {
    final notifier = ref.read(onedriveSyncProvider.notifier);

    final cloud = await notifier.fetchCloudBackup();
    if (!mounted) return;
    if (cloud == null) {
      _showSnack(context.tr('云端还没有备份，请先在其他设备上传'));
      return;
    }

    // 黄色警告弹窗二次确认（与软件数据恢复风格一致）
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.warning_amber_rounded,
          size: 48,
          color: Colors.amber.shade800,
        ),
        title: Text(context.tr('从 OneDrive 恢复数据')),
        content: Text(
          '${context.tr('将使用云端备份完全覆盖当前设备的数据：\n\n')}'
          '${context.trArgs('• 备份导出时间：{0}\n', [_formatTime(cloud.exportedAt)])}'
          '${context.trArgs('• 词书 {0} 个 / 单词 {1} 个\n\n', [cloud.deckCount, cloud.wordCount])}'
          '${context.tr('当前设备上的词书与学习记录将被替换，该操作不可撤销！')}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('取消')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('我已了解，覆盖恢复')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await notifier.downloadBackup(wipeExisting: true);

    // 数据已整体替换，刷新所有依赖数据库的 Provider（含连续打卡 / 待复习）
    invalidateDbDerivedProviders(ref);

    if (!mounted) return;
    _showResult(result, context.tr('已从 OneDrive 恢复'));
  }

  /// 展示同步结果
  void _showResult(OneDriveSyncResult result, String successMsg) {
    if (result.success) {
      final detail = result.deckCount != null
          ? context.trArgs('（词书 {0} 个 / 单词 {1} 个）',
              [result.deckCount, result.wordCount])
          : '';
      _showSnack('$successMsg$detail');
    } else {
      _showSnack(result.error ?? context.tr('操作失败'));
    }
  }

  String _formatTime(DateTime time) {
    return DateFormat('yyyy-MM-dd HH:mm').format(time.toLocal());
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
