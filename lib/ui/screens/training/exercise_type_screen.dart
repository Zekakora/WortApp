import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../data/models/training.dart';
import '../../../ui/utils/wide_layout.dart';
import 'training_setup_screen.dart';

/// 题型列表（某个技能下的所有题型）
class ExerciseTypeScreen extends ConsumerWidget {
  final TrainingSkill skill;

  const ExerciseTypeScreen({super.key, required this.skill});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final types = ExerciseType.forSkill(skill);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(skill.germanName),
            const SizedBox(width: 8),
            Text(
              context.tr(skill.titleZh),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 宽屏（平板）：两列卡片，充分利用横向空间
          if (!WideLayout.isWideWidth(constraints.maxWidth)) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                for (final type in types)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TypeCard(type: type),
                  ),
              ],
            );
          }
          final cardWidth = (constraints.maxWidth - 16 * 2 - 12) / 2;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final type in types)
                  SizedBox(
                    width: cardWidth,
                    child: _TypeCard(type: type),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final ExerciseType type;

  const _TypeCard({required this.type});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => TrainingSetupScreen(type: type)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconOf(type),
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(type.titleZh),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.tr(type.descZh),
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

  static IconData _iconOf(ExerciseType type) => switch (type) {
    ExerciseType.listeningComprehension => Icons.hearing,
    ExerciseType.dictation => Icons.keyboard,
    ExerciseType.listeningCloze => Icons.playlist_add_check,
    ExerciseType.dialogComprehension => Icons.forum_outlined,
    ExerciseType.listeningSentenceOrdering => Icons.swap_vert,
    ExerciseType.readingComprehension => Icons.menu_book,
    ExerciseType.readingCloze => Icons.text_fields,
    ExerciseType.contextVocabulary => Icons.translate,
    ExerciseType.trueFalseReading => Icons.rule,
    ExerciseType.paragraphOrdering => Icons.reorder,
    ExerciseType.headingMatching => Icons.title,
    ExerciseType.sentenceBuilding => Icons.construction,
    ExerciseType.errorCorrection => Icons.edit_note,
    ExerciseType.translationWriting => Icons.language,
    ExerciseType.situationalWriting => Icons.mail_outline,
    ExerciseType.freeWriting => Icons.edit,
    ExerciseType.mixedPractice => Icons.shuffle,
  };
}
