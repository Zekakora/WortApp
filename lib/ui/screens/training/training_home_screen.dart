import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../data/models/training.dart';
import '../../../ui/utils/training_icons.dart';
import '../../../ui/utils/wide_layout.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/training_provider.dart';
import 'exercise_type_screen.dart';
import 'training_history_screen.dart';
import 'exercise_result_screen.dart';

/// AI 训练首页：三个并列技能入口
class TrainingHomeScreen extends ConsumerWidget {
  const TrainingHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final aiConfigured = settings.aiConfig.isConfigured;
    final historyAsync = ref.watch(trainingHistoryProvider(null));
    final recent = (historyAsync.valueOrNull ?? const []).take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('AI 训练')),
        actions: [
          IconButton(
            tooltip: context.tr('练习历史'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const TrainingHistoryScreen()),
            ),
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trainingHistoryProvider);
          await ref.read(trainingHistoryProvider(null).future);
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            Text(
              context.tr('按技能专项练习：听力、阅读、写作互相独立，可只练其中一项'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (!aiConfigured) ...[const SizedBox(height: 12), _ConfigHint()],
            const SizedBox(height: 16),
            // 宽屏（平板）：三个技能入口并排，一眼看全
            if (WideLayout.isWide(context))
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < TrainingSkill.values.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(
                        child: _SkillCard(skill: TrainingSkill.values[i]),
                      ),
                    ],
                  ],
                ),
              )
            else
              for (final skill in TrainingSkill.values) ...[
                _SkillCard(skill: skill),
                const SizedBox(height: 12),
              ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  context.tr('最近练习'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const Spacer(),
                if (recent.isNotEmpty)
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const TrainingHistoryScreen(),
                      ),
                    ),
                    child: Text(context.tr('查看全部')),
                  ),
              ],
            ),
            if (recent.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  context.tr('还没有练习记录，选择一个题型开始吧'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else
              for (final entry in recent)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(trainingSkillIcon(entry.exerciseType.skill)),
                    title: Text(context.tr(entry.exerciseType.titleZh)),
                    subtitle: Text(
                      '${entry.level.code} · '
                      '${entry.totalScore}/${entry.maxScore} · '
                      '${_formatDate(entry.submittedAt ?? entry.createdAt)}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ExerciseResultScreen(exerciseId: entry.id),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final now = DateTime.now();
    final sameDay =
        now.year == date.year && now.month == date.month && now.day == date.day;
    String two(int value) => value.toString().padLeft(2, '0');
    return sameDay
        ? '${two(date.hour)}:${two(date.minute)}'
        : '${date.year}-${two(date.month)}-${two(date.day)}';
  }
}

class _SkillCard extends StatelessWidget {
  final TrainingSkill skill;

  const _SkillCard({required this.skill});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final implemented = ExerciseType.forSkill(
      skill,
    ).where((t) => t.implemented).length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ExerciseTypeScreen(skill: skill)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  trainingSkillIcon(skill),
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          skill.germanName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.tr(skill.titleZh),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.trArgs('{0} 个题型可用', [implemented]),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr('尚未配置 AI API Key，练习题无法生成（请到设置页配置）'),
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
