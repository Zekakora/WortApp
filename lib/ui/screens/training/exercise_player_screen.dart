import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../data/database/daos/exercise_dao.dart';
import '../../../data/models/training.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/training_provider.dart';
import '../../../ui/utils/wide_layout.dart';
import '../../../ui/widgets/context_lookup_sheet.dart';
import 'exercise_result_screen.dart';
import 'widgets/question_input.dart';
import 'widgets/stimulus_view.dart';

/// 答题页
///
/// 三条硬约束（任务书 §1.2 / §9）：
/// 1. 提交前不展示任何正确答案与解析（题目数据来自不含答案的 `getPlayback`）；
/// 2. 听力理解题在提交前不展示原文；
/// 3. 退出时明确询问"保存草稿 / 放弃"，已提交的练习一定保留。
///
/// 平板布局（≥ 720dp）：左栏放材料（阅读原文 / 听力音频 / 题型要求），
/// 右栏放题干与作答区，两栏各自独立滚动；窄屏保持单栏上下顺序。
class ExercisePlayerScreen extends ConsumerStatefulWidget {
  /// 从历史继续作答时传入；直接在生成后进入时为 null
  final int? exerciseId;

  const ExercisePlayerScreen({super.key, this.exerciseId});

  @override
  ConsumerState<ExercisePlayerScreen> createState() =>
      _ExercisePlayerScreenState();
}

class _ExercisePlayerScreenState extends ConsumerState<ExercisePlayerScreen> {
  bool _allowPop = false;
  bool _speechReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(trainingSessionProvider.notifier);
      final session = ref.read(trainingSessionProvider);
      if (widget.exerciseId != null &&
          session.playback?.exercise.id != widget.exerciseId) {
        await notifier.load(widget.exerciseId!);
      }
      final service = ref.read(trainingSpeechProvider);
      await service.initialize(rate: ref.read(settingsProvider).ttsSpeed);
      if (mounted) setState(() => _speechReady = service.isAvailable);
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(trainingSessionProvider);
    final playback = session.playback;

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _confirmExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: playback == null
              ? Text(context.tr('AI 训练'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(
                        ExerciseType.fromCode(
                          playback.exercise.exerciseType,
                        ).titleZh,
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${playback.exercise.level} · '
                      '${context.tr(TrainingDifficulty.fromCode(playback.exercise.difficulty).titleZh)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: context.tr('退出'),
            onPressed: _confirmExit,
          ),
        ),
        body: _buildBody(context, session),
      ),
    );
  }

  Widget _buildBody(BuildContext context, TrainingSessionState session) {
    if (session.isBusy) {
      return _BusyView(
        title: session.hasExercise
            ? context.tr('正在批改…')
            : context.tr('AI 正在出题…'),
        subtitle: session.hasExercise
            ? context.tr('写作类题目由 AI 按评分标准批改，请稍候')
            : context.tr('根据你的等级、难度和主题生成题目，通常 10–30 秒'),
      );
    }

    if (session.error != null) {
      return _ErrorView(
        message: session.error!,
        onRetry: () {
          ref.read(trainingSessionProvider.notifier).clearError();
          if (widget.exerciseId != null) {
            ref.read(trainingSessionProvider.notifier).load(widget.exerciseId!);
          }
        },
      );
    }

    final playback = session.playback;
    final question = session.currentQuestion;
    if (playback == null || question == null) {
      return _BusyView(title: context.tr('正在加载练习…'), subtitle: '');
    }

    final isWide = WideLayout.isWide(context);

    return Column(
      children: [
        LinearProgressIndicator(
          value: session.total == 0
              ? 0
              : (session.currentIndex + 1) / session.total,
          minHeight: 4,
        ),
        Expanded(
          child: isWide
              ? _buildWide(context, session, playback, question)
              : _buildNarrow(context, session, playback, question),
        ),
        _buildBottomBar(context, session),
      ],
    );
  }

  /// 窄屏：单栏上下滚动（原有布局）
  Widget _buildNarrow(
    BuildContext context,
    TrainingSessionState session,
    ExercisePlayback playback,
    PlaybackQuestion question,
  ) {
    final isListening =
        ExerciseType.fromCode(playback.exercise.exerciseType).skill ==
        TrainingSkill.listening;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        ..._headerSlivers(context, playback),
        if (playback.exercise.stimulusText.isNotEmpty) ...[
          StimulusView(
            text: playback.exercise.stimulusText,
            kind: playback.exercise.stimulusKind,
            onLookup: isListening ? null : _openLookup,
            revealed: false,
          ),
          const SizedBox(height: 16),
        ],
        _QuestionCard(
          question: question,
          index: session.currentIndex,
          total: session.total,
        ),
        const SizedBox(height: 12),
        _buildInput(context, session, playback, question),
        ..._noticeSlivers(context, session),
        const SizedBox(height: 24),
      ],
    );
  }

  /// 宽屏：左材料 / 右题目+作答，两栏独立滚动
  Widget _buildWide(
    BuildContext context,
    TrainingSessionState session,
    ExercisePlayback playback,
    PlaybackQuestion question,
  ) {
    final isListening =
        ExerciseType.fromCode(playback.exercise.exerciseType).skill ==
        TrainingSkill.listening;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._headerSlivers(context, playback),
                if (playback.exercise.stimulusText.isNotEmpty)
                  StimulusView(
                    text: playback.exercise.stimulusText,
                    kind: playback.exercise.stimulusKind,
                    onLookup: isListening ? null : _openLookup,
                    revealed: false,
                  )
                else
                  _RequirementCard(playback: playback),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _QuestionCard(
                  question: question,
                  index: session.currentIndex,
                  total: session.total,
                ),
                const SizedBox(height: 12),
                _buildInput(context, session, playback, question),
                ..._noticeSlivers(context, session),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _headerSlivers(BuildContext context, ExercisePlayback playback) {
    return [
      if (playback.exercise.title.isNotEmpty)
        Text(
          playback.exercise.title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
      if (playback.exercise.instructions.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: Text(
            playback.exercise.instructions,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
    ];
  }

  Widget _buildInput(
    BuildContext context,
    TrainingSessionState session,
    ExercisePlayback playback,
    PlaybackQuestion question,
  ) {
    return QuestionInput(
      key: ValueKey('${playback.exercise.id}-${question.key}'),
      question: question,
      initialValue: session.answers[question.key] ?? '',
      onChanged: (value) => ref
          .read(trainingSessionProvider.notifier)
          .setAnswer(question.key, value),
      onPlayAudio: () => _playDictation(question),
      audioAvailable: _speechReady,
    );
  }

  List<Widget> _noticeSlivers(
    BuildContext context,
    TrainingSessionState session,
  ) {
    if (session.notices.isEmpty) return const [];
    return [
      const SizedBox(height: 12),
      for (final notice in session.notices)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            notice,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
    ];
  }

  Widget _buildBottomBar(BuildContext context, TrainingSessionState session) {
    final isLast = session.isLast;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: session.currentIndex > 0
                  ? () => ref.read(trainingSessionProvider.notifier).previous()
                  : null,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(context.tr('上一题')),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {
                if (isLast) {
                  _confirmSubmit();
                } else {
                  ref.read(trainingSessionProvider.notifier).next();
                }
              },
              child: Text(isLast ? context.tr('提交') : context.tr('下一题')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playDictation(PlaybackQuestion question) async {
    final text = question.audioText;
    if (text == null || text.isEmpty) return;
    await ref.read(trainingSpeechProvider).speak(text);
  }

  void _openLookup(String selected, String? sentence, String? surrounding) {
    final playback = ref.read(trainingSessionProvider).playback;
    ContextLookupSheet.show(
      context,
      selectedText: selected,
      sentence: sentence,
      surrounding: surrounding,
      cefrLevel: playback?.exercise.level,
    );
  }

  Future<void> _confirmSubmit() async {
    final session = ref.read(trainingSessionProvider);
    final unanswered =
        session.total -
        session.answers.values.where((v) => v.trim().isNotEmpty).length;
    if (unanswered > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(dialogContext.tr('还有题目未作答')),
          content: Text(
            dialogContext.trArgs('还有 {0} 题未作答，确定提交吗？', [unanswered]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(dialogContext.tr('继续作答')),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(dialogContext.tr('仍然提交')),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    final id = await ref.read(trainingSessionProvider.notifier).submit();
    if (!mounted) return;
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ref.read(trainingSessionProvider).error ?? context.tr('提交失败'),
          ),
        ),
      );
      return;
    }
    ref.invalidate(trainingHistoryProvider);
    setState(() => _allowPop = true);
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => ExerciseResultScreen(exerciseId: id)),
    );
  }

  Future<void> _confirmExit() async {
    final notifier = ref.read(trainingSessionProvider.notifier);
    final session = ref.read(trainingSessionProvider);

    if (!session.hasExercise) {
      setState(() => _allowPop = true);
      Navigator.of(context).pop();
      return;
    }

    final choice = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('退出本次练习？')),
        content: Text(dialogContext.tr('未提交的练习可以保存草稿，稍后从历史记录继续；已提交的练习一定会保留。')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('cancel'),
            child: Text(dialogContext.tr('继续作答')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop('discard'),
            child: Text(dialogContext.tr('放弃')),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop('save'),
            child: Text(dialogContext.tr('保存草稿并退出')),
          ),
        ],
      ),
    );

    if (choice == null || choice == 'cancel') return;
    if (choice == 'save') {
      await notifier.saveDraft();
      ref.invalidate(trainingHistoryProvider);
    }
    if (!mounted) return;
    setState(() => _allowPop = true);
    Navigator.of(context).pop();
  }
}

/// 没有材料时的左栏内容：题型说明（题干在右栏，避免同一个题干显示两遍）
class _RequirementCard extends StatelessWidget {
  final ExercisePlayback playback;

  const _RequirementCard({required this.playback});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final type = ExerciseType.fromCode(playback.exercise.exerciseType);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr(type.titleZh), style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            context.tr(type.descZh),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  final PlaybackQuestion question;
  final int index;
  final int total;

  const _QuestionCard({
    required this.question,
    required this.index,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                context.trArgs('第 {0} / {1} 题', [index + 1, total]),
                style: theme.textTheme.labelMedium,
              ),
              const Spacer(),
              Text(
                context.trArgs('{0} 分', [question.points]),
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (question.contextText != null &&
              question.contextText!.isNotEmpty) ...[
            Text(
              question.contextText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            question.prompt,
            style: theme.textTheme.titleMedium?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _BusyView extends StatelessWidget {
  final String title;
  final String subtitle;

  const _BusyView({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text(context.tr('重试')),
            ),
          ],
        ),
      ),
    );
  }
}
