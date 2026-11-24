import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/utils/german_parser.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/deck_provider.dart';
import '../../../providers/batch_update_provider.dart';
import '../../../providers/search_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/conjugation_provider.dart';
import '../../../providers/study_provider.dart';
import '../../../data/database/app_database.dart';
import '../../../services/ai/batch_ai_service.dart';
import '../../../services/dictionary/dictionary_engine.dart';
import '../../../services/dictionary/ai_dictionary_engine.dart';
import '../../../ui/widgets/word_type_chip.dart';
import '../../../ui/widgets/expanding_fab.dart';
import '../../../ui/widgets/batch_task_widgets.dart';
import '../../../ui/widgets/batch_update_dialog.dart';
import 'word_detail_screen.dart';
import 'ai_data_management_screen.dart';
import 'word_dedup_screen.dart';

/// 词书内单词列表
class WordListScreen extends ConsumerStatefulWidget {
  final int deckId;
  final String deckName;

  const WordListScreen({
    super.key,
    required this.deckId,
    required this.deckName,
  });

  @override
  ConsumerState<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends ConsumerState<WordListScreen> {
  String _searchQuery = '';
  String? _filterWordType;
  bool _isMultiSelectMode = false;
  final Set<int> _selectedWordIds = {};

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(wordsByDeckProvider(widget.deckId));
    // 词书变格缓存（供单词列表展示变格摘要）
    final cacheAsync =
        ref.watch(deckConjugationCacheProvider(widget.deckId));

    // 批量 AI 更新完成后刷新变格缓存，保证单词行摘要立即显示新数据
    ref.listen(batchUpdateProvider, (previous, next) {
      final wasRunning = previous?.hasRunningTask ?? false;
      if (wasRunning && !next.hasRunningTask) {
        ref.invalidate(deckConjugationCacheProvider(widget.deckId));
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: _isMultiSelectMode
            ? Text(context.trArgs(
                '已选择 {0} 项', [_selectedWordIds.length]))
            : Text(widget.deckName),
        leading: _isMultiSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitMultiSelectMode,
              )
            : null,
        actions: [
          if (_isMultiSelectMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: _selectAll,
              tooltip: context.tr('全选'),
            ),
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: _selectedWordIds.isNotEmpty ? _batchUpdateSelectedWords : null,
              tooltip: context.tr('AI 更新词意'),
            ),
          ] else ...[
            // AI查询任务按钮（始终可见）
            const BatchTaskProgressButton(),
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _enterMultiSelectMode,
              tooltip: context.tr('多选'),
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: context.tr('筛选'),
            ),
          ],
        ],
        bottom: _isMultiSelectMode
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: context.tr('搜索单词...'),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ),
      ),
      body: wordsAsync.when(
        data: (words) {
          final cacheMap =
              cacheAsync.valueOrNull ?? const <int, ConjugationCacheData>{};
          var filtered = words;

          // 搜索过滤
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            filtered = filtered.where((w) {
              return w.german.toLowerCase().contains(query) ||
                  w.chinese.toLowerCase().contains(query);
            }).toList();
          }

          // 词性过滤
          if (_filterWordType != null) {
            filtered =
                filtered.where((w) => w.wordType == _filterWordType).toList();
          }

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? context.tr('词书还没有单词')
                        : context.tr('没有找到匹配的单词'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            // 非多选模式下预留底部空间，避免被「新建单词 + 展开工具按钮」遮挡
            padding: EdgeInsets.only(bottom: _isMultiSelectMode ? 0 : 150),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final word = filtered[index];
              return _WordTile(
                word: word,
                cache: cacheMap[word.id],
                isMultiSelectMode: _isMultiSelectMode,
                isSelected: _selectedWordIds.contains(word.id),
                onTap: () => _isMultiSelectMode
                    ? _toggleWordSelection(word.id)
                    : _navigateToDetail(word.id),
                onLongPress: () => _enterMultiSelectModeAndSelect(word.id),
                onAiUpdate: () => _aiUpdateWord(word),
                onCopyToDeck: () => _copyWordToDeck(word),
                onNormalizeGerman: () => _normalizeGermanWithAi(word),
                onDelete: () => _deleteWord(word),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.trArgs('错误: {0}', [e]))),
      ),
      // 多选模式下隐藏，避免遮挡操作
      floatingActionButton: !_isMultiSelectMode
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 低频工具（重置进度 / 数据管理 / 批量AI规范化 / 去重扫描）收进展开菜单
                ExpandingFab(
                  actions: [
                    ExpandingFabAction(
                      icon: Icons.restart_alt,
                      label: context.tr('重置学习进度'),
                      onPressed: _confirmResetLearningProgress,
                    ),
                    ExpandingFabAction(
                      icon: Icons.storage,
                      label: context.tr('数据管理'),
                      onPressed: _openDataManagement,
                    ),
                    ExpandingFabAction(
                      icon: Icons.auto_fix_high,
                      label: context.tr('批量 AI 规范化德语'),
                      onPressed: _batchNormalizeGerman,
                    ),
                    ExpandingFabAction(
                      icon: Icons.filter_alt_off,
                      label: context.tr('去重扫描'),
                      onPressed: _openDedupScan,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 主操作：新建单词
                FloatingActionButton.extended(
                  heroTag: 'addWordFab',
                  onPressed: _showAddWordDialog,
                  icon: const Icon(Icons.add),
                  label: Text(context.tr('新建单词')),
                ),
              ],
            )
          : null,
    );
  }

  /// 新建单词：仅输入德语单词即可创建，中文释义可留空
  Future<void> _showAddWordDialog() async {
    final germanController = TextEditingController();
    final chineseController = TextEditingController();

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('新建单词')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: germanController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: dialogContext.tr('德语单词 *'),
                hintText: dialogContext.tr('例如：der Apfel'),
              ),
              onSubmitted: (_) =>
                  _createWord(dialogContext, germanController, chineseController),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: chineseController,
              decoration: InputDecoration(
                labelText: dialogContext.tr('中文释义（可留空，稍后 AI 自动获取）'),
                hintText: dialogContext.tr('例如：苹果'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.tr('取消')),
          ),
          FilledButton(
            onPressed: () =>
                _createWord(dialogContext, germanController, chineseController),
            child: Text(dialogContext.tr('添加')),
          ),
        ],
      ),
    );
    germanController.dispose();
    chineseController.dispose();
  }

  /// 创建单词：词书内查重，成功后关闭对话框并提示
  Future<void> _createWord(
    BuildContext dialogContext,
    TextEditingController germanController,
    TextEditingController chineseController,
  ) async {
    final german = germanController.text.trim();
    if (german.isEmpty) return;

    final db = ref.read(databaseProvider);
    if (db == null) return;

    // 全局规范化查重：同一词不允许在任何词书中重复
    // （`der Hund` 与 `Hund` 归为同一词，德语大小写保留语义）
    final key = GermanParser.canonicalKey(german);
    final existing = await db.wordDao.findWordByCanonicalKey(key);
    if (existing != null) {
      final existingDeck = await db.deckDao.getDeckById(existing.deckId);
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text(
              existingDeck == null
                  ? dialogContext.tr('该单词已存在，未重复添加')
                  : dialogContext.trArgs(
                      '该单词已存在于词书「{0}」，未重复添加', [existingDeck.name]),
            ),
          ),
        );
      }
      return;
    }

    final now = DateTime.now();
    await db.wordDao.createWord(
      WordsCompanion(
        deckId: drift.Value(widget.deckId),
        german: drift.Value(german),
        chinese: drift.Value(chineseController.text.trim()),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
    );

    // 刷新词书管理页的单词数量缓存
    ref.invalidate(wordCountProvider);

    if (dialogContext.mounted) {
      Navigator.pop(dialogContext);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trArgs('已添加 "{0}"', [german]))),
      );
    }
  }

  void _navigateToDetail(int wordId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordDetailScreen(wordId: wordId),
      ),
    );
  }

  /// 打开数据管理页面（AI 释义状态查看与一键重试）
  void _openDataManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AiDataManagementScreen(deckId: widget.deckId),
      ),
    );
  }

  /// 打开去重扫描页面（合并词书内重复单词）
  void _openDedupScan() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordDedupScreen(deckId: widget.deckId),
      ),
    );
  }

  /// 重置学习进度：黄色警告弹窗二次确认后，将所有单词学习状态全部归零
  Future<void> _confirmResetLearningProgress() async {
    final db = ref.read(databaseProvider);
    if (db == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.amber.shade50,
        icon: const Icon(
          Icons.warning_amber_rounded,
          size: 40,
          color: Colors.amber,
        ),
        title: Text(dialogContext.tr('重置学习进度')),
        content: Text(
          dialogContext.tr(
            '确定要将所有单词的学习进度全部归零吗？\n\n'
            'SM-2 复习状态、熟练度与上次学习日期将被清除，'
            '所有单词将变回新词状态。此操作不可恢复！',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.tr('取消')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.tr('确认重置')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await db.resetAllLearningProgress();
    // 刷新学习计划与主页进度卡（SM-2 数据已变化）
    ref.invalidate(studyPlanProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('已重置所有单词的学习进度'))),
      );
    }
  }

  void _enterMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = true;
    });
  }

  void _enterMultiSelectModeAndSelect(int wordId) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedWordIds.add(wordId);
    });
  }

  void _exitMultiSelectMode() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedWordIds.clear();
    });
  }

  void _toggleWordSelection(int wordId) {
    setState(() {
      if (_selectedWordIds.contains(wordId)) {
        _selectedWordIds.remove(wordId);
        if (_selectedWordIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedWordIds.add(wordId);
      }
    });
  }

  void _selectAll() {
    final wordsAsync = ref.read(wordsByDeckProvider(widget.deckId));
    wordsAsync.whenData((words) {
      setState(() {
        if (_selectedWordIds.length == words.length) {
          // 已全选，则取消全选
          _selectedWordIds.clear();
        } else {
          // 全选
          _selectedWordIds.clear();
          _selectedWordIds.addAll(words.map((w) => w.id));
        }
      });
    });
  }

  void _batchUpdateSelectedWords() {
    if (_selectedWordIds.isEmpty) return;

    final selectedIds = _selectedWordIds.toList();
    // 退出多选模式
    _exitMultiSelectMode();

    // 显示确认对话框并启动批量更新
    _startAiUpdateWithConfirm(
      wordIds: selectedIds,
      message: context.trArgs(
          '确定要使用 AI 更新选中的 {0} 个单词的词意吗？\n这将覆盖原有的中文释义。',
          [selectedIds.length]),
    );
  }

  /// 单词行三点菜单：AI 更新单个单词词意
  Future<void> _aiUpdateWord(Word word) {
    return _startAiUpdateWithConfirm(
      wordIds: [word.id],
      message: context.trArgs(
          '确定要使用 AI 更新 "{0}" 的词意吗？\n这将覆盖原有的中文释义。',
          [word.german]),
    );
  }

  /// 从 AI 查词缓存中解析出该单词的规范化德语词形（result.word）
  ///
  /// OCR 导入的单词可能未规范化，AI 查词结果中的 word 为规范词形。
  /// 优先按当前德语查找缓存；批量 AI 更新后缓存以规范化词形为键，回退 baseForm 查找。
  Future<String?> _getAiNormalizedWord(AppDatabase db, Word word) async {
    var cached = await db.aiCacheDao.getCachedResult(word.german);
    cached ??= (word.baseForm != null &&
            word.baseForm!.trim().isNotEmpty &&
            word.baseForm != word.german)
        ? await db.aiCacheDao.getCachedResult(word.baseForm!)
        : null;
    if (cached == null) return null;
    try {
      final result =
          AIDictionaryEngine.parseResult(word.german, cached.resultJson);
      final normalized = result.word.trim();
      return normalized.isEmpty ? null : normalized;
    } catch (e) {
      debugPrint('AI 缓存解析失败: $e');
      return null;
    }
  }

  /// 将 AI 规范化词形写回 words.german 与 baseForm，并为旧词形写删除墓碑
  /// （使改名跨端传播，避免对端同步把旧词形带回来）
  Future<void> _applyAiNormalizedWord(AppDatabase db, Word word,
      String normalized) async {
    await db.renameWordGerman(word.id, normalized);
  }

  /// 单词行三点菜单：AI 规范化德语词形（与编辑界面的德语保持一致）
  Future<void> _normalizeGermanWithAi(Word word) async {
    final db = ref.read(databaseProvider);
    if (db == null) return;

    final normalized = await _getAiNormalizedWord(db, word);
    if (normalized == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(context.tr('该单词暂无 AI 查词结果，请先使用 AI 更新词义'))),
        );
      }
      return;
    }

    if (normalized == word.german.trim()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('德语已与 AI 词形一致'))),
        );
      }
      return;
    }

    // 确认对话框
    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('AI 规范化德语')),
        content: Text(dialogContext.trArgs(
          '将德语从「{0}」更新为 AI 规范化词形「{1}」？\n\n'
          '此操作会同步单词本与编辑界面中的德语单词。',
          [word.german, normalized],
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.tr('取消')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.tr('确定')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await _applyAiNormalizedWord(db, word, normalized);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trArgs('已将德语更新为 "{0}"', [normalized]))),
      );
    }
  }

  /// 批量 AI 规范化德语：扫描词书中所有单词的 AI 查词结果，
  /// 将德语更新为 AI 规范化词形（无 AI 缓存的单词自动跳过）
  Future<void> _batchNormalizeGerman() async {
    final db = ref.read(databaseProvider);
    if (db == null) return;

    final wordsAsync = ref.read(wordsByDeckProvider(widget.deckId));
    final words = wordsAsync.value ?? const <Word>[];
    if (words.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('词书还没有单词'))),
        );
      }
      return;
    }

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('批量 AI 规范化德语')),
        content: Text(dialogContext.trArgs(
          '将批量扫描词书中 {0} 个单词的 AI 查词结果，'
          '把德语更新为 AI 规范化词形（无 AI 缓存的单词自动跳过）。',
          [words.length],
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.tr('取消')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.tr('确定')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    var updated = 0;
    var skipped = 0;
    for (final word in words) {
      final normalized = await _getAiNormalizedWord(db, word);
      if (normalized == null) {
        skipped++;
        continue;
      }
      if (normalized == word.german.trim()) continue;
      await _applyAiNormalizedWord(db, word, normalized);
      updated++;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updated > 0
                ? context.trArgs('已规范化 {0} 个单词的德语', [updated])
                : context.trArgs(
                    '没有需要规范化的单词（{0} 个暂无 AI 缓存）', [skipped]),
          ),
        ),
      );
    }
  }

  /// 弹出 AI 更新确认对话框并启动批量更新任务（单/多词共用入口，可后台运行）
  Future<void> _startAiUpdateWithConfirm({
    required List<int> wordIds,
    required String message,
  }) async {
    final db = ref.read(databaseProvider);
    final aiEngine = ref.read(aiDictionaryEngineProvider);

    if (db == null || aiEngine == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('请先在设置中配置 AI API Key'))),
        );
      }
      return;
    }

    // 显示确认对话框
    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('AI 更新词意')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('取消')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('确定')),
          ),
        ],
      ),
    );

    if (shouldUpdate != true || !mounted) return;

    // 获取单词的德语文本（用于标记队列中的单词，避免详情页重复触发AI查询）
    final selectedWords = <String>[];
    for (final id in wordIds) {
      final word = await db.wordDao.getWordById(id);
      if (word != null) selectedWords.add(word.german);
    }

    if (!mounted) return;

    final batchService = BatchAIService(
      db,
      aiEngine,
      concurrency: ref.read(settingsProvider).aiConcurrency,
    );
    final notifier = ref.read(batchUpdateProvider.notifier);

    // 开始批量更新（关闭窗口可后台运行）
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => BatchUpdateDialog(
        batchService: batchService,
        wordIds: wordIds,
        words: selectedWords,
        notifier: notifier,
        taskName: context.trArgs('AI 更新 {0} 个单词', [wordIds.length]),
      ),
    );
  }

  /// 单词行三点菜单：删除单词
  ///
  /// 删除后若任何词书都不再存在该单词，将同时释放其 AI 释义缓存与请求状态。
  Future<void> _deleteWord(Word word) async {
    final db = ref.read(databaseProvider);
    if (db == null) return;

    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('删除单词')),
        content: Text(dialogContext.trArgs(
          '确定要删除 "{0}" 吗？\n\n'
          '删除后不可恢复。若其他词书也不存在该单词，将同时释放其 AI 释义缓存。',
          [word.german],
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(dialogContext.tr('取消')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(dialogContext.tr('删除')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await db.deleteWordWithCleanup(word.id);
    // 刷新词书管理页的单词数量缓存
    ref.invalidate(wordCountProvider);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trArgs('已删除 "{0}"', [word.german]))),
      );
    }
  }

  /// 单词行三点菜单：复制到其他词书（复制全部字段、变位缓存与学习状态，共享 AI 查词缓存）
  Future<void> _copyWordToDeck(Word word) async {
    final db = ref.read(databaseProvider);
    if (db == null) return;

    final decks = ref.read(allDecksProvider).value ?? const <Deck>[];
    final targets = decks.where((d) => d.id != widget.deckId).toList();
    if (targets.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('没有其他词书可复制，请先新建词书'))),
        );
      }
      return;
    }

    // 选择目标词书
    final targetDeckId = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('复制到词书')),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: targets.length,
            itemBuilder: (context, index) {
              final deck = targets[index];
              return ListTile(
                leading: const Icon(Icons.library_books),
                title: Text(deck.name),
                trailing: deck.isActive
                    ? const Icon(Icons.check_circle,
                        size: 18, color: Colors.green)
                    : null,
                onTap: () => Navigator.pop(context, deck.id),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('取消')),
          ),
        ],
      ),
    );
    if (targetDeckId == null || !mounted) return;

    final newId = await db.copyWordToDeck(word.id, targetDeckId);
    if (!mounted) return;

    if (newId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('该单词已在目标词书中'))),
      );
      return;
    }

    // 刷新词书管理页的单词数量缓存
    ref.invalidate(wordCountProvider);

    final targetName = targets
        .firstWhere((d) => d.id == targetDeckId, orElse: () => targets.first)
        .name;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.trArgs('已复制到「{0}」', [targetName]))),
    );
  }

  void _showFilterDialog() {
    // 词性筛选项：value 为 null 表示「全部」
    final options = <(String label, String? value, Color? color)>[
      ('全部', null, null),
      ('名词', 'noun', Colors.blue),
      ('动词', 'verb', WordTypeColors.verbPrimary),
      ('形容词', 'adjective', WordTypeColors.adjPrimary),
      ('副词', 'adverb', WordTypeColors.advPrimary),
      ('介词', 'preposition', WordTypeColors.prepPrimary),
      ('代词', 'pronoun', WordTypeColors.pronPrimary),
      ('连词', 'conjunction', WordTypeColors.conjPrimary),
      ('其他', 'other', WordTypeColors.otherPrimary),
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.tr('筛选词性')),
          // 9 个选项约 500dp 高，小屏上不加滚动会直接溢出
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (label, value, color) in options)
                  _FilterOption(
                    label: label,
                    value: value,
                    groupValue: _filterWordType,
                    color: color,
                    onChanged: (selected) {
                      setState(() => _filterWordType = selected);
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WordTile extends ConsumerWidget {
  final Word word;
  final ConjugationCacheData? cache;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback onAiUpdate;
  final VoidCallback onCopyToDeck;
  final VoidCallback onNormalizeGerman;
  final VoidCallback? onDelete;

  const _WordTile({
    required this.word,
    required this.onTap,
    this.cache,
    this.onLongPress,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    required this.onAiUpdate,
    required this.onCopyToDeck,
    required this.onNormalizeGerman,
    this.onDelete,
  });

  /// 解析变格缓存并生成摘要文本（缓存优先，回退 words 表字段）
  String? _inflectionSummary() {
    Map<String, dynamic>? inflection;
    final cacheJson = cache?.conjugationJson;
    if (cacheJson != null && cacheJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(cacheJson);
        if (decoded is Map<String, dynamic>) {
          inflection = decoded;
        }
      } catch (_) {}
    }
    return Inflection.summary(
      wordType: word.wordType,
      inflection: inflection,
      verbPresent: word.verbPresent,
      verbPast: word.verbPast,
      verbPerfect: word.verbPerfect,
      nounGenitive: word.nounGenitive,
      nounPlural: word.nounPlural,
      adjComparative: word.adjComparative,
      adjSuperlative: word.adjSuperlative,
    );
  }

  /// 变格摘要行（无数据时返回空组件）
  Widget buildInflectionSubtitle(BuildContext context) {
    final summary = _inflectionSummary();
    if (summary == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        summary,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genderColor = GenderColors.forArticle(word.article);

    return ListTile(
      leading: isMultiSelectMode
          ? Checkbox(
              value: isSelected,
              onChanged: (_) => onTap(),
            )
          : Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: word.article != null
                    ? genderColor.withValues(alpha: 0.1)
                    : WordTypeColors.forWordType(word.wordType)
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: word.article != null
                    ? Text(
                        word.article!,
                        style: TextStyle(
                          color: genderColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : Text(
                        WordTypeColors.getWordTypeLabel(word.wordType),
                        style: TextStyle(
                          color: WordTypeColors.forWordType(word.wordType),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              word.german,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
          ),
          if (!isMultiSelectMode)
            WordTypeChip(
              wordType: word.wordType,
              article: word.article,
              compact: true,
              showLabel: false,
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            word.chinese,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // 变格摘要（动词三态 / 名词第二格·复数 / 形容词比较级·最高级）
          if (!isMultiSelectMode) ...[buildInflectionSubtitle(context)],
        ],
      ),
      trailing: isMultiSelectMode
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 熟练度显示
                if (word.proficiency > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      word.proficiency.clamp(0, 5),
                      (index) => const Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 20),
                // 三点菜单：AI 更新词义 / 复制到词书
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  tooltip: context.tr('更多操作'),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    switch (value) {
                      case 'ai_update':
                        onAiUpdate();
                        break;
                      case 'normalize_german':
                        onNormalizeGerman();
                        break;
                      case 'copy_to_deck':
                        onCopyToDeck();
                        break;
                      case 'delete_word':
                        onDelete?.call();
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'ai_update',
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 18),
                          const SizedBox(width: 8),
                          Text(context.tr('AI更新词义')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'normalize_german',
                      child: Row(
                        children: [
                          const Icon(Icons.auto_fix_high, size: 18),
                          const SizedBox(width: 8),
                          Text(context.tr('AI规范化德语')),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'copy_to_deck',
                      child: Row(
                        children: [
                          const Icon(Icons.content_copy, size: 18),
                          const SizedBox(width: 8),
                          Text(context.tr('复制到词书')),
                        ],
                      ),
                    ),
                    if (onDelete != null)
                      PopupMenuItem(
                        value: 'delete_word',
                        child: Row(
                          children: [
                            const Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(context.tr('删除单词'),
                                style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
      onTap: onTap,
      onLongPress: onLongPress,
      selected: isSelected,
    );
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final String? value;
  final String? groupValue;
  final ValueChanged<String?> onChanged;
  final Color? color;

  const _FilterOption({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: RadioGroup<String?>(
        groupValue: groupValue,
        onChanged: onChanged,
        child: Radio<String?>(value: value),
      ),
      title: Row(
        children: [
          if (color != null) ...[
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(context.tr(label)),
        ],
      ),
      onTap: () => onChanged(value),
    );
  }
}