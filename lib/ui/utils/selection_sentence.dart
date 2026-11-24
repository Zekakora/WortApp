/// 选区 → 所在句子
///
/// 长按查词要把"用户选中的词 + 它所在的句子"一起交给查词引擎，
/// 因此在纯文本里按标点边界把句子切出来。
library;

/// 找出 [selectionStart] 所在的句子（以 `. ! ? 换行` 为界）
///
/// 返回去掉首尾空白后的句子；空文本时返回 null。
String? sentenceAtOffset(String text, int selectionStart) {
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
