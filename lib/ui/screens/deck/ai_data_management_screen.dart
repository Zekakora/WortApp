import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/ai_status_dao.dart';
import '../../../providers/batch_update_provider.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/search_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/ai/batch_ai_service.dart';
import '../../../ui/widgets/batch_task_widgets.dart';
import '../../../ui/widgets/batch_update_dialog.dart';

/// 单词 AI 释义状态
enum AiWordStatus {
  /// 已有 AI 释义（AI 缓存含有效释义，无需重试）
  hasDefinition,

  /// 上次 AI 请求成功（但无有效缓存，罕见）
  requestSuccess,

  /// 上次 AI 请求失败（可重试）
  requestFailed,

  /// 从未发起 AI 释义请求（可重试）
  none,
}

/// 单词 + AI 释义状态条目
class AiWordStatusEntry {
  final Word word;

  /// 是否已有有效的 AI 释义（AI 缓存 JSON 中含非空释义）
  final bool hasAiDefinition;

  /// 最近一次 AI 请求状态记录（可能为 null = 从未请求）
  final AiRequestStatusData? lastStatus;

  const AiWordStatusEntry({
    required this.word,
    required this.hasAiDefinition,
    this.lastStatus,
  });

  AiWordStatus get status {
    if (hasAiDefinition) return AiWordStatus.hasDefinition;
    final last = lastStatus;
    if (last == null) return AiWordStatus.none;
    return last.status == AiRequestStatusValue.failed
        ? AiWordStatus.requestFailed
        : AiWordStatus.requestSuccess;
  }

  /// 是否需要重试（没有 AI 释义的单词，含请求失败与从未请求）
  bool get needsRetry => !hasAiDefinition;

  /// 当前中文释义是否为英文（OCR/导入词书可能给出英文释义）
  bool get isEnglishMeaning => isEnglishLike(word.chinese);
}

/// 判断释义文本是否为英文：包含拉丁字母但几乎不含中文（CJK）字符
bool isEnglishLike(String text) {
  final t = text.trim();
  if (t.isEmpty) return false;
  final hasLatin = RegExp(r'[a-zA-Z]').hasMatch(t);
  if (!hasLatin) return false;
  // 统计 CJK 字符占比，若含中文则视为正常中文释义
  final cjkCount =
      RegExp(r'[\u4E00-\u9FFF\u3400-\u4DBF]').allMatches(t).length;
  return cjkCount == 0;
}

/// 筛选条件
enum _AiStatusFilter {
  all('全部'),
  needsRetry('需重试'),
  hasDefinition('已有释义'),
  failed('请求失败'),
  englishMeaning('英文释义');

  final String label;
  const _AiStatusFilter(this.label);
}

/// AI 数据管理界面
///
/// 展示词书中每个单词的 AI 释义状态（是否有 AI 释义、上次请求成功/失败），
/// 支持筛选与勾选后一键重试没有 AI 释义或上次请求失败的单词。
class AiDataManagementScreen extends ConsumerStatefulWidget {
  final int deckId;

  const AiDataManagementScreen({super.key, required this.deckId});

  @override
  ConsumerState<AiDataManagementScreen> createState() =>
      _AiDataManagementScreenState();
}

class _AiDataManagementScreenState
    extends ConsumerState<AiDataManagementScreen> {
  List<AiWordStatusEntry> _entries = const [];
  bool _isLoading = true;
  String? _error;
  _AiStatusFilter _filter = _AiStatusFilter.needsRetry;
  final Set<int> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    if (db == null) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final words = await db.wordDao.getWordsByDeck(widget.deckId);
      final texts = words.map((w) => w.german).toList();
      final caches = await db.aiCacheDao.getCachesForWords(texts);
      final statuses = await db.aiStatusDao.getStatusForWords(texts);

      final entries = words
          .map((w) {
            final cache = caches[w.german];
            return AiWordStatusEntry(
              word: w,
              hasAiDefinition: cache != null &&
                  AiStatusDao.hasValidAiDefinitions(cache.resultJson),
              lastStatus: statuses[w.german],
            );
          })
          .toList();

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = '$e';
      });
    }
  }

  List<AiWordStatusEntry> get _filteredEntries {
    switch (_filter) {
      case _AiStatusFilter.all:
        return _entries;
      case _AiStatusFilter.needsRetry:
        return _entries.where((e) => e.needsRetry).toList();
      case _AiStatusFilter.hasDefinition:
        return _entries.where((e) => e.hasAiDefinition).toList();
      case _AiStatusFilter.failed:
        return _entries.where((e) => e.status == AiWordStatus.requestFailed).toList();
      case _AiStatusFilter.englishMeaning:
        return _entries.where((e) => e.isEnglishMeaning).toList();
    }
  }

  /// 一键选择当前筛选条件下的全部单词
  void _selectAllFiltered() {
    final ids = _filteredEntries.map((e) => e.word.id).toList();
    setState(() {
      _selectedIds
        ..clear()
        ..addAll(ids);
    });
  }

  /// 当前筛选条件下的单词是否已被全部选中
  bool get _allFilteredSelected {
    final ids = _filteredEntries.map((e) => e.word.id).toSet();
    if (ids.isEmpty) return false;
    return _selectedIds.containsAll(ids);
  }

  /// 切换全选 / 取消全选当前筛选条件下的单词
  void _toggleSelectAllFiltered() {
    if (_allFilteredSelected) {
      // 已全部选中则取消选择
      setState(() {
        _selectedIds.removeWhere(
            (id) => _filteredEntries.any((e) => e.word.id == id));
      });
    } else {
      _selectAllFiltered();
    }
  }

  void _toggleSelection(int wordId) {
    setState(() {
      if (_selectedIds.contains(wordId)) {
        _selectedIds.remove(wordId);
      } else {
        _selectedIds.add(wordId);
      }
    });
  }

  /// 重试选中的单词（AI 批量更新词意，覆盖模式）
  Future<void> _startRetry(List<AiWordStatusEntry> selected) async {
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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重试 AI 释义'),
        content: Text(
          '确定要对选中的 ${selected.length} 个单词重新请求 AI 释义吗？\n\n'
          '将覆盖这些单词已有的中文释义，已成功获取 AI 释义的单词不会被影响。',
        ),
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
    if (confirmed != true || !mounted) return;

    final batchService = BatchAIService(
      db,
      aiEngine,
      concurrency: ref.read(settingsProvider).aiConcurrency,
    );
    final notifier = ref.read(batchUpdateProvider.notifier);

    // 显示进度对话框（关闭后后台运行，完成后自动刷新本页状态）
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => BatchUpdateDialog(
        batchService: batchService,
        notifier: notifier,
        wordIds: selected.map((e) => e.word.id).toList(),
        words: selected.map((e) => e.word.german).toList(),
        taskName: 'AI 重试释义 ${selected.length} 个单词',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 批量 AI 任务结束后自动刷新状态（含后台运行完成的情况）
    ref.listen(batchUpdateProvider, (previous, next) {
      final wasRunning = previous?.hasRunningTask ?? false;
      if (wasRunning && !next.hasRunningTask) {
        _load();
      }
    });

    final filtered = _filteredEntries;
    final hasDefinitionCount =
        _entries.where((e) => e.hasAiDefinition).length;
    final failedCount =
        _entries.where((e) => e.status == AiWordStatus.requestFailed).length;
    final noneCount =
        _entries.where((e) => e.status == AiWordStatus.none).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据管理'),
        actions: [
          const BatchTaskProgressButton(),
          IconButton(
            icon: Icon(
              _allFilteredSelected ? Icons.deselect : Icons.select_all,
            ),
            tooltip: '全选当前页面单词',
            onPressed: _filteredEntries.isEmpty ? null : _toggleSelectAllFiltered,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // 统计摘要
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _SummaryCard(
              total: _entries.length,
              hasDefinition: hasDefinitionCount,
              failed: failedCount,
              none: noneCount,
            ),
          ),
          // 筛选条件
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final f in _AiStatusFilter.values) ...[
                          FilterChip(
                            label: Text('${f.label}(${_countFor(f)})'),
                            selected: _filter == f,
                            onSelected: (_) => setState(() => _filter = f),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 单词状态列表
          Expanded(child: _buildList(filtered)),
        ],
      ),
      bottomNavigationBar: _isLoading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedIds.isEmpty)
                      Text(
                        '勾选需要处理的单词，点击下方按钮一键 AI 更新（无 AI 释义、请求失败或释义为英文的单词）',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      )
                    else
                      Text(
                        '已选择 $_selectedIdsCount 个单词（AI 更新将覆盖其当前释义）',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _selectedIds.isEmpty
                            ? null
                            : () => _startRetry(_selectedEntries()),
                        icon: const Icon(Icons.auto_awesome),
                        label: Text('重试选中 (${_selectedIds.length})'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  int get _selectedIdsCount => _selectedIds.length;

  int _countFor(_AiStatusFilter f) {
    switch (f) {
      case _AiStatusFilter.all:
        return _entries.length;
      case _AiStatusFilter.needsRetry:
        return _entries.where((e) => e.needsRetry).toList().length;
      case _AiStatusFilter.hasDefinition:
        return _entries.where((e) => e.hasAiDefinition).toList().length;
      case _AiStatusFilter.failed:
        return _entries
            .where((e) => e.status == AiWordStatus.requestFailed)
            .toList()
            .length;
      case _AiStatusFilter.englishMeaning:
        return _entries.where((e) => e.isEnglishMeaning).toList().length;
    }
  }

  /// 按选中 ID 过滤出条目（保持列表顺序）
  List<AiWordStatusEntry> _selectedEntries() {
    return _entries.where((e) => _selectedIds.contains(e.word.id)).toList();
  }

  Widget _buildList(List<AiWordStatusEntry> filtered) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('加载失败: $_error'));
    }
    if (_entries.isEmpty) {
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
              '词书中还没有单词',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }
    if (filtered.isEmpty) {
      return Center(
        child: Text(
          '当前筛选条件下没有单词',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 8),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final entry = filtered[index];
        return _AiStatusTile(
          entry: entry,
          isSelected: _selectedIds.contains(entry.word.id),
          onChanged: () => _toggleSelection(entry.word.id),
        );
      },
    );
  }
}

/// 统计摘要卡片
class _SummaryCard extends StatelessWidget {
  final int total;
  final int hasDefinition;
  final int failed;
  final int none;

  const _SummaryCard({
    required this.total,
    required this.hasDefinition,
    required this.failed,
    required this.none,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget item(Color color, String label, int count) {
      return Expanded(
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            item(scheme.onSurface, '总单词', total),
            item(Colors.green, '已有AI释义', hasDefinition),
            item(Colors.red, '请求失败', failed),
            item(Colors.orange.shade700, '无AI释义', none),
          ],
        ),
      ),
    );
  }
}

/// 单个单词的 AI 释义状态条目
class _AiStatusTile extends StatelessWidget {
  final AiWordStatusEntry entry;
  final bool isSelected;
  final VoidCallback onChanged;

  const _AiStatusTile({
    required this.entry,
    required this.isSelected,
    required this.onChanged,
  });

  String _formatTime(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(time.month)}-${two(time.day)} ${two(time.hour)}:${two(time.minute)}';
  }

  (Color, String) _statusStyle(BuildContext context) {
    switch (entry.status) {
      case AiWordStatus.hasDefinition:
        return (Colors.green, '已有AI释义');
      case AiWordStatus.requestSuccess:
        return (Colors.blue, 'AI请求成功');
      case AiWordStatus.requestFailed:
        return (Colors.red, '释义请求失败');
      case AiWordStatus.none:
        return (Colors.orange.shade700, '无AI释义');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (statusColor, statusText) = _statusStyle(context);
    final lastStatus = entry.lastStatus;
    final word = entry.word;
    final wordLabel = word.article != null ? '${word.article} ${word.german}' : word.german;

    return CheckboxListTile(
      value: isSelected,
      onChanged: (_) => onChanged(),
      controlAffinity: ListTileControlAffinity.leading,
      title: Text(
        wordLabel,
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
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              if (lastStatus != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '上次请求: ${_formatTime(lastStatus.lastRequestAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (entry.status == AiWordStatus.requestFailed &&
              lastStatus?.errorMessage != null) ...[
            Text(
              lastStatus!.errorMessage!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: scheme.error.withValues(alpha: 0.8),
              ),
            ),
          ],
        ],
      ),
      isThreeLine: true,
    );
  }
}
