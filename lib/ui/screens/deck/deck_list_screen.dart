import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import '../../../core/i18n/app_localizations.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/deck_provider.dart';
import '../../../providers/training_provider.dart';
import '../../../providers/search_provider.dart';
import '../../../providers/batch_update_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../data/database/app_database.dart';
import '../../../services/import_export/import_service.dart';
import '../../../services/import_export/export_service.dart';
import '../../../services/ai/batch_ai_service.dart';
import '../../../ui/widgets/import_dialog.dart';
import '../../../ui/widgets/batch_update_dialog.dart';
import 'word_list_screen.dart';

/// 词书列表管理界面
class DeckListScreen extends ConsumerWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbState = ref.watch(databaseStateProvider);
    final batchUpdateState = ref.watch(batchUpdateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('词书管理')),
        actions: [
          if (dbState.database != null)
            IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: () => _importDeck(context, ref),
              tooltip: context.tr('导入词书'),
            ),
        ],
      ),
      body: Column(
        children: [
          // 后台批量更新进度条
          if (batchUpdateState.hasRunningTask)
            _BatchUpdateProgressBar(state: batchUpdateState),
          // 主要内容
          Expanded(
            child: _buildBody(context, ref, dbState),
          ),
        ],
      ),
      floatingActionButton: dbState.database != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 桌面端无法下拉刷新，提供手动刷新按钮
                FloatingActionButton.small(
                  heroTag: 'refreshDecksFab',
                  onPressed: () =>
                      _refreshDecks(context, ref, dbState.database!),
                  tooltip: context.tr('刷新词书'),
                  child: const Icon(Icons.refresh),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'createDeckFab',
                  onPressed: () => _createDeck(context),
                  icon: const Icon(Icons.add),
                  label: Text(context.tr('新建词书')),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, DatabaseState dbState) {
    // 数据库加载中
    if (dbState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(context.tr('正在初始化数据库...')),
          ],
        ),
      );
    }

    // 数据库初始化失败
    if (dbState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              context.tr('数据库初始化失败'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              dbState.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: dbState.isLoading
                  ? null
                  : () => ref.read(databaseStateProvider.notifier).retry(),
              child: Text(context.tr('重试')),
            ),
          ],
        ),
      );
    }

    final db = dbState.database!;

    return StreamBuilder<List<Deck>>(
      stream: db.deckDao.watchAllDecks(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(context.trArgs('加载失败: {0}', [snapshot.error])),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final decks = snapshot.data!;

        if (decks.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _refreshDeckData(ref, db),
            child: LayoutBuilder(
              builder: (context, constraints) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: constraints.maxHeight,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.library_books_outlined,
                            size: 64,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('还没有词书'),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr('点击 + 创建词书，或导入 Excel/CSV 文件'),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _refreshDeckData(ref, db),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: decks.length,
            itemBuilder: (context, index) {
              final deck = decks[index];
              return _DeckCard(deck: deck);
            },
          ),
        );
      },
    );
  }

  /// 下拉刷新：重新拉取词书数据并刷新单词数量缓存
  Future<void> _refreshDeckData(WidgetRef ref, AppDatabase db) async {
    await db.deckDao.getAllDecks();
    ref.invalidate(wordCountProvider);
  }

  /// 手动刷新词书（桌面端无法下拉刷新，提供按钮入口）
  Future<void> _refreshDecks(
      BuildContext context, WidgetRef ref, AppDatabase db) async {
    await _refreshDeckData(ref, db);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('词书已刷新')),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _createDeck(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _CreateDeckDialog(),
    );
  }

  void _importDeck(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls', 'json'],
      withData: kIsWeb, // Web平台需要读取字节数据
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final fileBytes = file.bytes;
    final fileName = file.name;
    // Web平台不能访问path属性，完全避免引用
    String? filePath;
    if (!kIsWeb) {
      filePath = file.path;
    }

    // Web平台必须有字节数据，原生平台必须有文件路径
    if (kIsWeb && fileBytes == null) return;
    if (!kIsWeb && filePath == null) return;

    // 数据库备份（.json）：直接恢复整个词书，无需选择目标词书
    final ext = fileName.toLowerCase().split('.').last;
    if (ext == 'json') {
      if (context.mounted) {
        await _importBackup(context, ref, filePath, fileBytes, fileName);
      }
      return;
    }

    if (context.mounted) {
      final db = ref.read(databaseProvider);
      if (db == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('数据库未就绪'))),
        );
        return;
      }

      final decks = await db.deckDao.getAllDecks();

      if (context.mounted) {
        if (decks.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.tr('请先创建一个词书'))),
          );
          return;
        }

        final deckId = await showDialog<int>(
          context: context,
          builder: (context) => _SelectDeckDialog(decks: decks),
        );

        if (deckId != null && context.mounted) {
          _doImport(context, ref, filePath, fileBytes, fileName, deckId);
        }
      }
    }
  }

  /// 导入数据库备份（JSON）
  Future<void> _importBackup(
    BuildContext context,
    WidgetRef ref,
    String? filePath,
    Uint8List? fileBytes,
    String fileName,
  ) async {
    final db = ref.read(databaseProvider);
    if (db == null) return;

    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final importService = ImportService(db);
    BackupImportResult result;
    try {
      result = await importService.importBackup(
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
      );
    } catch (e) {
      debugPrint('备份导入失败: $e');
      if (context.mounted) {
        Navigator.pop(context); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.trArgs('导入失败: {0}', [e]))),
        );
      }
      return;
    }

    if (context.mounted) {
      Navigator.pop(context); // 关闭加载对话框

      // 显示导入结果
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr(
              result.errors.isEmpty ? '备份导入成功' : '备份导入完成')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.trArgs('导入词书: {0}', [result.deckCount])),
              Text(context.trArgs('导入单词: {0}', [result.wordCount])),
              if (result.skipCount > 0)
                Text(context.trArgs('跳过(重复): {0}', [result.skipCount])),
              if (result.hasErrors) ...[
                const SizedBox(height: 8),
                Text(context.tr('错误详情:'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                ...result.errors.take(5).map((e) => Text('• $e')),
                if (result.errors.length > 5)
                  Text(context.trArgs(
                      '... 还有 {0} 个错误', [result.errors.length - 5])),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('确定')),
            ),
          ],
        ),
      );
    }
  }

  void _doImport(
      BuildContext context, WidgetRef ref, String? filePath, Uint8List? fileBytes, String fileName, int deckId) async {
    final db = ref.read(databaseProvider);
    if (db == null) return;

    // 显示导入选项对话框
    final config = await ImportDialog.show(
      context: context,
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
      deckId: deckId,
      deckName: '',
    );

    if (config == null || !context.mounted) return;

    final importService = ImportService(db);

    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    ImportResult result;

    try {
      if (config.mode == ImportMode.simple && config.wordColumnIndex != null) {
        // 简单模式：只导入单词列
        result = await importService.importSimpleMode(
          filePath: filePath,
          fileBytes: fileBytes,
          fileName: fileName,
          deckId: deckId,
          wordColumnIndex: config.wordColumnIndex!,
          hasHeader: config.hasHeader,
        );
      } else {
        // 完整模式：按原格式导入
        result = await importService.importFromFile(
          filePath: filePath,
          fileBytes: fileBytes,
          fileName: fileName,
          deckId: deckId,
          hasHeader: config.hasHeader,
        );
      }
    } catch (e) {
      debugPrint('导入失败: $e');
      if (context.mounted) {
        Navigator.pop(context); // 关闭加载对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.trArgs('导入失败: {0}', [e]))),
        );
      }
      return;
    }

    if (context.mounted) {
      Navigator.pop(context); // 关闭加载对话框

      // 显示导入结果
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.tr(
              result.isFullySuccessful ? '导入成功' : '导入完成')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.trArgs('总行数: {0}', [result.totalRows])),
              Text(context.trArgs('成功导入: {0}', [result.successCount])),
              if (result.skipCount > 0)
                Text(context.trArgs('跳过: {0}', [result.skipCount])),
              if (result.hasErrors) ...[
                const SizedBox(height: 8),
                Text(context.tr('错误详情:'),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                ...result.errors.take(5).map((e) => Text('• $e')),
                if (result.errors.length > 5)
                  Text(context.trArgs(
                      '... 还有 {0} 个错误', [result.errors.length - 5])),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.tr('确定')),
            ),
          ],
        ),
      );

      // 如果是简单模式且有导入成功，询问是否AI更新词意
      if (config.mode == ImportMode.simple &&
          result.successCount > 0 &&
          context.mounted) {
        final shouldUpdate = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr('AI 更新词意')),
            content: Text(context.trArgs(
                '成功导入 {0} 个单词。是否使用 AI 自动获取词意、词性等信息？',
                [result.successCount])),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(context.tr('稍后再说')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(context.tr('立即更新')),
              ),
            ],
          ),
        );

        if (shouldUpdate == true && context.mounted) {
          _startBatchUpdate(context, ref, deckId);
        }
      }
    }
  }

  void _startBatchUpdate(BuildContext context, WidgetRef ref, int deckId) async {
    final db = ref.read(databaseProvider);
    final aiEngine = ref.read(aiDictionaryEngineProvider);

    if (db == null || aiEngine == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('请先在设置中配置 AI API Key'))),
        );
      }
      return;
    }

    final batchService = BatchAIService(
      db,
      aiEngine,
      concurrency: ref.read(settingsProvider).aiConcurrency,
    );
    final notifier = ref.read(batchUpdateProvider.notifier);

    // 显示进度对话框（可关闭）
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: true, // 允许点击外部关闭
        builder: (dialogContext) => BatchUpdateDialog(
          batchService: batchService,
          deckId: deckId,
          overwrite: true,
          notifier: notifier,
          taskName: context.tr('AI 更新词书词意'),
        ),
      );
    }
  }
}

class _DeckCard extends ConsumerWidget {
  final Deck deck;

  const _DeckCard({required this.deck});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final wordCount = db != null ? ref.watch(wordCountProvider(deck.id)) : null;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WordListScreen(
                deckId: deck.id,
                deckName: deck.name,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: deck.isActive
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.library_books,
                  color: deck.isActive
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          deck.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (deck.isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              context.tr('当前'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    wordCount != null
                        ? wordCount.when(
                            data: (count) => Text(
                              context.trArgs('{0} 个单词', [count]),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            loading: () => const Text('...'),
                            error: (_, _) =>
                                Text(context.trArgs('{0} 个单词', [0])),
                          )
                        : const Text('...'),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _onMenuAction(context, ref, value),
                itemBuilder: (context) => [
                  if (!deck.isActive)
                    PopupMenuItem(
                      value: 'activate',
                      child: Text(context.tr('设为当前词书')),
                    ),
                  PopupMenuItem(
                    value: 'rename',
                    child: Text(context.tr('重命名')),
                  ),
                  PopupMenuItem(
                    value: 'import',
                    child: Text(context.tr('导入单词')),
                  ),
                  PopupMenuItem(
                    value: 'export',
                    child: Text(context.tr('导出')),
                  ),
                  // 练习里收藏的词若还不在任何词书，会自动加入这本词书
                  PopupMenuItem(
                    value: 'practiceDefault',
                    child: Text(
                      ref.watch(practiceDefaultDeckProvider) == deck.id
                          ? context.tr('取消练习默认词书')
                          : context.tr('设为练习默认词书'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(context.tr('删除'),
                        style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMenuAction(
      BuildContext context, WidgetRef ref, String action) async {
    final db = ref.read(databaseProvider);
    if (db == null) return;

    switch (action) {
      case 'activate':
        await db.deckDao.setActiveDeck(deck.id);
        break;
      case 'rename':
        _showRenameDialog(context, ref);
        break;
      case 'import':
        _importToDeck(context, ref);
        break;
      case 'export':
        _exportDeck(context, ref);
        break;
      case 'practiceDefault':
        final notifier = ref.read(practiceDefaultDeckProvider.notifier);
        final isDefault = ref.read(practiceDefaultDeckProvider) == deck.id;
        await notifier.setDeck(isDefault ? null : deck.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isDefault
                  ? context.tr('已取消练习默认词书')
                  : context.trArgs('练习中收藏的词将加入「{0}」', [deck.name]),
            ),
          ),
        );
        break;
      case 'delete':
        _confirmDelete(context, ref);
        break;
    }
  }

  /// 导出词书：选择导出格式后生成文件
  Future<void> _exportDeck(BuildContext context, WidgetRef ref) async {
    final db = ref.read(databaseProvider);
    if (db == null) return;

    final format = await showDialog<ExportFormat>(
      context: context,
      builder: (context) => _ExportDialog(deckName: deck.name),
    );
    if (format == null || !context.mounted) return;

    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final service = ExportService(db);
    final ExportResult result;
    switch (format) {
      case ExportFormat.csv:
        result = await service.exportToCsv(deckId: deck.id);
        break;
      case ExportFormat.excel:
        result = await service.exportToExcel(deckId: deck.id);
        break;
      case ExportFormat.backupJson:
        result = await service.exportBackup(deckIds: [deck.id]);
        break;
    }

    if (context.mounted) {
      Navigator.pop(context); // 关闭加载对话框
    }

    if (!result.success || result.data == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.error ?? context.tr('导出失败'))),
        );
      }
      return;
    }

    if (context.mounted) {
      await _saveExportFile(context, result.data!);
    }
  }

  /// 保存/分享导出文件（跨平台：Web/Android 触发系统分享，其余原生平台保存到文档目录）
  Future<void> _saveExportFile(BuildContext context, ExportData data) async {
    try {
      if (kIsWeb || defaultTargetPlatform == TargetPlatform.android) {
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
          text: context.trArgs('WortApp 导出：{0}', [data.fileName]),
        );
      } else {
        // 原生平台：保存到文档目录
        final dir = await getApplicationDocumentsDirectory();
        final filePath = p.join(dir.path, data.fileName);
        await File(filePath).writeAsBytes(data.bytes, flush: true);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(context.trArgs('已导出到: {0}', [filePath]))),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  context.trArgs('保存导出文件失败: {0}', [e]))),
        );
      }
    }
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(text: deck.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('重命名词书')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: context.tr('词书名称'),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('取消')),
          ),
          FilledButton(
            onPressed: () {
              final db = ref.read(databaseProvider);
              if (db != null) {
                db.deckDao.updateDeck(
                  DecksCompanion(
                    id: drift.Value(deck.id),
                    name: drift.Value(controller.text.trim()),
                    updatedAt: drift.Value(DateTime.now()),
                  ),
                );
              }
              Navigator.pop(context);
            },
            child: Text(context.tr('保存')),
          ),
        ],
      ),
    ).whenComplete(() => controller.dispose());
  }

  void _importToDeck(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx', 'xls'],
      withData: kIsWeb, // Web平台需要读取字节数据
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final fileBytes = file.bytes;
    final fileName = file.name;
    // Web平台不能访问path属性，完全避免引用
    String? filePath;
    if (!kIsWeb) {
      filePath = file.path;
    }

    // Web平台必须有字节数据，原生平台必须有文件路径
    if (kIsWeb && fileBytes == null) return;
    if (!kIsWeb && filePath == null) return;

    if (context.mounted) {
      final db = ref.read(databaseProvider);
      if (db == null) return;

      final importService = ImportService(db);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const Center(child: CircularProgressIndicator()),
      );

      ImportResult importResult;
      try {
        importResult = await importService.importFromFile(
          filePath: filePath,
          fileBytes: fileBytes,
          fileName: fileName,
          deckId: deck.id,
        );
      } catch (e) {
        debugPrint('导入失败: $e');
        if (context.mounted) {
          Navigator.pop(context); // 关闭加载对话框
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.trArgs('导入失败: {0}', [e]))),
          );
        }
        return;
      }

      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.trArgs(
              '导入完成: {0}/{1} 成功',
              [importResult.successCount, importResult.totalRows],
            )),
          ),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('删除词书')),
        content: Text(context.trArgs(
            '确定要删除词书"{0}"吗？\n\n此操作将删除词书中的所有单词和学习记录，且不可恢复。',
            [deck.name])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('取消')),
          ),
          FilledButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              if (db != null) {
                await db.deckDao.deleteDeck(deck.id);
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.tr('删除')),
          ),
        ],
      ),
    );
  }
}

class _CreateDeckDialog extends ConsumerStatefulWidget {
  const _CreateDeckDialog();

  @override
  ConsumerState<_CreateDeckDialog> createState() => _CreateDeckDialogState();
}

class _CreateDeckDialogState extends ConsumerState<_CreateDeckDialog> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _canCreate = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_updateCanCreate);
  }

  @override
  void dispose() {
    _nameController.removeListener(_updateCanCreate);
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _updateCanCreate() {
    final canCreate = _nameController.text.trim().isNotEmpty;
    if (canCreate != _canCreate) {
      setState(() {
        _canCreate = canCreate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('新建词书')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: context.tr('词书名称'),
              hintText: context.tr('例如：德语A1词汇'),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            decoration: InputDecoration(
              labelText: context.tr('描述（可选）'),
              hintText: context.tr('例如：歌德学院 A1 级别核心词汇'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('取消')),
        ),
        FilledButton(
          onPressed: _canCreate ? _createDeck : null,
          child: Text(context.tr('创建')),
        ),
      ],
    );
  }

  void _createDeck() {
    final db = ref.read(databaseProvider);
    if (db == null) return;

    final now = DateTime.now();

    db.deckDao.createDeck(
      DecksCompanion(
        name: drift.Value(_nameController.text.trim()),
        description: drift.Value(_descController.text.trim().isEmpty
            ? null
            : _descController.text.trim()),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
    );

    Navigator.pop(context);
  }
}

class _SelectDeckDialog extends StatelessWidget {
  final List<Deck> decks;

  const _SelectDeckDialog({required this.decks});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('选择导入目标词书')),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
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
              subtitle: deck.description != null ? Text(deck.description!) : null,
              onTap: () => Navigator.pop(context, deck.id),
            );
          },
        ),
      ),
    );
  }
}

/// 导出格式选择对话框
class _ExportDialog extends StatelessWidget {
  final String deckName;

  const _ExportDialog({required this.deckName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.tr('导出词书')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('选择导出格式：'),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.table_chart),
            title: const Text('Excel (.xlsx)'),
            subtitle: Text(context.tr('通用格式，可用 Excel/WPS 打开编辑')),
            onTap: () => Navigator.pop(context, ExportFormat.excel),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description),
            title: const Text('CSV (.csv)'),
            subtitle: Text(context.tr('通用格式，文本编辑器或 Excel 可打开')),
            onTap: () => Navigator.pop(context, ExportFormat.csv),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.save_alt),
            title: Text(context.tr('数据库备份 (.json)')),
            subtitle: Text(
                context.tr('包含单词全部数据、复习记录和变位信息，可用于备份恢复')),
            onTap: () => Navigator.pop(context, ExportFormat.backupJson),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.tr('取消')),
        ),
      ],
    );
  }
}

/// 后台批量更新进度条
class _BatchUpdateProgressBar extends ConsumerWidget {
  final BatchUpdateState state;

  const _BatchUpdateProgressBar({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.trArgs('AI 正在更新词意 {0}', [state.progressText]),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                ),
              ),
              if (state.currentTask?.currentWord != null)
                Text(
                  state.currentTask!.currentWord!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  // 清除进度状态
                  ref.read(batchUpdateProvider.notifier).clearAll();
                },
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: state.currentTask?.progress,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
