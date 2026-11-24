import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../core/i18n/app_localizations.dart';
import '../ai/ai_service.dart';
import 'dictionary_engine.dart';

/// AI 深度解析引擎
class AIDictionaryEngine implements DictionaryEngine {
  final AIService _aiService;
  final Future<void> Function(String word, String resultJson)? cacheCallback;
  final Future<String?> Function(String word)? getCacheCallback;

  /// 记录 AI 请求结果（success=false 时携带失败原因），用于「数据管理」展示与重试
  final Future<void> Function(String word, bool success, String? error)?
      statusCallback;

  AIDictionaryEngine(
    this._aiService, {
    this.cacheCallback,
    this.getCacheCallback,
    this.statusCallback,
  });

  @override
  String get name => 'AI 解析';

  @override
  Future<DictionaryResult?> lookup(String word, {bool forceRefresh = false}) async {
    try {
      // 先检查缓存（手动更新 forceRefresh=true 时跳过缓存，强制请求 AI）
      final cacheGetter = getCacheCallback;
      if (!forceRefresh && cacheGetter != null) {
        String? cachedJson;
        try {
          cachedJson = await cacheGetter(word);
        } catch (e) {
          debugPrint('读取 AI 缓存失败: $word - $e');
        }
        if (cachedJson != null && !_isPollutedCache(cachedJson)) {
          try {
            final cachedResult = _parseResult(word, cachedJson);
            if (cachedResult.definitions.isNotEmpty) {
              debugPrint('Using cached result for: $word');
              return cachedResult;
            }
            // 缓存结果缺少释义，忽略缓存重新查询
            debugPrint('缓存结果缺少释义，重新查询: $word');
          } catch (e) {
            // 缓存损坏（结构异常）：忽略并重新查询；查询成功后会覆盖坏缓存自愈，
            // 避免该词从此每次查询都失败
            debugPrint('AI 缓存解析失败，重新查询: $word - $e');
          }
        } else if (cachedJson != null) {
          debugPrint('缓存含"null"占位符污染，重新查询: $word');
        }
      } else if (forceRefresh) {
        debugPrint('强制刷新，跳过缓存直接请求 AI: $word');
      }

      final systemPrompt = '''你是德语词典专家。严格返回纯JSON，无代码块无解释。释义最多3个，例句最多2个，分析最多50字，输出保持紧凑避免截断：
${_languageDirective()}
{
  "word": "原形",
  "definitions": ["释义1","释义2"],
  "examples": ["例句 - 翻译"],
  "analysis": "词根/等级/近义词(50字内)",
  "article": "der/die/das",
  "plural": "复数",
  "part_of_speech": "verb/noun/adjective/adverb/preposition/pronoun/conjunction/other",
  "verb_type": "basic/separable/null",
  "conjugation": {"ich":"","du":"","er":"","wir":"","ihr":"","sie":""},
  "separable_prefix": "前缀或null",
  "base_verb": "基础动词或null",
  "collocations": [{"pattern":"搭配","case":"dative/accusative","meaning":"含义"}],
  "noun_type": "countable/uncountable/both/null",
  "inflection": {
    "type": "verb/noun/adjective（与part_of_speech一致）",
    "praesens": {"ich":"","du":"","er_sie_es":"","wir":"","ihr":"","sie_Sie":""},
    "praeteritum": 同6人称,
    "perfekt": {"auxiliary":"haben/sein","partizip":"过去分词","ich":"","du":"","er_sie_es":"","wir":"","ihr":"","sie_Sie":""},
    "passiv": {"ich":"","du":"","er_sie_es":"","wir":"","ihr":"","sie_Sie":""},
    "genitiv": "名词第二格单数",
    "plural": "名词复数",
    "komparativ": "形容词比较级",
    "superlativ": "形容词最高级"
  }
}
注意：inflection 只返回与词性对应的键（动词返回 praesens/praeteritum/perfekt/passiv 四个时态，其中 passiv 为现在时被动态（werden + 过去分词）的 6 人称形式；名词返回 genitiv/plural，形容词返回 komparativ/superlativ），其他词性返回null。时态键（praesens/praeteritum/perfekt/passiv/genitiv/plural/komparativ/superlativ）必须直接放在 inflection 顶层，绝对不要使用中文键名（如"动词时""名词时"）或额外嵌套。变位人称键名必须用 er_sie_es、sie_Sie。''';

      String response;
      try {
        response = await _aiService.chat(
          systemPrompt: systemPrompt,
          userMessage: '请解析德语单词: $word',
          temperature: 0.3,
          maxTokens: 8192,
        );
      } catch (e) {
        debugPrint('AI 请求失败，尝试简化请求: $e');
        response = await _aiService.chat(
          systemPrompt:
              '德语词典。返回纯JSON。释义最多2个，例句1个，分析30字内。${_languageDirective()}',
          userMessage: '解析: $word',
          temperature: 0.3,
          maxTokens: 4096,
        );
      }

      debugPrint('AI response: $response');

      String jsonStr;
      try {
        jsonStr = _extractJson(response);
      } catch (e) {
        debugPrint('JSON 解析失败，尝试简化请求: $e');
        final retryResponse = await _aiService.chat(
          systemPrompt:
              '德语词典。严格只返回一个JSON对象。释义2个，例句1个，分析30字内。不要多余文字。${_languageDirective()}',
          userMessage: '解析: $word',
          temperature: 0.1,
          maxTokens: 4096,
        );
        jsonStr = _extractJson(retryResponse);
      }
      debugPrint('Extracted JSON: $jsonStr');

      // 缓存结果（仅当包含释义时缓存，避免把不完整数据写入缓存）
      final result = _parseResult(word, jsonStr);
      if (result.definitions.isNotEmpty) {
        final cacheWriter = cacheCallback;
        if (cacheWriter != null) {
          await cacheWriter(word, jsonStr);
        }
        await _recordStatus(word, true, null);
      } else {
        // AI 响应了但没有有效释义，按失败记录
        debugPrint('AI 未返回有效释义: $word');
        await _recordStatus(word, false, 'AI 未返回有效释义');
      }

      return result;
    } catch (e) {
      debugPrint('AI 查词失败: $e');
      await _recordStatus(word, false, e.toString());
      return null;
    }
  }

  /// 记录 AI 请求状态（失败不影响查词流程本身）
  Future<void> _recordStatus(
      String word, bool success, String? error) async {
    try {
      await statusCallback?.call(word, success, error);
    } catch (e) {
      debugPrint('记录AI请求状态失败: $e');
    }
  }

  /// 释义 / 例句翻译 / 分析 的输出语言指令，跟随界面语言设置。
  String _languageDirective() {
    switch (AppLocale.code) {
      case AppLocale.en:
        return 'IMPORTANT: Output the "definitions", the translations inside "examples" and the "analysis" in English.';
      case AppLocale.de:
        return 'WICHTIG: Gib die "definitions", die Übersetzungen in "examples" und die "analysis" auf Deutsch aus.';
      default:
        return '重要：definitions 释义、examples 中的翻译与 analysis 分析必须使用简体中文。';
    }
  }

  DictionaryResult _parseResult(String word, String jsonStr) {
    return parseResult(word, jsonStr);
  }

  /// 公开的JSON解析方法，供外部解析缓存数据使用
  static DictionaryResult parseResult(String word, String jsonStr) {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    return DictionaryResult(
      word: data['word'] as String? ?? word,
      article: _asNullableString(data['article']),
      plural: _asNullableString(data['plural']),
      definitions: (data['definitions'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList() ??
          [],
      examples: (data['examples'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList() ??
          [],
      partOfSpeech: _normalizePartOfSpeech(_asNullableString(data['part_of_speech'])),
      aiAnalysis: _asNullableString(data['analysis']),
      engine: 'AI 解析',
      verbType: _asNullableString(data['verb_type']),
      conjugation: (data['conjugation'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v.toString())),
      separablePrefix: _asNullableString(data['separable_prefix']),
      baseVerb: _asNullableString(data['base_verb']),
      collocations: (data['collocations'] as List?)
          ?.map((e) => VerbCollocation(
                pattern: e['pattern'] as String? ?? '',
                caseType: e['case'] as String? ?? '',
                meaning: e['meaning'] as String? ?? '',
              ))
          .toList(),
      nounType: _normalizeNounType(_asNullableString(data['noun_type'])),
      inflection: _parseInflection(data['inflection']),
    );
  }

  /// 解析 AI 返回的完整变格/变位数据（与 conjugation_cache 存储格式一致）
  ///
  /// 只保留有实际内容的字段；非 Map 或空内容返回 null
  static Map<String, dynamic>? _parseInflection(dynamic value) {
    if (value is! Map<String, dynamic>) return null;
    final map = Map<String, dynamic>.from(value);
    map.removeWhere((k, v) => v == null);
    if (map.isEmpty) return null;

    // 兼容 AI 返回的旧格式：时态嵌套在“动词时/名词时/形容词时”容器中，
    // 展平到顶层（顶层已有同名键时以顶层为准），保证存储格式统一
    for (final containerKey in const ['动词时', '名词时', '形容词时']) {
      final container = map[containerKey];
      if (container is Map<String, dynamic>) {
        map.remove(containerKey);
        container.forEach((key, value) {
          map.putIfAbsent(key, () => value);
        });
      }
    }

    // 清理各时态中的空字符串人称
    for (final key in ['praesens', 'praeteritum', 'perfekt', 'passiv']) {
      final tense = map[key];
      if (tense is Map<String, dynamic>) {
        final cleaned = Map<String, dynamic>.from(tense)
          ..removeWhere((k, v) => v == null || v.toString().trim().isEmpty);
        if (cleaned.isEmpty) {
          map.remove(key);
        } else {
          map[key] = cleaned;
        }
      }
    }
    for (final key in ['genitiv', 'genitive', 'plural', 'pluralform',
        'komparativ', 'comparative', 'superlativ', 'superlative']) {
      final v = map[key];
      if (v is String && v.trim().isEmpty) {
        map.remove(key);
      }
    }
    return map.isEmpty ? null : map;
  }

  /// 将 AI 返回的词性统一规范为小写英文
  /// （verb/noun/adjective/adverb/preposition/pronoun/conjunction/other）
  /// AI 可能返回 "Verb"、"动词"、"Präposition" 等不规范值，统一后保证下拉框/标签正常匹配
  static String? _normalizePartOfSpeech(String? value) {
    if (value == null) return null;
    final s = value.trim().toLowerCase();
    switch (s) {
      case 'verb':
      case '动词':
      case 'v':
        return 'verb';
      case 'noun':
      case '名词':
      case 'n':
        return 'noun';
      case 'adjective':
      case 'adj':
      case '形容词':
        return 'adjective';
      case 'adverb':
      case 'adv':
      case '副词':
        return 'adverb';
      case 'preposition':
      case 'prep':
      case '介词':
      case 'präposition':
      case 'praeposition':
        return 'preposition';
      case 'pronoun':
      case 'pron':
      case '代词':
      case 'pronomen':
        return 'pronoun';
      case 'conjunction':
      case 'conj':
      case '连词':
      case 'konjunktion':
        return 'conjunction';
      case 'other':
      case '其他':
      case 'sonst':
      case 'sonstiges':
        return 'other';
      default:
        // 无法识别的词性不传，避免脏值入库
        return null;
    }
  }

  /// 将 AI 返回的名词类型统一为小写英文（countable/uncountable/both）
  static String? _normalizeNounType(String? value) {
    if (value == null) return null;
    final s = value.trim().toLowerCase();
    switch (s) {
      case 'countable':
      case '可数':
      case 'c':
        return 'countable';
      case 'uncountable':
      case '不可数':
      case 'u':
        return 'uncountable';
      case 'both':
      case 'countable/uncountable':
      case 'c/u':
      case '可数不可数':
      case '可数/不可数':
        return 'both';
      default:
        return null;
    }
  }

  /// 将缓存/响应中的空值字符串（"null"、""）转换为真正的 null
  static String? _asNullableString(dynamic value) {
    if (value == null) return null;
    final s = value.toString();
    return (s.isEmpty || s == 'null') ? null : s;
  }

  /// 检测旧版本写入的 "null" 字符串占位污染（如 "noun_type": "null"）
  /// 真实 JSON null 不带引号，不会被误判
  static final RegExp _nullPlaceholderRegExp = RegExp(
    r'"((?:noun_type|verb_type|separable_prefix|base_verb))"\s*:\s*"null"',
  );

  bool _isPollutedCache(String json) {
    return _nullPlaceholderRegExp.hasMatch(json);
  }

  String _extractJson(String response) {
    // 1. 尝试直接解析
    try {
      jsonDecode(response);
      return response;
    } catch (_) {}

    // 2. 移除 markdown 代码块标记
    var cleaned = response.trim();

    // 移除 ```json 和 ```
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();

    // 尝试解析清理后的内容
    try {
      jsonDecode(cleaned);
      return cleaned;
    } catch (_) {}

    // 3. 使用正则表达式提取 JSON 对象
    // 找到第一个 { 和最后一个 }
    final startIndex = cleaned.indexOf('{');
    final endIndex = cleaned.lastIndexOf('}');

    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      final jsonCandidate = cleaned.substring(startIndex, endIndex + 1);
      try {
        jsonDecode(jsonCandidate);
        return jsonCandidate;
      } catch (_) {}
    }

    // 4. 尝试更宽松的正则匹配
    final jsonRegex = RegExp(r'\{[^{}]*\}');
    final matches = jsonRegex.allMatches(cleaned);

    for (final match in matches) {
      final candidate = match.group(0)!;
      try {
        jsonDecode(candidate);
        return candidate;
      } catch (_) {}
    }

    // 5. 尝试修复被截断的 JSON
    if (startIndex != -1) {
      var truncatedJson = cleaned.substring(startIndex);
      final fixedJson = _tryFixTruncatedJson(truncatedJson);
      if (fixedJson != null) {
        debugPrint('Fixed truncated JSON: $fixedJson');
        return fixedJson;
      }
    }

    // 6. 如果都失败，返回原始响应并让调用者处理
    debugPrint('无法提取 JSON，原始响应: $response');
    throw FormatException('无法从 AI 响应中提取 JSON');
  }

  /// 尝试修复被截断的 JSON
  String? _tryFixTruncatedJson(String json) {
    try {
      // 移除末尾可能不完整的部分
      var fixed = json.trim();

      // 跟踪括号和引号的嵌套状态
      int braceCount = 0;
      int bracketCount = 0;
      bool inString = false;
      bool escaped = false;

      for (int i = 0; i < fixed.length; i++) {
        final char = fixed[i];

        if (escaped) {
          escaped = false;
          continue;
        }

        if (char == '\\' && inString) {
          escaped = true;
          continue;
        }

        if (char == '"') {
          inString = !inString;
          continue;
        }

        if (inString) continue;

        if (char == '{') {
          braceCount++;
        } else if (char == '}') {
          braceCount--;
        } else if (char == '[') {
          bracketCount++;
        } else if (char == ']') {
          bracketCount--;
        }
      }

      // 如果在字符串中间被截断，移除不完整的字符串
      if (inString) {
        // 找到最后一个完整的字符串值
        final lastQuote = fixed.lastIndexOf('"');
        if (lastQuote > 0) {
          // 检查这个引号是否是字符串的开始
          final beforeQuote = fixed.substring(0, lastQuote);
          final lastColon = beforeQuote.lastIndexOf(':');
          if (lastColon > 0) {
            // 移除不完整的值，保留到冒号
            fixed = fixed.substring(0, lastColon);
          }
        }
      }

      // 补全缺失的括号
      // 先计算当前状态
      braceCount = 0;
      bracketCount = 0;
      inString = false;
      escaped = false;

      for (int i = 0; i < fixed.length; i++) {
        final char = fixed[i];

        if (escaped) {
          escaped = false;
          continue;
        }

        if (char == '\\' && inString) {
          escaped = true;
          continue;
        }

        if (char == '"') {
          inString = !inString;
          continue;
        }

        if (inString) continue;

        if (char == '{') {
          braceCount++;
        } else if (char == '}') {
          braceCount--;
        } else if (char == '[') {
          bracketCount++;
        } else if (char == ']') {
          bracketCount--;
        }
      }

      // 补全缺失的括号
      for (int i = 0; i < bracketCount; i++) {
        fixed += ']';
      }
      for (int i = 0; i < braceCount; i++) {
        fixed += '}';
      }

      // 验证修复后的 JSON
      jsonDecode(fixed);
      return fixed;
    } catch (_) {
      return null;
    }
  }
}
