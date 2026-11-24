import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/onedrive_config.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../providers/deck_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/onedrive_provider.dart';
import '../../widgets/onedrive_sync_actions.dart';
import 'widgets/progress_card.dart';
import 'widgets/feature_cards.dart';
import 'widgets/onedrive_sync_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDeck = ref.watch(activeDeckProvider);

    return Scaffold(
      appBar: AppBar(
        // 左上角 OneDrive 同步图标（未登录点登录，已登录点上传）
        leading: const OneDriveSyncButton(),
        title: activeDeck.when(
          data: (deck) => Text(deck?.name ?? 'WortApp'),
          loading: () => const Text('WortApp'),
          error: (_, _) => const Text('WortApp'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => _showDeckSwitcher(context, ref),
            tooltip: context.tr('切换词书'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _refresh(context, ref),
        child: ScrollConfiguration(
          // 桌面端也允许鼠标拖拽触发下拉刷新
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
          ),
          child: SingleChildScrollView(
            // 内容不满一屏时也能下拉刷新
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 今日进度卡片
                ProgressCard(deckId: activeDeck.valueOrNull?.id),
                const SizedBox(height: 24),
                // 功能入口
                Text(
                  context.tr('学习功能'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                const FeatureCards(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 下拉刷新：OneDrive 已连接时执行差异同步，否则仅提示
  Future<void> _refresh(BuildContext context, WidgetRef ref) async {
    // Web 平台或未配置 Azure：无云端同步能力，本地数据由数据库流实时更新
    if (kIsWeb || !OneDriveConfig.isConfigured) {
      _showSnack(context, context.tr('数据已是最新'));
      return;
    }

    if (!ref.read(onedriveSyncProvider).isConnected) {
      _showSnack(
        context,
        context.tr('尚未连接 OneDrive，点击左上角云朵图标登录后即可同步'),
      );
      return;
    }

    final result = await runOneDriveSync(context, ref);
    if (!context.mounted) return;
    showOneDriveSyncResult(context, result, successMsg: context.tr('同步完成'));
  }

  void _showSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showDeckSwitcher(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => const _DeckSwitcherSheet(),
    );
  }

}

/// 词书切换底部弹窗
///
/// 必须使用 [ref.watch] 监听 allDecksProvider，
/// 若用 ref.read 则在 provider 尚未发出首个数据时会一直停留在加载状态（转圈）。
class _DeckSwitcherSheet extends ConsumerWidget {
  const _DeckSwitcherSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decksAsync = ref.watch(allDecksProvider);

    return decksAsync.when(
      data: (decks) {
        if (decks.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(context.tr('还没有词书，请先创建一个词书')),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          itemCount: decks.length,
          itemBuilder: (context, index) {
            final deck = decks[index];
            return ListTile(
              leading: Icon(
                deck.isActive ? Icons.check_circle : Icons.circle_outlined,
                color: deck.isActive
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(
                deck.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: deck.description != null
                  ? Text(
                      deck.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : null,
              onTap: () async {
                final db = ref.read(databaseProvider);
                if (db != null) {
                  // 等待落库完成再关闭面板，避免切换后首页仍显示旧词书
                  await db.deckDao.setActiveDeck(deck.id);
                }
                if (context.mounted) Navigator.pop(context);
              },
            );
          },
        );
      },
      // 固定高度占位：直接放 Center 会撑满面板，数据到达后面板高度突降（跳动）
      loading: () => const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(child: Text(context.trArgs('错误: {0}', [e]))),
    );
  }
}
