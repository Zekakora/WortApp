/// 释义文本的语言判定（尽力而为的启发式）。
///
/// 应用新增多语言支持后，单词的释义（`words.chinese` 字段）可能为中文、
/// 英文或德文（由 AI 按当时界面语言生成）。去重时用于"优先保留与当前
/// 界面语言一致的释义"这一策略。
library;

/// 释义语言
enum DefinitionLanguage {
  chinese,
  german,
  english,

  /// 空文本 / 无法判断（如纯数字、符号）
  unknown,
}

final RegExp _cjk = RegExp(r'[\u4E00-\u9FFF\u3400-\u4DBF]');
final RegExp _latin = RegExp(r'[a-zA-Z]');
/// 德语特有字符（含变音与 ß）
final RegExp _germanSpecific = RegExp(r'[äöüÄÖÜß]');

/// 判断释义文本的语言。
///
/// 规则（按优先级）：
/// - 含 CJK 字符 → 中文
/// - 含德语特有字符（ä ö ü ß）→ 德语
/// - 含拉丁字母 → 英文（无法与无变音符号的德语区分时按英文处理）
/// - 其它 → 未知
DefinitionLanguage detectDefinitionLanguage(String text) {
  final t = text.trim();
  if (t.isEmpty) return DefinitionLanguage.unknown;
  if (_cjk.hasMatch(t)) return DefinitionLanguage.chinese;
  if (!_latin.hasMatch(t)) return DefinitionLanguage.unknown;
  if (_germanSpecific.hasMatch(t)) return DefinitionLanguage.german;
  return DefinitionLanguage.english;
}

/// 释义文本与界面语言 [languageCode]（'zh' / 'en' / 'de'）的契合度：
/// - 2 = 最佳匹配（语言一致）
/// - 1 = 可接受的次优（同为非中文拉丁文本：德语界面接受英文、英文界面接受德语）
/// - 0 = 不符（如中文界面下的非中文释义，或非中文界面下的中文释义）
int definitionLanguageRank(String text, String languageCode) {
  final lang = detectDefinitionLanguage(text);
  switch (languageCode) {
    case 'zh':
      return lang == DefinitionLanguage.chinese ? 2 : 0;
    case 'en':
      switch (lang) {
        case DefinitionLanguage.english:
          return 2;
        case DefinitionLanguage.german:
          return 1;
        default:
          return 0;
      }
    case 'de':
      switch (lang) {
        case DefinitionLanguage.german:
          return 2;
        case DefinitionLanguage.english:
          return 1;
        default:
          return 0;
      }
    default:
      return 0;
  }
}

/// 释义文本的语言是否与界面语言 [languageCode] 一致（即 [definitionLanguageRank] 为 2）。
bool definitionMatchesLanguage(String text, String languageCode) =>
    definitionLanguageRank(text, languageCode) == 2;

/// 去重时从一组重复记录中选出"应保留"元素的下标。
///
/// 优先级（高 → 低）：
/// 1. 有学习记录（[hasStudyRecord]）
/// 2. 释义语言与界面语言 [languageCode] 一致（基于 [definitionText] 启发式判定）
/// 3. 更新时间更新（[updatedAt]）
///
/// 返回下标；[items] 为空时返回 -1。
int pickKeepIndex<T>(
  List<T> items, {
  required bool Function(T item) hasStudyRecord,
  required String Function(T item) definitionText,
  required DateTime Function(T item) updatedAt,
  required String languageCode,
}) {
  if (items.isEmpty) return -1;
  var best = 0;
  for (var i = 1; i < items.length; i++) {
    if (_compareForKeep(
          items[i],
          items[best],
          hasStudyRecord,
          definitionText,
          updatedAt,
          languageCode,
        ) >
        0) {
      best = i;
    }
  }
  return best;
}

int _compareForKeep<T>(
  T a,
  T b,
  bool Function(T item) hasStudyRecord,
  String Function(T item) definitionText,
  DateTime Function(T item) updatedAt,
  String languageCode,
) {
  // 1. 有学习记录优先
  final aHasRecord = hasStudyRecord(a) ? 1 : 0;
  final bHasRecord = hasStudyRecord(b) ? 1 : 0;
  if (aHasRecord != bHasRecord) return aHasRecord - bHasRecord;

  // 2. 释义语言与界面语言一致优先
  final aLang = definitionLanguageRank(definitionText(a), languageCode);
  final bLang = definitionLanguageRank(definitionText(b), languageCode);
  if (aLang != bLang) return aLang - bLang;

  // 3. 更新时间更新优先
  return updatedAt(a).compareTo(updatedAt(b));
}
