import '../i18n/app_localizations.dart';

/// 德语词形解析工具
///
/// 自动识别德语单词中的冠词、词性、动词三态等信息
class GermanParser {
  GermanParser._();

  // 常见冠词
  static final RegExp _articleRegex =
      RegExp(r'^(der|die|das)\s+', caseSensitive: false);

  // 复数后缀模式（逗号后的复数形式，如 -n, -en, ße, ¨e, -）
  static final RegExp _pluralSuffixRegex =
      RegExp(r',\s*[-−]?\s*[A-Za-zÄÖÜäöüß]*$', caseSensitive: false);

  // 常见动词后缀
  static final List<String> _verbSuffixes = [
    'ieren', 'eln', 'ern', 'en', 'n'
  ];

  // 常见形容词后缀
  static final List<String> _adjSuffixes = [
    'lich', 'isch', 'bar', 'sam', 'haft', 'ig', 'los', 'voll'
  ];

  /// 解析德语单词，提取冠词和词性
  ///
  /// 支持多种格式：
  /// - `die Sache` → article=die, base=Sache
  /// - `die Sache, -n` → article=die, base=Sache
  /// - `der Zustand, ße` → article=der, base=Zustand
  /// - `Sache` → article=null, base=Sache
  static ParsedWord parse(String input) {
    final trimmed = input.trim();
    String? article;
    String baseWord = trimmed;

    // 提取冠词
    final articleMatch = _articleRegex.firstMatch(trimmed);
    if (articleMatch != null) {
      article = articleMatch.group(1)!.toLowerCase();
      baseWord = trimmed.substring(articleMatch.end).trim();
    }

    // 移除复数后缀（如 , -n , ße , -en 等）
    baseWord = baseWord.replaceAll(_pluralSuffixRegex, '').trim();

    // 判断词性
    final wordType = _detectWordType(baseWord, article);

    return ParsedWord(
      original: trimmed,
      article: article,
      baseWord: baseWord,
      wordType: wordType,
    );
  }

  /// 检测词性
  static WordType _detectWordType(String word, String? article) {
    // 有冠词的通常是名词
    if (article != null) {
      return WordType.noun;
    }

    // 检查动词后缀
    for (final suffix in _verbSuffixes) {
      if (word.endsWith(suffix)) {
        return WordType.verb;
      }
    }

    // 检查形容词后缀
    for (final suffix in _adjSuffixes) {
      if (word.endsWith(suffix)) {
        return WordType.adjective;
      }
    }

    return WordType.other;
  }

  /// 从 "der Tisch" 格式中提取冠词
  static String? extractArticle(String input) {
    final match = _articleRegex.firstMatch(input.trim());
    return match?.group(1)?.toLowerCase();
  }

  /// 从 "der Tisch" 格式中提取单词（不含冠词）
  static String extractBaseWord(String input) {
    final match = _articleRegex.firstMatch(input.trim());
    if (match != null) {
      return input.trim().substring(match.end).trim();
    }
    return input.trim();
  }

  /// 规范化去重 key（用于防止单词重复）
  ///
  /// - 剥离冠词与复数后缀，仅保留词干（如 `der Hund` → `Hund`）
  /// - **保留原始大小写**：德语首字母大小写具有语义（名词大写、动词/形容词
  ///   小写，如 `Lernen` 与 `lernen` 是两个不同的词），不能统一转小写
  static String canonicalKey(String input) => parse(input).baseWord.trim();

  /// 判断是否为名词（首字母大写）
  static bool isNoun(String word) {
    if (word.isEmpty) return false;
    return word[0] == word[0].toUpperCase() &&
        word[0] != word[0].toLowerCase();
  }

  /// 判断是否为动词（以 -en, -n, -ieren 结尾）
  static bool isVerb(String word) {
    return _verbSuffixes.any((suffix) => word.endsWith(suffix));
  }

  /// 宽容拼写检查（ae→ä, oe→ö, ue→ü, ss→ß）
  static String normalizeSpelling(String input) {
    return input
        .replaceAll('ae', 'ä')
        .replaceAll('oe', 'ö')
        .replaceAll('ue', 'ü')
        .replaceAll('Ae', 'Ä')
        .replaceAll('Oe', 'Ö')
        .replaceAll('Ue', 'Ü')
        .replaceAll('ss', 'ß');
  }

  /// 拼写比较（支持宽容模式）
  static bool compareSpelling(String input, String target, {bool tolerant = true}) {
    if (!tolerant) {
      return input.trim().toLowerCase() == target.trim().toLowerCase();
    }

    final normalizedInput = normalizeSpelling(input.trim().toLowerCase());
    final normalizedTarget = normalizeSpelling(target.trim().toLowerCase());

    return normalizedInput == normalizedTarget;
  }

  /// 检查首字母大小写（名词首字母应大写）
  static CapitalizationResult checkCapitalization(String input, String target) {
    if (input.isEmpty || target.isEmpty) {
      return CapitalizationResult(correct: true, needsCapitalize: false);
    }

    final inputFirst = input[0];
    final targetFirst = target[0];

    if (inputFirst == targetFirst) {
      return CapitalizationResult(correct: true, needsCapitalize: false);
    }

    // 检查是否只是大小写不同
    if (inputFirst.toLowerCase() == targetFirst.toLowerCase()) {
      return CapitalizationResult(
        correct: false,
        needsCapitalize: targetFirst == targetFirst.toUpperCase(),
        message: targetFirst == targetFirst.toUpperCase()
            ? AppLocale.tr('名词首字母需要大写')
            : AppLocale.tr('首字母应小写'),
      );
    }

    return CapitalizationResult(correct: false, needsCapitalize: false);
  }
}

/// 解析后的单词信息
class ParsedWord {
  final String original;
  final String? article;
  final String baseWord;
  final WordType wordType;

  const ParsedWord({
    required this.original,
    this.article,
    required this.baseWord,
    required this.wordType,
  });

  @override
  String toString() =>
      'ParsedWord(original=$original, article=$article, base=$baseWord, type=$wordType)';
}

/// 词性枚举
enum WordType {
  noun, // 名词
  verb, // 动词
  adjective, // 形容词
  adverb, // 副词
  preposition, // 介词
  pronoun, // 代词
  conjunction, // 连词
  other, // 其他（不可分类）
}

/// 大小写检查结果
class CapitalizationResult {
  final bool correct;
  final bool needsCapitalize;
  final String? message;

  const CapitalizationResult({
    required this.correct,
    required this.needsCapitalize,
    this.message,
  });
}
