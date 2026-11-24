import 'package:flutter/widgets.dart';

/// 宽屏（平板 / 折叠屏展开 / 桌面）判定
///
/// 断点取 600dp（Material 3 的 compact / medium 分界）：横屏手机与平板都会
/// 进入两栏，竖屏手机保持单栏。之前用 720dp 时，逻辑宽度 668dp 的平板
/// （如 1880px / 450dpi）反而排在"窄屏"，分栏永远不生效。
class WideLayout {
  WideLayout._();

  /// 分屏断点：≥ 600dp 视为宽屏
  static const double breakpoint = 600;

  /// 当前窗口是否宽屏
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= breakpoint;

  /// 给定宽度是否宽屏（在 LayoutBuilder 里用）
  static bool isWideWidth(double width) => width >= breakpoint;

  /// 内容最大宽度：窄屏铺满，宽屏居中限宽，避免一行文字拉得过长
  static double contentMaxWidth(BuildContext context) =>
      isWide(context) ? 960 : double.infinity;
}
