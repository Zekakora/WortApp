import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../../../algorithms/sm2_algorithm.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/database/app_database.dart';
import '../../../../providers/settings_provider.dart';
import '../../../../providers/study_provider.dart';
import '../../../../ui/screens/deck/word_detail_screen.dart';
import '../../../../ui/widgets/swipe_down_detail_route.dart';

/// 快闪卡模式
///
/// - 全屏卡片：先显示德语单词，2.5 秒后（黄灯）自动揭示释义与词性
///   （名词在单词上方显示 die/der/das 彩色冠词标签）
/// - 卡片顶部发光小条：绿(2.5s) → 黄(2.5s) → 红(保持到切卡)
/// - 右划：红灯亮起前 = 熟练，红灯亮起后 = 模糊；左划 = 忘记
/// - 电脑端可点击屏幕左侧/右侧代替滑动
/// - 卡片滑动跟手，松手后按速度/距离飞离屏幕或回弹
class FlashCardScreen extends ConsumerStatefulWidget {
  const FlashCardScreen({super.key});

  @override
  ConsumerState<FlashCardScreen> createState() => _FlashCardScreenState();
}

/// 顶部灯条阶段
enum _CardPhase { green, yellow, red }

class _FlashCardScreenState extends ConsumerState<FlashCardScreen>
    with TickerProviderStateMixin {
  /// 当前灯条阶段（yellow 起揭示释义，red = 模糊判定）
  _CardPhase _phase = _CardPhase.green;
  /// 是否进入模糊判定阶段：红灯亮起即为 true，此时右划才算模糊
  bool _hardEligible = false;
  /// 阶段计时器（绿 2.5s → 黄 2.5s → 红，红灯亮起即进入模糊判定）
  Timer? _phaseTimer;
  /// 卡片跟手拖动偏移
  double _dragOffset = 0;
  /// 是否正在播放滑出动画（防止重入）
  bool _swiping = false;
  /// 防重入：提交反馈（含 SM-2 落库）期间忽略操作
  bool _submitting = false;
  /// 滑出/回弹动画控制器
  late final AnimationController _slideController;
  /// 新卡进入淡入控制器（切词时从 0 淡入到 1，easeOutCubic 非线性）
  late final AnimationController _enterController;
  /// 水平位移动画（起点 = 当前拖动偏移，终点 = 屏幕外或 0）
  Animation<double> _slideX = const AlwaysStoppedAnimation<double>(0);
  /// 滑出动画开始时锁定的本轮反馈（以当时的灯条阶段为准）
  FeedbackLevel? _pendingFeedback;
  /// 记录已自动发音的单词 id，同一题只播放一次
  int? _lastAutoSpeakWordId;
  /// 切词序号：每次切到新词递增，用作揭示内容 AnimatedOpacity 的 key，
  /// 强制重建以跳过淡出动画（新卡出现时释义/词性必须立即隐藏）
  int _cardGeneration = 0;
  /// 垂直拖动累计位移（用于上滑打开单词详情）
  double _verticalDragAccum = 0;
  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..addStatusListener(_onSlideStatus);
    // 新卡淡入控制器：页面打开时第一张卡也淡入
    _enterController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    )..forward();
    _initTts();
    // 初始绿灯计时（initState 中不调用 setState）
    _scheduleNextPhase();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('de-DE');
    await _tts.setSpeechRate(ref.read(settingsProvider).ttsSpeed);
  }

  @override
  void dispose() {
    _phaseTimer?.cancel();
    _slideController.dispose();
    _enterController.dispose();
    _tts.stop();
    super.dispose();
  }

  void _speak(String text) async {
    // 每次发音前应用当前设置的语速，保证设置即时生效
    await _tts.setSpeechRate(ref.read(settingsProvider).ttsSpeed);
    await _tts.speak(text);
  }

  /// 重置灯条为绿灯并重新计时（切到新词时调用）
  void _startPhaseTimer() {
    _phaseTimer?.cancel();
    setState(() {
      _phase = _CardPhase.green;
      // 回到熟练判定阶段（黄灯揭示释义，红灯亮起才进入模糊判定）
      _hardEligible = false;
      // 递增切词序号：重建揭示内容，避免 AnimatedOpacity 从可见淡出到隐藏
      _cardGeneration++;
      // 旧卡滑出动画结束后停留在屏幕外，切词时一次性归零位移，
      // 避免 submitFeedback 更新 provider 触发重建时卡片弹回屏幕中央（闪回）
      _dragOffset = 0;
      _slideX = const AlwaysStoppedAnimation<double>(0);
    });
    // 新卡淡入：从透明开始，easeOutCubic 非线性浮现（旧卡已完全消失）
    _enterController.forward(from: 0);
    _scheduleNextPhase();
  }

  /// 依次调度 绿(2.5s) → 黄(2.5s，亮起时揭示释义) → 红(保持，进入模糊判定)
  void _scheduleNextPhase() {
    _phaseTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      setState(() => _phase = _CardPhase.yellow);
      _phaseTimer = Timer(const Duration(milliseconds: 2500), () {
        if (!mounted) return;
        setState(() {
          _phase = _CardPhase.red;
          // 红灯亮起：释义已揭示 2.5 秒，进入模糊判定
          _hardEligible = true;
        });
      });
    });
  }

  // ---------------- 手势与动画 ----------------

  void _onDragUpdate(DragUpdateDetails details) {
    if (_swiping || _submitting) return;
    // 回弹动画进行中先截断并把当前位移并入拖动偏移，避免与手指叠加
    if (_slideController.isAnimating) {
      _slideController.stop();
      _dragOffset += _slideX.value;
      _slideX = const AlwaysStoppedAnimation<double>(0);
    }
    setState(() => _dragOffset += details.delta.dx);
  }

  void _onDragEnd(DragEndDetails details) {
    if (_swiping || _submitting) return;
    if (_slideController.isAnimating) {
      _slideController.stop();
      _dragOffset += _slideX.value;
      _slideX = const AlwaysStoppedAnimation<double>(0);
    }
    final vx = details.velocity.pixelsPerSecond.dx;
    if (vx.abs() > 700 || _dragOffset.abs() > 120) {
      _commitSwipe(vx != 0 ? (vx > 0 ? 1 : -1) : (_dragOffset > 0 ? 1 : -1));
    } else {
      _springBack();
    }
  }

  /// 垂直拖动：累计位移，供上滑打开详情判断
  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (_swiping || _submitting) return;
    _verticalDragAccum += details.delta.dy;
  }

  /// 垂直拖动结束：上滑（速度快或位移大）打开单词详情页
  void _onVerticalDragEnd(DragEndDetails details) {
    if (_swiping || _submitting) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -700 || _verticalDragAccum < -120) {
      _openWordDetail();
    }
    _verticalDragAccum = 0;
  }

  /// 卡片回弹复位
  void _springBack() {
    setState(() {
      _slideX = Tween<double>(begin: _dragOffset, end: 0).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
      );
    });
    _slideController.forward(from: 0);
  }

  /// 提交滑出：direction = 1 右划，-1 左划
  ///
  /// 在滑出开始时锁定反馈等级：
  /// - 左划 = 忘记
  /// - 红灯亮起后（已充分看释义）右划 = 模糊
  /// - 其余（含黄灯揭示后的回忆期）右划 = 熟练
  void _commitSwipe(int direction) {
    if (_swiping || _submitting) return;
    _swiping = true;
    _phaseTimer?.cancel();
    _pendingFeedback = direction < 0
        ? FeedbackLevel.forgot
        : (_hardEligible ? FeedbackLevel.hard : FeedbackLevel.easy);

    if (_slideController.isAnimating) {
      _slideController.stop();
    }
    final start = _dragOffset + _slideX.value;
    _dragOffset = start;
    _slideX = const AlwaysStoppedAnimation<double>(0);
    final width = MediaQuery.sizeOf(context).width;
    setState(() {
      _slideX = Tween<double>(
        begin: start,
        end: start + direction * width * 1.4,
      ).animate(
        CurvedAnimation(parent: _slideController, curve: Curves.easeInCubic),
      );
    });
    _slideController.forward(from: 0);
  }

  void _onSlideStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    if (_swiping) {
      _finishSwipe();
    } else {
      // 回弹结束，清空拖动偏移
      setState(() {
        _dragOffset = 0;
        _slideX = const AlwaysStoppedAnimation<double>(0);
      });
    }
  }

  /// 滑出动画结束：提交反馈并切到下一张卡
  Future<void> _finishSwipe() async {
    final feedback = _pendingFeedback;
    _pendingFeedback = null;
    _swiping = false;
    // 注意：不在这里清零位移，让卡片继续停留在屏幕外终点，
    // 避免 submitFeedback 更新 provider 触发重建时卡片弹回屏幕中央（闪回），
    // 归零统一在切词 [_startPhaseTimer] 的 setState 中完成。
    if (feedback == null) {
      // 异常兜底：无反馈时恢复原位
      if (mounted) {
        setState(() {
          _dragOffset = 0;
          _slideX = const AlwaysStoppedAnimation<double>(0);
        });
      }
      return;
    }

    _submitting = true;
    try {
      await ref.read(studySessionProvider.notifier).submitFeedback(feedback);
    } catch (e) {
      debugPrint('提交反馈失败: $e');
    } finally {
      _submitting = false;
    }
    if (!mounted) return;

    final session = ref.read(studySessionProvider);
    if (session.isCompleted) {
      setState(() {});
      return;
    }
    // 新词：重置灯条为绿灯并重新计时
    _startPhaseTimer();
  }

  // ---------------- UI ----------------

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
        appBar: AppBar(title: const Text('快闪卡模式')),
        body: const Center(child: Text('没有待学习的单词')),
      );
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

    final screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      // 无熟练度标记：仅进度标题
      appBar: AppBar(
        title:
            Text('快闪卡模式 (${session.progressTitle})'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: session.progress,
            minHeight: 4,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 全屏卡片（居中，跟手拖动）
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: _onDragUpdate,
                      onHorizontalDragEnd: _onDragEnd,
                      onVerticalDragUpdate: _onVerticalDragUpdate,
                      onVerticalDragEnd: _onVerticalDragEnd,
                      child: _buildCard(colorScheme, word, screenWidth),
                    ),
                  ),
                ),
              ),
              // 底部中央：操作提示 + 查看单词详情
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _hardEligible
                          ? '右划 = 模糊 · 左划 = 忘记 · 上滑 = 详情'
                          : '右划 = 熟练 · 左划 = 忘记 · 上滑 = 详情',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      icon: const Icon(Icons.info_outline, size: 18),
                      label: const Text('查看单词详情'),
                      onPressed: _openWordDetail,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // 左右点击区（电脑端代替滑动；手势竞技场保证拖动仍命中卡片）
          _buildClickZone(-1),
          _buildClickZone(1),
        ],
      ),
    );
  }

  /// 屏幕左/右侧点击区（direction = -1 左划，1 右划）
  Widget _buildClickZone(int direction) {
    return Positioned(
      top: 0,
      bottom: 0,
      left: direction < 0 ? 0 : null,
      right: direction > 0 ? 0 : null,
      width: MediaQuery.sizeOf(context).width * 0.22,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _commitSwipe(direction),
        child: const SizedBox.expand(),
      ),
    );
  }

  /// 卡片本体：随手指平移 + 倾斜 + 指数淡出 + 新卡进入淡入
  ///
  /// 最终不透明度 = 滑动淡出（指数曲线，先慢后快）× 新卡进入淡入（easeOutCubic）。
  /// 用 AnimatedBuilder 同时监听滑动与进入控制器：滑出/回弹/淡入动画逐帧生效，
  /// 卡片内容预构建为 child，动画帧内只重建变换与透明度，避免重复构建。
  Widget _buildCard(
      ColorScheme colorScheme, Word word, double screenWidth) {
    return AnimatedBuilder(
      animation: Listenable.merge([_slideController, _enterController]),
      builder: (context, child) {
        final dx = _dragOffset + _slideX.value;
        final angle = ((dx / screenWidth) * 0.5).clamp(-0.35, 0.35);
        // 指数消失：开始阶段几乎不透明，越靠近边缘透明度下降越快
        const fadeStart = 40.0;
        final fadeEnd = (screenWidth * 0.2).clamp(200.0, 480.0);
        final progress = ((dx.abs() - fadeStart) / (fadeEnd - fadeStart))
            .clamp(0.0, 1.0)
            .toDouble();
        final slideOpacity = 1.0 - math.pow(progress, 2.0).toDouble();
        // 新卡进入淡入（非线性：先快后慢，easeOutCubic）
        final enterOpacity =
            Curves.easeOutCubic.transform(_enterController.value);

        return Transform.translate(
          offset: Offset(dx, 0),
          child: Transform.rotate(
            angle: angle,
            child: Opacity(
              opacity: slideOpacity * enterOpacity,
              child: child,
            ),
          ),
        );
      },
      child: _buildCardContent(colorScheme, word),
    );
  }

  /// 卡片内容：顶部发光小条 → 冠词标签（名词）→ 单词 → 释义与词性
  Widget _buildCardContent(ColorScheme colorScheme, Word word) {
    // 黄灯亮起即揭示释义（黄灯期间右划仍为熟练，红灯起进入模糊判定）
    final revealed = _phase != _CardPhase.green;
    final isNoun = _isNoun(word);
    final article = isNoun ? word.article!.trim().toLowerCase() : null;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLightStrip(),
            const SizedBox(height: 28),
            // 名词：die/der/das 彩色冠词标签（始终占位保持卡片高度固定，
            // 黄灯揭示后淡入）
            if (article != null)
              AnimatedOpacity(
                key: ValueKey('article-$_cardGeneration'),
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                opacity: revealed ? 1 : 0,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 6),
                    decoration: BoxDecoration(
                      color: GenderColors.forArticleSurface(article),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: GenderColors.forArticle(article),
                        width: 1.6,
                      ),
                    ),
                    child: Text(
                      article,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: GenderColors.forArticle(article),
                      ),
                    ),
                  ),
                ),
              ),
            // 德语单词
            Text(
              word.baseForm ?? word.german,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
            ),
            const SizedBox(height: 8),
            // 发音按钮
            IconButton(
              icon: const Icon(Icons.volume_up, size: 28),
              onPressed: () => _speak(word.baseForm ?? word.german),
            ),
            // 释义与词性：始终以完整内容占位（透明不可点），黄灯揭示后淡入，
            // 保证卡片高度从显示释义前就固定为揭示后的大小
            AnimatedOpacity(
              key: ValueKey('reveal-$_cardGeneration'),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOut,
              opacity: revealed ? 1 : 0,
              child: IgnorePointer(
                ignoring: !revealed,
                child: _buildRevealedContent(colorScheme, word),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 顶部发光小条：绿 → 黄 → 红，依次点亮
  Widget _buildLightStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PhaseLight(active: _phase == _CardPhase.green, color: Colors.green.shade500),
          const SizedBox(width: 14),
          _PhaseLight(active: _phase == _CardPhase.yellow, color: Colors.amber.shade600),
          const SizedBox(width: 14),
          _PhaseLight(active: _phase == _CardPhase.red, color: Colors.red.shade400),
        ],
      ),
    );
  }

  /// 黄灯揭示后的内容：词性徽章 + 所有释义
  Widget _buildRevealedContent(ColorScheme colorScheme, Word word) {
    final definitions = _splitDefinitions(word.chinese);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 词性徽章
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: WordTypeColors.forWordTypeSurface(word.wordType,
                  article: word.article),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: WordTypeColors.forWordType(word.wordType,
                    article: word.article),
              ),
            ),
            child: Text(
              '${WordTypeColors.getWordTypeLabel(word.wordType)} · '
              '${WordTypeColors.getWordTypeDescription(word.wordType)}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: WordTypeColors.forWordType(word.wordType,
                    article: word.article),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // 所有释义（按换行/分号拆分，逐条展示）
          for (var i = 0; i < definitions.length; i++) ...[
            Text(
              definitions[i],
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
            ),
            if (i != definitions.length - 1) const SizedBox(height: 10),
          ],
          if (_isNoun(word) &&
              word.nounPlural != null &&
              word.nounPlural!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              '复数: ${word.nounPlural}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  /// 是否为需要显示冠词标签的名词（wordType 缺失但带冠词时按名词处理）
  bool _isNoun(Word word) {
    final article = word.article;
    if (article == null) return false;
    final a = article.trim().toLowerCase();
    if (a != 'der' && a != 'die' && a != 'das') return false;
    return word.wordType == 'noun' || word.wordType == null;
  }

  /// 拆分所有释义：支持换行与中英文分号分隔
  List<String> _splitDefinitions(String chinese) {
    final parts = chinese
        .split(RegExp(r'[\n;；]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isEmpty ? [chinese] : parts;
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

/// 灯条上的单个指示灯：点亮时发光，未点亮时半透明
class _PhaseLight extends StatelessWidget {
  final bool active;
  final Color color;

  const _PhaseLight({required this.active, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: active ? color : color.withValues(alpha: 0.18),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.85),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : const [],
      ),
    );
  }
}
