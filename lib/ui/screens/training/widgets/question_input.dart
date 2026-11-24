import 'package:flutter/material.dart';

import '../../../../core/i18n/app_localizations.dart';
import '../../../../data/models/training.dart';

/// 题目输入控件（按题干类型渲染，任务书 §4.1 的 QuestionRenderer）
///
/// 答案编码约定（与 GradingService 对应）：
/// - 单选 / 排序：`0` / `2,0,1`
/// - 多选：`0,2`
/// - 判断：`true` / `false`
/// - 填空 / 听写 / 写作：原始文本
class QuestionInput extends StatefulWidget {
  final PlaybackQuestion question;
  final String initialValue;
  final ValueChanged<String> onChanged;
  final bool enabled;

  /// 听写题的播放回调（由答题页注入，复用 SpeechPlaybackService）
  final VoidCallback? onPlayAudio;

  /// 听写题是否已可播放（德语语音可用）
  final bool audioAvailable;

  const QuestionInput({
    super.key,
    required this.question,
    required this.initialValue,
    required this.onChanged,
    this.enabled = true,
    this.onPlayAudio,
    this.audioAvailable = true,
  });

  @override
  State<QuestionInput> createState() => _QuestionInputState();
}

class _QuestionInputState extends State<QuestionInput> {
  late final TextEditingController _controller;
  late List<int> _selectedIndices;
  late List<int> _order;
  bool? _trueFalse;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _selectedIndices = _parseIndices(widget.initialValue);
    _trueFalse = switch (widget.initialValue) {
      'true' => true,
      'false' => false,
      _ => null,
    };
    _order = _selectedIndices.isNotEmpty
        ? List<int>.from(_selectedIndices)
        : List<int>.generate(widget.question.options.length, (i) => i);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static List<int> _parseIndices(String raw) {
    if (raw.trim().isEmpty) return const [];
    return raw
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.question.type) {
      case QuestionType.singleChoice:
        return _buildSingleChoice(context);
      case QuestionType.multipleChoice:
        return _buildMultipleChoice(context);
      case QuestionType.trueFalse:
        return _buildTrueFalse(context);
      case QuestionType.fillBlank:
        return _buildTextInput(context, maxLines: 1, showCounter: false);
      case QuestionType.dictation:
        return _buildDictation(context);
      case QuestionType.ordering:
        return _buildOrdering(context);
      case QuestionType.freeText:
        return _buildTextInput(context, maxLines: 6, showCounter: true);
    }
  }

  Widget _buildSingleChoice(BuildContext context) {
    final selected = _selectedIndices.isEmpty ? null : _selectedIndices.first;
    return Column(
      children: [
        for (var i = 0; i < widget.question.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OptionTile(
              label: String.fromCharCode(65 + i),
              text: widget.question.options[i],
              selected: selected == i,
              onTap: widget.enabled
                  ? () {
                      setState(() => _selectedIndices = [i]);
                      widget.onChanged('$i');
                    }
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _buildMultipleChoice(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < widget.question.options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _OptionTile(
              label: String.fromCharCode(65 + i),
              text: widget.question.options[i],
              selected: _selectedIndices.contains(i),
              multiple: true,
              onTap: widget.enabled
                  ? () {
                      final next = List<int>.from(_selectedIndices);
                      if (next.contains(i)) {
                        next.remove(i);
                      } else {
                        next.add(i);
                      }
                      next.sort();
                      setState(() => _selectedIndices = next);
                      widget.onChanged(next.join(','));
                    }
                  : null,
            ),
          ),
      ],
    );
  }

  Widget _buildTrueFalse(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ChoiceButton(
            icon: Icons.check_circle_outline,
            label: context.tr('正确'),
            selected: _trueFalse == true,
            onTap: widget.enabled
                ? () {
                    setState(() => _trueFalse = true);
                    widget.onChanged('true');
                  }
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ChoiceButton(
            icon: Icons.cancel_outlined,
            label: context.tr('错误'),
            selected: _trueFalse == false,
            onTap: widget.enabled
                ? () {
                    setState(() => _trueFalse = false);
                    widget.onChanged('false');
                  }
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildDictation(BuildContext context) {
    final audioAvailable = widget.audioAvailable && widget.onPlayAudio != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (audioAvailable)
          OutlinedButton.icon(
            onPressed: widget.enabled ? widget.onPlayAudio : null,
            icon: const Icon(Icons.volume_up),
            label: Text(context.tr('播放句子')),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              context.tr('此设备没有德语语音，无法播放听写内容'),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          enabled: widget.enabled && audioAvailable,
          maxLines: 3,
          minLines: 2,
          autofocus: false,
          textCapitalization: TextCapitalization.sentences,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            labelText: context.tr('写下你听到的句子'),
            border: const OutlineInputBorder(),
            hintText: '...',
          ),
        ),
      ],
    );
  }

  Widget _buildOrdering(BuildContext context) {
    return Column(
      children: [
        for (var position = 0; position < _order.length; position++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(child: Text('${position + 1}')),
              title: Text(
                widget.question.options.length > _order[position]
                    ? widget.question.options[_order[position]]
                    : '${_order[position] + 1}',
              ),
              trailing: widget.enabled
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, size: 18),
                          onPressed: position == 0
                              ? null
                              : () => _move(position, -1),
                          visualDensity: VisualDensity.compact,
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward, size: 18),
                          onPressed: position == _order.length - 1
                              ? null
                              : () => _move(position, 1),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    )
                  : null,
            ),
          ),
      ],
    );
  }

  void _move(int position, int delta) {
    final next = List<int>.from(_order);
    final target = position + delta;
    if (target < 0 || target >= next.length) return;
    final item = next.removeAt(position);
    next.insert(target, item);
    setState(() => _order = next);
    widget.onChanged(next.join(','));
  }

  Widget _buildTextInput(
    BuildContext context, {
    required int maxLines,
    required bool showCounter,
  }) {
    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      maxLines: maxLines,
      minLines: maxLines > 1 ? 4 : 1,
      onChanged: (value) {
        if (showCounter) setState(() {});
        widget.onChanged(value);
      },
      decoration: InputDecoration(
        labelText: context.tr('你的答案'),
        border: const OutlineInputBorder(),
        counterText: showCounter ? _wordCountLabel(context) : null,
      ),
    );
  }

  /// 写作题显示词数（任务书 §3.3 要求字数统计）
  String _wordCountLabel(BuildContext context) {
    final words = _controller.text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    return context.trArgs('{0} 词', [words]);
  }
}

/// 单选 / 多选项
class _OptionTile extends StatelessWidget {
  final String label;
  final String text;
  final bool selected;
  final bool multiple;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.label,
    required this.text,
    required this.selected,
    this.multiple = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: multiple ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: multiple ? BorderRadius.circular(6) : null,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.surface,
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 15, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 判断正误按钮
class _ChoiceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _ChoiceButton({
    required this.icon,
    required this.label,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor:
            selected ? colorScheme.primaryContainer : null,
        side: selected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide(color: colorScheme.outlineVariant),
      ),
    );
  }
}
