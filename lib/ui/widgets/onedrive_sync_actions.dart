import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/i18n/app_localizations.dart';
import '../../providers/onedrive_provider.dart';
import '../../providers/sync_refresh.dart';
import '../../services/sync/backup_merger.dart';
import '../../services/sync/onedrive_sync_service.dart';

/// 执行 OneDrive 差异同步（静默合并），检测到数据冲突时弹窗让用户选择方向
///
/// - 无冲突：同步正常完成
/// - 有冲突：弹出「以本地为准 / 以云端为准」选择框，用户确认后带方向重试；
///   用户取消时返回带 [OneDriveSyncResult.conflicts] 的结果（未执行合并）
Future<OneDriveSyncResult> runOneDriveSync(
  BuildContext context,
  WidgetRef ref,
) async {
  final notifier = ref.read(onedriveSyncProvider.notifier);
  var result = await notifier.syncNow();

  if (result.conflicts.isNotEmpty && context.mounted) {
    final chosen = await showDialog<ConflictResolution>(
      context: context,
      builder: (context) => _ConflictDialog(conflicts: result.conflicts),
    );
    if (chosen != null && context.mounted) {
      result = await notifier.syncNow(resolution: chosen);
    }
  }

  // 同步会直接写库，主动失效缓存中的 Provider，否则主页「连续打卡 / 待复习」
  // 等卡片会继续显示同步前的旧数据（看起来像“没同步”）。
  if (result.success) {
    invalidateDbDerivedProviders(ref);
  }
  return result;
}

/// 展示同步结果（成功统计 / 冲突未处理 / 失败原因）
void showOneDriveSyncResult(
  BuildContext context,
  OneDriveSyncResult result, {
  String successMsg = '同步完成',
}) {
  if (!context.mounted) return;

  if (result.success) {
    final parts = <String>[];
    if (result.decksAdded > 0) {
      parts.add(context.trArgs('新词书 {0} 个', [result.decksAdded]));
    }
    if (result.wordsAdded > 0) {
      parts.add(context.trArgs('新词 {0} 个', [result.wordsAdded]));
    }
    if (result.wordsUpdated > 0) {
      parts.add(context.trArgs('更新 {0} 个', [result.wordsUpdated]));
    }
    final detail = parts.isEmpty
        ? ''
        : context.trArgs('（{0}）', [parts.join(' / ')]);
    _showSnack(context, '${context.tr(successMsg)}$detail');
  } else if (result.conflicts.isNotEmpty) {
    _showSnack(
      context,
      context.trArgs('检测到 {0} 处数据冲突，未处理', [result.conflicts.length]),
    );
  } else {
    _showSnack(context, result.error ?? context.tr('操作失败'));
  }
}

void _showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

/// 数据冲突选择弹窗：展示冲突概况，让用户选择以哪端数据为准
class _ConflictDialog extends StatelessWidget {
  final List<SyncConflict> conflicts;

  const _ConflictDialog({required this.conflicts});

  @override
  Widget build(BuildContext context) {
    final preview = conflicts.take(3).map((c) {
      final lTime = _shortTime(context, c.localUpdatedAt);
      final cTime = _shortTime(context, c.cloudUpdatedAt);
      return context.trArgs(
        '• {0}（{1}）\n  本地 {2} · 云端 {3}',
        [c.german, c.deckName, lTime, cTime],
      );
    }).join('\n');
    final more = conflicts.length > 3
        ? context.trArgs('\n…等共 {0} 处', [conflicts.length])
        : '';

    return AlertDialog(
      icon: Icon(
        Icons.sync_problem,
        size: 40,
        color: Theme.of(context).colorScheme.error,
      ),
      title: Text(context.tr('检测到词义编辑冲突')),
      content: Text(
        context.trArgs(
          '以下单词的词义内容在本地与云端都被编辑过：\n\n{0}{1}\n\n'
          '学习进度与收藏已自动合并，仅需选择以哪台设备编辑的词义为准'
          '（另一台设备的词义修改将被覆盖）：',
          [preview, more],
        ),
        style: const TextStyle(fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(context.tr('暂不处理')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, ConflictResolution.cloud),
          child: Text(context.tr('以云端为准')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, ConflictResolution.local),
          child: Text(context.tr('以本地为准')),
        ),
      ],
    );
  }

  String _shortTime(BuildContext context, DateTime? t) {
    if (t == null) return context.tr('无记录');
    final local = t.toLocal();
    final hhmm = '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return context.trArgs('{0}月{1}日 {2}', [local.month, local.day, hhmm]);
  }
}
