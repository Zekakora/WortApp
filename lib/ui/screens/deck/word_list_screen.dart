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
import '../../../data/database/app_database.dart';
import '../../../services/ai/batch_ai_service.dart';
import '../../../services/dictionary/dictionary_engine.dart';
import '../../../ui/widgets/word_type_chip.dart';
import '../../../ui/widgets/batch_task_widgets.dart';
import 'word_detail_screen.dart';

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
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
      ),
      // 多选模式下隐藏，避免遮挡操作
      floatingActionButton: !_isMultiSelectMode
          ? FloatingActionButton.extended(
              onPressed: _showAddWordDialog,
              icon: const Icon(Icons.add),
              label: const Text('新建单词'),
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
      builder: (dialogContext) => _BatchUpdateDialog(
        batchService: batchService,
        wordIds: wordIds,
        words: selectedWords,
        notifier: notifier,
      ),
    );
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

  const _WordTile({
    required this.word,
    required this.onTap,
    this.cache,
    this.onLongPress,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    required this.onAiUpdate,
    required this.onCopyToDeck,
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
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'ai_update',
                      child: Row(
                        children: [
                          Icon(Icons.auto_awesome, size: 18),
                          SizedBox(width: 8),
                          Text('AI更新词义'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'copy_to_deck',
                      child: Row(
                        children: [
                          Icon(Icons.content_copy, size: 18),
                          SizedBox(width: 8),
                          Text('复制到词书'),
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

/// 批量更新进度对话框
class _BatchUpdateDialog extends StatefulWidget {
  final BatchAIService batchService;
  final List<int> wordIds;
  final List<String> words;
  final BatchUpdateNotifier notifier;

  const _BatchUpdateDialog({
    required this.batchService,
    required this.wordIds,
    required this.words,
    required this.notifier,
  });

  @override
  State<_BatchUpdateDialog> createState() => _BatchUpdateDialogState();
}

class _BatchUpdateDialogState extends State<_BatchUpdateDialog> {
  BatchUpdateProgress? _progress;
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();
    // 延迟到widget树构建完成后启动，避免在构建期间修改provider状态
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startUpdate();
      }
    });
  }

  Future<void> _startUpdate() async {
    setState(() {
      _isStarted = true;
    });

    // 创建任务记录（携带单词列表，供详情页检测队列中的单词）
    final taskId = widget.notifier.addTask(
      'AI 更新 ${widget.wordIds.length} 个单词',
      widget.wordIds.length,
      words: widget.words,
    );
    widget.notifier.startTask(taskId);

    try {
      final progress = await widget.batchService.updateWordsMeaningByIds(
        wordIds: widget.wordIds,
        onProgress: (progress) {
          // 无论对话框是否关闭（含后台运行）都同步全局任务状态，
          // 保证任务列表/进度按钮实时更新；setState 仅限界面存活时
          widget.notifier.updateProgress(taskId, progress);
          if (mounted) {
            setState(() {
              _progress = progress;
            });
          }
        },
      );

      // 同样不依赖 mounted：对话框关闭后任务仍在后台运行
      widget.notifier.completeTask(taskId, progress);
      if (mounted) {
        setState(() {
          _progress = progress;
        });
      }
    } catch (e) {
      widget.notifier.failTask(taskId, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress;

    return AlertDialog(
      title: Text(progress?.isComplete == true ? '更新完成' : 'AI 更新词意'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (progress == null || !_isStarted) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('准备中...'),
          ] else if (!progress.isComplete) ...[
            LinearProgressIndicator(value: progress.progress),
            const SizedBox(height: 16),
            Text('${progress.completed}/${progress.total}'),
            if (progress.currentWord != null) ...[
              const SizedBox(height: 8),
              Text(
                '正在处理: ${progress.currentWord}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '关闭窗口可后台运行',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ] else ...[
            const Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            Text('成功更新: ${progress.completed} 个单词'),
            if (progress.failed > 0)
              Text('失败: ${progress.failed} 个单词',
                  style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
      actions: [
        if (progress?.isComplete == true || !_isStarted)
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('完成'),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('后台运行'),
          ),
      ],
    );
  }
}