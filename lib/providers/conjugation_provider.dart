import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/i18n/app_localizations.dart';
import '../data/database/app_database.dart';
import '../services/ai/ai_service.dart';
import '../services/ai/conjugation_service.dart';
import 'database_provider.dart';
import 'settings_provider.dart';

/// AI 服务 Provider
final aiServiceProvider = Provider<AIService?>((ref) {
  final settings = ref.watch(settingsProvider);
  final aiConfig = settings.aiConfig;

  if (!aiConfig.isConfigured) return null;

  return ConfigurableAIService(
    apiKey: aiConfig.apiKey,
    baseUrl: aiConfig.baseUrl,
    model: aiConfig.model,
  );
});

/// 变位服务 Provider
final conjugationServiceProvider = Provider<ConjugationService?>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  final db = ref.watch(databaseProvider);

  if (aiService == null || db == null) return null;

  return ConjugationService(aiService: aiService, db: db);
});

/// 练习大类
enum PracticeCategory { verb, noun, adjective }

/// 变位练习抓词范围
///
/// - [random]：随机练习——从整个词书随机抽取
/// - [todayOnly]：只练今日单词——仅从今天学习过的单词中抽取
enum ConjugationPickMode { random, todayOnly }

/// 二级练习模式（如：动词变位-现在时、名词变格-第二格单数…）
class PracticeMode {
  final String id;
  final PracticeCategory category;
  final String title; // 中文名：现在时
  final String subtitle; // 德语名：Präsens
  final IconData icon;
  final String requiredWordType; // 匹配的 word_type
  final bool isVerbTense; // 是否动词时态（6 人称完整变位）

  const PracticeMode({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.requiredWordType,
    this.isVerbTense = false,
  });

  // ── 动词变位 ──────────────────────────────
  static final verbPraesens = PracticeMode(
    id: 'verb_praesens',
    category: PracticeCategory.verb,
    title: AppLocale.tr('现在时'),
    subtitle: 'Präsens',
    icon: Icons.schedule,
    requiredWordType: 'verb',
    isVerbTense: true,
  );
  static final verbPraeteritum = PracticeMode(
    id: 'verb_praeteritum',
    category: PracticeCategory.verb,
    title: AppLocale.tr('过去时'),
    subtitle: 'Präteritum',
    icon: Icons.history,
    requiredWordType: 'verb',
    isVerbTense: true,
  );
  static final verbPerfekt = PracticeMode(
    id: 'verb_perfekt',
    category: PracticeCategory.verb,
    title: AppLocale.tr('现在完成时'),
    subtitle: 'Perfekt',
    icon: Icons.done_all,
    requiredWordType: 'verb',
    isVerbTense: true,
  );
  static final verbPassiv = PracticeMode(
    id: 'verb_passiv',
    category: PracticeCategory.verb,
    title: AppLocale.tr('被动语态'),
    subtitle: 'Passiv',
    icon: Icons.visibility,
    requiredWordType: 'verb',
    isVerbTense: true,
  );

  // ── 名词变格 ──────────────────────────────
  static final nounArticle = PracticeMode(
    id: 'noun_article',
    category: PracticeCategory.noun,
    title: AppLocale.tr('定冠词/性属'),
    subtitle: 'Artikel',
    icon: Icons.tag,
    requiredWordType: 'noun',
  );
  static final nounGenitiv = PracticeMode(
    id: 'noun_genitiv',
    category: PracticeCategory.noun,
    title: AppLocale.tr('第二格单数'),
    subtitle: 'Genitiv Singular',
    icon: Icons.format_list_numbered,
    requiredWordType: 'noun',
  );
  static final nounPlural = PracticeMode(
    id: 'noun_plural',
    category: PracticeCategory.noun,
    title: AppLocale.tr('复数形式'),
    subtitle: 'Plural',
    icon: Icons.group,
    requiredWordType: 'noun',
  );

  // ── 形容词变级 ────────────────────────────
  /// 变级练习：无二级子项，一个页面同时填写比较级与最高级
  static final adjSteigerung = PracticeMode(
    id: 'adj_steigerung',
    category: PracticeCategory.adjective,
    title: AppLocale.tr('变级练习'),
    subtitle: 'Komparativ & Superlativ',
    icon: Icons.trending_up,
    requiredWordType: 'adjective',
  );

  static final allVerbModes = [verbPraesens, verbPraeteritum, verbPerfekt, verbPassiv];
  static final allNounModes = [nounArticle, nounGenitiv, nounPlural];
  static final allAdjModes = [adjSteigerung];
  static final allModes = [...allVerbModes, ...allNounModes, ...allAdjModes];

  static PracticeMode? fromId(String id) {
    for (final mode in allModes) {
      if (mode.id == id) return mode;
    }
    return null;
  }
}

/// 一个待填写的格子（一个人称或一个格）
class PracticeField {
  final String label; // 显示标签：ich / er/sie/es / 冠词 / 复数形式…
  final String correctAnswer; // 标准答案

  const PracticeField({required this.label, required this.correctAnswer});
}

/// 单个格子的校验结果
class FieldCheckResult {
  final String label;
  final String userAnswer;
  final String correctAnswer;
  final bool isCorrect;
  final bool isBlank;

  const FieldCheckResult({
    required this.label,
    required this.userAnswer,
    required this.correctAnswer,
    required this.isCorrect,
    required this.isBlank,
  });
}

/// 变位题目（一个单词）
class ConjugationQuestion {
  final int wordId;
  final String word;
  final String? article;
  final String? meaning;
  final PracticeMode mode;
  final String prompt;
  final List<PracticeField> fields;

  const ConjugationQuestion({
    required this.wordId,
    required this.word,
    this.article,
    this.meaning,
    required this.mode,
    required this.prompt,
    required this.fields,
  });
}

/// 变位练习状态
class ConjugationDrillState {
  final PracticeMode? mode;
  final List<ConjugationQuestion> questions;
  final int currentIndex;
  final int answeredCount; // 已提交的题数
  final int correctCount; // 全部正确的题数
  final bool isCompleted;

  const ConjugationDrillState({
    this.mode,
    this.questions = const [],
    this.currentIndex = 0,
    this.answeredCount = 0,
    this.correctCount = 0,
    this.isCompleted = false,
  });

  ConjugationQuestion? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  double get progress => questions.isEmpty ? 0 : answeredCount / questions.length;

  double get accuracy =>
      answeredCount == 0 ? 0 : correctCount / answeredCount;

  ConjugationDrillState copyWith({
    PracticeMode? mode,
    List<ConjugationQuestion>? questions,
    int? currentIndex,
    int? answeredCount,
    int? correctCount,
    bool? isCompleted,
  }) {
    return ConjugationDrillState(
      mode: mode ?? this.mode,
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      answeredCount: answeredCount ?? this.answeredCount,
      correctCount: correctCount ?? this.correctCount,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// 变位练习 StateNotifier
class ConjugationDrillNotifier extends StateNotifier<ConjugationDrillState> {
  final AppDatabase? _db;

  ConjugationDrillNotifier(this._db)
      : super(const ConjugationDrillState());

  /// 6 个人称的标准键
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

  /// 加载练习：按 [pickMode] 决定单词来源，抽取 limit 个符合条件的单词组成练习队列
  ///
  /// - [ConjugationPickMode.random]：从整个词书随机抽取
  /// - [ConjugationPickMode.todayOnly]：仅从今日学习过的单词中抽取
  ///   （与学习模式口径一致：lastStudyDate 为今天）
  Future<void> loadDrill({
    required int deckId,
    required PracticeMode mode,
    required int limit,
    ConjugationPickMode pickMode = ConjugationPickMode.random,
  }) async {
    if (_db == null) return;

    final words = pickMode == ConjugationPickMode.todayOnly
        ? await _db.wordDao.getTodayStudiedWords(deckId)
        : await _db.wordDao.getWordsByDeck(deckId);
    final candidates =
        words.where((w) => w.wordType == mode.requiredWordType).toList();

    // 优先使用有完整数据的单词
    candidates.shuffle();

    final questions = <ConjugationQuestion>[];
    for (final word in candidates) {
      if (questions.length >= limit) break;
      final question = await _buildQuestion(word, mode);
      if (question != null) {
        questions.add(question);
      }
    }

    state = ConjugationDrillState(mode: mode, questions: questions);
  }

  /// 为单个单词构建题目，缺少目标数据时返回 null（不进入队列）
  Future<ConjugationQuestion?> _buildQuestion(
      Word word, PracticeMode mode) async {
    final meaning = _firstLine(word.chinese);

    switch (mode.id) {
      // ── 动词时态：6 人称完整变位 ────────────────
      case 'verb_praesens':
      case 'verb_praeteritum':
      case 'verb_perfekt':
      case 'verb_passiv':
        final forms = await _buildVerbForms(word, mode);
        if (forms == null) return null;
        final fields = personKeys
            .map((key) => PracticeField(
                label: personLabels[key]!, correctAnswer: forms[key]!))
            .toList();
        return ConjugationQuestion(
          wordId: word.id,
          word: word.german,
          article: word.article,
          meaning: meaning,
          mode: mode,
          prompt: AppLocale.trArgs(
            '请填写 "{0}" 的{1}全部人称变位',
            [word.german, mode.title],
          ),
          fields: fields,
        );

      // ── 名词 ─────────────────────────────────
      // 注意：名词练习不携带 article，避免单词卡片直接展示 der/die/das 泄露答案
      case 'noun_article':
        final article = word.article;
        if (article == null || article.trim().isEmpty) return null;
        return ConjugationQuestion(
          wordId: word.id,
          word: word.german,
          article: null,
          meaning: meaning,
          mode: mode,
          prompt: AppLocale.trArgs('请填写 "{0}" 的定冠词', [word.german]),
          fields: [PracticeField(label: '定冠词', correctAnswer: article.trim())],
        );

      case 'noun_genitiv':
        final cached = await _loadCacheJson(word.id);
        final genitiv =
            _pickString(cached, ['genitiv', 'genitive']) ?? word.nounGenitive;
        if (genitiv == null || genitiv.isEmpty) return null;
        return ConjugationQuestion(
          wordId: word.id,
          word: word.german,
          article: null,
          meaning: meaning,
          mode: mode,
          prompt: AppLocale.trArgs(
            '请填写 "{0}" 的第二格单数形式（Genitiv Singular）',
            [word.german],
          ),
          fields: [
            PracticeField(label: '第二格单数', correctAnswer: genitiv),
          ],
        );

      case 'noun_plural':
        final cached = await _loadCacheJson(word.id);
        final plural =
            _pickString(cached, ['plural', 'pluralform']) ?? word.nounPlural;
        if (plural == null || plural.isEmpty) return null;
        return ConjugationQuestion(
          wordId: word.id,
          word: word.german,
          article: null,
          meaning: meaning,
          mode: mode,
          prompt: AppLocale.trArgs(
            '请填写 "{0}" 的复数形式（Plural）',
            [word.german],
          ),
          fields: [
            PracticeField(label: '复数形式', correctAnswer: plural),
          ],
        );

      // ── 形容词变级：一页同时填写比较级与最高级 ──────
      case 'adj_steigerung':
        final cached = await _loadCacheJson(word.id);
        final comparative = _pickString(cached, ['komparativ', 'comparative']) ??
            word.adjComparative;
        final superlative = _pickString(cached, ['superlativ', 'superlative']) ??
            word.adjSuperlative;
        if (comparative == null || comparative.isEmpty) return null;
        if (superlative == null || superlative.isEmpty) return null;
        return ConjugationQuestion(
          wordId: word.id,
          word: word.german,
          article: word.article,
          meaning: meaning,
          mode: mode,
          prompt: AppLocale.trArgs(
            '请填写 "{0}" 的比较级与最高级',
            [word.german],
          ),
          fields: [
            PracticeField(label: '比较级', correctAnswer: comparative),
            PracticeField(label: '最高级', correctAnswer: superlative),
          ],
        );

      default:
        return null;
    }
  }

  /// 构建动词某一时态的 6 人称标准变位表
  ///
  /// 数据源优先级：conjugation_cache 完整 JSON → 单词表字段
  /// 被动语态（Passiv）由 "werden 现在时 + Partizip II" 推导
  Future<Map<String, String>?> _buildVerbForms(
      Word word, PracticeMode mode) async {
    final cached = await _loadCacheJson(word.id);

    // 被动语态：werden (Präsens) + Partizip II
    if (mode.id == 'verb_passiv') {
      final partizip = _pickString(
        cached?['perfekt'],
        ['partizip', 'partizip_ii', 'partizip2'],
      );
      if (partizip == null || partizip.isEmpty) return null;
      const werden = {
        'ich': 'werde',
        'du': 'wirst',
        'er_sie_es': 'wird',
        'wir': 'werden',
        'ihr': 'werdet',
        'sie_Sie': 'werden',
      };
      return werden.map((k, v) => MapEntry(k, '$v $partizip'));
    }

    final tenseKey = switch (mode.id) {
      'verb_praesens' => 'praesens',
      'verb_praeteritum' => 'praeteritum',
      'verb_perfekt' => 'perfekt',
      _ => null,
    };
    if (tenseKey == null) return null;

    final tense = cached?[tenseKey];
    if (tense is! Map<String, dynamic>) return null;

    final forms = <String, String>{};
    for (final person in personKeys) {
      final value = _findPersonValue(tense, person);
      if (value == null || value.trim().isEmpty) return null;
      forms[person] = value.trim();
    }
    return forms;
  }

  /// 从时态 JSON 中取某个人称的值（兼容 AI 返回的不同键名）
  String? _findPersonValue(Map<String, dynamic> tense, String person) {
    final candidates = switch (person) {
      'ich' => const ['ich'],
      'du' => const ['du'],
      'er_sie_es' => const ['er_sie_es', 'er/sie/es', 'er', 'es'],
      'wir' => const ['wir'],
      'ihr' => const ['ihr'],
      'sie_Sie' => const ['sie_Sie', 'sie/Sie', 'sie', 'Sie'],
      _ => const <String>[],
    };
    for (final key in candidates) {
      final value = tense[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  /// 读取单词的变位缓存 JSON
  Future<Map<String, dynamic>?> _loadCacheJson(int wordId) async {
    final cached = await _db?.conjugationDao.getByWordId(wordId);
    if (cached == null) return null;
    try {
      final decoded = jsonDecode(cached.conjugationJson);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  /// 从 JSON 中按候选键依次取值
  String? _pickString(Map<String, dynamic>? json, List<String> keys) {
    if (json == null) return null;
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  String? _firstLine(String? text) {
    if (text == null) return null;
    final line = text.trim().split('\n').first.trim();
    return line.isEmpty ? null : line;
  }

  /// 提交当前题答案（仅累计统计，不推进题目；推进由 next() 完成）
  void submitAnswer({required bool isCorrect}) {
    state = state.copyWith(
      answeredCount: state.answeredCount + 1,
      correctCount: state.correctCount + (isCorrect ? 1 : 0),
    );
  }

  /// 进入下一题
  void next() {
    if (state.questions.isEmpty) return;
    final nextIndex = state.currentIndex + 1;
    state = state.copyWith(
      currentIndex: nextIndex,
      isCompleted: nextIndex >= state.questions.length,
    );
  }

  /// 重置
  void reset() {
    state = const ConjugationDrillState();
  }

  /// 校验一组用户答案，返回每个格子的校验结果（供界面高亮展示）
  static Map<String, FieldCheckResult> checkFields(
    ConjugationQuestion question,
    Map<String, String> userAnswers,
  ) {
    final results = <String, FieldCheckResult>{};
    for (final field in question.fields) {
      final user = (userAnswers[field.label] ?? '').trim();
      final isBlank = user.isEmpty;
      final isCorrect = !isBlank && checkAnswer(user, field.correctAnswer);
      results[field.label] = FieldCheckResult(
        label: field.label,
        userAnswer: user,
        correctAnswer: field.correctAnswer,
        isCorrect: isCorrect,
        isBlank: isBlank,
      );
    }
    return results;
  }

  /// 答案对比（忽略大小写、多余空格；允许带/不带人称前缀）
  static bool checkAnswer(String userAnswer, String correctAnswer) {
    String normalize(String s) => s
        .toLowerCase()
        .replaceAll(RegExp(r'[,，;；\s]+'), ' ')
        .trim();

    final user = normalize(userAnswer);
    final correct = normalize(correctAnswer);
    if (user.isEmpty || correct.isEmpty) return false;
    if (user == correct) return true;

    // 人称前缀容错：标准 "habe gemacht" ⇄ 用户 "ich habe gemacht"
    const persons = {'ich', 'du', 'er', 'sie', 'es', 'wir', 'ihr', 'sie/sie'};
    final userParts = user.split(' ');
    if (userParts.length >= 2 && persons.contains(userParts.first)) {
      if (userParts.skip(1).join(' ') == correct) return true;
    }
    final correctParts = correct.split(' ');
    if (correctParts.length >= 2 && persons.contains(correctParts.first)) {
      if (user == correctParts.skip(1).join(' ')) return true;
    }
    return false;
  }
}

/// 变位练习 Provider
final conjugationDrillProvider =
    StateNotifierProvider<ConjugationDrillNotifier, ConjugationDrillState>(
        (ref) {
  final db = ref.watch(databaseProvider);
  return ConjugationDrillNotifier(db);
});

/// 词书中所有单词的变位缓存 Provider（wordId → 缓存记录）
final deckConjugationCacheProvider =
    FutureProvider.family<Map<int, ConjugationCacheData>, int>(
        (ref, deckId) async {
  final db = ref.watch(databaseProvider);
  if (db == null) return {};
  return db.conjugationDao.getCachedByDeck(deckId);
});
