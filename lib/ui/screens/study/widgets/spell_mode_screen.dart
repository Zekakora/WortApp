import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import '../../../../algorithms/sm2_algorithm.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/german_parser.dart';
import '../../../../providers/study_provider.dart';
import '../../../../providers/settings_provider.dart';

/// 德语拼写模式
class SpellModeScreen extends ConsumerStatefulWidget {
  const SpellModeScreen({super.key});

  @override
  ConsumerState<SpellModeScreen> createState() => _SpellModeScreenState();
}

class _SpellModeScreenState extends ConsumerState<SpellModeScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _answered = false;
  bool? _isCorrect;
  final FlutterTts _tts = FlutterTts();
  /// 自动确认防抖定时器（停止输入一段时间后自动检查拼写）
  Timer? _debounce;
  /// 记录当前题目单词 id，用于新题下发时触发自动发音
  int _lastWordId = -1;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(ref.read(settingsProvider).ttsSpeed);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _tts.stop();
    super.dispose();
  }

  void _speak(String text) async {
    // 每次发音前应用当前设置的语速，保证设置即时生效
    await _tts.setSpeechRate(ref.read(settingsProvider).ttsSpeed);
    await _tts.speak(text);
  }

  /// 输入变化：刷新按钮状态，并在自动确认开启时调度防抖检查
  void _onInputChanged(String _) {
    setState(() {});
    _scheduleAutoCheck();
  }

  /// 自动确认开启且已有输入时，停止输入 800ms 后自动检查拼写
  void _scheduleAutoCheck() {
    if (!ref.read(settingsProvider).autoConfirm) return;
    if (_answered) return;
    if (_controller.text.trim().isEmpty) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (mounted && !_answered) _checkAnswer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(studySessionProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (session.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('拼写模式')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (session.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('拼写模式')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(session.error!),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }

    if (session.isCompleted) {
      return _buildCompletedScreen(context, colorScheme, session);
    }

    final word = session.currentWord;
    if (word == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('拼写模式')),
        body: const Center(child: Text('没有单词')),
      );
    }

    // 自动发音：题目下发时播放一次（仅当设置开启且切换到新单词）
    if (ref.read(settingsProvider).autoPlayTts && word.id != _lastWordId) {
      _lastWordId = word.id;
      final speakWord = word;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            ref.read(studySessionProvider).currentWord?.id == speakWord.id) {
          _speak(speakWord.german);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('拼写模式 (${session.currentIndex + 1}/${session.words.length})'),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: session.progress,
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  // 中文提示
                  Text(
                    word.chinese,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (word.article != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '冠词: ${word.article}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  // 播放发音按钮
                  IconButton(
                    icon: const Icon(Icons.volume_up, size: 32),
                    onPressed: () => _speak(word.german),
                  ),
                  const SizedBox(height: 32),
                  // 输入框
                  TextField(
                    controller: _controller,
                    enabled: !_answered,
                    decoration: InputDecoration(
                      hintText: '输入德语单词...',
                      errorText: _answered && _isCorrect == false
                          ? '正确答案: ${word.article != null ? "${word.article} " : ""}${word.german}'
                          : null,
                      suffixIcon: _answered
                          ? Icon(
                              _isCorrect == true
                                  ? Icons.check_circle
                                  : Icons.cancel,
                              color: _isCorrect == true
                                  ? Colors.green
                                  : Colors.red,
                            )
                          : null,
                    ),
                    onChanged: _onInputChanged,
                  ),
                  const SizedBox(height: 16),
                  // 德语特殊字符键盘
                  _buildGermanKeyboard(colorScheme),
                  const SizedBox(height: 24),
                  // 宽容拼写提示
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              size: 20, color: colorScheme.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '支持宽容拼写: ae→ä, oe→ö, ue→ü, ss→ß',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildBottomButton(colorScheme),
          if (_answered) _buildFeedbackButtons(colorScheme),
        ],
      ),
    );
  }

  Widget _buildGermanKeyboard(ColorScheme colorScheme) {
    const specialChars = ['ä', 'ö', 'ü', 'ß', 'Ä', 'Ö', 'Ü'];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: specialChars.map((char) {
        return ActionChip(
          label: Text(
            char,
            style: const TextStyle(fontSize: 18),
          ),
          onPressed: _answered
              ? null
              : () {
                  final text = _controller.text;
                  final selection = _controller.selection;
                  final newText = text.replaceRange(
                    selection.start,
                    selection.end,
                    char,
                  );
                  _controller.text = newText;
                  _controller.selection = TextSelection.collapsed(
                    offset: selection.start + char.length,
                  );
                  // 特殊字符键盘修改文本后同样调度自动检查
                  _scheduleAutoCheck();
                },
        );
      }).toList(),
    );
  }

  Widget _buildBottomButton(ColorScheme colorScheme) {
    if (_answered) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _controller.text.isNotEmpty ? _checkAnswer : null,
          child: const Text('检查拼写'),
        ),
      ),
    );
  }

  Widget _buildFeedbackButtons(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _FeedbackButton(
              label: '忘记',
              color: ScoreColors.forgot,
              onPressed: () => _onFeedback(FeedbackLevel.forgot),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FeedbackButton(
              label: '模糊',
              color: ScoreColors.hard,
              onPressed: () => _onFeedback(FeedbackLevel.hard),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FeedbackButton(
              label: '熟悉',
              color: ScoreColors.good,
              onPressed: () => _onFeedback(FeedbackLevel.good),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FeedbackButton(
              label: '简单',
              color: ScoreColors.easy,
              onPressed: () => _onFeedback(FeedbackLevel.easy),
            ),
          ),
        ],
      ),
    );
  }

  void _checkAnswer() {
    final word = ref.read(studySessionProvider).currentWord;
    if (word == null) return;

    final input = _controller.text;
    final result = GermanParser.compareSpelling(input, word.german);

    setState(() {
      _answered = true;
      _isCorrect = result;
    });

    if (!result) {
      final capitalResult = GermanParser.checkCapitalization(input, word.german);
      if (capitalResult.needsCapitalize) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(capitalResult.message ?? '名词首字母需要大写'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _onFeedback(FeedbackLevel feedback) {
    ref.read(studySessionProvider.notifier).submitFeedback(feedback);

    setState(() {
      _controller.clear();
      _answered = false;
      _isCorrect = null;
    });
  }

  Widget _buildCompletedScreen(
      BuildContext context, ColorScheme colorScheme, StudySession session) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习完成')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration, size: 80, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              '恭喜完成！',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              '本次学习 ${session.completedCount} 个单词',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '正确率: ${(session.accuracy * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                ref.read(studySessionProvider.notifier).reset();
                Navigator.pop(context);
              },
              child: const Text('返回'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _FeedbackButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label),
    );
  }
}
