import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dictionary_engine.dart';

/// Wiktionary 查词引擎
class WiktionaryEngine implements DictionaryEngine {
  static const String engineName = 'Wiktionary';

  /// 请求超时：Wiktionary 在部分网络环境（如国内直连）连接不稳定，
  /// 超时后快速失败返回，避免查词界面长时间无响应
  static const Duration requestTimeout = Duration(seconds: 15);

  final http.Client _client;

  WiktionaryEngine({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get name => engineName;

  @override
  Future<DictionaryResult?> lookup(String word, {bool forceRefresh = false}) async {
    try {
      // Wiktionary 无本地缓存，forceRefresh 无实际作用，忽略
      // 使用 Wiktionary REST API 摘要（summary）
      final url = Uri.parse(
        'https://en.wiktionary.org/api/rest_v1/page/summary/${Uri.encodeComponent(word)}',
      );

      final response =
          await _client.get(url).timeout(requestTimeout);

      if (response.statusCode != 200) {
        return null;
      }

      final data =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;

      final title = data['title'] as String? ?? word;
      final extract = data['extract'] as String? ?? '';

      final definitions = cleanDefinitions(extract);
      if (definitions.isEmpty) {
        return null;
      }

      return DictionaryResult(
        word: title,
        definitions: definitions,
        examples: const [],
        engine: engineName,
        wordOnly: true,
      );
    } catch (e) {
      debugPrint('Wiktionary 查词失败: $e');
      return null;
    }
  }

  /// 从 summary 摘要文本中提取纯释义，剔除词源（From ...）、音标、来源说明等噪音。
  ///
  /// 只保留 definition 语义的内容：词源/音标等整段噪音直接跳过，
  /// 其余段落按句子切分，丢弃以词源/音标/提示信息开头的片段，仅返回释义。
  static List<String> cleanDefinitions(String extract) {
    final result = <String>[];
    if (extract.isEmpty) return result;

    for (final paragraph in extract.split('\n')) {
      var p = paragraph.trim();
      if (p.isEmpty) continue;

      // 词源/音标等整段噪音直接跳过
      if (_isNoise(p)) continue;

      for (final raw in _splitSentences(p)) {
        var sentence = raw.trim();
        if (sentence.isEmpty || _isNoise(sentence)) continue;

        // 去掉行内词源/音标类中括号标记，如 "x [From ...] y"
        sentence = sentence.replaceAll(RegExp(r'\[[^\]]*\]'), '').trim();
        // 去掉句首编号 "1. "、"1) "
        sentence = sentence.replaceFirst(RegExp(r'^\d+[.、)]\s*'), '');
        // 去掉尾部孤立的标点
        sentence = sentence.replaceFirst(RegExp(r'[,;:]$'), '').trim();

        if (sentence.isEmpty || sentence.length < 3) continue;
        result.add(sentence);
      }
    }
    return result;
  }

  /// 非释义内容（词源、音标、来源提示等）识别
  static bool _isNoise(String s) {
    final lower = s.toLowerCase();
    if (lower.startsWith('from ') ||
        lower.startsWith('etymology') ||
        lower.startsWith('see also') ||
        lower.startsWith('rhymes:') ||
        lower.startsWith('hyphenation:') ||
        lower.startsWith('audio') ||
        lower.startsWith('ipa') ||
        lower.startsWith('(this etymology is missing') ||
        lower.startsWith('please add to it') ||
        lower.startsWith('/')) {
      return true;
    }
    if (lower.contains('etymology is missing or incomplete') ||
        lower.contains('etymology scriptorium')) {
      return true;
    }
    return false;
  }

  /// 按句子边界切分（段落内多为单句时原样返回）
  static List<String> _splitSentences(String paragraph) {
    // 保留对句号/感叹号/问号后的切分，避免把整段词源与释义粘成一句
    return paragraph.split(RegExp(r'(?<=[.!?:])\s+'));
  }
}
