import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/deck_provider.dart';
import '../../../providers/database_provider.dart';
import 'widgets/progress_card.dart';
import 'widgets/feature_cards.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeDeck = ref.watch(activeDeckProvider);

    return Scaffold(
      appBar: AppBar(
        title: activeDeck.when(
          data: (deck) => Text(deck?.name ?? 'WortApp'),
          loading: () => const Text('WortApp'),
          error: (_, _) => const Text('WortApp'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: () => _showDeckSwitcher(context, ref),
            tooltip: '切换词书',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 今日进度卡片
            ProgressCard(deckId: activeDeck.valueOrNull?.id),
            const SizedBox(height: 24),
            // 功能入口
            Text(
              '学习功能',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const FeatureCards(),
          ],
        ),
      ),
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
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: Text('还没有词书，请先创建一个词书'),
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
              title: Text(deck.name),
              subtitle: deck.description != null
                  ? Text(deck.description!)
                  : null,
              onTap: () {
                final db = ref.read(databaseProvider);
                if (db != null) {
                  db.deckDao.setActiveDeck(deck.id);
                }
                Navigator.pop(context);
              },
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('错误: $e')),
    );
  }
}
