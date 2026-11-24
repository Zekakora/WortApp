import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/core/utils/definition_language.dart';

void main() {
  group('detectDefinitionLanguage', () {
    test('中文（含 CJK）', () {
      expect(detectDefinitionLanguage('狗'), DefinitionLanguage.chinese);
      expect(detectDefinitionLanguage('房子；家'), DefinitionLanguage.chinese);
    });

    test('德语（含 ä ö ü ß）', () {
      expect(detectDefinitionLanguage('Häuser'), DefinitionLanguage.german);
      expect(detectDefinitionLanguage('groß und schön'), DefinitionLanguage.german);
    });

    test('英文（拉丁字母、无德语特有字符）', () {
      expect(detectDefinitionLanguage('dog'), DefinitionLanguage.english);
      expect(detectDefinitionLanguage('the house'), DefinitionLanguage.english);
      // 无变音符号的德语词无法与英文区分，按英文处理
      expect(detectDefinitionLanguage('Hund'), DefinitionLanguage.english);
    });

    test('空 / 非文字 → 未知', () {
      expect(detectDefinitionLanguage(''), DefinitionLanguage.unknown);
      expect(detectDefinitionLanguage('   '), DefinitionLanguage.unknown);
      expect(detectDefinitionLanguage('12345'), DefinitionLanguage.unknown);
    });
  });

  group('definitionMatchesLanguage（精确匹配）与 rank', () {
    test('中文界面', () {
      expect(definitionMatchesLanguage('狗', 'zh'), isTrue);
      expect(definitionMatchesLanguage('dog', 'zh'), isFalse);
      expect(definitionLanguageRank('dog', 'zh'), 0);
    });

    test('英文界面', () {
      expect(definitionMatchesLanguage('dog', 'en'), isTrue);
      expect(definitionMatchesLanguage('狗', 'en'), isFalse);
      expect(definitionMatchesLanguage('Häuser', 'en'), isFalse); // 非精确匹配
      expect(definitionLanguageRank('Häuser', 'en'), 1); // 但为次优
    });

    test('德语界面', () {
      expect(definitionMatchesLanguage('Häuser', 'de'), isTrue);
      // 无变音符号的德语被判为英文：非精确匹配，但为次优
      expect(definitionMatchesLanguage('Hund', 'de'), isFalse);
      expect(definitionLanguageRank('Hund', 'de'), 1);
      expect(definitionMatchesLanguage('狗', 'de'), isFalse);
      expect(definitionLanguageRank('狗', 'de'), 0);
    });
  });

  group('pickKeepIndex 保留优先级', () {
    int pick({
      required List<int> ids,
      Set<int> records = const {},
      Map<int, String> defs = const {},
      Map<int, DateTime> times = const {},
      required String lang,
    }) {
      return pickKeepIndex<int>(
        ids,
        hasStudyRecord: (id) => records.contains(id),
        definitionText: (id) => defs[id] ?? '',
        updatedAt: (id) => times[id] ?? DateTime(2000),
        languageCode: lang,
      );
    }

    test('空列表返回 -1', () {
      expect(pick(ids: const [], lang: 'zh'), -1);
    });

    test('① 有学习记录优先（即使释义语言不符且更新更旧）', () {
      final index = pick(
        ids: [1, 2],
        records: {1},
        defs: {1: 'dog', 2: '狗'},
        times: {1: DateTime(2020), 2: DateTime(2026)},
        lang: 'zh',
      );
      expect(index, 0, reason: '有学习记录者优先');
    });

    test('② 无学习记录时，释义语言与界面一致优先', () {
      final index = pick(
        ids: [1, 2],
        defs: {1: 'dog', 2: '狗'},
        // 语言不符的一条更新，仍应让语言一致的胜出
        times: {1: DateTime(2026), 2: DateTime(2020)},
        lang: 'zh',
      );
      expect(index, 1, reason: '中文界面保留中文释义');
    });

    test('③ 学习记录与语言都相同时，更新时间新的优先', () {
      final index = pick(
        ids: [1, 2],
        defs: {1: '狗', 2: '狗'},
        times: {1: DateTime(2020), 2: DateTime(2026)},
        lang: 'zh',
      );
      expect(index, 1);
    });

    test('德语界面：保留德语（含变音符号）释义而非英文', () {
      final index = pick(
        ids: [1, 2],
        defs: {1: 'dog', 2: 'Häuser'},
        times: {1: DateTime(2020), 2: DateTime(2020)},
        lang: 'de',
      );
      expect(index, 1);
    });
  });
}
