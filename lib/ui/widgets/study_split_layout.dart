import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../../core/i18n/app_localizations.dart';
import '../screens/deck/word_detail_screen.dart';

/// 学习 / 变位练习答题界面的平板分屏容器
///
/// 宽屏（宽度 ≥ [minSplitWidth]，如平板横屏）时分为左右两栏：
/// - 左侧：答题界面（与原布局完全一致）
/// - 右侧：当前单词的详情面板，初始带模糊层；
///   点击右侧任意位置或通过 [StudySplitLayoutState.reveal]
///   （回答正确时调用）关闭模糊层，查看单词详情。
/// 切换到新单词后模糊层自动恢复。
class StudySplitLayout extends StatefulWidget {
  /// 启用分屏的最小宽度
  static const double minSplitWidth = 720;

  /// 左侧答题内容
  final Widget left;

  /// 当前单词 id（变化时自动重新加载详情并恢复模糊层）
  final int wordId;

  /// 右侧详情面板是否只读（隐藏编辑/删除等操作，学习场景下防误触）
  final bool readOnly;

  const StudySplitLayout({
    super.key,
    required this.left,
    required this.wordId,
    this.readOnly = true,
  });

  /// 当前屏幕宽度是否满足分屏条件
  static bool isSplitWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= minSplitWidth;

  @override
  State<StudySplitLayout> createState() => StudySplitLayoutState();
}

/// [StudySplitLayout] 的状态，可通过 GlobalKey 调用 [reveal]
class StudySplitLayoutState extends State<StudySplitLayout> {
  bool _blurred = true;

  /// 关闭右侧详情面板的模糊层（回答正确时调用）
  void reveal() {
    if (!_blurred) return;
    setState(() => _blurred = false);
  }

  @override
  void didUpdateWidget(StudySplitLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 切换到新单词时恢复模糊层
    if (oldWidget.wordId != widget.wordId) {
      _blurred = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < StudySplitLayout.minSplitWidth) {
          // 手机 / 窄屏：保持原有单栏布局
          return widget.left;
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(flex: 3, child: widget.left),
            const VerticalDivider(width: 1, thickness: 1),
            Expanded(flex: 2, child: _buildDetailPanel(context)),
          ],
        );
      },
    );
  }

  /// 右侧单词详情面板（带模糊层）
  Widget _buildDetailPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      fit: StackFit.expand,
      children: [
        // 单词详情：以单词 id 为 key，切换单词时强制重建并重新加载
        KeyedSubtree(
          key: ValueKey(widget.wordId),
          child: WordDetailScreen(
            wordId: widget.wordId,
            readOnly: widget.readOnly,
          ),
        ),
        // 模糊层：点击关闭
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _blurred
              ? GestureDetector(
                  key: const ValueKey('detail_blur'),
                  behavior: HitTestBehavior.opaque,
                  onTap: reveal,
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        color: colorScheme.surface.withValues(alpha: 0.55),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.touch_app_outlined,
                              size: 48,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.tr('点击查看单词详情'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              context.tr('回答正确后自动显示'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
