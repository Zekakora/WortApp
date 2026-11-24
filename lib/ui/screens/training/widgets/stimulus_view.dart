import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/i18n/app_localizations.dart';
import './speech_controls.dart';

/// 材料区（阅读短文 / 听力音频 / 无材料）
///
/// 阅读材料支持**长按选择 → 查词**：选区文本连同所在句子一起交给
/// [ContextLookupSheet]（任务书 §6.1），因此这里要把选区偏移映射回句子边界。
/// 听力材料在提交前不展示原文，只给播放控件。
class StimulusView extends StatelessWidget {
  final String text;
  final String kind;
  final String? cefrLevel;

  /// 长按查词回调（selectedText, 所在句子, 整段上下文）
  final void Function(String selectedText, String? sentence, String? context)?
  onLookup;

  /// 是否已提交（听力原文在提交后才可见）
  final bool revealed;

  const StimulusView({
    super.key,
    required this.text,
    required this.kind,
    this.cefrLevel,
    this.onLookup,
    this.revealed = false,
  });

  bool get _isAudio => kind == 'audio';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (text.trim().isEmpty) return const SizedBox.shrink();

    if (_isAudio) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SpeechControls(text: text, sentenceMode: true),
          const SizedBox(height: 8),
          if (!revealed)
            Text(
              context.tr('听完后作答，提交后可查看原文'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            _TextBody(
              text: text,
              onLookup: onLookup,
              label: context.tr('听力原文'),
            ),
        ],
      );
    }

    return _TextBody(text: text, onLookup: onLookup, label: null);
  }

  /// 在当前段落里找选中位置所在的句子
  static String? sentenceAt(String text, int selectionStart) {
    if (text.isEmpty) return null;
    final index = selectionStart.clamp(0, text.length - 1);
    var start = index;
    var end = index;
    const terminators = {'.', '!', '?', '\n'};
    while (start > 0 && !terminators.contains(text[start - 1])) {
      start--;
    }
    while (end < text.length && !terminators.contains(text[end])) {
      end++;
    }
    if (end < text.length) end++;
    final sentence = text.substring(start, end).trim();
    return sentence.isEmpty ? null : sentence;
  }
}

class _TextBody extends StatelessWidget {
  final String text;
  final String? label;
  final void Function(String selectedText, String? sentence, String? context)?
  onLookup;

  const _TextBody({required this.text, this.label, this.onLookup});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(label!, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
          ],
          SelectableText(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            contextMenuBuilder: (menuContext, editableTextState) {
              final value = editableTextState.textEditingValue;
              final selection = value.selection;
              final selected = selection.isValid && !selection.isCollapsed
                  ? selection.textInside(value.text).trim()
                  : '';
              final sentence = selected.isEmpty
                  ? null
                  : StimulusView.sentenceAt(value.text, selection.start);

              return AdaptiveTextSelectionToolbar.buttonItems(
                anchors: editableTextState.contextMenuAnchors,
                buttonItems: [
                  if (selected.isNotEmpty && onLookup != null)
                    ContextMenuButtonItem(
                      label: context.tr('查词'),
                      onPressed: () {
                        editableTextState.hideToolbar();
                        onLookup!(selected, sentence, value.text);
                      },
                    ),
                  ContextMenuButtonItem(
                    label: context.tr('复制'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: selected));
                      editableTextState.hideToolbar();
                    },
                  ),
                ],
              );
            },
          ),
          if (onLookup != null) ...[
            const SizedBox(height: 8),
            Text(
              context.tr('长按选择单词可查词并加入词书'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
