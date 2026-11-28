import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:async';
import '../../../../algorithms/sm2_algorithm.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/utils/german_parser.dart';
import '../../../../data/database/app_database.dart';
import '../../../../providers/study_provider.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../ui/screens/deck/word_detail_screen.dart';
import '../../../../ui/widgets/noun_article_selector.dart';
import '../../../../ui/widgets/study_split_layout.dart';
import '../../../../ui/widgets/study_rating_help.dart';
import '../../../../ui/widgets/swipe_down_detail_route.dart';

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

  /// 名词作答：用户选择的定冠词（der/die/das）
  String? _selectedArticle;

  /// 记录词性作答对应的单词 id，切换单词时自动失效
  int? _articleWordId;

  /// 防重入：提交反馈（含 SM-2 落库）期间忽略重复点击
  bool _submitting = false;
  final FlutterTts _tts = FlutterTts();

  /// 自动确认防抖定时器（停止输入一段时间后自动检查拼写）
  Timer? _debounce;

  /// 记录当前题目单词 id，用于新题下发时触发自动发音
  int _lastWordId = -1;

  /// 平板分屏：控制右侧单词详情面板的模糊层
  final GlobalKey<StudySplitLayoutState> _splitKey = GlobalKey();

  /// 输入框焦点：键盘收起（失焦）时撤销待触发的自动判定，
  /// 避免「输入法一消失就自动提交」
  final FocusNode _inputFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _initTts();
    _inputFocus.addListener(_onInputFocusChanged);
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(ref.read(settingsProvider).ttsSpeed);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _inputFocus.removeListener(_onInputFocusChanged);
    _inputFocus.dispose();
    _controller.dispose();
    _tts.stop();
    super.dispose();
  }

  void _speak(String text) async {
    // 每次发音前应用当前设置的语速，保证设置即时生效
    await _tts.setSpeechRate(ref.read(settingsProvider).ttsSpeed);
    await _tts.speak(text);
  }

  /// 是否已答对该名词的定冠词
  bool _articleAnswered(Word word) =>
      NounArticle.isAnswered(word, _selectedArticle, _articleWordId);

  /// 名词是否已满足「先选对词性」的作答前置条件
  bool _canAnswer(Word? word) =>
      word == null ||
      !NounArticle.isNounWithArticle(word) ||
      _articleAnswered(word);

  /// 点击定冠词：答错提示重试，答对后可继续拼写作答
  void _onArticleSelected(Word word, String article) {
    final correct = NounArticle.normalizedArticle(word);
    setState(() {
      _selectedArticle = article;
      _articleWordId = word.id;
    });
    if (article != correct) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(context.tr('词性选择错误，请重试')),
            duration: const Duration(seconds: 1),
          ),
        );
    } else {
      // 选对词性后，若已有输入且开启自动确认，补一次拼写检查
      _scheduleAutoCheck();
    }
  }

  /// 名词未选对词性前不允许作答，给出提示
  void _showArticleGateHint() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(context.tr('请先选择正确的词性')),
          duration: const Duration(seconds: 1),
        ),
      );
  }

  /// 输入变化：刷新按钮状态，并在自动确认开启时调度防抖检查
  void _onInputChanged(String _) {
    setState(() {});
    _scheduleAutoCheck();
  }

  /// 输入框失焦（键盘收起）时撤销待触发的自动检查
  void _onInputFocusChanged() {
    if (!_inputFocus.hasFocus) {
      _debounce?.cancel();
    }
  }

  /// 自动确认开启时的「已答对就自动提交」
  ///
  /// 只有在**当前输入已经和正确拼写一致**时才自动判定；输入不完整或拼错时
  /// 一律不动，等用户自己按确认按钮。
  /// （之前的实现是「停止输入 800ms 就判定」，导致打到一半停一下就判错。）
  void _scheduleAutoCheck() {
    if (!ref.read(settingsProvider).autoConfirm) return;
    if (_answered) return;
    if (!_inputFocus.hasFocus) return;
    if (_controller.value.composing.isValid) return;
    if (!_canAnswer(ref.read(studySessionProvider).currentWord)) return;
    if (_controller.text.trim().isEmpty) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      if (!mounted || _answered) return;
      // 等待期间键盘可能已收起、或输入法又进入组词，这里重新确认一次
      if (!_inputFocus.hasFocus) return;
      if (_controller.value.composing.isValid) return;
      final word = ref.read(studySessionProvider).currentWord;
      if (word == null) return;
      final tolerant = ref.read(settingsProvider).tolerantSpelling;
      if (!GermanParser.compareSpelling(
        _controller.text,
        word.german,
        tolerant: tolerant,
      )) {
        // 还没打对：不自动提交，避免把没打完的词判错
        return;
      }
      _checkAnswer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(studySessionProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (session.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('拼写模式'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (session.error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.tr('拼写模式'))),
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
                child: Text(context.tr('返回')),
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
        appBar: AppBar(title: Text(context.tr('拼写模式'))),
        body: Center(child: Text(context.tr('没有单词'))),
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
        title: Text(context.trArgs('拼写模式 ({0})', [session.progressTitle])),
        actions: const [StudyRatingHelpButton()],
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
              // 键盘弹出时可用高度会被压缩：内容改为可滚动，
              // 否则底部（特殊字符键盘 / 反馈按钮）会被挤到屏幕外触发
              // "bottom overflowed"。
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    // 中文提示
                    Text(
                      word.chinese,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    // 名词：先选对词性（定冠词）才能作答，选对前不显示冠词以免泄露
                    if (NounArticle.isNounWithArticle(word)) ...[
                      const SizedBox(height: 16),
                      NounArticleSelector(
                        selectedArticle: _articleWordId == word.id
                            ? _selectedArticle
                            : null,
                        answered: _articleAnswered(word),
                        onSelect: (article) =>
                            _onArticleSelected(word, article),
                      ),
                    ] else if (word.article != null) ...[
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(
                          word.article!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: GenderColors.forArticle(word.article),
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
                      focusNode: _inputFocus,
                      enabled: !_answered,
                      decoration: InputDecoration(
                        hintText: context.tr('输入德语单词...'),
                        errorText: _answered && _isCorrect == false
                            ? context.trArgs('正确答案: {0}', [
                                '${word.article != null ? "${word.article} " : ""}${word.german}',
                              ])
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
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.tr('支持宽容拼写: ae→ä, oe→ö, ue→ü, ss→ß'),
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
          label: Text(char, style: const TextStyle(fontSize: 18)),
          onPressed: _answered
              ? null
              : () {
                  final text = _controller.text;
                  final selection = _controller.selection;
                  // 从未聚焦过输入框时 selection 是无效值（offset = -1），
                  // 直接 replaceRange 会抛 RangeError 把页面打红，此时追加到末尾
                  final start = selection.isValid
                      ? selection.start
                      : text.length;
                  final end = selection.isValid ? selection.end : text.length;
                  final newText = text.replaceRange(start, end, char);
                  _controller.value = TextEditingValue(
                    text: newText,
                    selection: TextSelection.collapsed(
                      offset: start + char.length,
                    ),
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
          onPressed:
              _controller.text.isNotEmpty &&
                  _canAnswer(ref.read(studySessionProvider).currentWord)
              ? _checkAnswer
              : null,
          child: Text(context.tr('检查拼写')),
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
                label: Text(context.tr('查看单词详情')),
                onPressed: _openWordDetail,
              ),
            ),
          if (!StudySplitLayout.isSplitWidth(context))
            const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _FeedbackButton(
                  label: context.tr('忘记'),
                  color: ScoreColors.forgot,
                  onPressed: () => _onFeedback(FeedbackLevel.forgot),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FeedbackButton(
                  label: context.tr('模糊'),
                  color: ScoreColors.hard,
                  onPressed: () => _onFeedback(FeedbackLevel.hard),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FeedbackButton(
                  label: context.tr('熟悉'),
                  color: ScoreColors.good,
                  onPressed: () => _onFeedback(FeedbackLevel.good),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _FeedbackButton(
                  label: context.tr('简单'),
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

  void _checkAnswer() {
    final word = ref.read(studySessionProvider).currentWord;
    if (word == null) return;

    // 名词必须先选对词性才能作答
    if (!_canAnswer(word)) {
      _showArticleGateHint();
      return;
    }

    final input = _controller.text;
    final result = GermanParser.compareSpelling(input, word.german);

    setState(() {
      _answered = true;
      _isCorrect = result;
    });

    // 拼写正确时自动显示右侧单词详情
    if (result) {
      _splitKey.currentState?.reveal();
    }

    if (!result) {
      final capitalResult = GermanParser.checkCapitalization(
        input,
        word.german,
      );
      if (capitalResult.needsCapitalize) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(capitalResult.message ?? context.tr('名词首字母需要大写')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _onFeedback(FeedbackLevel feedback) async {
    if (_submitting) return;
    _submitting = true;
    try {
      await ref.read(studySessionProvider.notifier).submitFeedback(feedback);
    } catch (e) {
      debugPrint('提交反馈失败: $e');
    } finally {
      _submitting = false;
    }
    if (!mounted) return;
    setState(() {
      _controller.clear();
      _answered = false;
      _isCorrect = null;
      _selectedArticle = null;
      _articleWordId = null;
    });
  }

  Widget _buildCompletedScreen(
    BuildContext context,
    ColorScheme colorScheme,
    StudySession session,
  ) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('学习完成'))),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.celebration, size: 80, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              context.tr('恭喜完成！'),
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              context.trArgs('本次学习 {0} 个单词', [session.completedCount]),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              context.trArgs('正确率: {0}%', [
                (session.accuracy * 100).toStringAsFixed(0),
              ]),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: colorScheme.primary),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () {
                ref.read(studySessionProvider.notifier).reset();
                Navigator.pop(context);
              },
              child: Text(context.tr('返回')),
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
