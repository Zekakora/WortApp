import 'package:flutter/widgets.dart';

/// 宽屏（平板 / 折叠屏展开 / 桌面）判定
///
/// 断点与学习模式的 `StudySplitLayout.minSplitWidth` 保持一致（720dp），
/// 这样"什么时候变成两栏"在整个应用里是同一套标准。
class WideLayout {
  WideLayout._();

  /// 分屏断点：≥ 720dp 视为宽屏
  static const double breakpoint = 720;

  /// 当前窗口是否宽屏
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= breakpoint;

  /// 给定宽度是否宽屏（在 LayoutBuilder 里用）
  static bool isWideWidth(double width) => width >= breakpoint;

  /// 内容最大宽度：窄屏铺满，宽屏居中限宽，避免一行文字拉得过长
  static double contentMaxWidth(BuildContext context) =>
      isWide(context) ? 960 : double.infinity;
}
