/// 答案文本标准化（对应任务书 §5.1）
///
/// 刻意**不复用** `GermanParser.compareSpelling`：后者默认 `tolerant: true`，
/// 会把 `ae→ä`、`ss→ß` 折叠，用于"拼写宽容"的学习模式是对的，
/// 但听写/填空里 `Masse` 与 `Maße` 是两个词，折叠会把错答判对。
/// 这里默认严格，需要宽容时**按题**显式打开 [NormalizeOptions.allowUmlautFolding]。
library;

/// 标准化选项
class NormalizeOptions {
  /// 忽略大小写（名词首字母大写通常仍应计分，故默认 false）
  final bool ignoreCase;

  /// 忽略标点（听写默认忽略标点差异，但会在差异报告里单独列出）
  final bool ignorePunctuation;

  /// 合并多余空格并去掉首尾空白
  final bool collapseWhitespace;

  /// 是否允许 ä→ae / ö→oe / ü→ue / ß→ss 的替代写法
  ///
  /// 默认 **false**：任务书要求德语变音符号属于拼写本身，不得忽略。
  final bool allowUmlautFolding;

  const NormalizeOptions({
    this.ignoreCase = false,
    this.ignorePunctuation = true,
    this.collapseWhitespace = true,
    this.allowUmlautFolding = false,
  });

  /// 听写：忽略标点与空格，但大小写、变音符号严格
  static const dictation = NormalizeOptions(
    ignoreCase: false,
    ignorePunctuation: true,
    allowUmlautFolding: false,
  );

  /// 填空：德语冠词/名词大小写重要，但忽略标点
  static const fillBlank = NormalizeOptions(
    ignoreCase: false,
    ignorePunctuation: true,
    allowUmlautFolding: false,
  );

  NormalizeOptions copyWith({
    bool? ignoreCase,
    bool? ignorePunctuation,
    bool? collapseWhitespace,
    bool? allowUmlautFolding,
  }) =>
      NormalizeOptions(
        ignoreCase: ignoreCase ?? this.ignoreCase,
        ignorePunctuation: ignorePunctuation ?? this.ignorePunctuation,
        collapseWhitespace: collapseWhitespace ?? this.collapseWhitespace,
        allowUmlautFolding: allowUmlautFolding ?? this.allowUmlautFolding,
      );
}

/// 文本标准化器
///
/// 注：Dart 标准库没有 Unicode NFC/NFD 归一化，而项目约定不为此引入新依赖，
/// 因此这里只做等价的实用替换（全角→半角、不间断空格、各种引号/连字符），
/// 足以覆盖"复制粘贴自德语材料"的常见变体。
class AnswerNormalizer {
  AnswerNormalizer._();

  /// 标点（含德语常用标点与引号），标准化时按需剥离
  static final RegExp _punctuation = RegExp(r'''[.,;:!?¡¿"“”„‟'‚‘’«»‹›()\[\]{}—–\-…/\\|*_~`]+''');

  static String normalize(String input, NormalizeOptions options) {
    var text = _unifyCharacters(input);

    if (options.ignorePunctuation) {
      text = text.replaceAll(_punctuation, ' ');
    }
    if (options.collapseWhitespace) {
      text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    if (options.ignoreCase) {
      text = text.toLowerCase();
    }
    if (options.allowUmlautFolding) {
      text = _foldUmlauts(text);
    }
    return text;
  }

  /// 判断用户答案是否命中任一可接受答案
  ///
  /// [accepted] 为空时返回 false（生成阶段已校验，理论上不会出现）。
  static bool matches(
    String userAnswer,
    List<String> accepted, {
    NormalizeOptions options = NormalizeOptions.fillBlank,
  }) {
    final normalizedUser = normalize(userAnswer, options);
    if (normalizedUser.isEmpty) return false;
    for (final candidate in accepted) {
      if (normalize(candidate, options) == normalizedUser) return true;
    }
    return false;
  }

  /// 全角→半角、特殊空格与引号统一（不做大小写与标点处理）
  static String _unifyCharacters(String input) {
    final buffer = StringBuffer();
    for (final rune in input.runes) {
      var code = rune;
      // 全角 ASCII（！ 到 ～）→ 半角
      if (code >= 0xFF01 && code <= 0xFF5E) {
        code -= 0xFEE0;
      }
      // 全角空格
      if (code == 0x3000) code = 0x20;
      buffer.writeCharCode(code);
    }
    return buffer
        .toString()
        // 不间断空格 / 窄空格 / 零宽字符
        .replaceAll('\u00a0', ' ')
        .replaceAll('\u2007', ' ')
        .replaceAll('\u202f', ' ')
        .replaceAll('\u200b', '')
        // 常见引号与连字符变体
        .replaceAll('\u2018', "'")
        .replaceAll('\u2019', "'")
        .replaceAll('\u201a', "'")
        .replaceAll('\u00b4', "'")
        .replaceAll('\u2013', '-')
        .replaceAll('\u2014', '-')
        .replaceAll('\u2212', '-')
        // ä/ö/ü 的组合形式（a + ̈ ）折叠成单字符
        .replaceAll('a\u0308', 'ä')
        .replaceAll('o\u0308', 'ö')
        .replaceAll('u\u0308', 'ü')
        .replaceAll('A\u0308', 'Ä')
        .replaceAll('O\u0308', 'Ö')
        .replaceAll('U\u0308', 'Ü');
  }

  static String _foldUmlauts(String text) => text
      .replaceAll('ä', 'ae')
      .replaceAll('ö', 'oe')
      .replaceAll('ü', 'ue')
      .replaceAll('Ä', 'Ae')
      .replaceAll('Ö', 'Oe')
      .replaceAll('Ü', 'Ue')
      .replaceAll('ß', 'ss');
}

/// 大小写检查结果（名词首字母应大写等）
class CapitalizationCheck {
  final bool isCorrect;
  final String? message;

  const CapitalizationCheck({required this.isCorrect, this.message});
}

/// 检查两个词是否只差大小写（用于在差异报告里区分"拼写错"与"大小写错"）
CapitalizationCheck checkCapitalization(String userWord, String targetWord) {
  if (userWord == targetWord) {
    return const CapitalizationCheck(isCorrect: true);
  }
  if (userWord.toLowerCase() == targetWord.toLowerCase()) {
    return CapitalizationCheck(
      isCorrect: false,
      message: targetWord[0] == targetWord[0].toUpperCase()
          ? '首字母应大写'
          : '首字母应小写',
    );
  }
  return const CapitalizationCheck(isCorrect: false);
}
