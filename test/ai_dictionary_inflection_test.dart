import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/services/dictionary/ai_dictionary_engine.dart';
import 'package:wortapp/services/dictionary/dictionary_engine.dart';

void main() {
  group('AI查词解析 inflection（动词完整变位）', () {
    const verbJson = '''
    {
      "word": "gehen",
      "definitions": ["走，去"],
      "examples": ["Ich gehe zur Schule. - 我去学校"],
      "part_of_speech": "verb",
      "inflection": {
        "type": "verb",
        "praesens": {
          "ich": "gehe", "du": "gehst", "er_sie_es": "geht",
          "wir": "gehen", "ihr": "geht", "sie_Sie": "gehen"
        },
        "praeteritum": {
          "ich": "ging", "du": "gingst", "er_sie_es": "ging",
          "wir": "gingen", "ihr": "gingt", "sie_Sie": "gingen"
        },
        "perfekt": {
          "auxiliary": "sein",
          "partizip": "gegangen",
          "ich": "bin gegangen", "du": "bist gegangen", "er_sie_es": "ist gegangen",
          "wir": "sind gegangen", "ihr": "seid gegangen", "sie_Sie": "sind gegangen"
        },
        "passiv": {
          "ich": "werde gegangen", "du": "wirst gegangen", "er_sie_es": "wird gegangen",
          "wir": "werden gegangen", "ihr": "werdet gegangen", "sie_Sie": "werden gegangen"
        }
      }
    }
    ''';

    test('解析出完整 6 人称三时态与被动态', () {
      final result = AIDictionaryEngine.parseResult('gehen', verbJson);
      expect(result.inflection, isNotNull);
      expect(result.normalizedInflection!['type'], 'verb');

      final tenses = Inflection.verbTenses(result.inflection);
      expect(tenses, isNotNull);
      expect(tenses!.keys, containsAll(['praesens', 'praeteritum', 'perfekt', 'passiv']));
      expect(tenses['praesens']!['er_sie_es'], 'geht');
      expect(tenses['praeteritum']!['er_sie_es'], 'ging');
      expect(tenses['perfekt']!['sie_Sie'], 'sind gegangen');
      expect(tenses['passiv']!['er_sie_es'], 'wird gegangen');
      expect(tenses['passiv']!['sie_Sie'], 'werden gegangen');

      final perfekt = Inflection.perfektParts(result.inflection);
      expect(perfekt.auxiliary, 'sein');
      expect(perfekt.partizip, 'gegangen');
    });

    test('提取 words 表动词三态字段', () {
      final result = AIDictionaryEngine.parseResult('gehen', verbJson);
      final fields = Inflection.wordsFields(result);
      expect(fields['verbPresent'], 'geht');
      expect(fields['verbPast'], 'ging');
      expect(fields['verbPerfect'], 'gegangen');
      expect(fields['nounGenitive'], isNull);
    });

    test('动词摘要：现在时/过去时/过去分词', () {
      final result = AIDictionaryEngine.parseResult('gehen', verbJson);
      final summary = Inflection.summary(
        wordType: 'verb',
        inflection: result.inflection,
      );
      expect(summary, 'geht · ging · gegangen');
    });
  });

  group('AI查词解析 inflection（名词/形容词）', () {
    test('名词：第二格与复数', () {
      const json = '''
      {
        "word": "Haus",
        "definitions": ["房子"],
        "part_of_speech": "noun",
        "article": "das",
        "plural": "Häuser",
        "inflection": {"type": "noun", "genitiv": "Hauses", "plural": "Häuser"}
      }
      ''';
      final result = AIDictionaryEngine.parseResult('Haus', json);
      final noun = Inflection.nounParts(result.inflection);
      expect(noun.genitiv, 'Hauses');
      expect(noun.plural, 'Häuser');
      expect(Inflection.isEmpty(result.inflection), isFalse);

      final fields = Inflection.wordsFields(result);
      expect(fields['nounGenitive'], 'Hauses');

      final summary = Inflection.summary(
        wordType: 'noun',
        inflection: result.inflection,
      );
      expect(summary, 'Gen. Hauses · Pl. Häuser');
    });

    test('形容词：比较级与最高级', () {
      const json = '''
      {
        "word": "groß",
        "definitions": ["大的"],
        "part_of_speech": "adjective",
        "inflection": {"type": "adjective", "komparativ": "größer", "superlativ": "am größten"}
      }
      ''';
      final result = AIDictionaryEngine.parseResult('groß', json);
      final adj = Inflection.adjParts(result.inflection);
      expect(adj.komparativ, 'größer');
      expect(adj.superlativ, 'am größten');

      final fields = Inflection.wordsFields(result);
      expect(fields['adjComparative'], 'größer');
      expect(fields['adjSuperlative'], 'am größten');

      final summary = Inflection.summary(
        wordType: 'adjective',
        inflection: result.inflection,
      );
      expect(summary, 'Komparativ größer · Superlativ am größten');
    });
  });

  group('inflection 兼容与容错', () {
    test('缺少 inflection 字段时返回 null', () {
      const json = '{"word": "laufen", "definitions": ["跑"], "part_of_speech": "verb"}';
      final result = AIDictionaryEngine.parseResult('laufen', json);
      expect(result.inflection, isNull);
      expect(Inflection.isEmpty(result.inflection), isTrue);
      expect(Inflection.wordsFields(result), isEmpty);
    });

    test('type 缺失时按词性自动补全', () {
      const json = '''
      {
        "word": "machen",
        "definitions": ["做"],
        "part_of_speech": "verb",
        "inflection": {"praesens": {"ich": "mache", "du": "machst", "er_sie_es": "macht", "wir": "machen", "ihr": "macht", "sie_Sie": "machen"}}
      }
      ''';
      final result = AIDictionaryEngine.parseResult('machen', json);
      expect(result.normalizedInflection!['type'], 'verb');
    });

    test('兼容 er/sie/es 与 er 等变体键名', () {
      const json = '''
      {
        "word": "sprechen",
        "definitions": ["说"],
        "part_of_speech": "verb",
        "inflection": {"praesens": {"ich": "spreche", "du": "sprichst", "er": "spricht", "wir": "sprechen", "ihr": "sprecht", "sie": "sprechen"}}
      }
      ''';
      final result = AIDictionaryEngine.parseResult('sprechen', json);
      final tenses = Inflection.verbTenses(result.inflection);
      expect(tenses!['praesens']!['er_sie_es'], 'spricht');
      expect(tenses['praesens']!['sie_Sie'], 'sprechen');
    });

    test('空字符串人称被清理，不完整时态不参与展示', () {
      const json = '''
      {
        "word": "testen",
        "definitions": ["测试"],
        "part_of_speech": "verb",
        "inflection": {
          "praesens": {"ich": "teste", "du": "testest", "er_sie_es": "testet", "wir": "testen", "ihr": "testet", "sie_Sie": "testen"},
          "praeteritum": {"ich": "", "du": ""}
        }
      }
      ''';
      final result = AIDictionaryEngine.parseResult('testen', json);
      final tenses = Inflection.verbTenses(result.inflection);
      // praeteritum 不完整被排除，仅保留 praesens
      expect(tenses!.keys, ['praesens']);
    });

    test('摘要回退 words 表字段', () {
      final summary = Inflection.summary(
        wordType: 'noun',
        nounGenitive: 'Hundes',
        nounPlural: 'Hunde',
      );
      expect(summary, 'Gen. Hundes · Pl. Hunde');

      final verbSummary = Inflection.summary(
        wordType: 'verb',
        verbPresent: 'geht',
        verbPast: 'ging',
        verbPerfect: 'gegangen',
      );
      expect(verbSummary, 'geht · ging · gegangen');

      final empty = Inflection.summary(wordType: 'adverb');
      expect(empty, isNull);
    });
  });

group('兼容旧格式（中文容器键“动词时/名词时/形容词时”）', () {
    test('动词时态嵌套在“动词时”容器中也能解析（用户实测场景）', () {
      const json = '''
      {
        "word": "lieben",
        "definitions": ["爱，热爱"],
        "part_of_speech": "verb",
        "inflection": {
          "type": "verb",
          "动词时": {
            "praesens": {"ich":"liebe","du":"liebst","er_sie_es":"liebt","wir":"lieben","ihr":"liebt","sie_Sie":"lieben"},
            "praeteritum": {"ich":"liebte","du":"liebtest","er_sie_es":"liebte","wir":"liebten","ihr":"liebtet","sie_Sie":"liebten"},
            "perfekt": {"auxiliary":"haben","partizip":"geliebt","ich":"habe geliebt","du":"hast geliebt","er_sie_es":"hat geliebt","wir":"haben geliebt","ihr":"habt geliebt","sie_Sie":"haben geliebt"}
          }
        }
      }
      ''';
      final result = AIDictionaryEngine.parseResult('lieben', json);
      // 容器已展平到顶层，存储格式统一
      expect(result.inflection!['动词时'], isNull);
      expect(result.inflection!['praesens'], isNotNull);

      final tenses = Inflection.verbTenses(result.inflection);
      expect(tenses, isNotNull);
      expect(tenses!.keys, containsAll(['praesens', 'praeteritum', 'perfekt']));
      expect(tenses['praesens']!['er_sie_es'], 'liebt');
      expect(tenses['praeteritum']!['er_sie_es'], 'liebte');

      final perfekt = Inflection.perfektParts(result.inflection);
      expect(perfekt.auxiliary, 'haben');
      expect(perfekt.partizip, 'geliebt');

      // isEmpty 必须为 false，才能写入 conjugation_cache
      expect(Inflection.isEmpty(result.inflection), isFalse);

      final fields = Inflection.wordsFields(result);
      expect(fields['verbPresent'], 'liebt');
      expect(fields['verbPast'], 'liebte');
      expect(fields['verbPerfect'], 'geliebt');

      final summary = Inflection.summary(
        wordType: 'verb',
        inflection: result.inflection,
      );
      expect(summary, 'liebt · liebte · geliebt');
    });

    test('工具类直接兼容未展平的“动词时”容器（旧缓存数据）', () {
      const inflection = {
        'type': 'verb',
        '动词时': {
          'praesens': {'ich': 'gehe', 'du': 'gehst', 'er_sie_es': 'geht', 'wir': 'gehen', 'ihr': 'geht', 'sie_Sie': 'gehen'},
          'praeteritum': {'ich': 'ging', 'du': 'gingst', 'er_sie_es': 'ging', 'wir': 'gingen', 'ihr': 'gingt', 'sie_Sie': 'gingen'},
          'perfekt': {'auxiliary': 'sein', 'partizip': 'gegangen', 'ich': 'bin gegangen', 'du': 'bist gegangen', 'er_sie_es': 'ist gegangen', 'wir': 'sind gegangen', 'ihr': 'seid gegangen', 'sie_Sie': 'sind gegangen'},
        },
      };
      final tenses = Inflection.verbTenses(inflection);
      expect(tenses!['praesens']!['er_sie_es'], 'geht');
      expect(tenses['praeteritum']!['er_sie_es'], 'ging');
      expect(Inflection.perfektParts(inflection).partizip, 'gegangen');
      expect(Inflection.isEmpty(inflection), isFalse);
    });

    test('“名词时”容器与“形容词时”容器兼容', () {
      const nounInflection = {
        'type': 'noun',
        '名词时': {'genitiv': 'Hauses', 'plural': 'Häuser'},
      };
      final noun = Inflection.nounParts(nounInflection);
      expect(noun.genitiv, 'Hauses');
      expect(noun.plural, 'Häuser');
      expect(Inflection.isEmpty(nounInflection), isFalse);

      const adjInflection = {
        'type': 'adjective',
        '形容词时': {'komparativ': 'größer', 'superlativ': 'am größten'},
      };
      final adj = Inflection.adjParts(adjInflection);
      expect(adj.komparativ, 'größer');
      expect(adj.superlativ, 'am größten');
      expect(Inflection.isEmpty(adjInflection), isFalse);
    });
  });
}
