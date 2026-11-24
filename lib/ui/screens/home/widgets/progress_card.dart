import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../providers/deck_provider.dart';
import '../../../../providers/study_provider.dart';

class ProgressCard extends ConsumerWidget {
  final int? deckId;

  const ProgressCard({super.key, this.deckId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    if (deckId == null) {
      return _buildEmptyCard(context, colorScheme);
    }

    final wordCount = ref.watch(wordCountProvider(deckId!));
    final studyPlan = ref.watch(studyPlanProvider(deckId!));
    final checkInStreak = ref.watch(checkInStreakProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 今日学习（新词 / 复习）
            // stretch 撑满卡片宽度，避免内容列被外层 Column 居中
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.tr('今日学习'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                studyPlan.when(
                  data: (plan) => Text(
                    plan != null
                        ? '${plan.todayNewStudiedCount} / ${plan.todayReviewStudiedCount}'
                        : '0 / 0',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                  ),
                  // 用固定尺寸 + 左对齐的转圈：裸 CircularProgressIndicator 会在
                  // 自适应的 Column 里被拉成整行宽，数据到达时高度突变（观感跳动）
                  loading: () => const Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (e, s) => Text(
                    '0 / 0',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                  ),
                ),
                Text(
                  context.tr('今日已学（新词 / 复习）'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                checkInStreak.when(
                  data: (days) => _StatItem(
                    icon: Icons.local_fire_department,
                    label: context.tr('连续打卡'),
                    value: context.trArgs('{0} 天', [days]),
                    color: Colors.orange,
                  ),
                  loading: () => _StatItem(
                    icon: Icons.local_fire_department,
                    label: context.tr('连续打卡'),
                    value: '...',
                    color: Colors.orange,
                  ),
                  error: (e, s) => _StatItem(
                    icon: Icons.local_fire_department,
                    label: context.tr('连续打卡'),
                    value: context.trArgs('{0} 天', [0]),
                    color: Colors.orange,
                  ),
                ),
                wordCount.when(
                  data: (count) => _StatItem(
                    icon: Icons.school_outlined,
                    label: context.tr('总词汇'),
                    value: context.trArgs('{0} 词', [count]),
                    color: Colors.green,
                  ),
                  loading: () => _StatItem(
                    icon: Icons.school_outlined,
                    label: context.tr('总词汇'),
                    value: '...',
                    color: Colors.green,
                  ),
                  error: (e, s) => _StatItem(
                    icon: Icons.school_outlined,
                    label: context.tr('总词汇'),
                    value: context.trArgs('{0} 词', [0]),
                    color: Colors.green,
                  ),
                ),
                studyPlan.when(
                  data: (plan) => _StatItem(
                    icon: Icons.schedule,
                    label: context.tr('待复习'),
                    value: context.trArgs('{0} 词', [plan?.dueReviewCount ?? 0]),
                    color: Colors.blue,
                  ),
                  loading: () => _StatItem(
                    icon: Icons.schedule,
                    label: context.tr('待复习'),
                    value: '...',
                    color: Colors.blue,
                  ),
                  error: (e, s) => _StatItem(
                    icon: Icons.schedule,
                    label: context.tr('待复习'),
                    value: context.trArgs('{0} 词', [0]),
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              context.tr('请选择或创建一个词书'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('在词书管理中创建词书并导入单词'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
