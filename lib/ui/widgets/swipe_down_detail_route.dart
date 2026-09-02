import 'package:flutter/material.dart';

/// 从底部滑入、可下滑关闭的单词详情页路由。
///
/// - 打开：页面从屏幕底部滑入
/// - 关闭：在页面任意位置下滑并超过阈值后，页面跟手向下滑动并退出；
///   未达阈值则回弹复位
/// - 详情内容区域的内部滚动不受影响：内容未处于顶部时，下滑交给滚动处理
///   （向上翻阅历史内容）；内容处于顶部时，任意位置下滑都会跟手关闭
class SwipeDownDetailRoute<T> extends PageRouteBuilder<T> {
  SwipeDownDetailRoute({required WidgetBuilder builder})
      : super(
          // 非不透明路由：滑动期间透出底层学习页面，避免露出黑色背景
          opaque: false,
          transitionDuration: const Duration(milliseconds: 300),
          reverseTransitionDuration: const Duration(milliseconds: 240),
          pageBuilder: (context, animation, secondaryAnimation) =>
              SwipeDownDismissiblePage(child: builder(context)),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            );
          },
        );
}

/// 包裹详情页，提供跟手下滑关闭交互。
///
/// 使用 [Listener] 监听原始指针事件：即使拖动手势被内部可滚动区域抢占
/// （Scrollable 在手势竞技场中胜出），页面仍能跟手位移；
/// 同时通过 [NotificationListener] 跟踪滚动位置，避免与上翻阅读冲突。
class SwipeDownDismissiblePage extends StatefulWidget {
  final Widget child;

  const SwipeDownDismissiblePage({super.key, required this.child});

  @override
  State<SwipeDownDismissiblePage> createState() =>
      _SwipeDownDismissiblePageState();
}

class _SwipeDownDismissiblePageState extends State<SwipeDownDismissiblePage>
    with SingleTickerProviderStateMixin {
  /// 下滑进度（0 = 原位，1 = 已完全滑出屏幕），拖动时直接赋值实现跟手
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );
  bool _dismissing = false;

  /// 完全滑出屏幕所需的位移
  double get _maxOffset => MediaQuery.sizeOf(context).height * 1.15;

  /// 内容当前是否处于顶部（滚动通知实时更新）
  bool _scrollAtTop = true;
  bool _scrollable = false;

  // ---- 原始指针拖动追踪 ----
  Offset? _pointerStart;
  double _dragStartValue = 0;
  bool _dragEngaged = false;
  Offset? _lastMovePos;
  DateTime? _lastMoveTime;
  double _velocity = 0;

  /// 跟手前允许的滑动距离（防止误触）
  static const double _dragSlop = 8;

  /// 触发关闭的位移比例阈值
  static const double _dismissFraction = 0.18;

  bool _onScrollNotification(ScrollNotification notification) {
    _scrollable = notification.metrics.maxScrollExtent > 0;
    _scrollAtTop = notification.metrics.pixels <= 0;
    return false;
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_dismissing) return;
    _pointerStart = event.position;
    _dragStartValue = _controller.value;
    _dragEngaged = false;
    _velocity = 0;
    _lastMovePos = null;
    _lastMoveTime = null;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_dismissing || _pointerStart == null) return;

    // 记录即时速度（供松手时的惯性判断）
    final now = DateTime.now();
    if (_lastMovePos != null && _lastMoveTime != null) {
      final dt = now.difference(_lastMoveTime!).inMilliseconds;
      if (dt > 0) {
        _velocity = (event.position.dy - _lastMovePos!.dy) / (dt / 1000);
      }
    }
    _lastMovePos = event.position;
    _lastMoveTime = now;

    final dy = event.position.dy - _pointerStart!.dy;

    // 向上拖动：若此前已跟手位移，随手指回弹
    if (dy <= 0) {
      if (_dragEngaged) {
        _controller.value =
            (_dragStartValue + dy / _maxOffset).clamp(0.0, 1.0);
      }
      return;
    }

    // 内容不在顶部时，下滑交给内部滚动（向上翻阅），不触发关闭
    if (_scrollable && !_scrollAtTop) return;

    if (_controller.isAnimating) _controller.stop();
    final offset = dy < _dragSlop ? 0.0 : dy - _dragSlop;
    if (offset > 0) _dragEngaged = true;
    _controller.value =
        (_dragStartValue + offset / _maxOffset).clamp(0.0, 1.0);
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_dismissing || _pointerStart == null) return;
    _pointerStart = null;
    _finishDrag();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerStart = null;
    _finishDrag();
  }

  void _finishDrag() {
    if (!_dragEngaged) return;
    _dragEngaged = false;
    final velocity = _velocity;
    if (velocity > 700 || _controller.value > _dismissFraction) {
      // 超过阈值：先跟手动画滑出屏幕，再关闭路由，
      // 与路由反向下滑动画无缝衔接
      _dismissing = true;
      _controller.animateTo(1).then((_) {
        if (mounted) Navigator.of(context).pop();
      });
    } else {
      // 未达阈值：回弹复位
      _controller.animateTo(0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _controller.value * _maxOffset),
            child: child,
          ),
          child: Stack(
            children: [
              widget.child,
              // 顶部下滑关闭把手（视觉提示，不拦截触摸）
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.45),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
