import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../providers/training_provider.dart';
import '../../../services/training/writing_insight.dart';

/// 写作知识点统计页
///
/// 只统计写作类练习里 AI 指出的知识点（第二虚拟式、动词变位、格与冠词…），
/// 客观题的对错不计入——这是产品明确要求的口径。
class WritingInsightScreen extends ConsumerWidget {
  const WritingInsightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncInsight = ref.watch(writingInsightProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('写作知识点统计'))),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(writingInsightProvider);
          await ref.read(writingInsightProvider.future);
        },
        child: asyncInsight.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(context.trArgs('读取统计失败: {0}', [error])),
            ),
          ),
          data: (insight) {
            if (insight.isEmpty) return _EmptyView();
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _Summary(insight: insight),
                const SizedBox(height: 16),
                for (final stat in insight.points)
                  _KnowledgeCard(
                    stat: stat,
                    maxCount: insight.points.first.count,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(context.tr('还没有写作练习记录'), style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              context.tr('完成写作类练习后，这里会统计常错的知识点'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  final WritingKnowledgeInsight insight;

  const _Summary({required this.insight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _Metric(label: context.tr('写作练习'), value: '${insight.exerciseCount}'),
          const SizedBox(width: 24),
          _Metric(
            label: context.tr('纠正条数'),
            value: '${insight.correctionCount}',
          ),
          const SizedBox(width: 24),
          _Metric(
            label: context.tr('涉及知识点'),
            value: '${insight.points.length}',
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

class _KnowledgeCard extends StatelessWidget {
  final KnowledgePointStat stat;
  final int maxCount;

  const _KnowledgeCard({required this.stat, required this.maxCount});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = maxCount <= 0 ? 0.0 : stat.count / maxCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr(stat.knowledge.titleZh),
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                Text(
                  context.trArgs('{0} 次', [stat.count]),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: ratio, minHeight: 6),
            ),
            if (stat.lastOriginal != null || stat.lastSuggestion != null) ...[
              const SizedBox(height: 10),
              if (stat.lastOriginal != null)
                Text(
                  stat.lastOriginal!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              if (stat.lastSuggestion != null)
                Text(
                  stat.lastSuggestion!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              if (stat.lastReason != null && stat.lastReason!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    stat.lastReason!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
