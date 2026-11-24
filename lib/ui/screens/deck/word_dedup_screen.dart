import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/utils/definition_language.dart';
import '../../../data/database/app_database.dart';
import '../../../providers/database_provider.dart';

/// 去重扫描界面
///
/// 按规范化词形（`der Hund` 与 `Hund` 归为同一词，德语大小写保留语义）
/// 扫描当前词书内的重复单词，逐组勾选要保留的记录，其余记录的 SM-2
/// 学习状态 / 每日错误统计 / 变位缓存会合并进保留记录后删除。
class WordDedupScreen extends ConsumerStatefulWidget {
  final int deckId;

  const WordDedupScreen({super.key, required this.deckId});

  @override
  ConsumerState<WordDedupScreen> createState() => _WordDedupScreenState();
}

class _WordDedupScreenState extends ConsumerState<WordDedupScreen> {
  List<WordDedupGroup> _groups = const [];
  /// 每组保留的单词 id（key 为规范化词形）
  final Map<String, int> _keepIds = {};
  /// 各单词的 SM-2 状态（用于推荐保留记录与展示复习次数）
  Map<int, Sm2State> _sm2Map = const {};
  bool _isLoading = true;
  bool _merging = false;
  String? _error;

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
      final groups = await db.findDeckDuplicateGroups(widget.deckId);

      // 批量收集所有单词的 SM-2 状态，用于推荐保留记录（避免逐词串行查询）
      final allWordIds = groups
          .expand((g) => g.words.map((w) => w.id))
          .toSet()
          .toList();
      final states = await db.sm2Dao.getStatesForWords(allWordIds);
      final sm2Map = {for (final s in states) s.wordId: s};

      final keepIds = <String, int>{};
      for (final g in groups) {
        keepIds[g.canonicalKey] = _recommendKeep(g, sm2Map).id;
      }

      if (!mounted) return;
      setState(() {
        _groups = groups;
        _sm2Map = sm2Map;
        _keepIds
          ..clear()
          ..addAll(keepIds);
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

  /// 推荐保留的记录，优先级（高 → 低）：
  /// 1. 有学习记录（存在 SM-2 状态）
  /// 2. 释义语言与当前界面语言一致
  /// 3. 更新时间更新
  Word _recommendKeep(WordDedupGroup group, Map<int, Sm2State> sm2Map) {
    final index = pickKeepIndex<Word>(
      group.words,
      hasStudyRecord: (w) => sm2Map.containsKey(w.id),
      definitionText: (w) => w.chinese,
      updatedAt: (w) => w.updatedAt,
      languageCode: AppLocale.code,
    );
    return group.words[index < 0 ? 0 : index];
  }

  Future<void> _mergeAll() async {
    if (_merging) return;
    setState(() => _merging = true);

    try {
      final db = ref.read(databaseProvider);
      if (db == null) return;
      var removedCount = 0;
      for (final g in _groups) {
        final keepId = _keepIds[g.canonicalKey];
        if (keepId == null) continue;
        final removeIds =
            g.words.map((w) => w.id).where((id) => id != keepId).toList();
        if (removeIds.isEmpty) continue;
        removedCount +=
            (await db.mergeDuplicateGroup(keepWordId: keepId, removeWordIds: removeIds))
                .length;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(context.trArgs('已合并 {0} 组重复，删除 {1} 个单词',
                [_groups.length, removedCount]))),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.trArgs('合并失败: {0}', [e]))),
      );
    } finally {
      if (mounted) setState(() => _merging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('去重扫描'))),
      body: _buildBody(),
      bottomNavigationBar: _groups.isEmpty || _merging
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: _merging ? null : _mergeAll,
                  icon: const Icon(Icons.merge),
                  label: Text(context
                      .trArgs('合并并删除（{0} 组重复）', [_groups.length])),
                ),
              ),
            ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(context.trArgs('扫描失败: {0}', [_error])),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: Text(context.tr('重试'))),
          ],
        ),
      );
    }
    if (_groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              context.tr('未发现重复单词'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('同一词书内不存在规范化词形相同的重复记录'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        return _buildGroupCard(_groups[index]);
      },
    );
  }

  Widget _buildGroupCard(WordDedupGroup group) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    context.trArgs('重复 {0} 条', [group.words.length]),
                    style: TextStyle(
                      color: colorScheme.onErrorContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    group.canonicalKey,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              context.tr('选择要保留的记录，其余将被合并并删除'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            RadioGroup<int>(
              groupValue: _keepIds[group.canonicalKey],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _keepIds[group.canonicalKey] = value;
                });
              },
              child: Column(
                children: [
                  for (final w in group.words)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: Radio<int>(value: w.id),
                      title: Text(
                        w.german,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        _wordSubtitle(w),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: _keepIds[group.canonicalKey] == w.id
                          ? const Icon(Icons.check_circle,
                              color: Colors.green, size: 20)
                          : null,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _wordSubtitle(Word w) {
    final parts = <String>[];
    if (w.chinese.isNotEmpty) parts.add(w.chinese);
    final sm2 = _sm2Map[w.id];
    if (sm2 != null) {
      parts.add(context.trArgs('复习 {0} 次', [sm2.totalReviews]));
    } else {
      parts.add(context.tr('新词'));
    }
    if (w.proficiency > 0) {
      parts.add(context.trArgs('熟练度 {0}', [w.proficiency]));
    }
    parts.add(
      context.trArgs(
          '更新于 {0}', ['${w.updatedAt.month}-${w.updatedAt.day}']),
    );
    return parts.join(' · ');
  }
}
