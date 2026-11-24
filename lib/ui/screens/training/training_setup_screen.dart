import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../data/models/training.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/training_provider.dart';
import '../../../services/training/exercise_generator.dart';
import 'exercise_player_screen.dart';

/// 训练设置：等级 / 难度 / 题量 / 主题 / 词汇范围
///
/// CEFR 等级与难度是**两个维度**（任务书 §2 明确要求），因此分开选择。
class TrainingSetupScreen extends ConsumerStatefulWidget {
  final ExerciseType type;

  const TrainingSetupScreen({super.key, required this.type});

  @override
  ConsumerState<TrainingSetupScreen> createState() =>
      _TrainingSetupScreenState();
}

class _TrainingSetupScreenState extends ConsumerState<TrainingSetupScreen> {
  late CefrLevel _level;
  late TrainingDifficulty _difficulty;
  late int _count;
  late String _topic;
  bool _useFavorites = false;
  bool _starting = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    final prefs = ref.read(trainingPrefsProvider);
    _level = prefs.level;
    _difficulty = prefs.difficulty;
    _count = prefs.questionCount;
    _topic = prefs.topic;
    _initialized = true;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final aiConfigured = settings.aiConfig.isConfigured;
    final favorites = ref.watch(favoriteVocabularyProvider);
    final favoriteWords = favorites.valueOrNull ?? const <String>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr(widget.type.titleZh)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            context.tr(widget.type.descZh),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          if (!aiConfigured) _AiWarningBanner(),
          _SectionTitle(context.tr('CEFR 等级')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final level in CefrLevel.values)
                ChoiceChip(
                  label: Text(level.code),
                  selected: _level == level,
                  onSelected: (_) => setState(() => _level = level),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionTitle(context.tr('难度')),
          SegmentedButton<TrainingDifficulty>(
            segments: [
              for (final difficulty in TrainingDifficulty.values)
                ButtonSegment(
                  value: difficulty,
                  label: Text(context.tr(difficulty.titleZh)),
                ),
            ],
            selected: {_difficulty},
            onSelectionChanged: (selection) =>
                setState(() => _difficulty = selection.first),
          ),
          const SizedBox(height: 16),
          _SectionTitle(context.tr('题量')),
          Wrap(
            spacing: 8,
            children: [
              for (final count in trainingQuestionCounts)
                ChoiceChip(
                  label: Text('$count'),
                  selected: _count == count,
                  onSelected: (_) => setState(() => _count = count),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _SectionTitle(context.tr('主题')),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(context.tr('随机主题')),
                selected: _topic.isEmpty,
                onSelected: (_) => setState(() => _topic = ''),
              ),
              for (final topic in trainingTopics)
                ChoiceChip(
                  label: Text(context.tr(topic)),
                  selected: _topic == topic,
                  onSelected: (_) => setState(() => _topic = topic),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (favoriteWords.isNotEmpty) ...[
            _SectionTitle(context.tr('词汇范围')),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.tr('优先使用收藏词汇')),
              subtitle: Text(
                context.trArgs('共 {0} 个收藏词，生成时会尽量用到', [
                  favoriteWords.length,
                ]),
              ),
              value: _useFavorites,
              onChanged: (value) => setState(() => _useFavorites = value),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _starting || !aiConfigured ? null : _start,
            icon: _starting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.play_arrow),
            label: Text(
              _starting ? context.tr('正在生成题目…') : context.tr('开始练习'),
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          if (!aiConfigured)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                context.tr('训练题目由 AI 生成，请先在设置中配置 AI API Key'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    final prefs = TrainingPrefs(
      level: _level,
      difficulty: _difficulty,
      questionCount: _count,
      topic: _topic,
    );
    await ref.read(trainingPrefsProvider.notifier).save(prefs);

    final favorites = ref.read(favoriteVocabularyProvider).valueOrNull ??
        const <String>[];
    final vocabularyFocus =
        _useFavorites && favorites.isNotEmpty ? favorites.join(', ') : null;

    final id = await ref.read(trainingSessionProvider.notifier).start(
          ExerciseGenerationRequest(
            type: widget.type,
            level: _level,
            difficulty: _difficulty,
            topic: _topic,
            questionCount: _count,
            vocabularyFocus: vocabularyFocus,
          ),
        );

    if (!mounted) return;
    setState(() => _starting = false);

    if (id == null) {
      final error = ref.read(trainingSessionProvider).error ??
          context.tr('生成失败');
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(dialogContext.tr('生成题目失败')),
          content: Text(error),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dialogContext.tr('知道了')),
            ),
          ],
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ExercisePlayerScreen(),
      ),
    );
    // 答题页返回后，如果已经提交，历史列表需要刷新
    ref.invalidate(trainingHistoryProvider);
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }
}

class _AiWarningBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.tr('尚未配置 AI API Key，无法生成练习题'),
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
