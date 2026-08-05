import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
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
import '../../../ui/widgets/word_type_chip.dart';
import '../../../ui/widgets/batch_task_widgets.dart';
import '../../../ui/widgets/batch_update_dialog.dart';
import 'word_detail_screen.dart';
import 'ai_data_management_screen.dart';

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
            ? Text('已选择 ${_selectedWordIds.length} 项')
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
              tooltip: '全选',
            ),
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: _selectedWordIds.isNotEmpty ? _batchUpdateSelectedWords : null,
              tooltip: 'AI 更新词意',
            ),
          ] else ...[
            // AI查询任务按钮（始终可见）
            const BatchTaskProgressButton(),
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _enterMultiSelectMode,
              tooltip: '多选',
            ),
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: _showFilterDialog,
              tooltip: '筛选',
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
                      hintText: '搜索单词...',
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
                    _searchQuery.isEmpty ? '词书还没有单词' : '没有找到匹配的单词',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            // 非多选模式下预留底部空间，避免被新建按钮遮挡
            padding: EdgeInsets.only(bottom: _isMultiSelectMode ? 0 : 88),
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
                onDelete: () => _deleteWord(word),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
      ),
      // 多选模式下隐藏，避免遮挡操作
      floatingActionButton: !_isMultiSelectMode
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // 重置学习进度（所有单词 SM-2 状态归零）
                FloatingActionButton.small(
                  heroTag: 'resetProgressFab',
                  onPressed: _confirmResetLearningProgress,
                  tooltip: '重置学习进度',
                  child: const Icon(Icons.restart_alt),
                ),
                const SizedBox(height: 12),
                // 数据管理（AI 释义状态查看与一键重试）
                FloatingActionButton.small(
                  heroTag: 'aiDataManageFab',
                  onPressed: _openDataManagement,
                  tooltip: '数据管理',
                  child: const Icon(Icons.storage),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'addWordFab',
                  onPressed: _showAddWordDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('新建单词'),
                ),
              ],
            )
          : null,
    );
  }

  /// 新建单词：仅输入德语单词即可创建，中文释义可留空
  void _showAddWordDialog() {
    final germanController = TextEditingController();
    final chineseController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('新建单词'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: germanController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: '德语单词 *',
                hintText: '例如：der Apfel',
              ),
              onSubmitted: (_) =>
                  _createWord(dialogContext, germanController, chineseController),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: chineseController,
              decoration: const InputDecoration(
                labelText: '中文释义（可留空，稍后 AI 自动获取）',
                hintText: '例如：苹果',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                _createWord(dialogContext, germanController, chineseController),
            child: const Text('添加'),
          ),
        ],
      ),
    );
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

    // 词书内查重
    final existing = await db.wordDao.findWordByGerman(widget.deckId, german);
    if (existing != null) {
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(content: Text('该单词已在词书中')),
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
        SnackBar(content: Text('已添加 "$german"')),
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
        title: const Text('重置学习进度'),
        content: const Text(
          '确定要将所有单词的学习进度全部归零吗？\n\n'
          'SM-2 复习状态、熟练度与上次学习日期将被清除，'
          '所有单词将变回新词状态。此操作不可恢复！',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.amber.shade700,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('确认重置'),
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
        const SnackBar(content: Text('已重置所有单词的学习进度')),
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
      message:
          '确定要使用 AI 更新选中的 ${selectedIds.length} 个单词的词意吗？\n这将覆盖原有的中文释义。',
    );
  }

  /// 单词行三点菜单：AI 更新单个单词词意
  Future<void> _aiUpdateWord(Word word) {
    return _startAiUpdateWithConfirm(
      wordIds: [word.id],
      message: '确定要使用 AI 更新 "${word.german}" 的词意吗？\n这将覆盖原有的中文释义。',
    );
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
          const SnackBar(content: Text('请先在设置中配置 AI API Key')),
        );
      }
      return;
    }

    // 显示确认对话框
    final shouldUpdate = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI 更新词意'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
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
        taskName: 'AI 更新 ${wordIds.length} 个单词',
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
        title: const Text('删除单词'),
        content: Text(
          '确定要删除 "${word.german}" 吗？\n\n'
          '删除后不可恢复。若其他词书也不存在该单词，将同时释放其 AI 释义缓存。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('删除'),
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
        SnackBar(content: Text('已删除 "${word.german}"')),
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
          const SnackBar(content: Text('没有其他词书可复制，请先新建词书')),
        );
      }
      return;
    }

    // 选择目标词书
    final targetDeckId = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('复制到词书'),
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
            child: const Text('取消'),
          ),
        ],
      ),
    );
    if (targetDeckId == null || !mounted) return;

    final newId = await db.copyWordToDeck(word.id, targetDeckId);
    if (!mounted) return;

    if (newId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该单词已在目标词书中')),
      );
      return;
    }

    // 刷新词书管理页的单词数量缓存
    ref.invalidate(wordCountProvider);

    final targetName = targets
        .firstWhere((d) => d.id == targetDeckId, orElse: () => targets.first)
        .name;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制到「$targetName」')),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('筛选词性'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _FilterOption(
                label: '全部',
                value: null,
                groupValue: _filterWordType,
                onChanged: (value) {
                  setState(() => _filterWordType = value);
                  Navigator.pop(context);
                },
              ),
              _FilterOption(
                label: '名词',
                value: 'noun',
                groupValue: _filterWordType,
                onChanged: (value) {
                  setState(() => _filterWordType = value);
                  Navigator.pop(context);
                },
                color: Colors.blue,
              ),
              _FilterOption(
                label: '动词',
                value: 'verb',
                groupValue: _filterWordType,
                onChanged: (value) {
                  setState(() => _filterWordType = value);
                  Navigator.pop(context);
                },
                color: WordTypeColors.verbPrimary,
              ),
              _FilterOption(
                label: '形容词',
                value: 'adjective',
                groupValue: _filterWordType,
                onChanged: (value) {
                  setState(() => _filterWordType = value);
                  Navigator.pop(context);
                },
                color: WordTypeColors.adjPrimary,
              ),
              _FilterOption(
                label: '副词',
                value: 'adverb',
                groupValue: _filterWordType,
                onChanged: (value) {
                  setState(() => _filterWordType = value);
                  Navigator.pop(context);
                },
                color: WordTypeColors.advPrimary,
              ),
            ],
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
                  tooltip: '更多操作',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    switch (value) {
                      case 'ai_update':
                        onAiUpdate();
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
                    const PopupMenuItem(
                      value: 'ai_update',
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 18),
                          SizedBox(width: 8),
                          Text('AI更新词义'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'copy_to_deck',
                      child: Row(
                        children: [
                          Icon(Icons.content_copy, size: 18),
                          SizedBox(width: 8),
                          Text('复制到词书'),
                        ],
                      ),
                    ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete_word',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('删除单词',
                                style: TextStyle(color: Colors.red)),
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
      leading: Radio<String?>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
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
          Text(label),
        ],
      ),
      onTap: () => onChanged(value),
    );
  }
}