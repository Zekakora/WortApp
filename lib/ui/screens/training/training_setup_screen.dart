import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../data/models/training.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/training_provider.dart';
import '../../../services/training/exercise_generator.dart';
import '../../../ui/utils/wide_layout.dart';
import 'exercise_player_screen.dart';

/// 训练设置：等级 / 难度 / 题量 / 主题 / 词汇范围
///
/// - CEFR 等级与难度是**两个维度**（任务书 §2），分开选择；
/// - 所有选项（含「优先使用近期学习的词汇」）都会即时写入 settings 表，
///   下次进入默认就是上次的选择；
/// - 平板（≥ 720dp）：左栏选项、右栏当前选择摘要 + 开始按钮，避免底部按钮
///   被推到屏幕外。
class TrainingSetupScreen extends ConsumerStatefulWidget {
  final ExerciseType type;

  const TrainingSetupScreen({super.key, required this.type});

  @override
  ConsumerState<TrainingSetupScreen> createState() =>
      _TrainingSetupScreenState();
}

class _TrainingSetupScreenState extends ConsumerState<TrainingSetupScreen> {
  CefrLevel _level = CefrLevel.b1;
  TrainingDifficulty _difficulty = TrainingDifficulty.normal;
  int _count = 5;
  String _topic = '';
  bool _useVocabularyFocus = false;
  bool _starting = false;

  /// 是否已经把上次保存的选项填进控件（只填一次，之后以用户操作为准）
  bool _prefilled = false;

  void _prefill(TrainingPrefs prefs) {
    if (_prefilled) return;
    _level = prefs.level;
    _difficulty = prefs.difficulty;
    _count = prefs.questionCount;
    _topic = prefs.topic;
    _useVocabularyFocus = prefs.useVocabularyFocus;
    _prefilled = true;
  }

  /// 记忆当前选项（每次改动立即落库，不依赖"点了开始才保存"）
  void _persist() {
    ref
        .read(trainingPrefsProvider.notifier)
        .save(
          TrainingPrefs(
            level: _level,
            difficulty: _difficulty,
            questionCount: _count,
            topic: _topic,
            useVocabularyFocus: _useVocabularyFocus,
            isLoaded: true,
          ),
        );
  }

  void _update(void Function() change) {
    setState(change);
    _persist();
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(trainingPrefsProvider);

    // 设置读库是异步的：先等加载完，避免"默认值闪一下再跳成上次的选择"
    if (!prefs.isLoaded) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr(widget.type.titleZh))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    _prefill(prefs);

    final settings = ref.watch(settingsProvider);
    final aiConfigured = settings.aiConfig.isConfigured;
    final vocabFocus =
        ref.watch(trainingVocabularyFocusProvider).valueOrNull ??
        const TrainingVocabularyFocus();
    final isWide = WideLayout.isWide(context);

    final options = _buildOptions(context, vocabFocus);
    final panel = _buildStartPanel(context, aiConfigured);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr(widget.type.titleZh))),
      body: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 24),
                    children: options,
                  ),
                ),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(
                  flex: 2,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 20, 24),
                    children: panel,
                  ),
                ),
              ],
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [...options, const SizedBox(height: 8), ...panel],
            ),
    );
  }

  /// 左栏：题目说明 + 各选项
  List<Widget> _buildOptions(
    BuildContext context,
    TrainingVocabularyFocus vocabFocus,
  ) {
    return [
      Text(
        context.tr(widget.type.descZh),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 16),
      _SectionTitle(context.tr('CEFR 等级')),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final level in CefrLevel.values)
            ChoiceChip(
              label: Text(level.code),
              selected: _level == level,
              onSelected: (_) => _update(() => _level = level),
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
            _update(() => _difficulty = selection.first),
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
              onSelected: (_) => _update(() => _count = count),
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
            onSelected: (_) => _update(() => _topic = ''),
          ),
          for (final topic in trainingTopics)
            ChoiceChip(
              label: Text(context.tr(topic)),
              selected: _topic == topic,
              onSelected: (_) => _update(() => _topic = topic),
            ),
        ],
      ),
      if (!vocabFocus.isEmpty) ...[
        const SizedBox(height: 16),
        _SectionTitle(context.tr('词汇范围')),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(context.tr('优先使用近期学习的词汇')),
          subtitle: Text(
            context.trArgs(
              '从「{0}」取 {1} 个词（今日学习 / 待复习 / 收藏）作参考，不必全部出现',
              [vocabFocus.deckName, vocabFocus.words.length],
            ),
          ),
          value: _useVocabularyFocus,
          onChanged: (value) => _update(() => _useVocabularyFocus = value),
        ),
      ],
    ];
  }

  /// 右栏：当前选择摘要 + 开始按钮
  List<Widget> _buildStartPanel(BuildContext context, bool aiConfigured) {
    return [
      _SummaryCard(
        type: widget.type,
        level: _level,
        difficulty: _difficulty,
        count: _count,
        topic: _topic,
        useVocabularyFocus: _useVocabularyFocus,
      ),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _starting || !aiConfigured ? null : _start,
        icon: _starting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow),
        label: Text(_starting ? context.tr('正在生成题目…') : context.tr('开始练习')),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      if (!aiConfigured) ...[
        const SizedBox(height: 12),
        const _AiWarningBanner(),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            context.tr('训练题目由 AI 生成，请先在设置中配置 AI API Key'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    ];
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    _persist();

    final focus =
        ref.read(trainingVocabularyFocusProvider).valueOrNull ??
            const TrainingVocabularyFocus();
    final vocabularyFocus = _useVocabularyFocus && !focus.isEmpty
        ? focus.promptText
        : null;

    final id = await ref
        .read(trainingSessionProvider.notifier)
        .start(
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
      final error =
          ref.read(trainingSessionProvider).error ?? context.tr('生成失败');
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

    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ExercisePlayerScreen()));
    // 答题页返回后，如果已经提交，历史列表需要刷新
    ref.invalidate(trainingHistoryProvider);
  }
}

/// 当前选择摘要（宽屏右栏 / 窄屏底部）
class _SummaryCard extends StatelessWidget {
  final ExerciseType type;
  final CefrLevel level;
  final TrainingDifficulty difficulty;
  final int count;
  final String topic;
  final bool useVocabularyFocus;

  const _SummaryCard({
    required this.type,
    required this.level,
    required this.difficulty,
    required this.count,
    required this.topic,
    required this.useVocabularyFocus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            type.skill.germanName,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(context.tr(type.titleZh), style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _Chip(text: level.code),
              _Chip(text: context.tr(difficulty.titleZh)),
              _Chip(text: context.trArgs('{0} 题', [count])),
              _Chip(
                text: topic.isEmpty ? context.tr('随机主题') : context.tr(topic),
              ),
              if (useVocabularyFocus) _Chip(text: context.tr('近期词汇')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String text;

  const _Chip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}

class _AiWarningBanner extends StatelessWidget {
  const _AiWarningBanner();

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
              context.tr('尚未配置 AI API Key，无法生成练习题'),
              style: TextStyle(color: colorScheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
