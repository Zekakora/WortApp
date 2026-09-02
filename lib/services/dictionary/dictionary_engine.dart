/// 查词结果
class DictionaryResult {
  final String word;
  final String? article;
  final String? plural;
  final List<String> definitions;
  final List<String> examples;
  final String? partOfSpeech;
  final String? aiAnalysis;
  final String engine;
  
  // 动词相关字段
  final String? verbType; // basic, separable, null
  final Map<String, String>? conjugation; // 动词变位
  final String? separablePrefix; // 可分前缀
  final String? baseVerb; // 基础动词
  final List<VerbCollocation>? collocations; // 动词搭配
  
  // 名词相关字段
  final String? nounType; // countable, uncountable, both, null

  /// 是否仅携带释义的纯词典来源（Wiktionary / 德语助手）：
  /// 展示时只显示释义，入库时只添加单词本身（不写入释义/词性/变格等），避免数据干扰
  final bool wordOnly;

  /// 完整变格/变位数据（与 conjugation_cache 存储格式一致）：
  /// - 动词: {"type":"verb","praesens":{6人称},"praeteritum":{6人称},"perfekt":{auxiliary,partizip,6人称},"passiv":{6人称}}
  /// - 名词: {"type":"noun","genitiv":"...","plural":"..."}
  /// - 形容词: {"type":"adjective","komparativ":"...","superlativ":"..."}
  final Map<String, dynamic>? inflection;

  const DictionaryResult({
    required this.word,
    this.article,
    this.plural,
    required this.definitions,
    required this.examples,
    this.partOfSpeech,
    this.aiAnalysis,
    required this.engine,
    this.verbType,
    this.conjugation,
    this.separablePrefix,
    this.baseVerb,
    this.collocations,
    this.nounType,
    this.inflection,
    this.wordOnly = false,
  });

  /// 规范化后的变格数据（补充 type 字段；无变格数据时返回 null）
  Map<String, dynamic>? get normalizedInflection {
    final raw = inflection;
    if (raw == null || raw.isEmpty) return null;
    final map = Map<String, dynamic>.from(raw);
    if (map['type'] is! String) {
      map['type'] = switch (partOfSpeech) {
        'verb' => 'verb',
        'noun' => 'noun',
        'adjective' => 'adjective',
        _ => null,
      };
    }
    return map;
  }
}

/// 动词搭配
class VerbCollocation {
  final String pattern; // 搭配模式
  final String caseType; // dative, accusative
  final String meaning; // 含义

  const VerbCollocation({
    required this.pattern,
    required this.caseType,
    required this.meaning,
  });
}

/// 变格/变位数据工具类（与变格练习 conjugation_cache 格式兼容）
class Inflection {
  /// 6 个人称的标准键（与变位练习一致）
  static const personKeys = ['ich', 'du', 'er_sie_es', 'wir', 'ihr', 'sie_Sie'];

  /// 人称键 → 界面显示标签
  static const personLabels = {
    'ich': 'ich',
    'du': 'du',
    'er_sie_es': 'er/sie/es',
    'wir': 'wir',
    'ihr': 'ihr',
    'sie_Sie': 'sie/Sie',
  };

  /// 从 JSON 中按候选键依次取值（兼容 AI 返回的不同键名）
  static String? pick(Map<String, dynamic>? json, List<String> keys) {
    if (json == null) return null;
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  /// 从时态 JSON 中取某个人称的值（兼容 er_sie_es / er/sie/es / er 等键名）
  static String? personOf(Map<String, dynamic>? tense, String person) {
    if (tense == null) return null;
    final candidates = switch (person) {
      'ich' => const ['ich'],
      'du' => const ['du'],
      'er_sie_es' => const ['er_sie_es', 'er/sie/es', 'er', 'es'],
      'wir' => const ['wir'],
      'ihr' => const ['ihr'],
      'sie_Sie' => const ['sie_Sie', 'sie/Sie', 'sie', 'Sie'],
      _ => const <String>[],
    };
    return pick(tense, candidates);
  }

  /// 提取一个时态的完整 6 人称变位（缺任一人称返回 null）
  static Map<String, String>? personsOf(Map<String, dynamic>? tense) {
    if (tense == null) return null;
    final forms = <String, String>{};
    for (final person in personKeys) {
      final value = personOf(tense, person);
      if (value == null || value.isEmpty) return null;
      forms[person] = value;
    }
    return forms;
  }

  /// 定位动词时态数据所在的层：
  /// 优先顶层（praesens/praeteritum/perfekt/passiv 直接位于 inflection 下），
  /// 兼容旧格式（时态嵌套在“动词时”等中文容器键下）
  static Map<String, dynamic>? _tensesMap(Map<String, dynamic>? inflection) {
    if (inflection == null) return null;
    for (final key in const ['praesens', 'praeteritum', 'perfekt', 'passiv']) {
      if (inflection[key] is Map<String, dynamic>) return inflection;
    }
    for (final key in const ['动词时', '动词变位', 'tenses', 'verb_tenses']) {
      final container = inflection[key];
      if (container is Map<String, dynamic>) return container;
    }
    return null;
  }

  /// 提取动词时态（praesens/praeteritum/perfekt/passiv），被动态为现在时被动态
  static Map<String, Map<String, String>>? verbTenses(
      Map<String, dynamic>? inflection) {
    final map = _tensesMap(inflection);
    if (map == null) return null;
    final result = <String, Map<String, String>>{};
    for (final key in const ['praesens', 'praeteritum', 'perfekt', 'passiv']) {
      final tense = map[key];
      if (tense is Map<String, dynamic>) {
        final persons = personsOf(tense);
        if (persons != null) {
          result[key] = persons;
        }
      }
    }
    return result.isEmpty ? null : result;
  }

  /// 提取完成时辅助动词与过去分词
  static ({String? auxiliary, String? partizip}) perfektParts(
      Map<String, dynamic>? inflection) {
    final map = _tensesMap(inflection);
    if (map == null) return (auxiliary: null, partizip: null);
    final perfekt = map['perfekt'];
    if (perfekt is! Map<String, dynamic>) {
      return (auxiliary: null, partizip: null);
    }
    return (
      auxiliary: pick(perfekt, ['auxiliary', 'hilfsverb']),
      partizip: pick(perfekt, ['partizip', 'partizip_ii', 'partizip2']),
    );
  }

  /// 名词变格：第二格 / 复数（兼容“名词时”容器格式）
  static ({String? genitiv, String? plural}) nounParts(
      Map<String, dynamic>? inflection) {
    if (inflection == null) return (genitiv: null, plural: null);
    var map = inflection;
    if (pick(map, ['genitiv', 'genitive', 'plural', 'pluralform']) == null) {
      for (final key in const ['名词时', '名词变格', 'noun_declension']) {
        final container = map[key];
        if (container is Map<String, dynamic>) {
          map = container;
          break;
        }
      }
    }
    return (
      genitiv: pick(map, ['genitiv', 'genitive']),
      plural: pick(map, ['plural', 'pluralform']),
    );
  }

  /// 形容词变级：比较级 / 最高级（兼容“形容词时”容器格式）
  static ({String? komparativ, String? superlativ}) adjParts(
      Map<String, dynamic>? inflection) {
    if (inflection == null) return (komparativ: null, superlativ: null);
    var map = inflection;
    if (pick(map, ['komparativ', 'comparative', 'superlativ', 'superlative']) ==
        null) {
      for (final key in const ['形容词时', '形容词变级', 'adjective_comparison']) {
        final container = map[key];
        if (container is Map<String, dynamic>) {
          map = container;
          break;
        }
      }
    }
    return (
      komparativ: pick(map, ['komparativ', 'comparative']),
      superlativ: pick(map, ['superlativ', 'superlative']),
    );
  }

  /// 判断变格数据是否有实际内容
  static bool isEmpty(Map<String, dynamic>? inflection) {
    if (inflection == null || inflection.isEmpty) return true;
    final verb = verbTenses(inflection);
    if (verb != null && verb.isNotEmpty) return false;
    final noun = nounParts(inflection);
    if (noun.genitiv != null || noun.plural != null) return false;
    final adj = adjParts(inflection);
    if (adj.komparativ != null || adj.superlativ != null) return false;
    return true;
  }

  /// 从变格数据提取 words 表单值字段（供加入词书 / 批量更新时写库）
  ///
  /// 动词三态取 er/sie/es 人称（与详情页“动词变位”区域语义一致）
  static Map<String, String?> wordsFields(DictionaryResult result) {
    final inf = result.normalizedInflection;
    if (inf == null) return const {};
    final verb = verbTenses(inf);
    final perfekt = perfektParts(inf);
    final noun = nounParts(inf);
    final adj = adjParts(inf);
    return {
      'verbPresent': verb?['praesens']?['er_sie_es'],
      'verbPast': verb?['praeteritum']?['er_sie_es'],
      'verbPerfect': perfekt.partizip ?? verb?['perfekt']?['er_sie_es'],
      'nounGenitive': noun.genitiv,
      'adjComparative': adj.komparativ,
      'adjSuperlative': adj.superlativ,
    };
  }

  /// 生成单词列表中的变格摘要文本（如 "geht · ging · gegangen"、"des Hundes · Hunde"）
  ///
  /// 数据源优先级：变格缓存 JSON → words 表字段
  static String? summary({
    required String? wordType,
    Map<String, dynamic>? inflection,
    String? verbPresent,
    String? verbPast,
    String? verbPerfect,
    String? nounGenitive,
    String? nounPlural,
    String? adjComparative,
    String? adjSuperlative,
  }) {
    switch (wordType) {
      case 'verb':
        final tenses = verbTenses(inflection);
        if (tenses != null) {
          final praesens = tenses['praesens']?['er_sie_es'];
          final praeteritum = tenses['praeteritum']?['er_sie_es'];
          final partizip = perfektParts(inflection).partizip;
          final items = [praesens, praeteritum, partizip]
              .whereType<String>()
              .toList();
          if (items.isNotEmpty) return items.join(' · ');
        }
        final fallback = [verbPresent, verbPast, verbPerfect]
            .whereType<String>()
            .toList();
        return fallback.isEmpty ? null : fallback.join(' · ');
      case 'noun':
        final noun = nounParts(inflection);
        final items = <String>[
          if (noun.genitiv != null) 'Gen. ${noun.genitiv}',
          if (noun.plural != null) 'Pl. ${noun.plural}',
        ];
        if (items.isNotEmpty) return items.join(' · ');
        final fallback = <String>[
          if (nounGenitive != null) 'Gen. $nounGenitive',
          if (nounPlural != null) 'Pl. $nounPlural',
        ];
        return fallback.isEmpty ? null : fallback.join(' · ');
      case 'adjective':
        final adj = adjParts(inflection);
        final items = <String>[
          if (adj.komparativ != null) 'Komparativ ${adj.komparativ}',
          if (adj.superlativ != null) 'Superlativ ${adj.superlativ}',
        ];
        if (items.isNotEmpty) return items.join(' · ');
        final fallback = <String>[
          if (adjComparative != null) 'Komparativ $adjComparative',
          if (adjSuperlative != null) 'Superlativ $adjSuperlative',
        ];
        return fallback.isEmpty ? null : fallback.join(' · ');
      default:
        return null;
    }
  }
}

/// 查词引擎抽象接口
abstract class DictionaryEngine {
  /// 引擎名称
  String get name;

  /// 查词
  ///
  /// [forceRefresh] 为 true 时跳过本地缓存，强制向引擎发起新请求（用于手动更新）。
  Future<DictionaryResult?> lookup(String word, {bool forceRefresh = false});
}
