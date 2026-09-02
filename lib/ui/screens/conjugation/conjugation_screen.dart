import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/batch_update_provider.dart';
import '../../../providers/conjugation_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/deck_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/ai/batch_ai_service.dart';
import '../../../services/ai/conjugation_service.dart';
import '../../../ui/widgets/batch_task_widgets.dart';
import 'conjugation_drill.dart';
import 'conjugation_data_manager_screen.dart';

/// 变位练习主界面（入口页）
///
/// - 单次练习词量设置（10/20/50/自定义，持久化到数据库）
/// - 三大类练习：动词变位 / 名词变格 / 形容词变级
/// - 每类展开后可选择具体的二级子项（时态/语法点）
class ConjugationScreen extends ConsumerStatefulWidget {
  const ConjugationScreen({super.key});

  @override
  ConsumerState<ConjugationScreen> createState() => _ConjugationScreenState();
}

class _ConjugationScreenState extends ConsumerState<ConjugationScreen> {
  static const _countKey = 'practiceWordCount';
  static const _pickModeKey = 'practicePickMode';
  static const _presetCounts = [10, 20, 50];

  int _wordCount = 10;
  ConjugationPickMode _pickMode = ConjugationPickMode.random;

  @override
  void initState() {
    super.initState();
    _loadWordCount();
    _loadPickMode();
  }

  /// 从数据库加载练习词量设置
  Future<void> _loadWordCount() async {
    final db = ref.read(databaseProvider);
    final value = await db?.getSetting(_countKey);
    final parsed = int.tryParse(value ?? '');
    if (parsed != null && parsed > 0 && mounted) {
      setState(() => _wordCount = parsed);
    }
  }

  /// 保存练习词量设置
  Future<void> _setWordCount(int count) async {
    if (count <= 0) return;
    setState(() => _wordCount = count);
    final db = ref.read(databaseProvider);
    try {
      await db?.setSetting(_countKey, count.toString());
    } catch (e) {
      debugPrint('保存练习词量失败: $e');
    }
  }

  /// 从数据库加载练习范围设置
  Future<void> _loadPickMode() async {
    final db = ref.read(databaseProvider);
    final value = await db?.getSetting(_pickModeKey);
    final parsed = ConjugationPickMode.values.asNameMap()[value];
    if (parsed != null && mounted) {
      setState(() => _pickMode = parsed);
    }
  }

  /// 保存练习范围设置
  Future<void> _setPickMode(ConjugationPickMode mode) async {
    setState(() => _pickMode = mode);
    final db = ref.read(databaseProvider);
    try {
      await db?.setSetting(_pickModeKey, mode.name);
    } catch (e) {
      debugPrint('保存练习范围失败: $e');
    }
  }

  /// 自定义词量对话框
  Future<void> _showCustomCountDialog() async {
    final controller = TextEditingController(text: _wordCount.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('自定义单次练习词量'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '单词数量',
            hintText: '请输入正整数',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final count = int.tryParse(controller.text.trim());
              if (count != null && count > 0) {
                Navigator.pop(context, count);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入有效的正整数')),
                );
              }
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) {
      await _setWordCount(result);
    }
  }

  /// 启动指定模式的练习
  Future<void> _startDrill(BuildContext context, PracticeMode mode) async {
    final activeDeck = ref.read(activeDeckProvider).valueOrNull;
    if (activeDeck == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一个词书')),
      );
      return;
    }

    final notifier = ref.read(conjugationDrillProvider.notifier);
    await notifier.loadDrill(
      deckId: activeDeck.id,
      mode: mode,
      limit: _wordCount,
      pickMode: _pickMode,
    );

    if (!context.mounted) return;
    final state = ref.read(conjugationDrillProvider);
    if (state.questions.isEmpty) {
      if (_pickMode == ConjugationPickMode.todayOnly) {
        // 只练今日单词：优先提示今日未学习，而非词书缺数据
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('今日还没有学习过的单词，请先在学习模式中学习')),
        );
        return;
      }
      // 动词时态与形容词变级需要 AI 生成的变位数据
      final needsGeneratedData =
          mode.isVerbTense || mode.id == 'adj_steigerung';
      final hint = needsGeneratedData
          ? '，请先在下方"变位数据管理"中生成变位数据'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('词书中没有可练习的${mode.title}数据$hint')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ConjugationDrillScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeDeck = ref.watch(activeDeckProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('变位练习'),
        actions: [
          // 后台 AI 任务入口
          const BatchTaskProgressButton(),
        ],
      ),
      body: activeDeck.when(
        data: (deck) {
          if (deck == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '请先选择一个词书',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 词书信息
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.library_books,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '当前词书',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            Text(
                              deck.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 练习参数：单次练习词量
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tune,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '练习参数',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '单次练习词量',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<int>(
                        segments: [
                          for (final count in _presetCounts)
                            ButtonSegment(
                              value: count,
                              label: Text('$count 个'),
                            ),
                          const ButtonSegment(
                            value: -1,
                            label: Text('自定义'),
                          ),
                        ],
                        selected: {
                          if (_presetCounts.contains(_wordCount))
                            _wordCount
                          else
                            -1,
                        },
                        onSelectionChanged: (selection) {
                          final value = selection.first;
                          if (value == -1) {
                            _showCustomCountDialog();
                          } else {
                            _setWordCount(value);
                          }
                        },
                      ),
                      if (!_presetCounts.contains(_wordCount)) ...[
                        const SizedBox(height: 8),
                        Text(
                          '当前: $_wordCount 个',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color:
                                    Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text(
                        '练习范围',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<ConjugationPickMode>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: ConjugationPickMode.random,
                            label: Text('随机练习'),
                          ),
                          ButtonSegment(
                            value: ConjugationPickMode.todayOnly,
                            label: Text('只练今日单词'),
                          ),
                        ],
                        selected: {_pickMode},
                        onSelectionChanged: (selection) {
                          _setPickMode(selection.first);
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _pickMode == ConjugationPickMode.todayOnly
                            ? '仅从今天学习过的单词中抽取'
                            : '从整个词书随机抽取',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
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
              const SizedBox(height: 24),
              // 练习类型
              Text(
                '选择练习类型',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              // 动词变位
              _CategorySection(
                icon: Icons.directions_run,
                title: '动词变位',
                subtitle: 'Verb Konjugation',
                color: Theme.of(context).colorScheme.primaryContainer,
                iconColor: Theme.of(context).colorScheme.primary,
                modes: PracticeMode.allVerbModes,
                onModeTap: (mode) => _startDrill(context, mode),
              ),
              const SizedBox(height: 12),
              // 名词变格
              _CategorySection(
                icon: Icons.category,
                title: '名词变格',
                subtitle: 'Nomen Deklination',
                color: Theme.of(context).colorScheme.secondaryContainer,
                iconColor: Theme.of(context).colorScheme.secondary,
                modes: PracticeMode.allNounModes,
                onModeTap: (mode) => _startDrill(context, mode),
              ),
              const SizedBox(height: 12),
              // 形容词变级（无二级子项，点击直接进入：比较级 + 最高级）
              _CategorySection(
                icon: Icons.trending_up,
                title: '形容词变级',
                subtitle: 'Adjektiv Steigerung · 比较级 & 最高级',
                color: Theme.of(context).colorScheme.tertiaryContainer,
                iconColor: Theme.of(context).colorScheme.tertiary,
                directMode: PracticeMode.adjSteigerung,
                onModeTap: (mode) => _startDrill(context, mode),
              ),
              const SizedBox(height: 24),
              // 变位数据管理
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '变位数据管理',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.manage_search,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: const Text(
                          '管理变位数据',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text('查看各单词变位数据状态，可多选更新 / 删除'),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                        ),
                        onTap: () => _openDataManager(context, deck.id),
                      ),
                      const Divider(),
                      const SizedBox(height: 4),
                      OutlinedButton.icon(
                        onPressed: () => _generateConjugationData(context),
                        icon: const Icon(Icons.auto_awesome),
                        label: const Text('AI 批量生成变位数据'),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '使用 AI 分析词书中的词汇，生成变位数据并缓存到本地',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
      ),
    );
  }

  /// 打开变位数据管理页
  void _openDataManager(BuildContext context, int deckId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConjugationDataManagerScreen(deckId: deckId),
      ),
    );
  }

  Future<void> _generateConjugationData(BuildContext context) async {
    final conjugationService = ref.read(conjugationServiceProvider);
    final activeDeck = ref.read(activeDeckProvider).valueOrNull;

    if (conjugationService == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先在设置中配置 AI API Key')),
        );
      }
      return;
    }

    if (activeDeck == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先选择一个词书')),
        );
      }
      return;
    }

    // 显示生成进度对话框（关闭后可后台运行，可从右上角任务按钮查看进度）
    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) => _GenerateProgressDialog(
          service: conjugationService,
          deckId: activeDeck.id,
          concurrency: ref.read(settingsProvider).aiConcurrency,
          notifier: ref.read(batchUpdateProvider.notifier),
          onDone: () =>
              ref.invalidate(deckConjugationCacheProvider(activeDeck.id)),
        ),
      );
    }
  }
}

/// 词书变位数据生成进度对话框
///
/// 仅生成尚无变位缓存的单词；关闭窗口后任务转入后台继续运行，
/// 可从页面右上角的任务按钮查看进度。
class _GenerateProgressDialog extends ConsumerStatefulWidget {
  final ConjugationService service;
  final int deckId;
  final int concurrency;
  final BatchUpdateNotifier notifier;
  /// 任务完成后刷新变位缓存的回调（由父级传入，规避对话框关闭后 ref 失效）
  final VoidCallback onDone;

  const _GenerateProgressDialog({
    required this.service,
    required this.deckId,
    required this.concurrency,
    required this.notifier,
    required this.onDone,
  });

  @override
  ConsumerState<_GenerateProgressDialog> createState() =>
      _GenerateProgressDialogState();
}

class _GenerateProgressDialogState
    extends ConsumerState<_GenerateProgressDialog> {
  int _total = 0;
  int _completed = 0;
  int _failed = 0;
  String? _currentWord;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    // 延迟到 widget 树构建完成后启动，避免在构建期间修改状态
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    // 统计需要生成（尚无缓存）的单词数量
    final db = ref.read(databaseProvider);
    if (db == null) {
      if (mounted) {
        setState(() => _isComplete = true);
      }
      return;
    }
    final words = await db.wordDao.getWordsByDeck(widget.deckId);
    final cachedIds = await db.conjugationDao.getCachedWordIds();
    final uncached = words.where((w) => !cachedIds.contains(w.id)).toList();
    _total = uncached.length;

    if (_total == 0) {
      if (mounted) setState(() => _isComplete = true);
      return;
    }

    // 创建后台任务记录（携带单词列表，供其它界面检测进行中的任务）
    final taskId = widget.notifier.addTask(
      'AI 生成变位数据（${uncached.length} 个单词）',
      _total,
      words: uncached.map((w) => w.german).toList(),
    );
    widget.notifier.startTask(taskId);

    try {
      // 进度同步到全局任务状态，对话框关闭（后台运行）后任务仍继续执行
      await widget.service.generateForDeck(
        widget.deckId,
        concurrency: widget.concurrency,
        onProgress: (completed, failed, currentWord) {
          widget.notifier.updateProgress(
            taskId,
            BatchUpdateProgress(
              total: _total,
              completed: completed,
              failed: failed,
              currentWord: currentWord,
              isRunning: true,
            ),
          );
          if (!mounted) return;
          setState(() {
            _completed = completed;
            _failed = failed;
            _currentWord = currentWord;
          });
        },
      );

      // 不依赖 mounted：对话框关闭后任务仍在后台运行；
      // 最后一次进度回调即最终结果，完成时通过父级回调刷新变位缓存
      widget.notifier.completeTask(
        taskId,
        BatchUpdateProgress(
          total: _total,
          completed: _completed,
          failed: _failed,
          currentWord: null,
          isRunning: false,
        ),
      );
      try {
        widget.onDone();
      } catch (_) {
        // 父级页面已销毁时刷新缓存无意义，忽略且不把任务误判为失败
      }
      if (mounted) setState(() => _isComplete = true);
    } catch (e) {
      widget.notifier.failTask(taskId, e.toString());
      if (mounted) {
        setState(() {
          _isComplete = true;
          _failed = _total;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _isComplete && _total == 0;
    return AlertDialog(
      title: Text(
        isEmpty ? '无需生成' : (_isComplete ? '生成完成' : 'AI 生成变位数据'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isComplete) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 16),
            Text('$_total 个单词需要生成'),
            const SizedBox(height: 8),
            if (_currentWord != null) ...[
              Text(
                '正在处理: $_currentWord',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              '关闭窗口可后台运行',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ] else ...[
            Icon(
              isEmpty ? Icons.info_outline : Icons.check_circle,
              size: 48,
              color: isEmpty ? Colors.grey : Colors.green,
            ),
            const SizedBox(height: 16),
            if (isEmpty)
              const Text('所有单词已有变位数据')
            else
              Text(
                '成功 $_completed 个${_failed > 0 ? '，失败 $_failed 个' : ''}',
              ),
          ],
        ],
      ),
      actions: [
        if (_isComplete)
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

/// 大类卡片：
/// - 有二级子项时：点击展开子项列表
/// - 无二级子项（[directMode] 非空）时：整卡点击直接进入对应练习
class _CategorySection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;
  final List<PracticeMode> modes;
  final PracticeMode? directMode; // 无子项时直接进入的模式
  final ValueChanged<PracticeMode> onModeTap;

  const _CategorySection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
    required this.onModeTap,
    this.modes = const [],
    this.directMode,
  });

  @override
  Widget build(BuildContext context) {
    // 无二级子项：整卡点击直接进入练习
    if (directMode != null) {
      return Card(
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          title: Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => onModeTap(directMode!),
        ),
      );
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: iconColor),
        ),
        title: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        children: [
          const Divider(height: 1),
          for (final mode in modes)
            ListTile(
              leading: Icon(mode.icon, color: iconColor),
              title: Text(
                mode.title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(mode.subtitle),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => onModeTap(mode),
            ),
        ],
      ),
    );
  }
}
