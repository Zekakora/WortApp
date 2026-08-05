import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/conjugation_provider.dart';
import '../../widgets/study_split_layout.dart';

/// 变位练习界面
///
/// - 动词模式：一个单词卡片提供 6 个人称输入框（ich/du/er/sie/es/wir/ihr/sie/Sie），
///   全部填写后提交，逐格对比标准变位表并高亮错误/漏填
/// - 名词 / 形容词模式：根据所选二级子项进行针对性填空；
///   定冠词模式使用 die/das/der 三色选项按钮（与翻牌模式一致），其余模式为输入框
class ConjugationDrillScreen extends ConsumerStatefulWidget {
  const ConjugationDrillScreen({super.key});

  @override
  ConsumerState<ConjugationDrillScreen> createState() =>
      _ConjugationDrillScreenState();
}

class _ConjugationDrillScreenState
    extends ConsumerState<ConjugationDrillScreen> {
  final Map<String, TextEditingController> _controllers = {};
  bool _submitted = false;
  Map<String, FieldCheckResult> _results = {};
  String _activeKey = '';
  /// 定冠词模式：用户选择的三色选项（die/das/der）
  String? _selectedArticle;
  /// 平板分屏：控制右侧单词详情面板的模糊层
  final GlobalKey<StudySplitLayoutState> _splitKey = GlobalKey();

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _disposeControllers() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _controllers.clear();
  }

  /// 当题目切换时重建输入控制器并重置答题状态
  void _ensureControllers(ConjugationQuestion question, String key) {
    if (key == _activeKey) return;
    _disposeControllers();
    _activeKey = key;
    _submitted = false;
    _results = {};
    _selectedArticle = null;
    for (final field in question.fields) {
      // 定冠词模式：使用三色选项按钮，无需输入框
      if (field.label == '定冠词') continue;
      _controllers[field.label] = TextEditingController();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(conjugationDrillProvider);
    final colorScheme = Theme.of(context).colorScheme;

    if (state.isCompleted) {
      return _buildCompletedScreen(context, colorScheme, state);
    }

    final question = state.currentQuestion;
    if (question == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('变位练习')),
        body: const Center(child: Text('没有题目')),
      );
    }

    final key = '${state.currentIndex}_${question.wordId}';
    _ensureControllers(question, key);

    final isVerb = question.mode.isVerbTense;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '变位练习 (${state.answeredCount + 1}/${state.questions.length})'),
      ),
      body: StudySplitLayout(
        key: _splitKey,
        wordId: question.wordId,
        left: Column(
          children: [
            // 进度条
            LinearProgressIndicator(
              value: state.progress,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 模式徽章
                    _buildModeBadge(question.mode),
                    const SizedBox(height: 16),
                    // 单词卡片
                    _buildWordCard(question),
                    const SizedBox(height: 24),
                    // 题目
                    Text(
                      question.prompt,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    if (isVerb) ...[
                      const SizedBox(height: 8),
                      Text(
                        '请完整填写 ${question.mode.title} 的 6 个人称变位形态',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 20),
                    // 输入区域
                    for (final field in question.fields)
                      _buildField(field, isVerb),
                    // 被动语态提示
                    if (isVerb && question.mode.id == 'verb_passiv') ...[
                      const SizedBox(height: 12),
                      _buildHint(colorScheme,
                          '提示：被动语态 = werden 的现在时变位 + 动词第二分词（Partizip II）'),
                    ],
                    // 形容词变级提示
                    if (question.mode.id == 'adj_steigerung') ...[
                      const SizedBox(height: 12),
                      _buildHint(
                          colorScheme,
                          '提示：比较级一般加 -er，最高级一般用 am ...-sten（注意变音与词尾变化）'),
                    ],
                    const SizedBox(height: 20),
                    // 结果反馈
                    if (_submitted) _buildResultBanner(colorScheme),
                  ],
                ),
              ),
            ),
            // 底部按钮
            _buildBottomButton(colorScheme),
          ],
        ),
      ),
    );
  }

  /// 模式徽章（类别色：动词蓝 / 名词橙 / 形容词紫）
  Widget _buildModeBadge(PracticeMode mode) {
    final color = _categoryColor(mode.category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${_categoryLabel(mode.category)} · ${mode.title} (${mode.subtitle})',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// 单词卡片
  Widget _buildWordCard(ConjugationQuestion question) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (question.article != null && question.article!.isNotEmpty) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  question.article!,
                  style: TextStyle(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              question.word,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            if (question.meaning != null) ...[
              const SizedBox(height: 8),
              Text(
                question.meaning!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 单个填写格子
  Widget _buildField(PracticeField field, bool isVerb) {
    final controller = _controllers[field.label];
    if (controller == null) {
      // 定冠词模式：使用三色选项按钮代替输入框
      if (field.label == '定冠词') return _buildArticleOptions(field);
      return const SizedBox.shrink();
    }

    final result = _results[field.label];
    final showFeedback = _submitted && result != null;

    Color? borderColor;
    String? errorText;
    Color? fillColor;
    if (showFeedback) {
      if (result.isCorrect) {
        borderColor = Colors.green;
        fillColor = Colors.green.withValues(alpha: 0.05);
      } else {
        borderColor = Colors.red;
        fillColor = Colors.red.withValues(alpha: 0.05);
        errorText = result.isBlank ? '未填写' : '正确: ${result.correctAnswer}';
      }
    }

    InputBorder border() => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: showFeedback && borderColor != null
              ? BorderSide(color: borderColor, width: 2)
              : BorderSide.none,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // 人称/格标签
          SizedBox(
            width: 104,
            child: Text(
              field.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !_submitted,
              decoration: InputDecoration(
                hintText: isVerb ? '请输入...' : '请输入 ${field.label}...',
                hintStyle: const TextStyle(fontSize: 14),
                filled: fillColor != null,
                fillColor: fillColor,
                border: border(),
                enabledBorder: border(),
                focusedBorder: border(),
                errorText: errorText,
                errorMaxLines: 2,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              style: const TextStyle(fontSize: 16),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  /// 定冠词三色选项按钮（die/das/der），替代文本输入框
  ///
  /// 与翻牌模式配色一致：der 蓝 / die 红 / das 绿；
  /// 提交后选对填充对应色并打勾，选错标红并提示正确答案
  Widget _buildArticleOptions(PracticeField field) {
    const articles = ['die', 'das', 'der'];
    final result = _results[field.label];
    final showFeedback = _submitted && result != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // 标签
          SizedBox(
            width: 104,
            child: Text(
              field.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              children: articles.map((article) {
                final color = GenderColors.forArticle(article);
                final isSelected = _selectedArticle == article;
                // 提交前：高亮当前选中项；提交后：选对 / 选错 / 提示正确选项
                final isPicked = !showFeedback && isSelected;
                final isCorrectPick =
                    showFeedback && isSelected && result!.isCorrect;
                final isWrongPick =
                    showFeedback && isSelected && !result!.isCorrect;
                final isCorrectOption = showFeedback &&
                    !result!.isCorrect &&
                    article == result!.correctAnswer.toLowerCase();

                return Expanded(
                  child: GestureDetector(
                    onTap: _submitted
                        ? null
                        : () => _onArticleOptionSelected(article),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isCorrectPick
                            ? color
                            : isWrongPick
                                ? Colors.red.withValues(alpha: 0.1)
                                : isCorrectOption
                                    ? color.withValues(alpha: 0.2)
                                    : isPicked
                                        ? color.withValues(alpha: 0.3)
                                        : color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCorrectPick ||
                                  isCorrectOption ||
                                  isPicked
                              ? color
                              : isWrongPick
                                  ? Colors.red
                                  : color.withValues(alpha: 0.45),
                          width:
                              isCorrectPick || isCorrectOption || isPicked
                                  ? 2
                                  : 1.2,
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
                              color:
                                  isCorrectPick || isPicked
                                      ? Colors.white
                                      : color,
                            ),
                          ),
                          if (isCorrectPick) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.check_circle,
                                color: Colors.white, size: 18),
                          ] else if (isWrongPick) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.cancel,
                                color: Colors.red, size: 18),
                          ] else if (isCorrectOption) ...[
                            const SizedBox(width: 4),
                            Icon(Icons.check_circle, color: color, size: 18),
                          ] else if (isPicked) ...[
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
          ),
        ],
      ),
    );
  }

  /// 点击定冠词选项
  void _onArticleOptionSelected(String article) {
    setState(() => _selectedArticle = article);
  }

  /// 提示条
  Widget _buildHint(ColorScheme colorScheme, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline,
              size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  /// 提交后的结果横幅
  Widget _buildResultBanner(ColorScheme colorScheme) {
    final correctCount = _results.values.where((r) => r.isCorrect).length;
    final total = _results.length;
    final allCorrect = correctCount == total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: allCorrect
            ? Colors.green.withValues(alpha: 0.08)
            : Colors.red.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: allCorrect ? Colors.green : Colors.red,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            allCorrect ? Icons.check_circle : Icons.cancel,
            color: allCorrect ? Colors.green : Colors.red,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allCorrect ? '全部正确！' : '有 ${total - correctCount} 处错误',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: allCorrect ? Colors.green : Colors.red,
                  ),
                ),
                Text(
                  '正确 $correctCount / $total',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(ColorScheme colorScheme) {
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
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: _submitted || _canSubmit() ? _submit : null,
          child: Text(_submitted ? '下一题' : '检查答案'),
        ),
      ),
    );
  }

  bool _canSubmit() {
    final state = ref.read(conjugationDrillProvider);
    final question = state.currentQuestion;
    // 定冠词模式：需先选择一个选项
    if (question != null && question.mode.id == 'noun_article') {
      return _selectedArticle != null;
    }
    return _controllers.values.every((c) => c.text.trim().isNotEmpty);
  }

  void _submit() {
    final state = ref.read(conjugationDrillProvider);
    final question = state.currentQuestion;
    if (question == null) return;

    if (!_submitted) {
      // 收集答案并对比标准变位表（定冠词模式取选项值）
      final userAnswers = <String, String>{
        for (final field in question.fields)
          field.label: field.label == '定冠词'
              ? _selectedArticle ?? ''
              : _controllers[field.label]?.text ?? '',
      };
      final results = ConjugationDrillNotifier.checkFields(question, userAnswers);
      final allCorrect = results.values.every((r) => r.isCorrect);

      setState(() {
        _submitted = true;
        _results = results;
      });

      // 全部答对时自动显示右侧单词详情
      if (allCorrect) {
        _splitKey.currentState?.reveal();
      }

      ref.read(conjugationDrillProvider.notifier).submitAnswer(
            isCorrect: allCorrect,
          );
    } else {
      // 下一题
      ref.read(conjugationDrillProvider.notifier).next();
    }
  }

  /// 完成页
  Widget _buildCompletedScreen(BuildContext context, ColorScheme colorScheme,
      ConjugationDrillState state) {
    return Scaffold(
      appBar: AppBar(title: const Text('练习完成')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                '练习完成！',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildStatRow(
                          context, '完成题目', '${state.questions.length} 道'),
                      const Divider(height: 24),
                      _buildStatRow(
                          context, '全部正确', '${state.correctCount} 道'),
                      const Divider(height: 24),
                      _buildStatRow(
                          context,
                          '正确率',
                          '${(state.accuracy * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  ref.read(conjugationDrillProvider.notifier).reset();
                  Navigator.pop(context);
                },
                child: const Text('返回'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyLarge),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Color _categoryColor(PracticeCategory category) {
    switch (category) {
      case PracticeCategory.verb:
        return Colors.blue;
      case PracticeCategory.noun:
        return Colors.orange;
      case PracticeCategory.adjective:
        return Colors.purple;
    }
  }

  String _categoryLabel(PracticeCategory category) {
    switch (category) {
      case PracticeCategory.verb:
        return '动词变位';
      case PracticeCategory.noun:
        return '名词变格';
      case PracticeCategory.adjective:
        return '形容词变级';
    }
  }
}
