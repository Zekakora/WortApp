import 'package:flutter/material.dart';

/// 入场动画：淡入 + 轻微上移，用非线性曲线（默认 easeOutBack/ easeOutCubic）
///
/// 训练模块里用得比较克制：技能卡片、结果页的题目网格。
/// 目的只是让"新内容出现"不那么生硬，不做花哨的连续动画。
class Entrance extends StatefulWidget {
  final Widget child;

  /// 同一批元素的下标，用来做错峰延迟（0、1、2…）
  final int index;

  /// 每个元素之间的延迟
  final Duration stagger;

  final Duration duration;

  /// 位移曲线（非线性，默认带回弹的 easeOutBack）
  final Curve slideCurve;

  /// 淡入曲线
  final Curve fadeCurve;

  /// 起始垂直偏移（相对自身高度）
  final double offsetY;

  const Entrance({
    super.key,
    required this.child,
    this.index = 0,
    this.stagger = const Duration(milliseconds: 55),
    this.duration = const Duration(milliseconds: 380),
    this.slideCurve = Curves.easeOutBack,
    this.fadeCurve = Curves.easeOut,
    this.offsetY = 0.10,
  });

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: widget.fadeCurve,
  );

  late final Animation<Offset> _slide = Tween<Offset>(
    begin: Offset(0, widget.offsetY),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: widget.slideCurve));

  @override
  void initState() {
    super.initState();
    final delay = widget.stagger * widget.index;
    if (delay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
