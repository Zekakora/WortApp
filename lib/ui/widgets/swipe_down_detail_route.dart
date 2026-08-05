import 'package:flutter/material.dart';

/// 从底部滑入、可下滑关闭的单词详情页路由。
///
/// - 打开：页面从屏幕底部滑入
/// - 关闭：在页面顶部区域（含状态栏 / AppBar 区域）下滑并超过阈值后，
///   页面跟手向下滑动并退出；未达阈值则回弹复位
/// - 详情内容区域的内部滚动不受影响（滚动手势优先于下滑关闭）
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

/// 包裹详情页，提供跟手下滑关闭交互
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

  void _onDragUpdate(DragUpdateDetails details) {
    if (_dismissing) return;
    if (_controller.isAnimating) _controller.stop();
    final current = _controller.value * _maxOffset;
    final next = (current + details.delta.dy).clamp(0.0, _maxOffset);
    _controller.value = next / _maxOffset;
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dismissing) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 700 || _controller.value > 0.18) {
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
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
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
    );
  }
}
