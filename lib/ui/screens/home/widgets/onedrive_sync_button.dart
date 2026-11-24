import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/onedrive_config.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../providers/onedrive_provider.dart';
import '../../../widgets/onedrive_sync_actions.dart';

/// 主页左上角 OneDrive 同步图标按钮
///
/// 联动 [onedriveSyncProvider]：
/// - 未登录：云朵轮廓图标，点击登录 OneDrive
/// - 已登录：云朵完成图标（绿色），点击上传备份到 OneDrive
/// - 同步中：转圈并禁用点击
/// - Web 平台或未配置 Azure Client ID 时不显示
class OneDriveSyncButton extends ConsumerStatefulWidget {
  const OneDriveSyncButton({super.key});

  @override
  ConsumerState<OneDriveSyncButton> createState() =>
      _OneDriveSyncButtonState();
}

class _OneDriveSyncButtonState extends ConsumerState<OneDriveSyncButton> {
  @override
  Widget build(BuildContext context) {
    // Web 平台不支持 flutter_onedrive，隐藏入口
    if (kIsWeb || !OneDriveConfig.isConfigured) {
      return const SizedBox.shrink();
    }

    final syncState = ref.watch(onedriveSyncProvider);

    // 同步/登录进行中：转圈
    if (syncState.isBusy) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final connected = syncState.isConnected;
    return IconButton(
      icon: Icon(
        connected ? Icons.cloud_done : Icons.cloud_outlined,
        color: connected ? Colors.green : null,
      ),
      tooltip: connected
          ? context.tr('OneDrive 已连接，点击同步')
          : context.tr('OneDrive 未登录，点击登录'),
      onPressed: connected ? _handleSync : _handleLogin,
    );
  }

  /// 登录 OneDrive（应用内 WebView 授权）
  Future<void> _handleLogin() async {
    final ok =
        await ref.read(onedriveSyncProvider.notifier).connect(context);
    if (!mounted) return;
    _showSnack(ok ? context.tr('已连接到 OneDrive') : context.tr('登录失败或已取消'));
  }

  /// 差异同步（静默合并，检测到冲突时弹窗选择方向后重试）
  Future<void> _handleSync() async {
    final result = await runOneDriveSync(context, ref);
    if (!mounted) return;
    showOneDriveSyncResult(context, result);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
