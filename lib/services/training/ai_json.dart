/// AI 文本 → JSON 对象的容错解析工具
///
/// 从 `AIDictionaryEngine._extractJson`（原本是私有方法）提取出的公共实现，
/// 供查词与训练生成共用：模型经常在 JSON 外面包 ```json 围栏、加前言、
/// 或输出中文引号/尾随逗号，直接 `jsonDecode` 会失败。
library;

import 'dart:convert';

/// 从模型输出中解析出 JSON 对象；失败返回 null。
Map<String, dynamic>? decodeJsonObject(String raw) {
  final jsonText = extractJson(raw);
  if (jsonText == null) return null;
  try {
    final decoded = jsonDecode(jsonText);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return null;
  } catch (_) {
    return null;
  }
}

/// 从模型输出中提取 JSON 文本（对象或数组均可）
///
/// 尝试顺序：原文 → 去代码围栏 → 括号配对截取 → 常见格式修复后重试。
String? extractJson(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  // 1. 原文即合法 JSON
  if (_isValid(text)) return text;

  // 2. 去掉 ```json ... ``` 围栏
  final unfenced = _stripCodeFence(text);
  if (unfenced != text && _isValid(unfenced)) return unfenced;

  // 3. 从第一个 { 或 [ 开始做括号配对截取
  for (final source in [text, unfenced]) {
    final candidate = _balancedSlice(source);
    if (candidate != null && _isValid(candidate)) return candidate;
  }

  // 4. 修复常见问题（中文标点、尾随逗号、单引号）后再试
  for (final source in [text, unfenced]) {
    final candidate = _balancedSlice(source);
    for (final fixed in [_fixQuotes(source), _fixQuotes(candidate ?? source)]) {
      final repaired = _removeTrailingCommas(fixed);
      if (_isValid(repaired)) return repaired;
      final sliced = _balancedSlice(repaired);
      if (sliced != null && _isValid(sliced)) return sliced;
    }
  }

  return null;
}

bool _isValid(String text) {
  try {
    jsonDecode(text);
    return true;
  } catch (_) {
    return false;
  }
}

/// 去掉 markdown 代码围栏
String _stripCodeFence(String text) {
  var s = text;
  final fence = RegExp(r'```[a-zA-Z]*\s*');
  s = s.replaceAll(fence, '');
  return s.replaceAll('```', '').trim();
}

/// 从首个 { 或 [ 开始，按配对截取到对应结束符
String? _balancedSlice(String text) {
  final start = text.indexOf(RegExp(r'[\[{]'));
  if (start < 0) return null;
  final open = text[start];
  final close = open == '{' ? '}' : ']';

  var depth = 0;
  var inString = false;
  var escaped = false;
  for (var i = start; i < text.length; i++) {
    final ch = text[i];
    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (ch == r'\') {
        escaped = true;
      } else if (ch == '"') {
        inString = false;
      }
      continue;
    }
    if (ch == '"') {
      inString = true;
    } else if (ch == open) {
      depth++;
    } else if (ch == close) {
      depth--;
      if (depth == 0) return text.substring(start, i + 1);
    }
  }
  // 未闭合：返回从起点到末尾（后续修复可能补全）
  return text.substring(start);
}

/// 中文引号 / 全角符号 → 半角
String _fixQuotes(String text) {
  return text
      .replaceAll('\u201c', '"')
      .replaceAll('\u201d', '"')
      .replaceAll('\u2018', "'")
      .replaceAll('\u2019', "'")
      .replaceAll('：', ':')
      .replaceAll('，', ',')
      .replaceAll('\u00a0', ' ');
}

/// 去掉对象/数组里的尾随逗号（`,` 紧跟 `}` 或 `]`）
String _removeTrailingCommas(String text) {
  return text.replaceAll(RegExp(r',\s*([}\]])'), r'$1');
}
