import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../data/database/app_database.dart';
import '../../../data/database/daos/exercise_dao.dart';
import '../../../data/models/training.dart';
import '../../../providers/database_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/training_provider.dart';
import '../../../ui/utils/selection_sentence.dart';
import '../../../ui/utils/wide_layout.dart';
import '../../../ui/widgets/entrance.dart';
import '../../../ui/widgets/context_lookup_sheet.dart';
import 'exercise_player_screen.dart';
import 'training_setup_screen.dart';

/// 结果页：得分、逐题对错、正确答案、解析、听写差异与写作 Rubric
///
/// 平板布局（≥ 720dp）：左侧是题目列表（带每题得分），右侧显示所选题目的
/// 详细结果（用户答案 / 正确答案 / 解析 / 评分维度），避免长列表来回滚动。
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

class _ResultBody extends ConsumerStatefulWidget {
  final ExerciseResultView view;

  const _ResultBody({required this.view});

  @override
  ConsumerState<_ResultBody> createState() => _ResultBodyState();
}

class _ResultBodyState extends ConsumerState<_ResultBody> {
  int _selected = 0;

  /// 重练错题：本地克隆错题为新练习（不重新调用 AI），直接进入答题页
  Future<void> _redoWrong() async {
    final db = ref.read(databaseProvider);
    if (db == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final newId = await db.exerciseDao.cloneWrongQuestions(
      widget.view.exercise.id,
    );
    if (!mounted) return;

    if (newId == null) {
      messenger.showSnackBar(SnackBar(content: Text(context.tr('本次没有错题'))));
      return;
    }

    ref.invalidate(trainingHistoryProvider);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExercisePlayerScreen(exerciseId: newId),
      ),
    );
    if (!mounted) return;
    ref.invalidate(trainingResultProvider(widget.view.exercise.id));
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final exercise = view.exercise;
    final type = ExerciseType.fromCode(exercise.exerciseType);
    final ratio = exercise.maxScore == 0
        ? 0.0
        : exercise.totalScore / exercise.maxScore;

    final header = _ScoreHeader(
      score: exercise.totalScore,
      maxScore: exercise.maxScore,
      ratio: ratio,
      type: type,
      level: exercise.level,
      difficulty: exercise.difficulty,
      topic: exercise.topic,
      durationSeconds: exercise.durationSeconds,
    );

    final wrongCount = view.items.where((item) {
      final attempt = view.attemptOf(item.question.key);
      return attempt != null && !attempt.isCorrect;
    }).length;

    final actions = Row(
      children: [
        if (wrongCount > 0) ...[
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: _redoWrong,
              icon: const Icon(Icons.replay),
              label: Text(context.tr('重练错题')),
            ),
          ),
          const SizedBox(width: 12),
        ],
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
    );

    if (!WideLayout.isWide(context) || view.items.length < 2) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          header,
          // 阅读理解 / 完形填空：结果页也要能看到原文（可折叠，默认展开）
          if (exercise.stimulusText.isNotEmpty) ...[
            const SizedBox(height: 12),
            _StimulusSection(
              text: exercise.stimulusText,
              isListening: type.skill == TrainingSkill.listening,
              cefrLevel: exercise.level,
            ),
          ],
          const SizedBox(height: 16),
          for (var i = 0; i < view.items.length; i++)
            _QuestionReview(
              item: view.items[i],
              attempt: view.attemptOf(view.items[i].question.key),
              index: i,
              total: view.items.length,
              asCard: true,
            ),
          const SizedBox(height: 8),
          actions,
        ],
      );
    }

    // 宽屏：左原文，右栏内部 = 结果详情 + 底部小网格选题
    final index = _selected.clamp(0, view.items.length - 1);
    final item = view.items[index];
    final hasStimulus = exercise.stimulusText.isNotEmpty;

    final detail = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 16),
      child: _QuestionReview(
        item: item,
        attempt: view.attemptOf(item.question.key),
        index: index,
        total: view.items.length,
        asCard: false,
      ),
    );

    // 右栏：详情占满剩余高度，小网格固定在右栏底部（不跨到原文那一栏）
    final rightPane = Column(
      children: [
        Expanded(child: detail),
        const Divider(height: 1),
        _QuestionGrid(
          items: view.items,
          attemptsByKey: {
            for (final entry in view.items)
              entry.question.key: view.attemptOf(entry.question.key),
          },
          selected: index,
          onSelected: (value) => setState(() => _selected = value),
        ),
      ],
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: header,
        ),
        const Divider(height: 1),
        Expanded(
          child: hasStimulus
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 2,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
                        children: [
                          _StimulusSection(
                            text: exercise.stimulusText,
                            isListening: type.skill == TrainingSkill.listening,
                            cefrLevel: exercise.level,
                          ),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1, thickness: 1),
                    Expanded(flex: 3, child: rightPane),
                  ],
                )
              : rightPane,
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: actions,
          ),
        ),
      ],
    );
  }
}

/// 右栏底部的题目小网格：只显示「第 N 题」+ 对错标志，可上下滚动
class _QuestionGrid extends StatelessWidget {
  final List<ExerciseQuestionView> items;
  final Map<String, ExerciseAttempt?> attemptsByKey;
  final int selected;
  final ValueChanged<int> onSelected;

  const _QuestionGrid({
    required this.items,
    required this.attemptsByKey,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 100),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < items.length; i++)
              Entrance(
                index: i,
                duration: const Duration(milliseconds: 260),
                stagger: const Duration(milliseconds: 30),
                offsetY: 0.06,
                child: _buildChip(context, i),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final attempt = attemptsByKey[items[index].question.key];
    final isCorrect = attempt?.isCorrect ?? false;
    final isPartial = attempt?.isPartial ?? false;
    final unavailable = attempt?.graderType == 'unavailable';
    final statusColor = unavailable
        ? colorScheme.outline
        : isCorrect
        ? Colors.green
        : isPartial
        ? Colors.orange
        : colorScheme.error;

    return Material(
      color: index == selected
          ? colorScheme.secondaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onSelected(index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                unavailable
                    ? Icons.help_outline
                    : isCorrect
                    ? Icons.check_circle
                    : isPartial
                    ? Icons.adjust
                    : Icons.cancel,
                size: 14,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Text(
                context.trArgs('第 {0} 题', [index + 1]),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ),
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

    // 紧凑两行：得分 + 百分比 + 类型/等级等元信息，避免占掉半屏
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // 得分从 0 滚到实际分数（easeOutCubic，非线性）
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: score),
            duration: const Duration(milliseconds: 650),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => Text(
              '$value',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onPrimaryContainer,
                height: 1.1,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 2),
            child: Text(
              '/$maxScore',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Entrance(
            index: 1,
            duration: const Duration(milliseconds: 420),
            offsetY: 0.05,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.onPrimaryContainer.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$percent%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${context.tr(type.titleZh)}'
              '${topic.isEmpty ? '' : ' · ${context.tr(topic)}'}'
              '${durationSeconds != null && durationSeconds! > 0 ? ' · ${context.trArgs('耗时 {0} 秒', [durationSeconds])}' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _MetaChip(label: level),
          const SizedBox(width: 4),
          _MetaChip(
            label: context.tr(TrainingDifficulty.fromCode(difficulty).titleZh),
          ),
        ],
      ),
    );
  }
}

/// 原文卡片（结果页：阅读短文 / 听力原文）
///
/// - 阅读：原文默认展开，可隐藏/显示；
/// - 听力：额外给播放按钮（复用 SpeechPlaybackService，德语语音不可用时
///   显示说明而不是无效按钮），方便"再听一遍"对照原文。
class _StimulusSection extends ConsumerStatefulWidget {
  final String text;
  final bool isListening;

  /// 材料 CEFR 等级（长按查词时一起交给查词引擎）
  final String? cefrLevel;

  const _StimulusSection({
    required this.text,
    this.isListening = false,
    this.cefrLevel,
  });

  @override
  ConsumerState<_StimulusSection> createState() => _StimulusSectionState();
}

class _StimulusSectionState extends ConsumerState<_StimulusSection> {
  bool _visible = true;
  bool _playing = false;
  bool _speechChecked = false;
  bool _speechAvailable = true;

  @override
  void initState() {
    super.initState();
    if (widget.isListening) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _prepareSpeech());
    }
  }

  Future<void> _prepareSpeech() async {
    final service = ref.read(trainingSpeechProvider);
    await service.initialize(rate: ref.read(settingsProvider).ttsSpeed);
    if (!mounted) return;
    setState(() {
      _speechChecked = true;
      _speechAvailable = service.isAvailable;
    });
  }

  Future<void> _togglePlay() async {
    final service = ref.read(trainingSpeechProvider);
    if (_playing) {
      await service.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    await service.speak(widget.text);
    if (mounted) setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = context.tr(widget.isListening ? '听力原文' : '原文');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: theme.textTheme.labelMedium),
              const Spacer(),
              if (widget.isListening) ...[
                if (!_speechChecked)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else if (_speechAvailable)
                  IconButton(
                    tooltip: _playing ? context.tr('停止') : context.tr('播放'),
                    visualDensity: VisualDensity.compact,
                    iconSize: 20,
                    onPressed: _togglePlay,
                    icon: Icon(
                      _playing
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_outline,
                    ),
                  ),
              ],
              TextButton.icon(
                onPressed: () => setState(() => _visible = !_visible),
                icon: Icon(
                  _visible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
                label: Text(_visible ? context.tr('隐藏原文') : context.tr('显示原文')),
              ),
            ],
          ),
          if (widget.isListening && _speechChecked && !_speechAvailable)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                context.tr('此设备没有德语语音，无法播放听力材料'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (_visible)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SingleChildScrollView(
                child: _buildSelectableText(context),
              ),
            ),
        ],
      ),
    );
  }

  /// 原文同样支持长按查词：选区文本 + 所在句子一起交给语境查词面板
  Widget _buildSelectableText(BuildContext context) {
    final theme = Theme.of(context);
    return SelectableText(
      widget.text,
      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
      contextMenuBuilder: (menuContext, editableTextState) {
        final value = editableTextState.textEditingValue;
        final selection = value.selection;
        final selected = selection.isValid && !selection.isCollapsed
            ? selection.textInside(value.text).trim()
            : '';
        final sentence = selected.isEmpty
            ? null
            : sentenceAtOffset(value.text, selection.start);

        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: editableTextState.contextMenuAnchors,
          buttonItems: [
            if (selected.isNotEmpty)
              ContextMenuButtonItem(
                label: context.tr('查词'),
                onPressed: () {
                  editableTextState.hideToolbar();
                  ContextLookupSheet.show(
                    context,
                    selectedText: selected,
                    sentence: sentence,
                    surrounding: widget.text,
                    cefrLevel: widget.cefrLevel,
                  );
                },
              ),
            ContextMenuButtonItem(
              label: context.tr('复制'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: selected));
                editableTextState.hideToolbar();
              },
            ),
          ],
        );
      },
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

  /// 是否包一层 Card（窄屏列表用）；宽屏右栏直接铺开
  final bool asCard;

  const _QuestionReview({
    required this.item,
    required this.attempt,
    required this.index,
    required this.total,
    this.asCard = true,
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

    final content = Column(
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
        if (question.contextText != null && question.contextText!.isNotEmpty)
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
                Text(context.tr('解析'), style: theme.textTheme.labelMedium),
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
    );

    if (!asCard) return content;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(padding: const EdgeInsets.all(16), child: content),
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
          .map(
            (i) => i < question.options.length
                ? String.fromCharCode(65 + i)
                : '${i + 1}',
          )
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
                fontWeight: highlight == null
                    ? FontWeight.w500
                    : FontWeight.w600,
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
