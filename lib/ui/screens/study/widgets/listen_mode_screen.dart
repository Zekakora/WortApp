import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../algorithms/sm2_algorithm.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../providers/study_provider.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../ui/screens/deck/word_detail_screen.dart';
import '../../../../ui/widgets/study_split_layout.dart';
import '../../../../ui/widgets/swipe_down_detail_route.dart';
import 'distractor_pool_mixin.dart';

/// 听德语选单词模式
class ListenModeScreen extends ConsumerStatefulWidget {
  const ListenModeScreen({super.key});

  @override
  ConsumerState<ListenModeScreen> createState() => _ListenModeScreenState();
}

class _ListenModeScreenState extends ConsumerState<ListenModeScreen>
    with DistractorPoolMixin {
  int? _selectedAnswer;
  bool _answered = false;
  List<String> _options = [];
  int _correctIndex = 0;
  int _lastWordId = -1;
  /// 防重入：提交反馈（含 SM-2 落库）期间忽略重复点击
  bool _submitting = false;
  /// 平板分屏：控制右侧单词详情面板的模糊层
  final GlobalKey<StudySplitLayoutState> _splitKey = GlobalKey();
  final FlutterTts _tts = FlutterTts();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(ref.read(settingsProvider).ttsSpeed);
    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
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

    if (_lastWordId == word.id && _options.isNotEmpty) return;
    _lastWordId = word.id;

    // 生成选项：正确答案 + 3个干扰项（从会话选项池随机抽取）
    final options = <String>[
      word.german,
      ...pickDistractors(correctWord: word, selector: (w) => w.german),
    ];

    options.shuffle();
    _correctIndex = options.indexOf(word.german);
    _options = options;
  }

  void _playAudio() async {
    final word = ref.read(studySessionProvider).currentWord;
    if (word == null) return;

    setState(() {
      _isPlaying = true;
    });
    // 播放前应用当前设置的语速，保证设置即时生效
    await _tts.setSpeechRate(ref.read(settingsProvider).ttsSpeed);
    await _tts.speak(word.german);
  }

  /// 回答正确时自动关闭右侧详情面板的模糊层
  void _maybeRevealDetail() {
    if (_answered && _selectedAnswer == _correctIndex) {
      _splitKey.currentState?.reveal();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(studySessionProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (session.currentWord != null && session.currentWord!.id != _lastWordId) {
      final newWordId = session.currentWord!.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _generateOptions();
          });
          // 自动发音：题目下发时自动播放一次
          if (ref.read(settingsProvider).autoPlayTts &&
              ref.read(studySessionProvider).currentWord?.id == newWordId) {
            _playAudio();
          }
        }
      });
    }

    if (session.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('听德语选单词')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (session.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('听德语选单词')),
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
        appBar: AppBar(title: const Text('听德语选单词')),
        body: const Center(child: Text('没有单词')),
      );
    }

    if (_options.isEmpty) {
      _generateOptions();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '听德语选单词 (${session.progressTitle})'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: session.progress,
            minHeight: 4,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
      body: StudySplitLayout(
        key: _splitKey,
        wordId: word.id,
        left: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 48),
                    IconButton(
                      icon: Icon(
                        _isPlaying ? Icons.stop_circle : Icons.play_circle_fill,
                        size: 80,
                      ),
                      color: colorScheme.primary,
                      onPressed: _playAudio,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '点击播放发音',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 48),
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
                // 回答正确时自动显示右侧单词详情
                _maybeRevealDetail();
              },
        borderRadius: BorderRadius.circular(16),
        child: Center(
          child: Text(
            _options[index],
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
            // 回答正确时自动显示右侧单词详情
            _maybeRevealDetail();
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
          // 查看单词详情（复用单词本详情页布局），占满整行；分屏时右侧常驻详情，隐藏该按钮
          if (!StudySplitLayout.isSplitWidth(context))
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                icon: const Icon(Icons.info_outline, size: 18),
                label: const Text('查看单词详情'),
                onPressed: _openWordDetail,
              ),
            ),
          if (!StudySplitLayout.isSplitWidth(context)) const SizedBox(height: 8),
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
      SwipeDownDetailRoute(builder: (_) => WordDetailScreen(wordId: word.id)),
    );
  }

  Future<void> _onFeedback(FeedbackLevel feedback) async {
    if (_submitting) return;
    _submitting = true;
    try {
      // 先等会话状态更新完成（currentWord 已切到下一词）再重置状态：
      // 若提前清空选项，中间帧会先用旧词重新生成选项，之后又变成新词选项（闪烁）
      await ref.read(studySessionProvider.notifier).submitFeedback(feedback);
    } finally {
      _submitting = false;
    }
    if (!mounted) return;

    setState(() {
      _selectedAnswer = null;
      _answered = false;
      _lastWordId = -1;
      _options = []; // 清空旧题选项：避免下一帧先渲染上一题选项再被刷新（闪烁）
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
