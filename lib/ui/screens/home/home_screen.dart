import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../providers/deck_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../services/import_export/export_service.dart';
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
          PopupMenuButton<String>(
            onSelected: (value) => _onMenuAction(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export_csv',
                child: Text('导出为 CSV'),
              ),
              const PopupMenuItem(
                value: 'export_excel',
                child: Text('导出为 Excel'),
              ),
              const PopupMenuItem(
                value: 'export_backup',
                child: Text('导出数据库备份 (.json)'),
              ),
            ],
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

  void _onMenuAction(BuildContext context, WidgetRef ref, String action) async {
    final activeDeck = ref.read(activeDeckProvider).valueOrNull;
    if (activeDeck == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一个词书')),
      );
      return;
    }

    final db = ref.read(databaseProvider);
    if (db == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('数据库未就绪')),
      );
      return;
    }
    final exportService = ExportService(db);

    final ExportResult result;
    switch (action) {
      case 'export_csv':
        result = await exportService.exportToCsv(deckId: activeDeck.id);
        break;
      case 'export_excel':
        result = await exportService.exportToExcel(deckId: activeDeck.id);
        break;
      case 'export_backup':
        result = await exportService.exportBackup(deckIds: [activeDeck.id]);
        break;
      default:
        return;
    }

    if (!result.success || result.data == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? '导出失败')),
        );
      }
      return;
    }

    if (context.mounted) {
      await _saveExportFile(context, result.data!);
    }
  }

  /// 保存/分享导出文件（跨平台：原生保存到文档目录，Web 触发浏览器下载）
  Future<void> _saveExportFile(BuildContext context, ExportData data) async {
    try {
      if (kIsWeb) {
        // Web 平台：通过系统分享触发浏览器下载
        await Share.shareXFiles(
          [
            XFile.fromData(
              data.bytes,
              mimeType: data.mimeType,
              name: data.fileName,
            ),
          ],
          fileNameOverrides: [data.fileName],
          text: 'WortApp 导出：${data.fileName}',
        );
      } else {
        // 原生平台：保存到文档目录
        final dir = await getApplicationDocumentsDirectory();
        final filePath = p.join(dir.path, data.fileName);
        await File(filePath).writeAsBytes(data.bytes, flush: true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已导出到: $filePath')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存导出文件失败: $e')),
        );
      }
    }
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
