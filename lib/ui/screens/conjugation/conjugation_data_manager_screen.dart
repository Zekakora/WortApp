import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/batch_update_provider.dart';
import '../../../providers/conjugation_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/deck_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/ai/batch_ai_service.dart';
import '../../../services/ai/conjugation_service.dart';
import '../../../ui/widgets/batch_task_widgets.dart';

/// 变位数据管理界面
///
/// 列出词书中所有单词及其变位数据状态：
/// - 普通模式：每个单词可单独「编辑」「AI 更新」或「删除」变位数据
/// - 多选模式：勾选多个单词后批量更新 / 删除
class ConjugationDataManagerScreen extends ConsumerStatefulWidget {
  final int deckId;

  const ConjugationDataManagerScreen({super.key, required this.deckId});

  @override
  ConsumerState<ConjugationDataManagerScreen> createState() =>
      _ConjugationDataManagerScreenState();
}

class _ConjugationDataManagerScreenState
    extends ConsumerState<ConjugationDataManagerScreen> {
  final Set<int> _selectedWordIds = {};
  bool _isMultiSelectMode = false;
  String? _wordTypeFilter; // null=全部

  // ── 多选模式控制 ──────────────────────────────

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

  void _selectAll(List<Word> words) {
    setState(() {
      if (_selectedWordIds.length == words.length) {
        _selectedWordIds.clear();
      } else {
        _selectedWordIds
          ..clear()
          ..addAll(words.map((w) => w.id));
      }
    });
  }

  // ── 更新操作 ──────────────────────────────────

  Future<void> _updateSelectedWords(List<Word> words) async {
    if (words.isEmpty) return;

    final service = ref.read(conjugationServiceProvider);
    if (service == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('请先在设置中配置 AI API Key'))),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('AI 更新变位数据')),
        content: Text(
          context.trArgs(
            '确定要使用 AI 重新生成选中的 {0} 个单词的变位数据吗？\n\n'
            '将覆盖已有的变位数据，未配置过变位数据的单词将自动补全。',
            [words.length],
          ),
        ),
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

    if (confirmed != true || !mounted) return;

    // 退出多选模式并显示进度对话框（并发数取设置中的 AI 并发配置）
    _exitMultiSelectMode();
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => _UpdateProgressDialog(
        service: service,
        words: words,
        concurrency: ref.read(settingsProvider).aiConcurrency,
        notifier: ref.read(batchUpdateProvider.notifier),
        onDone: _onUpdateDone,
      ),
    );
  }

  void _onUpdateDone({required int success, required int failed}) {
    // 无论对话框是否已关闭（后台运行），都刷新缓存
    ref.invalidate(deckConjugationCacheProvider(widget.deckId));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          failed > 0
              ? context.trArgs('更新完成：成功 {0} 个，失败 {1} 个',
                  [success, failed])
              : context.trArgs('变位数据更新完成（{0} 个）', [success]),
        ),
      ),
    );
  }

  // ── 删除操作 ──────────────────────────────────

  Future<void> _deleteSelectedWords(List<Word> words) async {
    if (words.isEmpty) return;

    final db = ref.read(databaseProvider);
    if (db == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('删除变位数据')),
        content: Text(
          context.trArgs(
            '确定要删除选中的 {0} 个单词的变位数据吗？\n\n'
            '删除后：动词时态练习将不再出现这些单词（可重新生成恢复）；\n'
            '名词变格 / 形容词变级将回退使用单词表中的基础字段。',
            [words.length],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('取消')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('删除')),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final count = await db.conjugationDao.deleteByWordIds(
      words.map((w) => w.id).toList(),
    );
    if (!mounted) return;
    ref.invalidate(deckConjugationCacheProvider(widget.deckId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.trArgs('已删除 {0} 个单词的变位数据', [count])),
      ),
    );
  }

  // ── 编辑操作 ──────────────────────────────────

  /// 打开单个单词的变位数据编辑对话框
  void _openEditor(Word word, ConjugationCacheData? cache) {
    if (_isMultiSelectMode) return;
    showDialog<bool>(
      context: context,
      builder: (context) => _EditConjugationDialog(
        word: word,
        initialJson: cache?.conjugationJson,
      ),
    ).then((saved) {
      if (saved == true && mounted) {
        ref.invalidate(deckConjugationCacheProvider(widget.deckId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.trArgs('已保存 {0} 的变位数据', [word.german]),
            ),
          ),
        );
      }
    });
  }

  // ── 界面构建 ──────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final wordsAsync = ref.watch(wordsByDeckProvider(widget.deckId));
    final cacheAsync =
        ref.watch(deckConjugationCacheProvider(widget.deckId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isMultiSelectMode
              ? context.trArgs('已选择 {0} 项', [_selectedWordIds.length])
              : context.tr('变位数据管理'),
        ),
        leading: _isMultiSelectMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitMultiSelectMode,
                tooltip: context.tr('退出多选'),
              )
            : null,
        actions: [
          // 后台 AI 任务入口（始终可见）
          const BatchTaskProgressButton(),
          if (_isMultiSelectMode)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                wordsAsync.whenData((words) => _selectAll(words));
              },
              tooltip: context.tr('全选'),
            )
          else ...[
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              tooltip: context.tr('筛选词性'),
              onSelected: (value) {
                setState(() => _wordTypeFilter = value == 'all' ? null : value);
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'all',
                  child: Text(
                    context.tr('全部词性'),
                    style: TextStyle(
                      fontWeight: _wordTypeFilter == null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'verb',
                  child: Text(
                    context.tr('动词'),
                    style: TextStyle(
                      fontWeight: _wordTypeFilter == 'verb'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'noun',
                  child: Text(
                    context.tr('名词'),
                    style: TextStyle(
                      fontWeight: _wordTypeFilter == 'noun'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'adjective',
                  child: Text(
                    context.tr('形容词'),
                    style: TextStyle(
                      fontWeight: _wordTypeFilter == 'adjective'
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _enterMultiSelectMode,
              tooltip: context.tr('多选'),
            ),
          ],
        ],
      ),
      body: wordsAsync.when(
        data: (words) {
          var filtered = words;
          if (_wordTypeFilter != null) {
            filtered = filtered
                .where((w) => w.wordType == _wordTypeFilter)
                .toList();
          }

          return cacheAsync.when(
            data: (cacheMap) {
              if (filtered.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storage_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        context.tr('词书中没有可管理的单词'),
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 88),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final word = filtered[index];
                  final cache = cacheMap[word.id];
                  return _WordDataTile(
                    word: word,
                    cache: cache,
                    isMultiSelectMode: _isMultiSelectMode,
                    isSelected: _selectedWordIds.contains(word.id),
                    onTap: () => _isMultiSelectMode
                        ? _toggleWordSelection(word.id)
                        : _enterMultiSelectModeAndSelect(word.id),
                    onLongPress: () => _enterMultiSelectModeAndSelect(word.id),
                    onEdit: () => _openEditor(word, cache),
                    onUpdate: () => _updateSelectedWords([word]),
                    onDelete: () => _deleteSelectedWords([word]),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text(context.trArgs('错误: {0}', [e]))),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            Center(child: Text(context.trArgs('错误: {0}', [e]))),
      ),
      bottomNavigationBar: _isMultiSelectMode
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _selectedWordIds.isEmpty
                            ? null
                            : () {
                                final words = _selectedWords();
                                _deleteSelectedWords(words);
                              },
                        icon: const Icon(Icons.delete_outline),
                        label: Text(context.tr('删除选中')),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _selectedWordIds.isEmpty
                            ? null
                            : () {
                                final words = _selectedWords();
                                _updateSelectedWords(words);
                              },
                        icon: const Icon(Icons.auto_awesome),
                        label: Text(context.tr('AI 更新选中')),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  /// 按选中 ID 过滤出单词（保持列表顺序）
  List<Word> _selectedWords() {
    final words = ref.read(wordsByDeckProvider(widget.deckId)).valueOrNull;
    if (words == null) return const [];
    return words.where((w) => _selectedWordIds.contains(w.id)).toList();
  }
}

/// 单个单词的变位数据管理项
class _WordDataTile extends StatelessWidget {
  final Word word;
  final ConjugationCacheData? cache;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onUpdate;
  final VoidCallback onDelete;

  const _WordDataTile({
    required this.word,
    required this.cache,
    required this.isMultiSelectMode,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onUpdate,
    required this.onDelete,
  });

  String _formatTime(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasCache = cache != null;

    final leading = isMultiSelectMode
        ? Checkbox(
            value: isSelected,
            onChanged: (_) => onTap(),
          )
        : Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: WordTypeColors.forWordTypeSurface(
                word.wordType,
                article: word.article,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              WordTypeColors.getWordTypeLabel(word.wordType),
              style: TextStyle(
                color: WordTypeColors.forWordType(
                  word.wordType,
                  article: word.article,
                ),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          );

    final status = hasCache
        ? Text(
            context.trArgs('已缓存 · {0} · 更新于 {1}', [
              cache!.source == 'manual' ? context.tr('手动') : 'AI',
              _formatTime(cache!.updatedAt),
            ]),
            style: TextStyle(fontSize: 12, color: scheme.primary),
          )
        : Text(
            context.tr('无变位数据'),
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          );

    return ListTile(
      leading: leading,
      title: Text(
        '${word.article != null ? '${word.article} ' : ''}${word.german}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (word.chinese.trim().isNotEmpty) ...[
            Text(
              word.chinese.trim().split('\n').first,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 2),
          status,
        ],
      ),
      isThreeLine: true,
      trailing: isMultiSelectMode
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: hasCache ? scheme.primary : Colors.grey.shade400,
                  tooltip: context.tr('编辑变位数据'),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  color: scheme.primary,
                  tooltip: context.tr('AI 更新变位数据'),
                  onPressed: onUpdate,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: hasCache ? scheme.error : Colors.grey.shade400,
                  tooltip: context.tr('删除变位数据'),
                  onPressed: onDelete,
                ),
              ],
            ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}

/// AI 更新变位数据进度对话框
///
/// 并发重新生成选中单词的变位数据；关闭窗口后任务转入后台继续运行，
/// 可从页面右上角的任务按钮查看进度。
class _UpdateProgressDialog extends StatefulWidget {
  final ConjugationService service;
  final List<Word> words;
  final int concurrency;
  final BatchUpdateNotifier notifier;
  final void Function({required int success, required int failed}) onDone;

  const _UpdateProgressDialog({
    required this.service,
    required this.words,
    required this.concurrency,
    required this.notifier,
    required this.onDone,
  });

  @override
  State<_UpdateProgressDialog> createState() => _UpdateProgressDialogState();
}

class _UpdateProgressDialogState extends State<_UpdateProgressDialog> {
  int _completed = 0;
  int _failed = 0;
  int _total = 0;
  String? _currentWord;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _total = widget.words.length;
    // 延迟到 widget 树构建完成后启动，避免在构建期间修改状态
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    // 创建后台任务记录（携带单词列表，供其它界面检测进行中的任务）
    final taskId = widget.notifier.addTask(
      AppLocale.trArgs(
        'AI 更新变位数据 {0} 个单词',
        [widget.words.length],
      ),
      widget.words.length,
      words: widget.words.map((w) => w.german).toList(),
    );
    widget.notifier.startTask(taskId);

    try {
      // 并发 worker 池批量更新；进度同步到全局任务状态，
      // 对话框关闭（后台运行）后任务仍继续执行
      final result = await widget.service.regenerateBatch(
        widget.words.map((w) => w.id).toList(),
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

      // 不依赖 mounted：对话框关闭后任务仍在后台运行
      widget.notifier.completeTask(
        taskId,
        BatchUpdateProgress(
          total: _total,
          completed: result.success,
          failed: result.failed,
          currentWord: null,
          isRunning: false,
        ),
      );
      widget.onDone(success: result.success, failed: result.failed);
      if (mounted) setState(() => _isComplete = true);
    } catch (e) {
      widget.notifier.failTask(taskId, e.toString());
      widget.onDone(success: 0, failed: _total);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _isComplete ? context.tr('更新完成') : context.tr('AI 更新变位数据'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isComplete) ...[
            LinearProgressIndicator(
              value: _total == 0 ? null : _completed / _total,
            ),
            const SizedBox(height: 16),
            Text('${_completed + _failed}/$_total'),
            if (_currentWord != null) ...[
              const SizedBox(height: 8),
              Text(
                context.trArgs('正在处理: {0}', [_currentWord]),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              context.tr('关闭窗口可后台运行'),
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ] else ...[
            const Icon(Icons.check_circle, size: 48, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              context.trArgs('成功 {0} 个', [_completed]) +
                  (_failed > 0
                      ? context.trArgs('，失败 {0} 个', [_failed])
                      : ''),
            ),
          ],
        ],
      ),
      actions: [
        if (_isComplete)
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('完成')),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('后台运行')),
          ),
      ],
    );
  }
}

/// 编辑单词变位数据对话框
///
/// 支持查看 / 修改现有 JSON 数据，也可为暂无数据的单词手动新建；
/// 保存前校验 JSON 合法性，并以 manual 来源写入缓存。
class _EditConjugationDialog extends ConsumerStatefulWidget {
  final Word word;
  final String? initialJson;

  const _EditConjugationDialog({
    required this.word,
    required this.initialJson,
  });

  @override
  ConsumerState<_EditConjugationDialog> createState() =>
      _EditConjugationDialogState();
}

class _EditConjugationDialogState
    extends ConsumerState<_EditConjugationDialog> {
  late final TextEditingController _controller;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialJson;
    _controller = TextEditingController(
      text: initial == null ? '' : _prettyJson(initial),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 格式化 JSON（缩进 2 空格），解析失败则原样返回
  String _prettyJson(String json) {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(json));
    } catch (_) {
      return json;
    }
  }

  /// 校验并格式化当前输入
  void _format() {
    try {
      final decoded = jsonDecode(_controller.text);
      setState(() {
        _controller.text = const JsonEncoder.withIndent('  ').convert(decoded);
        _error = null;
      });
    } catch (_) {
      setState(() => _error = context.tr('JSON 格式无效，无法格式化'));
    }
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _error = context.tr('变位数据不能为空'));
      return;
    }

    Object? decoded;
    try {
      decoded = jsonDecode(text);
    } catch (e) {
      setState(
        () => _error = context.trArgs('JSON 格式无效：{0}', [_shortError(e)]),
      );
      return;
    }
    if (decoded is! Map<String, dynamic>) {
      setState(() => _error = context.tr('变位数据必须是 JSON 对象（{...}）'));
      return;
    }

    final db = ref.read(databaseProvider);
    if (db == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await db.conjugationDao.upsert(widget.word.id, text, source: 'manual');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = context.trArgs('保存失败：{0}', [_shortError(e)]);
        });
      }
    }
  }

  String _shortError(Object e) {
    final s = e.toString().replaceAll('\n', ' ');
    return s.length > 80 ? '${s.substring(0, 80)}...' : s;
  }

  /// 词性对应的 JSON 结构参考
  String get _structureHint {
    switch (widget.word.wordType) {
      case 'verb':
        return '{"type":"verb","praesens":{"ich":"","du":"","er_sie_es":"","wir":"","ihr":"","sie_Sie":""},"praeteritum":{...},"perfekt":{"auxiliary":"haben/sein","partizip":"","ich":""},"passiv":{${context.tr('6人称')}}}';
      case 'noun':
        return '{"type":"noun","article":"der/die/das","genitiv":"","plural":""}';
      case 'adjective':
        return '{"type":"adjective","komparativ":"","superlativ":""}';
      default:
        return '{"type":"..."}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final word = widget.word;
    final wordLabel = word.article != null ? '${word.article} ${word.german}' : word.german;

    return AlertDialog(
      title: Text(context.trArgs('编辑变位数据 - {0}', [wordLabel])),
      content: SizedBox(
        width: 560,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.trArgs('词性：{0} · 结构参考：{1}', [
                WordTypeColors.getWordTypeLabel(word.wordType),
                _structureHint,
              ]),
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
            if (widget.initialJson == null) ...[
              const SizedBox(height: 4),
              Text(
                context.tr('该单词暂无变位数据，保存后将新建并标记为手动'),
                style: TextStyle(fontSize: 12, color: scheme.tertiary),
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.4,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  hintText: '{"type": "verb", ...}',
                  alignLabelWithHint: true,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(fontSize: 12, color: scheme.error),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _saving ? null : _format,
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: Text(context.tr('格式化')),
                ),
                const Spacer(),
                TextButton(
                  onPressed:
                      _saving ? null : () => Navigator.pop(context, false),
                  child: Text(context.tr('取消')),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(context.tr('保存')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
