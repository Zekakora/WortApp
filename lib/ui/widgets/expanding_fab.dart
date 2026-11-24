import 'package:flutter/material.dart';

/// 展开式 FAB 的一个动作项
class ExpandingFabAction {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const ExpandingFabAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
}

/// 展开式 FAB：点击主按钮展开一排小动作按钮（带底部标签），
/// 点击空白处收起。用于收纳多个低频操作，避免常驻 FAB 列遮挡列表内容。
class ExpandingFab extends StatefulWidget {
  final List<ExpandingFabAction> actions;

  const ExpandingFab({super.key, required this.actions});

  @override
  State<ExpandingFab> createState() => _ExpandingFabState();
}

class _ExpandingFabState extends State<ExpandingFab> {
  bool _expanded = false;

  void _run(ExpandingFabAction action) {
    setState(() => _expanded = false);
    action.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = widget.actions.length - 1; i >= 0; i--)
              _buildAction(context, widget.actions[i], i),
            const SizedBox(height: 8),
            FloatingActionButton(
              heroTag: 'expandingFabMain',
              onPressed: () => setState(() => _expanded = !_expanded),
              shape: const CircleBorder(),
              child: AnimatedRotation(
                turns: _expanded ? 0.125 : 0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                child: Icon(_expanded ? Icons.close : Icons.tune),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAction(
      BuildContext context, ExpandingFabAction action, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    return IgnorePointer(
      ignoring: !_expanded,
      child: AnimatedSlide(
        offset: _expanded ? Offset.zero : const Offset(0, 0.5),
        duration: Duration(milliseconds: 160 + index * 30),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _expanded ? 1 : 0,
          duration: Duration(milliseconds: 160 + index * 30),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedOpacity(
                  opacity: _expanded ? 1 : 0,
                  duration: const Duration(milliseconds: 120),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      action.label,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.small(
                  heroTag: 'expandingFabAction$index',
                  onPressed: () => _run(action),
                  child: Icon(action.icon),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
