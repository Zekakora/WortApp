import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../data/database/app_database.dart';
import 'ai_service.dart';

/// 变位服务
///
/// 使用 AI 生成德语单词的变位数据
class ConjugationService {
  final AIService _aiService;
  final AppDatabase _db;

  ConjugationService({
    required AIService aiService,
    required AppDatabase db,
  })  : _aiService = aiService,
        _db = db;

  /// 获取单词的变位数据（优先从缓存读取）
  Future<Map<String, dynamic>?> getConjugation(int wordId) async {
    // 先查缓存
    final cached = await _db.conjugationDao.getByWordId(wordId);
    if (cached != null) {
      return jsonDecode(cached.conjugationJson) as Map<String, dynamic>;
    }

    // 缓存未命中，调用 AI 生成
    final word = await _db.wordDao.getWordById(wordId);
    if (word == null) return null;

    return await _generateAndCache(word);
  }

  /// 批量生成变位数据
  Future<void> generateBatch(List<int> wordIds, {int concurrency = 1}) async {
    await regenerateBatch(wordIds, concurrency: concurrency);
  }

  /// 强制重新生成单个单词的变位数据（先删除旧缓存，覆盖更新）
  Future<void> regenerateWord(int wordId) async {
    await _db.conjugationDao.deleteByWordId(wordId);
    await getConjugation(wordId);
  }

  /// 批量强制重新生成变位数据（支持并发）
  ///
  /// 按 [concurrency] 同时启动多个 worker，每个 worker 依次领取待处理单词；
  /// 串行（1）时保留请求间延迟避免 API 限流（与批量查词行为一致）。
  /// [onProgress] 在每处理完一个单词后回调（completed/failed 为累计值）；
  /// [isCancelled] 返回 true 时 worker 停止领取新任务（进行中的请求会完成）。
  Future<({int success, int failed})> regenerateBatch(
    List<int> wordIds, {
    int concurrency = 1,
    void Function(int completed, int failed, String currentWord)? onProgress,
    bool Function()? isCancelled,
  }) async {
    final total = wordIds.length;
    if (total == 0) return (success: 0, failed: 0);

    var completed = 0;
    var failed = 0;
    var nextIndex = 0;

    Future<void> processOne(int wordId) async {
      final word = await _db.wordDao.getWordById(wordId);
      final label = word?.german ?? '#$wordId';
      try {
        await regenerateWord(wordId);
        completed++;
      } catch (e) {
        debugPrint('更新变位数据失败 ($label): $e');
        failed++;
      }
      onProgress?.call(completed, failed, label);
      // 串行模式添加延迟避免 API 限流（并发模式由并发数控制请求压力）
      if (concurrency <= 1) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    // 并发 worker 池：每个 worker 领取下一个未处理的单词，直到全部完成
    final workerCount = concurrency.clamp(1, 500);
    final workers = List.generate(workerCount, (_) async {
      while (true) {
        if (isCancelled?.call() ?? false) break;
        final index = nextIndex++;
        if (index >= total) break;
        await processOne(wordIds[index]);
      }
    });
    await Future.wait(workers);
    return (success: completed, failed: failed);
  }

  /// 删除指定单词的变位缓存
  Future<int> deleteConjugationData(List<int> wordIds) {
    return _db.conjugationDao.deleteByWordIds(wordIds);
  }

  /// 为词书中的所有单词生成变位数据
  ///
  /// 仅生成尚无缓存的单词；[onProgress] 在每处理完一个单词后回调
  /// （completed/failed 为累计值，currentWord 为当前单词）。
  Future<void> generateForDeck(
    int deckId, {
    int concurrency = 1,
    void Function(int completed, int failed, String currentWord)? onProgress,
  }) async {
    final words = await _db.wordDao.getWordsByDeck(deckId);
    final cachedIds = await _db.conjugationDao.getCachedWordIds();

    // 过滤掉已有缓存的
    final uncached = words
        .where((w) => !cachedIds.contains(w.id))
        .toList();

    await regenerateBatch(
      uncached.map((w) => w.id).toList(),
      concurrency: concurrency,
      onProgress: onProgress,
    );
  }

  /// 调用 AI 生成变位并缓存
  Future<Map<String, dynamic>> _generateAndCache(Word word) async {
    final systemPrompt = '''你是一个德语语法专家。请根据用户提供的德语单词，生成完整的变位/变形数据。

返回格式必须是纯 JSON，不要包含任何其他文字，不要使用 markdown 代码块。输出保持紧凑，不要添加注释或额外说明。

动词格式（四个时态都必须输出，每个时态包含全部 6 个人称，passiv 为现在时被动态即 werden + 过去分词）：
{
  "type": "verb",
  "praesens": {
    "ich": "...", "du": "...", "er_sie_es": "...",
    "wir": "...", "ihr": "...", "sie_Sie": "..."
  },
  "praeteritum": {
    "ich": "...", "du": "...", "er_sie_es": "...",
    "wir": "...", "ihr": "...", "sie_Sie": "..."
  },
  "perfekt": {
    "auxiliary": "haben/sein",
    "partizip": "...",
    "ich": "...", "du": "...", "er_sie_es": "...",
    "wir": "...", "ihr": "...", "sie_Sie": "..."
  },
  "passiv": {
    "ich": "...", "du": "...", "er_sie_es": "...",
    "wir": "...", "ihr": "...", "sie_Sie": "..."
  }
}

名词格式：
{
  "type": "noun",
  "article": "der/die/das",
  "genitiv": "...",
  "plural": "..."
}

形容词格式：
{
  "type": "adjective",
  "komparativ": "...",
  "superlativ": "..."
}''';

    final wordInfo = word.article != null
        ? '${word.article} ${word.german}'
        : word.german;

    final response = await _aiService.chat(
      systemPrompt: systemPrompt,
      userMessage: '请为以下德语单词生成变位数据: $wordInfo',
      temperature: 0.3,
      maxTokens: 8192,
    );

    // 解析 JSON
    final jsonStr = _extractJson(response);
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;

    // 缓存到数据库
    await _db.conjugationDao.upsert(
      word.id,
      jsonEncode(data),
      source: 'ai',
    );

    return data;
  }

  /// 从 AI 响应中提取 JSON
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

    // 5. 尝试修复被截断的 JSON（token 不足导致响应中断）
    if (startIndex != -1) {
      final truncatedJson = cleaned.substring(startIndex);
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

  /// 尝试修复被截断的 JSON（补齐缺失括号、移除不完整字符串值）
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
