import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../algorithms/sm2_algorithm.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/study_provider.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../ui/screens/deck/word_detail_screen.dart';

/// 看德语选中文模式
class DeToCnScreen extends ConsumerStatefulWidget {
  const DeToCnScreen({super.key});

  @override
  ConsumerState<DeToCnScreen> createState() => _DeToCnScreenState();
}

class _DeToCnScreenState extends ConsumerState<DeToCnScreen> {
  int? _selectedAnswer;
  bool _answered = false;
  List<String> _options = [];
  int _correctIndex = 0;
  int _lastWordId = -1;
  final FlutterTts _tts = FlutterTts();

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
    _tts.stop();
    super.dispose();
  }

  void _generateOptions() {
    final session = ref.read(studySessionProvider);
    final word = session.currentWord;
    if (word == null) return;

    // 避免重复生成同一单词的选项
    if (_lastWordId == word.id && _options.isNotEmpty) return;
    _lastWordId = word.id;

    // 生成选项：正确答案 + 3个干扰项
    final allWords = session.words;
    final otherWords = allWords.where((w) => w.id != word.id).toList();
    otherWords.shuffle();

    final options = <String>[word.chinese];
    for (var i = 0; i < 3 && i < otherWords.length; i++) {
      options.add(otherWords[i].chinese);
    }

    // 如果选项不足4个，添加占位
    while (options.length < 4) {
      options.add('选项${options.length + 1}');
    }

    options.shuffle();
    _correctIndex = options.indexOf(word.chinese);
    _options = options;
  }

  void _speak(String text) async {
    // 每次发音前应用当前设置的语速，保证设置即时生效
    await _tts.setSpeechRate(ref.read(settingsProvider).ttsSpeed);
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(studySessionProvider);
    final colorScheme = Theme.of(context).colorScheme;

    // 当单词变化时重新生成选项
    if (session.currentWord != null && session.currentWord!.id != _lastWordId) {
      final newWordId = session.currentWord!.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _generateOptions();
          });
          // 自动发音：题目下发时播放一次
          if (ref.read(settingsProvider).autoPlayTts) {
            final word = ref.read(studySessionProvider).currentWord;
            if (word != null && word.id == newWordId) _speak(word.german);
          }
        }
      });
    }

    if (session.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('看德语选中文')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (session.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('看德语选中文')),
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
        appBar: AppBar(title: const Text('看德语选中文')),
        body: const Center(child: Text('没有单词')),
      );
    }

    // 确保选项已生成
    if (_options.isEmpty) {
      _generateOptions();
    }

    final genderColor = GenderColors.forArticle(word.article);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '看德语选中文 (${session.currentIndex + 1}/${session.words.length})'),
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
                  // 德语单词
                  if (word.article != null)
                    Chip(
                      label: Text(
                        word.article!,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      backgroundColor: genderColor,
                    ),
                  const SizedBox(height: 16),
                  Text(
                    word.german,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: genderColor,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.volume_up, size: 32),
                    onPressed: () => _speak(word.german),
                  ),
                  const SizedBox(height: 48),
                  // 选项网格
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _options.length,
                      itemBuilder: (context, index) {
                        return _buildOptionCard(index, colorScheme);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_answered) _buildFeedbackButtons(colorScheme),
          if (!_answered && _selectedAnswer != null)
            _buildConfirmButton(colorScheme),
        ],
      ),
    );
  }

  Widget _buildOptionCard(int index, ColorScheme colorScheme) {
    final isSelected = _selectedAnswer == index;
    final isCorrect = index == _correctIndex;

    Color? bgColor;
    if (_answered) {
      if (isCorrect) {
        bgColor = Colors.green.shade100;
      } else if (isSelected && !isCorrect) {
        bgColor = Colors.red.shade100;
      }
    } else if (isSelected) {
      bgColor = colorScheme.primaryContainer;
    }

    return Card(
      color: bgColor,
      child: InkWell(
        onTap: _answered
            ? null
            : () {
                setState(() {
                  _selectedAnswer = index;
                  // 回答后自动确认：选中即确认，无需再点击确认按钮
                  if (ref.read(settingsProvider).autoConfirm) {
                    _answered = true;
                  }
                });
              },
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Text(
            _options[index],
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmButton(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: () {
            setState(() {
              _answered = true;
            });
          },
          child: const Text('确认答案'),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 查看单词详情（复用单词本详情页布局），占满整行
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('查看单词详情'),
              onPressed: _openWordDetail,
            ),
          ),
          const SizedBox(height: 8),
          Row(
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
        ],
      ),
    );
  }

  /// 打开当前单词的详情页（与单词本详情页一致）
  void _openWordDetail() {
    final word = ref.read(studySessionProvider).currentWord;
    if (word == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WordDetailScreen(wordId: word.id)),
    );
  }

  void _onFeedback(FeedbackLevel feedback) {
    ref.read(studySessionProvider.notifier).submitFeedback(feedback);

    // 重置状态，下一题会在 build 中自动生成选项
    setState(() {
      _selectedAnswer = null;
      _answered = false;
      _lastWordId = -1; // 强制重新生成选项
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
