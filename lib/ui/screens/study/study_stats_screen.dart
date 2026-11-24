import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../data/database/daos/study_stat_dao.dart';
import '../../../providers/database_provider.dart';
import '../deck/word_detail_screen.dart';

/// 统计时间范围
enum StatRange { today, history }

/// 统计排序指标
enum StatMetric { errors, errorRate }

/// 错误统计排行榜（二级页面）
///
/// - 顶部一排：今天/历史 与 错误次数/错误率 并排切换
/// - 列表每行：点击进入单词详情，中间显示错误次数/出现次数，右侧收藏按钮
class StudyStatsScreen extends ConsumerStatefulWidget {
  final int deckId;

  const StudyStatsScreen({super.key, required this.deckId});

  @override
  ConsumerState<StudyStatsScreen> createState() => _StudyStatsScreenState();
}

class _StudyStatsScreenState extends ConsumerState<StudyStatsScreen> {
  StatRange _range = StatRange.today;
  StatMetric _metric = StatMetric.errors;
  List<StudyStatEntry>? _entries;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final db = ref.read(databaseProvider);
    if (db == null) return;
    final entries = await db.studyStatDao.getStats(
      deckId: widget.deckId,
      todayOnly: _range == StatRange.today,
    );
    if (mounted) {
      setState(() => _entries = entries);
    }
  }

  /// 按当前指标排序（错得最多的在最上方）
  List<StudyStatEntry> get _sorted {
    final list = [...?_entries];
    switch (_metric) {
      case StatMetric.errors:
        list.sort((a, b) => b.errors.compareTo(a.errors));
      case StatMetric.errorRate:
        list.sort((a, b) => b.errorRate.compareTo(a.errorRate));
    }
    return list;
  }

  /// 切换收藏状态并刷新列表
  Future<void> _toggleFavorite(StudyStatEntry entry) async {
    final db = ref.read(databaseProvider);
    if (db == null) return;
    await db.wordDao.updateFavorite(entry.wordId, !entry.isFavorite);
    _load();
  }

  /// 打开单词详情页
  void _openDetail(StudyStatEntry entry) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WordDetailScreen(wordId: entry.wordId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final entries = _sorted;
    final isEmpty = _entries != null && entries.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('错误统计'))),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                // 范围切换：今日 / 历史
                Expanded(
                  child: SegmentedButton<StatRange>(
                    segments: [
                      ButtonSegment(
                        value: StatRange.today,
                        label: Text(context.tr('今天')),
                      ),
                      ButtonSegment(
                        value: StatRange.history,
                        label: Text(context.tr('历史')),
                      ),
                    ],
                    selected: {_range},
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onSelectionChanged: (selection) {
                      setState(() => _range = selection.first);
                      _load();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // 指标切换：错误次数 / 错误率
                Expanded(
                  child: SegmentedButton<StatMetric>(
                    segments: [
                      ButtonSegment(
                        value: StatMetric.errors,
                        label: Text(context.tr('错误次数')),
                      ),
                      ButtonSegment(
                        value: StatMetric.errorRate,
                        label: Text(context.tr('错误率')),
                      ),
                    ],
                    selected: {_metric},
                    showSelectedIcon: false,
                    style: SegmentedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onSelectionChanged: (selection) {
                      setState(() => _metric = selection.first);
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              context.tr('每次练习记录出现与错误次数，忘记/模糊计为错误'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: _entries == null
                ? const Center(child: CircularProgressIndicator())
                : isEmpty
                    ? Center(
                        child: Text(
                          _range == StatRange.today
                              ? context.tr('今天还没有练习记录')
                              : context.tr('暂无历史统计记录'),
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: entries.length,
                        itemBuilder: (context, index) =>
                            _buildStatRow(entries[index], index + 1),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(StudyStatEntry entry, int rank) {
    final colorScheme = Theme.of(context).colorScheme;
    final genderColor = GenderColors.forArticle(entry.article);
    // 前三名高亮
    final rankColor = rank == 1
        ? Colors.red
        : rank == 2
            ? Colors.orange
            : rank == 3
                ? Colors.amber
                : colorScheme.onSurfaceVariant;

    return InkWell(
      onTap: () => _openDetail(entry),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // 名次
            SizedBox(
              width: 28,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: rankColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 单词
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.german,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (entry.article != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: genderColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            entry.article!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: genderColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    entry.chinese,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 中间：错误次数/出现次数（或错误率）
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _metric == StatMetric.errors
                      ? context.trArgs('错误 {0} 次', [entry.errors])
                      : context.trArgs(
                          '错误率 {0}%',
                          [(entry.errorRate * 100).toStringAsFixed(0)]),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: entry.errors > 0 ? Colors.red : null,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                Text(
                  context.trArgs('出现 {0} 次', [entry.appearances]),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            // 最右侧：收藏按钮
            IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(
                entry.isFavorite ? Icons.star : Icons.star_border,
                size: 20,
                color: entry.isFavorite ? Colors.amber : null,
              ),
              tooltip: entry.isFavorite
                  ? context.tr('取消收藏')
                  : context.tr('收藏'),
              onPressed: () => _toggleFavorite(entry),
            ),
          ],
        ),
      ),
    );
  }
}
