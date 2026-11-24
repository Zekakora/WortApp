import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dictionary_engine.dart';

/// 德语助手（godic.net）查词引擎
///
/// 抓取词条页 HTML，仅提取释义（`<span class="exp">`），
/// 不返回冠词/变位/例句等其他字段，入库时仅添加单词本身，避免数据干扰。
class GedicDictionaryEngine implements DictionaryEngine {
  static const String engineName = '德语助手';

  /// 请求超时：避免网络异常时查词界面长时间无响应
  static const Duration requestTimeout = Duration(seconds: 15);

  final http.Client _client;

  GedicDictionaryEngine({http.Client? client})
      : _client = client ?? http.Client();

  @override
  String get name => engineName;

  @override
  Future<DictionaryResult?> lookup(
    String word, {
    bool forceRefresh = false,
    LookupContext? context,
  }) async {
    try {
      // 德语助手无本地缓存，forceRefresh 无实际作用，忽略
      final url = Uri.parse(
        'https://www.godic.net/dicts/de/${Uri.encodeComponent(word)}',
      );

      final response =
          await _client.get(url).timeout(requestTimeout);

      if (response.statusCode != 200) {
        return null;
      }

      final definitions = parseDefinitions(response.body);
      if (definitions.isEmpty) {
        return null;
      }

      return DictionaryResult(
        word: word,
        definitions: definitions,
        examples: const [],
        engine: engineName,
        wordOnly: true,
      );
    } catch (e) {
      debugPrint('德语助手查词失败: $e');
      return null;
    }
  }

  /// 从词条页 HTML 中提取全部释义文本。
  ///
  /// 只匹配 `<span class="exp">`（释义块），剥离其中的 `<img>`、
  /// 解释性标签等 HTML 标记，并去掉句首的 ① ② ③ 等序号。
  static List<String> parseDefinitions(String html) {
    final result = <String>[];

    // 释义块：class="exp" 的 span；示例句块用 <p class="exp">，不匹配
    final expRegExp = RegExp(r'<span class="exp">(.*?)</span>', dotAll: true);
    final tagRegExp = RegExp(r'<[^>]+>');
    // 允许序号前存在空白（部分条目 "<span class=\"exp\"> ① ...</span>"）
    final numberRegExp = RegExp(r'^\s*[\u2460-\u24FF]+[\s、，,.;]*');
    final spaceRegExp = RegExp(r'\s+');

    for (final match in expRegExp.allMatches(html)) {
      var text = match.group(1)!;
      // 剥离 HTML 标记（含 <img>、<宾语...> 等解释性标签）
      text = text.replaceAll(tagRegExp, '');
      // 去掉句首序号 ① ② … ⑳ 及随后的空格/标点
      text = text.replaceAll(numberRegExp, '');
      // 合并多余空白
      text = text.replaceAll(spaceRegExp, ' ').trim();

      if (text.isEmpty) continue;
      result.add(text);
    }

    return result;
  }
}
