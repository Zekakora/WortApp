import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../algorithms/sm2_algorithm.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/database/app_database.dart';
import '../../../../providers/study_provider.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../ui/screens/deck/word_detail_screen.dart';

/// 经典翻牌模式
class FlipModeScreen extends ConsumerStatefulWidget {
  const FlipModeScreen({super.key});

  @override
  ConsumerState<FlipModeScreen> createState() => _FlipModeScreenState();
}

class _FlipModeScreenState extends ConsumerState<FlipModeScreen>
    with SingleTickerProviderStateMixin {
  bool _isFlipped = false;
  /// 名词答题：用户选择的定冠词（die/das/der）
  String? _selectedArticle;
  /// 记录作答冠词对应的单词 id，切换单词时自动失效
  int? _selectedForWordId;
  /// 记录已自动发音的单词 id，同一题目只播放一次
  int? _lastAutoSpeakWordId;
  late AnimationController _controller;
  late Animation<double> _animation;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(ref.read(settingsProvider).ttsSpeed);
  }

  @override
  void dispose() {
    _controller.dispose();
    _tts.stop();
    super.dispose();
  }

  void _flipCard() {
    if (_isFlipped) {
      _controller.reverse();
      setState(() => _isFlipped = false);
      return;
    }

    // 名词：必须先答对定冠词才能翻牌
    final word = ref.read(studySessionProvider).currentWord;
    if (word != null && _isNounWithArticle(word) && !_hasAnsweredArticle(word)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('请先选择正确的定冠词'),
            duration: Duration(seconds: 1),
          ),
        );
      return;
    }

    _controller.forward();
    setState(() => _isFlipped = true);
  }

  /// 是否为需要先作答定冠词的名词（wordType 缺失但带冠词时按名词处理）
  bool _isNounWithArticle(Word word) {
    final article = word.article;
    if (article == null) return false;
    final a = article.trim().toLowerCase();
    if (a != 'der' && a != 'die' && a != 'das') return false;
    return word.wordType == 'noun' || word.wordType == null;
  }

  /// 是否已答对该名词的定冠词
  bool _hasAnsweredArticle(Word word) {
    final article = word.article;
    if (article == null) return false;
    return _selectedForWordId == word.id &&
        _selectedArticle == article.trim().toLowerCase();
  }

  /// 点击定冠词标签：答对自动翻牌查看答案，答错提示重试
  void _onArticleSelected(String article) {
    final word = ref.read(studySessionProvider).currentWord;
    if (word == null || !_isNounWithArticle(word)) return;

    final correct = word.article!.trim().toLowerCase();
    setState(() {
      _selectedArticle = article;
      _selectedForWordId = word.id;
    });

    if (article == correct) {
      if (!_isFlipped) _flipCard();
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('冠词选择错误，请重试'),
            duration: Duration(seconds: 1),
          ),
        );
    }
  }

  void _speak(String text) async {
    // 每次发音前应用当前设置的语速，保证设置即时生效
    await _tts.setSpeechRate(ref.read(settingsProvider).ttsSpeed);
    await _tts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final session = ref.watch(studySessionProvider);

    if (session.isCompleted) {
      return _buildCompletedScreen(context, colorScheme, session);
    }

    final word = session.currentWord;
    if (word == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('翻牌模式')),
        body: const Center(child: Text('没有待学习的单词')),
      );
    }

    // 切换单词时重置冠词选择状态（仅内部字段，不触发重建）
    if (_selectedForWordId != word.id) {
      _selectedForWordId = word.id;
      _selectedArticle = null;
    }

    // 自动发音：题目下发时播放一次（仅当设置开启且切换到新单词）
    if (ref.read(settingsProvider).autoPlayTts &&
        _lastAutoSpeakWordId != word.id) {
      _lastAutoSpeakWordId = word.id;
      final speakWord = word;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            ref.read(studySessionProvider).currentWord?.id == speakWord.id) {
          _speak(speakWord.baseForm ?? speakWord.german);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('翻牌模式 (${session.currentIndex + 1}/${session.words.length})'),
        actions: [
          // 熟练度标记
          IconButton(
            icon: Icon(
              word.proficiency > 0 ? Icons.star : Icons.star_outline,
              color: word.proficiency > 0 ? Colors.amber : null,
            ),
            onPressed: () => _showProficiencyDialog(word.id, word.proficiency),
            tooltip: '设置熟练度',
          ),
        ],
      ),
      body: Column(
        children: [
          // 进度条
          LinearProgressIndicator(
            value: session.progress,
            backgroundColor: colorScheme.surfaceContainerHighest,
          ),
          Expanded(
            child: GestureDetector(
              onTap: _flipCard,
              child: Center(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final angle = _animation.value * 3.14159;
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: angle < 3.14159 / 2
                          ? _buildFrontCard(colorScheme, word)
                          : Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(3.14159),
                              child: _buildBackCard(colorScheme, word),
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
          // 底部反馈按钮
          if (_isFlipped) _buildFeedbackButtons(colorScheme),
        ],
      ),
    );
  }

  Widget _buildFrontCard(ColorScheme colorScheme, Word word) {
    return Card(
      margin: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 名词：顶部定冠词三色选择器（先选对才能翻牌）
            if (_isNounWithArticle(word)) ...[
              _buildArticleSelector(word),
              const SizedBox(height: 24),
            ] else if (word.article != null) ...[
              // 非名词场景保留冠词标签展示
              Chip(
                label: Text(
                  word.article!,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                backgroundColor: GenderColors.forArticle(word.article),
              ),
              const SizedBox(height: 24),
            ],
            // 德语单词（不使用任何颜色标记，防止泄露答案）
            Text(
              word.baseForm ?? word.german,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            // 发音按钮
            IconButton(
              icon: const Icon(Icons.volume_up, size: 32),
              onPressed: () => _speak(word.baseForm ?? word.german),
            ),
            const SizedBox(height: 24),
            Text(
              '点击显示答案',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// 定冠词三色选择器（die/das/der）
  Widget _buildArticleSelector(Word word) {
    const articles = ['die', 'das', 'der'];
    final answered = _hasAnsweredArticle(word);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '请选择定冠词',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: articles.map((article) {
            final color = GenderColors.forArticle(article);
            final isSelected =
                _selectedForWordId == word.id && _selectedArticle == article;
            return Expanded(
              child: GestureDetector(
                onTap: () => _onArticleSelected(article),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isSelected && answered
                        ? color
                        : color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected && answered
                          ? color
                          : color.withValues(alpha: 0.45),
                      width: isSelected && answered ? 2 : 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        article,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected && answered ? Colors.white : color,
                        ),
                      ),
                      if (isSelected && answered) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.check_circle,
                            color: Colors.white, size: 18),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBackCard(ColorScheme colorScheme, Word word) {
    return Card(
      margin: const EdgeInsets.all(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '中文释义',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              word.chinese,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            if (word.example != null && word.example!.isNotEmpty) ...[
              Text(
                '例句',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                word.example!,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
            if (word.nounPlural != null && word.nounPlural!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '复数: ${word.nounPlural}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ],
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

    // 重置翻牌与冠词选择状态
    setState(() {
      _selectedArticle = null;
      _selectedForWordId = null;
    });
    if (_isFlipped) {
      _controller.reverse();
      setState(() {
        _isFlipped = false;
      });
    }
  }

  void _showProficiencyDialog(int wordId, int currentProficiency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置熟练度'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final level = index + 1;
            return ListTile(
              leading: Icon(
                level <= currentProficiency ? Icons.star : Icons.star_outline,
                color: level <= currentProficiency ? Colors.amber : null,
              ),
              title: Text('等级 $level'),
              onTap: () {
                // TODO: 更新熟练度
                Navigator.pop(context);
              },
            );
          }),
        ),
      ),
    );
  }

  Widget _buildCompletedScreen(
      BuildContext context, ColorScheme colorScheme, StudySession session) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习完成')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              size: 80,
              color: colorScheme.primary,
            ),
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
