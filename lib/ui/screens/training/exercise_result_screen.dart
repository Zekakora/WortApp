import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/exercise_dao.dart';
import '../../../data/models/training.dart';
import '../../../providers/training_provider.dart';
import 'training_setup_screen.dart';

/// 结果页：得分、逐题对错、正确答案、解析、听写差异与写作 Rubric
class ExerciseResultScreen extends ConsumerWidget {
  final int exerciseId;

  const ExerciseResultScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncResult = ref.watch(trainingResultProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('练习结果'))),
      body: asyncResult.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(context.trArgs('读取结果失败: {0}', [error])),
          ),
        ),
        data: (view) {
          if (view == null) {
            return Center(child: Text(context.tr('练习不存在或已被删除')));
          }
          return _ResultBody(view: view);
        },
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  final ExerciseResultView view;

  const _ResultBody({required this.view});

  @override
  Widget build(BuildContext context) {
    final exercise = view.exercise;
    final type = ExerciseType.fromCode(exercise.exerciseType);
    final total = exercise.maxScore == 0
        ? 0.0
        : exercise.totalScore / exercise.maxScore;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _ScoreHeader(
          score: exercise.totalScore,
          maxScore: exercise.maxScore,
          ratio: total,
          type: type,
          level: exercise.level,
          difficulty: exercise.difficulty,
          topic: exercise.topic,
          durationSeconds: exercise.durationSeconds,
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < view.items.length; i++)
          _QuestionReview(
            item: view.items[i],
            attempt: view.attemptOf(view.items[i].question.key),
            index: i,
            total: view.items.length,
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => TrainingSetupScreen(type: type),
                  ),
                ),
                icon: const Icon(Icons.refresh),
                label: Text(context.tr('再练一次')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.check),
                label: Text(context.tr('完成')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final int score;
  final int maxScore;
  final double ratio;
  final ExerciseType type;
  final String level;
  final String difficulty;
  final String topic;
  final int? durationSeconds;

  const _ScoreHeader({
    required this.score,
    required this.maxScore,
    required this.ratio,
    required this.type,
    required this.level,
    required this.difficulty,
    required this.topic,
    this.durationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percent = (ratio * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$score',
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  '/ $maxScore',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$percent%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.tr(type.titleZh),
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _MetaChip(label: level),
              _MetaChip(
                label: context.tr(TrainingDifficulty.fromCode(difficulty).titleZh),
              ),
              if (topic.isNotEmpty) _MetaChip(label: context.tr(topic)),
              if (durationSeconds != null && durationSeconds! > 0)
                _MetaChip(
                  label: context.trArgs('耗时 {0} 秒', [durationSeconds]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _QuestionReview extends StatelessWidget {
  final ExerciseQuestionView item;
  final ExerciseAttempt? attempt;
  final int index;
  final int total;

  const _QuestionReview({
    required this.item,
    required this.attempt,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final question = item.question;
    final solution = item.solution;
    final isCorrect = attempt?.isCorrect ?? false;
    final isPartial = attempt?.isPartial ?? false;
    final unavailable = attempt?.graderType == 'unavailable';
    final feedback = _decode(attempt?.feedbackJson);

    final statusColor = unavailable
        ? colorScheme.outline
        : isCorrect
            ? Colors.green
            : isPartial
                ? Colors.orange
                : colorScheme.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  unavailable
                      ? Icons.help_outline
                      : isCorrect
                          ? Icons.check_circle
                          : isPartial
                              ? Icons.adjust
                              : Icons.cancel,
                  size: 18,
                  color: statusColor,
                ),
                const SizedBox(width: 6),
                Text(
                  context.trArgs('第 {0} / {1} 题', [index + 1, total]),
                  style: theme.textTheme.labelMedium,
                ),
                const Spacer(),
                Text(
                  '${_fmt(attempt?.score ?? 0)} / ${_fmt(attempt?.maxScore ?? question.points)}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (question.contextText != null &&
                question.contextText!.isNotEmpty)
              Text(
                question.contextText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            Text(question.prompt, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 12),
            _AnswerRow(
              label: context.tr('你的答案'),
              value: _formatUserAnswer(question, attempt?.userAnswer ?? ''),
              highlight: statusColor,
            ),
            _AnswerRow(
              label: context.tr('正确答案'),
              value: _formatCorrectAnswer(question, solution),
              highlight: null,
            ),
            if (unavailable)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  context.tr('本题评分暂不可用，已保留你的答案'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (feedback != null) _FeedbackBlock(feedback: feedback),
            if (solution.explanation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('解析'),
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      solution.explanation,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _fmt(num value) =>
      value == value.roundToDouble() ? value.round().toString() : '$value';

  static Map<String, dynamic>? _decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // 忽略损坏的反馈
    }
    return null;
  }

  /// 选择题把下标转成字母，其余原样
  static String _formatUserAnswer(PlaybackQuestion question, String raw) {
    if (raw.trim().isEmpty) return '—';
    if (question.type == QuestionType.singleChoice ||
        question.type == QuestionType.multipleChoice) {
      final letters = raw
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .whereType<int>()
          .map((i) => String.fromCharCode(65 + i))
          .join(', ');
      return letters.isEmpty ? raw : letters;
    }
    if (question.type == QuestionType.trueFalse) {
      return raw == 'true' ? 'richtig' : (raw == 'false' ? 'falsch' : raw);
    }
    return raw;
  }

  static String _formatCorrectAnswer(
    PlaybackQuestion question,
    QuestionSolution solution,
  ) {
    final key = solution.answerKey;
    if (key.correctIndices.isNotEmpty) {
      final letters = key.correctIndices
          .map((i) => i < question.options.length
              ? String.fromCharCode(65 + i)
              : '${i + 1}')
          .join(', ');
      final optionTexts = key.correctIndices
          .where((i) => i < question.options.length)
          .map((i) => question.options[i])
          .join(' / ');
      return optionTexts.isEmpty ? letters : '$letters · $optionTexts';
    }
    if (key.acceptedAnswers.isNotEmpty) return key.acceptedAnswers.join(' / ');
    if (key.correctOrder.isNotEmpty) return key.correctOrder.join(' → ');
    if (key.referenceAnswers.isNotEmpty) {
      return key.referenceAnswers.first;
    }
    return '—';
  }
}

class _AnswerRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? highlight;

  const _AnswerRow({
    required this.label,
    required this.value,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 76,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                color: highlight,
                fontWeight:
                    highlight == null ? FontWeight.w500 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 结构化反馈：听写差异 / 写作 Rubric
class _FeedbackBlock extends StatelessWidget {
  final Map<String, dynamic> feedback;

  const _FeedbackBlock({required this.feedback});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dimensions = feedback['dimensions'];
    final corrections = feedback['corrections'];
    final diffs = feedback['diffs'];
    final overall = feedback['overallFeedback']?.toString() ?? '';

    if (dimensions is! List && corrections is! List && diffs is! List) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 听写：逐词差异
          if (diffs is List && diffs.isNotEmpty) ...[
            Text(context.tr('听写差异'), style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final diff in diffs.whereType<Map>())
                  _DiffChip(diff: Map<String, dynamic>.from(diff)),
              ],
            ),
          ],
          // 写作：维度评分
          if (dimensions is List && dimensions.isNotEmpty) ...[
            Text(context.tr('评分维度'), style: theme.textTheme.labelMedium),
            const SizedBox(height: 6),
            for (final dimension in dimensions.whereType<Map>())
              _DimensionRow(dimension: Map<String, dynamic>.from(dimension)),
          ],
          // 写作：逐项纠错
          if (corrections is List && corrections.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(context.tr('修改建议'), style: theme.textTheme.labelMedium),
            const SizedBox(height: 4),
            for (final correction in corrections.whereType<Map>())
              _CorrectionRow(correction: Map<String, dynamic>.from(correction)),
          ],
          if (overall.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              overall,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiffChip extends StatelessWidget {
  final Map<String, dynamic> diff;

  const _DiffChip({required this.diff});

  @override
  Widget build(BuildContext context) {
    final kind = diff['kind']?.toString() ?? '';
    final expected = diff['expected']?.toString();
    final actual = diff['actual']?.toString();
    final (label, color) = switch (kind) {
      'missing' => ('漏写 $expected', Colors.orange),
      'replaced' => ('写错 $actual → $expected', Colors.red),
      'spelling' => ('拼写 $actual → $expected', Colors.deepOrange),
      'extra' => ('多写 $actual', Colors.blueGrey),
      'caseOnly' => ('大小写 $actual → $expected', Colors.blue),
      _ => (kind, Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _DimensionRow extends StatelessWidget {
  final Map<String, dynamic> dimension;

  const _DimensionRow({required this.dimension});

  @override
  Widget build(BuildContext context) {
    final name = dimension['name']?.toString() ?? '';
    final score = (dimension['score'] as num?)?.toDouble() ?? 0;
    final maxScore = (dimension['maxScore'] as num?)?.toDouble() ?? 1;
    final feedback = dimension['feedback']?.toString() ?? '';
    final ratio = maxScore <= 0 ? 0.0 : (score / maxScore).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  _dimensionLabel(context, name),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(value: ratio, minHeight: 6),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${score.toStringAsFixed(score == score.roundToDouble() ? 0 : 1)}/${maxScore.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
          if (feedback.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 120, top: 2),
              child: Text(
                feedback,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
        ],
      ),
    );
  }

  /// 维度名本地化（模型可能返回英文键）
  static String _dimensionLabel(BuildContext context, String name) {
    final zh = switch (name) {
      'grammar' => '语法',
      'vocabulary' => '词汇',
      'sentenceStructure' => '句法',
      'taskCompletion' => '任务完成',
      'naturalness' => '自然度',
      'coherence' => '连贯性',
      _ => name,
    };
    return zh == name ? name : context.tr(zh);
  }
}

class _CorrectionRow extends StatelessWidget {
  final Map<String, dynamic> correction;

  const _CorrectionRow({required this.correction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final original = correction['original']?.toString() ?? '';
    final suggestion = correction['suggestion']?.toString() ?? '';
    final reason = correction['reason']?.toString() ?? '';
    final certain = correction['certain'] != false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                certain ? Icons.error_outline : Icons.lightbulb_outline,
                size: 14,
                color: certain ? theme.colorScheme.error : Colors.orange,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  certain ? context.tr('确定错误') : context.tr('改进建议'),
                  style: theme.textTheme.labelSmall,
                ),
              ),
            ],
          ),
          if (original.isNotEmpty)
            Text(
              original,
              style: theme.textTheme.bodySmall?.copyWith(
                decoration: TextDecoration.lineThrough,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          if (suggestion.isNotEmpty)
            Text(
              suggestion,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          if (reason.isNotEmpty)
            Text(
              reason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}
