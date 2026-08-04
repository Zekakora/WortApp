import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dictionary_engine.dart';

/// Wiktionary 查词引擎
class WiktionaryEngine implements DictionaryEngine {
  final http.Client _client;

  WiktionaryEngine({http.Client? client}) : _client = client ?? http.Client();

  @override
  String get name => 'Wiktionary';

  @override
  Future<DictionaryResult?> lookup(String word, {bool forceRefresh = false}) async {
    try {
      // Wiktionary 无本地缓存，forceRefresh 无实际作用，忽略
      // 使用 Wiktionary API
      final url = Uri.parse(
        'https://en.wiktionary.org/api/rest_v1/page/summary/${Uri.encodeComponent(word)}',
      );

      final response = await _client.get(url);

      if (response.statusCode != 200) {
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      final title = data['title'] as String? ?? word;
      final extract = data['extract'] as String? ?? '';

      if (extract.isEmpty) {
        return null;
      }

      return DictionaryResult(
        word: title,
        definitions: [extract],
        examples: [],
        engine: name,
      );
    } catch (e) {
      print('Wiktionary 查词失败: $e');
      return null;
    }
  }
}
