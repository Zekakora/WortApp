/// AI 训练模块领域模型
///
/// 设计要点（对应实施任务书 §4）：
/// - 三大技能（听/读/写）并列，题型通过 [ExerciseType] 扩展，不复制流程；
/// - 题目展示数据 [PlaybackQuestion] 与答案数据 [QuestionSolution] **在模型层分离**，
///   UI 在提交前只拿得到前者；
/// - 题型编码 `code` 会写进本地数据库，**禁止随意改名**（改名需做旧记录兼容）。
library;

/// 训练技能（一级分类）
enum TrainingSkill {
  listening('listening'),
  reading('reading'),
  writing('writing'),

  /// 混合练习：一套题里听 / 读 / 写题型各出几道
  mixed('mixed');

  const TrainingSkill(this.code);

  /// 持久化编码（写入 exercises.skill）
  final String code;

  static TrainingSkill fromCode(String code) => TrainingSkill.values.firstWhere(
    (s) => s.code == code,
    orElse: () => TrainingSkill.reading,
  );

  /// 中文名（i18n key）
  String get titleZh => switch (this) {
    TrainingSkill.listening => '听力',
    TrainingSkill.reading => '阅读',
    TrainingSkill.writing => '写作',
    TrainingSkill.mixed => '混合',
  };

  /// 德语名（界面上与中文并列展示，属产品术语，不参与翻译）
  String get germanName => switch (this) {
    TrainingSkill.listening => 'Hören',
    TrainingSkill.reading => 'Lesen',
    TrainingSkill.writing => 'Schreiben',
    TrainingSkill.mixed => 'Gemischt',
  };
}

/// 题目类型（决定 Renderer 与判分方式）
enum QuestionType {
  singleChoice('single_choice'),
  multipleChoice('multiple_choice'),
  trueFalse('true_false'),
  fillBlank('fill_blank'),
  dictation('dictation'),
  ordering('ordering'),
  freeText('free_text');

  const QuestionType(this.code);

  final String code;

  static QuestionType fromCode(String code) => QuestionType.values.firstWhere(
    (t) => t.code == code,
    orElse: () => QuestionType.freeText,
  );

  /// 是否由程序确定性判分（false 表示必须走 AI Rubric）
  bool get isObjective => this != QuestionType.freeText;

  /// 用户答案是否为纯文本输入
  bool get isTextInput => switch (this) {
    QuestionType.fillBlank ||
    QuestionType.dictation ||
    QuestionType.freeText => true,
    _ => false,
  };
}

/// 判分方式
enum GradingMode {
  /// 程序确定性判分
  program,

  /// AI Rubric 评分（开放式答案）
  aiRubric,

  /// 混合：同一套题里客观题走程序判分、写作题走 AI Rubric
  mixed,
}

/// 训练题型
///
/// [implemented] 为 false 的题型只在列表里出现（标注"后续"），不可进入练习。
enum ExerciseType {
  // ---- Hören · 听力 ----
  listeningComprehension(
    'listening_comprehension',
    TrainingSkill.listening,
    '听力理解',
    '听德语短文后回答选择题',
    QuestionType.singleChoice,
    GradingMode.program,
  ),
  dictation(
    'dictation',
    TrainingSkill.listening,
    '听写',
    '听句子并写出听到的内容',
    QuestionType.dictation,
    GradingMode.program,
  ),
  listeningCloze(
    'listening_cloze',
    TrainingSkill.listening,
    '听力填空',
    '边听边补全挖空文本',
    QuestionType.fillBlank,
    GradingMode.program,
  ),
  dialogComprehension(
    'dialog_comprehension',
    TrainingSkill.listening,
    '对话理解',
    '听生活场景对话并作答',
    QuestionType.singleChoice,
    GradingMode.program,
  ),
  listeningSentenceOrdering(
    'listening_sentence_ordering',
    TrainingSkill.listening,
    '语句排序',
    '听取片段后排列正确顺序',
    QuestionType.ordering,
    GradingMode.program,
  ),

  // ---- Lesen · 阅读 ----
  readingComprehension(
    'reading_comprehension',
    TrainingSkill.reading,
    '阅读理解',
    '阅读德语短文并回答选择题',
    QuestionType.singleChoice,
    GradingMode.program,
  ),
  readingCloze(
    'reading_cloze',
    TrainingSkill.reading,
    '完形填空',
    '从短文中挖空，填写缺失词',
    QuestionType.fillBlank,
    GradingMode.program,
  ),
  contextVocabulary(
    'context_vocabulary',
    TrainingSkill.reading,
    '语境词汇',
    '根据上下文选择词义或搭配',
    QuestionType.singleChoice,
    GradingMode.program,
  ),
  trueFalseReading(
    'true_false',
    TrainingSkill.reading,
    '判断正误',
    '判断陈述与材料是否一致',
    QuestionType.trueFalse,
    GradingMode.program,
  ),
  paragraphOrdering(
    'paragraph_ordering',
    TrainingSkill.reading,
    '段落排序',
    '排列句子或段落恢复逻辑',
    QuestionType.ordering,
    GradingMode.program,
  ),
  headingMatching(
    'heading_matching',
    TrainingSkill.reading,
    '标题匹配',
    '为段落匹配最合适的标题',
    QuestionType.singleChoice,
    GradingMode.program,
  ),

  // ---- Schreiben · 写作 ----
  sentenceBuilding(
    'sentence_building',
    TrainingSkill.writing,
    '句子构造',
    '按给定词语与要求写出德语句子',
    QuestionType.freeText,
    GradingMode.aiRubric,
  ),
  errorCorrection(
    'error_correction',
    TrainingSkill.writing,
    '语法改错',
    '找出并改正句中的错误',
    QuestionType.freeText,
    GradingMode.aiRubric,
  ),
  translationWriting(
    'translation',
    TrainingSkill.writing,
    '中德翻译',
    '把中文句子译成德语',
    QuestionType.freeText,
    GradingMode.aiRubric,
  ),
  situationalWriting(
    'situational_writing',
    TrainingSkill.writing,
    '情景写作',
    '按场景写邮件、预约、请假等',
    QuestionType.freeText,
    GradingMode.aiRubric,
  ),
  freeWriting(
    'free_writing',
    TrainingSkill.writing,
    '自由写作',
    '按主题与字数写短文',
    QuestionType.freeText,
    GradingMode.aiRubric,
  ),

  /// 混合练习：一套题里包含听力（听写）、语法词汇（填空/判断）与写作（AI 评分），
  /// 判分方式由**每道题的题干类型**决定，不统一。
  mixedPractice(
    'mixed_practice',
    TrainingSkill.mixed,
    '混合练习',
    '听、读、写题型混合出题，一节课练全面',
    QuestionType.singleChoice,
    GradingMode.mixed,
  );

  const ExerciseType(
    this.code,
    this.skill,
    this.titleZh,
    this.descZh,
    this.defaultQuestionType,
    this.gradingMode,
  );

  /// 持久化编码（写入 exercises.exercise_type）
  final String code;
  final TrainingSkill skill;

  /// 中文名（i18n key）
  final String titleZh;

  /// 中文说明（i18n key）
  final String descZh;

  /// 该题型默认题干类型（AI 可在同一题型内返回多个题干类型）
  final QuestionType defaultQuestionType;

  final GradingMode gradingMode;

  static ExerciseType fromCode(String code) => ExerciseType.values.firstWhere(
    (t) => t.code == code,
    orElse: () => ExerciseType.readingComprehension,
  );

  static List<ExerciseType> forSkill(TrainingSkill skill) =>
      ExerciseType.values.where((t) => t.skill == skill).toList();
}

/// CEFR 等级
enum CefrLevel {
  a1('A1'),
  a2('A2'),
  b1('B1'),
  b2('B2'),
  c1('C1'),
  c2('C2');

  const CefrLevel(this.code);

  final String code;

  static CefrLevel fromCode(String code) {
    final upper = code.trim().toUpperCase();
    return CefrLevel.values.firstWhere(
      (l) => l.code == upper,
      orElse: () => CefrLevel.b1,
    );
  }
}

/// 难度（与 CEFR 是两个维度，任务书 §2 明确要求不要混为一谈）
enum TrainingDifficulty {
  easy('easy', '简单'),
  normal('normal', '普通'),
  hard('hard', '困难');

  const TrainingDifficulty(this.code, this.titleZh);

  final String code;
  final String titleZh;

  static TrainingDifficulty fromCode(String code) =>
      TrainingDifficulty.values.firstWhere(
        (d) => d.code == code,
        orElse: () => TrainingDifficulty.normal,
      );
}

/// 主题候选（中文名，同时作为 i18n key 与提示词内容）
const List<String> trainingTopics = [
  '日常生活',
  '学习',
  '工作',
  '旅行',
  '住房',
  '购物',
  '健康',
  '社会',
];

/// 题量候选
const List<int> trainingQuestionCounts = [5, 10, 15, 20];

/// 标准答案 / 可接受答案
///
/// 字段都是"可选"的，具体题型只填自己有意义的字段：
/// - 选择题：[correctIndices]（0 基，与 options 下标一致）
/// - 排序题：[correctOrder] / [acceptedOrders]（0 基，元素为原始顺序下标）
/// - 填空 / 听写：[acceptedAnswers]（第一项视为标准答案）
/// - 写作：[referenceAnswers]（参考答案，不作为唯一正确标准）
class AnswerKey {
  final List<String> acceptedAnswers;
  final List<int> correctIndices;
  final List<int> correctOrder;
  final List<List<int>> acceptedOrders;
  final List<String> referenceAnswers;

  const AnswerKey({
    this.acceptedAnswers = const [],
    this.correctIndices = const [],
    this.correctOrder = const [],
    this.acceptedOrders = const [],
    this.referenceAnswers = const [],
  });

  static const AnswerKey empty = AnswerKey();

  bool get isEmpty =>
      acceptedAnswers.isEmpty &&
      correctIndices.isEmpty &&
      correctOrder.isEmpty &&
      acceptedOrders.isEmpty &&
      referenceAnswers.isEmpty;

  /// 首选标准答案文本（结果页展示用）
  String? get primaryAnswer {
    if (acceptedAnswers.isNotEmpty) return acceptedAnswers.first;
    if (referenceAnswers.isNotEmpty) return referenceAnswers.first;
    return null;
  }

  Map<String, dynamic> toJson() => {
    if (acceptedAnswers.isNotEmpty) 'acceptedAnswers': acceptedAnswers,
    if (correctIndices.isNotEmpty) 'correctIndices': correctIndices,
    if (correctOrder.isNotEmpty) 'correctOrder': correctOrder,
    if (acceptedOrders.isNotEmpty) 'acceptedOrders': acceptedOrders,
    if (referenceAnswers.isNotEmpty) 'referenceAnswers': referenceAnswers,
  };

  factory AnswerKey.fromJson(Map<String, dynamic> json) => AnswerKey(
    acceptedAnswers: _stringList(json['acceptedAnswers']),
    correctIndices: _intList(json['correctIndices']),
    correctOrder: _intList(json['correctOrder']),
    acceptedOrders: _intListList(json['acceptedOrders']),
    referenceAnswers: _stringList(json['referenceAnswers']),
  );

  static List<String> _stringList(dynamic raw) {
    if (raw is String) return raw.trim().isEmpty ? const [] : [raw];
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<int> _intList(dynamic raw) {
    if (raw is int) return [raw];
    if (raw is String) {
      final parsed = int.tryParse(raw.trim());
      return parsed == null ? const [] : [parsed];
    }
    if (raw is! List) return const [];
    return raw.map(_asInt).whereType<int>().toList();
  }

  static List<List<int>> _intListList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<List>()
        .map((e) => e.map(_asInt).whereType<int>().toList())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static int? _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }
}

/// Rubric 评分维度（开放式题型）
class RubricDimension {
  final String name;
  final int maxScore;

  const RubricDimension({required this.name, required this.maxScore});

  Map<String, dynamic> toJson() => {'name': name, 'maxScore': maxScore};

  factory RubricDimension.fromJson(Map<String, dynamic> json) =>
      RubricDimension(
        name: json['name']?.toString() ?? 'grammar',
        maxScore: (json['maxScore'] as num?)?.toInt() ?? 1,
      );
}

/// 开放式题目的评分标准
class Rubric {
  final List<RubricDimension> dimensions;

  const Rubric({this.dimensions = const []});

  bool get isEmpty => dimensions.isEmpty;

  int get maxScore => dimensions.fold(0, (sum, d) => sum + d.maxScore);

  Map<String, dynamic> toJson() => {
    'dimensions': dimensions.map((d) => d.toJson()).toList(),
  };

  factory Rubric.fromJson(Map<String, dynamic> json) => Rubric(
    dimensions:
        (json['dimensions'] as List?)
            ?.whereType<Map>()
            .map((e) => RubricDimension.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const [],
  );
}

/// AI 生成并被校验通过的题目（含答案，只在生成/评分/落库链路中流转）
class GeneratedQuestion {
  final String key;
  final QuestionType type;
  final String prompt;
  final List<String> options;
  final String? contextText;
  final int points;
  final AnswerKey answerKey;
  final String explanation;
  final Rubric? rubric;

  const GeneratedQuestion({
    required this.key,
    required this.type,
    required this.prompt,
    this.options = const [],
    this.contextText,
    this.points = 1,
    this.answerKey = AnswerKey.empty,
    this.explanation = '',
    this.rubric,
  });

  /// 展示用题目（不含答案）
  ///
  /// 听写题是唯一例外：用户必须听到句子才可能写出来，因此把句子放进
  /// [PlaybackQuestion.audioText]（**只供 TTS 朗读，UI 不得显示**），
  /// 而 `contextText` 保持为空，避免被当成可展示的上下文渲染出来。
  PlaybackQuestion toPlayback(int orderIndex) => PlaybackQuestion(
    key: key,
    orderIndex: orderIndex,
    type: type,
    prompt: prompt,
    options: options,
    contextText: type == QuestionType.dictation ? null : contextText,
    audioText: type == QuestionType.dictation ? contextText : null,
    points: points,
  );

  /// 评分用答案
  QuestionSolution toSolution() => QuestionSolution(
    key: key,
    type: type,
    answerKey: answerKey,
    explanation: explanation,
    rubric: rubric,
  );
}

/// AI 生成并被校验通过的整套练习
class GeneratedExercise {
  final TrainingSkill skill;
  final ExerciseType exerciseType;
  final CefrLevel level;
  final TrainingDifficulty difficulty;
  final String topic;
  final String title;
  final String instructions;
  final String stimulusKind;
  final String stimulusText;
  final List<GeneratedQuestion> questions;

  const GeneratedExercise({
    required this.skill,
    required this.exerciseType,
    required this.level,
    required this.difficulty,
    required this.topic,
    required this.title,
    required this.instructions,
    required this.stimulusKind,
    required this.stimulusText,
    required this.questions,
  });

  int get maxScore => questions.fold(0, (sum, q) => sum + q.points);

  /// 是否为听力材料（需要朗读）
  bool get hasAudio => stimulusKind == 'audio' || stimulusKind == 'text_audio';
}

/// 答题阶段可见的题目（**不含任何答案字段**）
class PlaybackQuestion {
  final String key;
  final int orderIndex;
  final QuestionType type;
  final String prompt;
  final List<String> options;

  /// 可展示的上下文（完形填空所在句子等）
  final String? contextText;

  /// 听写题的朗读文本：**不可显示**，只交给 SpeechPlaybackService
  final String? audioText;
  final int points;

  const PlaybackQuestion({
    required this.key,
    required this.orderIndex,
    required this.type,
    required this.prompt,
    this.options = const [],
    this.contextText,
    this.audioText,
    this.points = 1,
  });
}

/// 提交后才可见的答案与解析
class QuestionSolution {
  final String key;
  final QuestionType type;
  final AnswerKey answerKey;
  final String explanation;
  final Rubric? rubric;

  const QuestionSolution({
    required this.key,
    required this.type,
    required this.answerKey,
    this.explanation = '',
    this.rubric,
  });
}

/// 单题判分结果
class QuestionGrade {
  /// 0..[maxScore]
  final double score;
  final double maxScore;
  final bool isCorrect;
  final bool isPartial;

  /// 'program' / 'ai'
  final String graderType;

  /// 结构化反馈（听写差异、Rubric 明细等），入库到 exercise_attempts.feedback_json
  final Map<String, dynamic>? feedback;

  const QuestionGrade({
    required this.score,
    required this.maxScore,
    required this.isCorrect,
    this.isPartial = false,
    this.graderType = 'program',
    this.feedback,
  });

  static QuestionGrade correct(double maxScore) => QuestionGrade(
    score: maxScore,
    maxScore: maxScore,
    isCorrect: true,
    graderType: 'program',
  );

  static QuestionGrade wrong(
    double maxScore, {
    Map<String, dynamic>? feedback,
  }) => QuestionGrade(
    score: 0,
    maxScore: maxScore,
    isCorrect: false,
    graderType: 'program',
    feedback: feedback,
  );

  /// 评分暂不可用（AI 失败）：保留用户答案，不伪造分数
  static QuestionGrade unavailable(double maxScore) => QuestionGrade(
    score: 0,
    maxScore: maxScore,
    isCorrect: false,
    graderType: 'unavailable',
    feedback: const {'pending': true},
  );
}

/// 历史列表条目
class ExerciseHistoryEntry {
  final int id;
  final TrainingSkill skill;
  final ExerciseType exerciseType;
  final CefrLevel level;
  final TrainingDifficulty difficulty;
  final String topic;
  final String title;
  final String status;
  final int totalScore;
  final int maxScore;
  final DateTime createdAt;
  final DateTime? submittedAt;

  const ExerciseHistoryEntry({
    required this.id,
    required this.skill,
    required this.exerciseType,
    required this.level,
    required this.difficulty,
    required this.topic,
    required this.title,
    required this.status,
    required this.totalScore,
    required this.maxScore,
    required this.createdAt,
    this.submittedAt,
  });

  /// 得分率（0..1），未作答时按 0
  double get ratio => maxScore <= 0 ? 0 : totalScore / maxScore;
}
