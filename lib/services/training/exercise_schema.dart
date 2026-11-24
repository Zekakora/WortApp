/// AI 生成结果的 Schema 解析与业务校验（任务书 §4.3）
///
/// 原则：**绝不把模型输出直接当成页面数据**。所有字段在这里做类型收敛、
/// 缺失兜底与业务校验（选项数量、答案引用、分值、题数），
/// 只有全部通过才返回 [GeneratedExercise]；否则返回问题清单供上层重试或提示。
library;

import '../../data/models/training.dart';

/// 一条校验问题
class SchemaIssue {
  final String field;

  /// 中文说明（可直接展示给用户，同时也是 i18n key 的近似形态）
  final String message;

  /// 是否致命（致命则整份练习不可用）
  final bool fatal;

  const SchemaIssue(this.field, this.message, {this.fatal = true});

  @override
  String toString() => '${fatal ? '✕' : '!'} $field: $message';
}

/// 解析结果
class SchemaParseResult {
  final GeneratedExercise? exercise;
  final List<SchemaIssue> issues;

  const SchemaParseResult({this.exercise, this.issues = const []});

  bool get ok => exercise != null;

  List<SchemaIssue> get fatalIssues => issues.where((i) => i.fatal).toList();

  /// 给用户看的简短错误描述
  String get errorSummary => fatalIssues.isEmpty
      ? ''
      : fatalIssues.take(3).map((i) => i.message).join('；');
}

/// 生成结果 Schema
class ExerciseSchema {
  ExerciseSchema._();

  /// 当前生成格式版本（写入 exercises.schema_version，便于排查质量问题）
  static const int currentVersion = 1;

  /// 各题型允许出现的题干类型
  static Set<QuestionType> allowedQuestionTypes(ExerciseType type) =>
      switch (type) {
        ExerciseType.listeningComprehension ||
        ExerciseType.dialogComprehension ||
        ExerciseType.readingComprehension => const {
          QuestionType.singleChoice,
          QuestionType.multipleChoice,
          QuestionType.trueFalse,
        },
        ExerciseType.contextVocabulary ||
        ExerciseType.headingMatching => const {QuestionType.singleChoice},
        ExerciseType.dictation => const {QuestionType.dictation},
        ExerciseType.listeningCloze ||
        ExerciseType.readingCloze => const {QuestionType.fillBlank},
        ExerciseType.trueFalseReading => const {QuestionType.trueFalse},
        ExerciseType.listeningSentenceOrdering ||
        ExerciseType.paragraphOrdering => const {QuestionType.ordering},
        ExerciseType.sentenceBuilding ||
        ExerciseType.errorCorrection ||
        ExerciseType.translationWriting ||
        ExerciseType.situationalWriting ||
        ExerciseType.freeWriting => const {QuestionType.freeText},
      };

  /// 该题型是否需要材料（文章/听力原文）
  static bool needsStimulus(ExerciseType type) => switch (type) {
    ExerciseType.dictation => false,
    ExerciseType.sentenceBuilding => false,
    ExerciseType.errorCorrection => false,
    // 段落排序的材料由 options（打乱的段落）承载，不需要额外正文
    ExerciseType.paragraphOrdering => false,
    _ => true,
  };

  /// 解析并校验模型输出
  static SchemaParseResult parse(
    Map<String, dynamic> json, {
    required ExerciseType expectedType,
    required CefrLevel expectedLevel,
    required TrainingDifficulty expectedDifficulty,
    required String expectedTopic,
    int? minQuestions,
    int? maxQuestions,
  }) {
    final issues = <SchemaIssue>[];

    // ---- 顶层字段 ----
    final skillRaw = _str(json['skill']);
    final typeRaw = _str(json['exerciseType'] ?? json['exercise_type']);
    if (typeRaw.isNotEmpty && typeRaw != expectedType.code) {
      issues.add(
        SchemaIssue(
          'exerciseType',
          '题型不一致（期望 ${expectedType.code}，实际 $typeRaw）',
        ),
      );
    }
    if (skillRaw.isNotEmpty && skillRaw != expectedType.skill.code) {
      issues.add(
        SchemaIssue(
          'skill',
          '技能分类不一致（期望 ${expectedType.skill.code}，实际 $skillRaw）',
        ),
      );
    }

    final level = _str(json['level']).isEmpty
        ? expectedLevel
        : CefrLevel.fromCode(_str(json['level']));
    if (level != expectedLevel) {
      issues.add(SchemaIssue('level', '等级与请求不一致（按请求等级展示）', fatal: false));
    }
    final difficulty = _str(json['difficulty']).isEmpty
        ? expectedDifficulty
        : TrainingDifficulty.fromCode(_str(json['difficulty']));

    final title = _str(json['title']);
    final instructions = _str(json['instructions']);

    // ---- 材料 ----
    final stimulus = _asMap(json['stimulus']);
    var stimulusKind = _str(stimulus['kind']);
    var stimulusText = _str(stimulus['text']).isNotEmpty
        ? _str(stimulus['text'])
        : _str(stimulus['content']);
    if (stimulusText.isEmpty) {
      // 兼容模型把材料直接放在顶层的情况
      stimulusText = _str(json['text']).isNotEmpty
          ? _str(json['text'])
          : _str(json['passage']);
    }
    if (stimulusKind.isEmpty) {
      stimulusKind = needsStimulus(expectedType) ? 'text' : 'none';
    }
    if (needsStimulus(expectedType) && stimulusText.isEmpty) {
      issues.add(const SchemaIssue('stimulus.text', '缺少材料正文'));
    }

    // ---- 题目 ----
    final rawQuestions = json['questions'];
    if (rawQuestions is! List || rawQuestions.isEmpty) {
      issues.add(const SchemaIssue('questions', '题目列表为空'));
      return SchemaParseResult(issues: issues);
    }

    if (minQuestions != null && rawQuestions.length < minQuestions) {
      issues.add(
        SchemaIssue(
          'questions',
          '题目数量不足（请求 $minQuestions 题，实际 ${rawQuestions.length} 题）',
        ),
      );
    }
    if (maxQuestions != null && rawQuestions.length > maxQuestions) {
      issues.add(
        SchemaIssue(
          'questions',
          '题目数量超出（请求 $maxQuestions 题，实际 ${rawQuestions.length} 题）',
        ),
      );
    }

    final questions = <GeneratedQuestion>[];
    for (var index = 0; index < rawQuestions.length; index++) {
      final raw = _asMap(rawQuestions[index]);
      final parsed = _parseQuestion(
        raw,
        index: index,
        type: expectedType,
        issues: issues,
      );
      if (parsed != null) questions.add(parsed);
    }

    if (issues.any((i) => i.fatal) || questions.isEmpty) {
      return SchemaParseResult(issues: issues);
    }

    return SchemaParseResult(
      exercise: GeneratedExercise(
        skill: expectedType.skill,
        exerciseType: expectedType,
        level: expectedLevel,
        difficulty: difficulty,
        topic: expectedTopic,
        title: title.isEmpty ? expectedType.titleZh : title,
        instructions: instructions,
        stimulusKind: stimulusKind,
        stimulusText: stimulusText,
        questions: questions,
      ),
      issues: issues,
    );
  }

  static GeneratedQuestion? _parseQuestion(
    Map<String, dynamic> raw, {
    required int index,
    required ExerciseType type,
    required List<SchemaIssue> issues,
  }) {
    final key = _str(raw['id'] ?? raw['key']);
    final questionKey = key.isEmpty ? 'q${index + 1}' : key;
    final fieldPrefix = 'questions[$questionKey]';

    final prompt = _str(raw['prompt'] ?? raw['question'] ?? raw['stem']);
    if (prompt.isEmpty) {
      issues.add(SchemaIssue(fieldPrefix, '题干为空'));
      return null;
    }

    final declaredType = _str(raw['questionType'] ?? raw['question_type']);
    var questionType = declaredType.isEmpty
        ? type.defaultQuestionType
        : QuestionType.fromCode(declaredType);
    final allowed = allowedQuestionTypes(type);
    if (!allowed.contains(questionType)) {
      // 题型声明的题干类型不在允许集合里：能改回默认就改，改不了就报错
      issues.add(
        SchemaIssue(
          fieldPrefix,
          '题干类型 ${questionType.code} 不适用于 ${type.code}',
          fatal: false,
        ),
      );
      questionType = type.defaultQuestionType;
    }

    final options = _stringList(raw['options']);
    final contextText = _str(raw['context'] ?? raw['contextText']);
    final points =
        _asInt(raw['points'] ?? raw['score']) ??
        (questionType == QuestionType.freeText ? 10 : 1);
    if (points <= 0) {
      issues.add(SchemaIssue(fieldPrefix, '分值必须为正数'));
      return null;
    }

    final answerRaw = _asMap(raw['answerKey'] ?? raw['answer_key']);
    final explanation = _str(raw['explanation'] ?? raw['analysis']);
    if (explanation.isEmpty && questionType.isObjective) {
      issues.add(SchemaIssue('$fieldPrefix.explanation', '缺少解析', fatal: false));
    }

    final answerKey = _buildAnswerKey(
      answerRaw.isEmpty ? raw : answerRaw,
      questionType: questionType,
      options: options,
      fieldPrefix: fieldPrefix,
      issues: issues,
    );
    if (answerKey == null) return null;

    final rubric = questionType == QuestionType.freeText
        ? _buildRubric(raw, fieldPrefix, issues)
        : null;

    return GeneratedQuestion(
      key: questionKey,
      type: questionType,
      prompt: prompt,
      options: options,
      contextText: contextText.isEmpty ? null : contextText,
      points: points,
      answerKey: answerKey,
      explanation: explanation,
      rubric: rubric,
    );
  }

  /// 构造答案键；结构不合法时返回 null
  static AnswerKey? _buildAnswerKey(
    Map<String, dynamic> raw, {
    required QuestionType questionType,
    required List<String> options,
    required String fieldPrefix,
    required List<SchemaIssue> issues,
  }) {
    final accepted = _stringList(
      raw['acceptedAnswers'] ??
          raw['accepted_answers'] ??
          raw['answers'] ??
          raw['answer'],
    );
    final references = _stringList(
      raw['referenceAnswers'] ?? raw['reference_answers'],
    );

    switch (questionType) {
      case QuestionType.singleChoice:
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        final indices = _resolveChoiceIndices(raw, options);
        if (indices.isEmpty) {
          issues.add(SchemaIssue('$fieldPrefix.answerKey', '选择题答案无法定位到选项'));
          return null;
        }
        final outOfRange = indices
            .where((i) => i < 0 || i >= options.length)
            .toList();
        if (outOfRange.isNotEmpty) {
          issues.add(
            SchemaIssue('$fieldPrefix.answerKey', '答案引用了不存在的选项：$outOfRange'),
          );
          return null;
        }
        if (questionType == QuestionType.singleChoice && indices.length > 1) {
          issues.add(
            SchemaIssue(
              '$fieldPrefix.answerKey',
              '单选题出现多个答案，已保留第一个',
              fatal: false,
            ),
          );
        }
        return AnswerKey(
          correctIndices: questionType == QuestionType.singleChoice
              ? [indices.first]
              : (indices.toSet().toList()..sort()),
          acceptedAnswers: accepted,
          referenceAnswers: references,
        );

      case QuestionType.fillBlank:
        if (accepted.isEmpty) {
          issues.add(SchemaIssue('$fieldPrefix.answerKey', '填空题缺少可接受答案'));
          return null;
        }
        return AnswerKey(
          acceptedAnswers: accepted,
          referenceAnswers: references,
        );

      case QuestionType.dictation:
        if (accepted.isEmpty) {
          issues.add(SchemaIssue('$fieldPrefix.answerKey', '听写题缺少标准答案'));
          return null;
        }
        return AnswerKey(acceptedAnswers: accepted);

      case QuestionType.ordering:
        final order = _asIntList(raw['correctOrder'] ?? raw['order']);
        final acceptedOrders =
            (raw['acceptedOrders'] as List?)
                ?.whereType<List>()
                .map((e) => e.map(_asInt).whereType<int>().toList())
                .where((e) => e.isNotEmpty)
                .toList() ??
            const <List<int>>[];
        final primary = order.isNotEmpty
            ? order
            : (acceptedOrders.isNotEmpty
                  ? acceptedOrders.first
                  : const <int>[]);
        if (primary.isEmpty) {
          issues.add(SchemaIssue('$fieldPrefix.answerKey', '排序题缺少正确顺序'));
          return null;
        }
        final sorted = [...primary]..sort();
        final expected = List.generate(primary.length, (i) => i);
        if (sorted.join(',') != expected.join(',')) {
          issues.add(SchemaIssue('$fieldPrefix.answerKey', '排序题答案不是有效排列'));
          return null;
        }
        return AnswerKey(correctOrder: primary, acceptedOrders: acceptedOrders);

      case QuestionType.freeText:
        // 开放式题目：参考答案可选，不强制
        return AnswerKey(
          acceptedAnswers: accepted,
          referenceAnswers: references,
        );
    }
  }

  /// 把 `answerKey.correctIndices` / `["A","C"]` / `"B"` 统一解析成 0 基下标
  static List<int> _resolveChoiceIndices(
    Map<String, dynamic> raw,
    List<String> options,
  ) {
    final explicit = _asIntList(
      raw['correctIndices'] ?? raw['correct_indices'] ?? raw['correctIndex'],
    );
    if (explicit.isNotEmpty &&
        explicit.every((i) => i >= 0 && i < options.length)) {
      return explicit;
    }

    final rawAnswers =
        raw['correctAnswers'] ??
        raw['correct_answers'] ??
        raw['answers'] ??
        raw['answer'] ??
        raw['acceptedAnswers'];
    final answers = _stringList(rawAnswers);
    final indices = <int>[];
    for (final answer in answers) {
      final index = _indexOfAnswer(answer, options);
      if (index != null) indices.add(index);
    }
    return indices;
  }

  /// "A" / "B." / "C) ..." / 选项原文 → 下标
  static int? _indexOfAnswer(String answer, List<String> options) {
    final value = answer.trim();
    if (value.isEmpty) return null;

    // 纯数字（0 基）
    final asInt = int.tryParse(value);
    if (asInt != null) {
      if (asInt >= 1 && asInt <= options.length) return asInt - 1;
      if (asInt >= 0 && asInt < options.length) return asInt;
      return null;
    }

    // 字母 A-F（允许 "A." / "A)" / "A、" 等后缀）
    final letterMatch = RegExp(
      r'^([A-Fa-f])(?:[.)、．\]]|\s|$)',
    ).firstMatch(value);
    if (letterMatch != null) {
      final index = letterMatch.group(1)!.toUpperCase().codeUnitAt(0) - 65;
      if (index >= 0 && index < options.length) return index;
    }

    // 直接命中选项文本（含 "A. xxx" 形式的选项，按去前缀后比较）
    for (var i = 0; i < options.length; i++) {
      final option = options[i].trim();
      if (option == value) return i;
      final stripped = option.replaceFirst(RegExp(r'^[A-Fa-f][.)、．\]]\s*'), '');
      if (stripped.isNotEmpty && stripped == value) return i;
    }
    return null;
  }

  /// 构造评分标准：优先用模型给的，其次用默认五维
  static Rubric _buildRubric(
    Map<String, dynamic> raw,
    String fieldPrefix,
    List<SchemaIssue> issues,
  ) {
    final rubricRaw = _asMap(raw['rubric'] ?? raw['rubricDimensions']);
    if (rubricRaw.isEmpty) return defaultWritingRubric;

    final dimensions = <RubricDimension>[];
    final list = rubricRaw['dimensions'];
    if (list is List && list.isNotEmpty) {
      for (final item in list.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        final name = _str(map['name'] ?? map['dimension']);
        final maxScore =
            _asInt(map['maxScore'] ?? map['max'] ?? map['weight']) ?? 1;
        if (name.isEmpty || maxScore <= 0) continue;
        dimensions.add(RubricDimension(name: name, maxScore: maxScore));
      }
    } else {
      // 兼容 {grammar: 3, vocabulary: 2} 形式
      rubricRaw.forEach((key, value) {
        final maxScore = _asInt(value);
        if (maxScore != null && maxScore > 0 && key != 'dimensions') {
          dimensions.add(RubricDimension(name: key, maxScore: maxScore));
        }
      });
    }

    if (dimensions.isEmpty) {
      issues.add(
        SchemaIssue('$fieldPrefix.rubric', '评分维度无效，改用默认评分标准', fatal: false),
      );
      return defaultWritingRubric;
    }
    return Rubric(dimensions: dimensions);
  }

  /// 写作类默认评分标准（语法 / 词汇 / 句法 / 任务完成 / 自然度）
  static const Rubric defaultWritingRubric = Rubric(
    dimensions: [
      RubricDimension(name: 'grammar', maxScore: 3),
      RubricDimension(name: 'vocabulary', maxScore: 2),
      RubricDimension(name: 'sentenceStructure', maxScore: 2),
      RubricDimension(name: 'taskCompletion', maxScore: 2),
      RubricDimension(name: 'naturalness', maxScore: 1),
    ],
  );

  // ---- 类型收敛工具 ----

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  static String _str(dynamic raw) => raw?.toString().trim() ?? '';

  static int? _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.trim());
    return null;
  }

  static List<int> _asIntList(dynamic raw) {
    if (raw is int) return [raw];
    if (raw is String) {
      final value = int.tryParse(raw.trim());
      return value == null ? const [] : [value];
    }
    if (raw is! List) return const [];
    return raw
        .map((e) => e is num ? e.toInt() : int.tryParse(e.toString().trim()))
        .whereType<int>()
        .toList();
  }

  static List<String> _stringList(dynamic raw) {
    if (raw == null) return const [];
    if (raw is String) {
      final value = raw.trim();
      return value.isEmpty ? const [] : [value];
    }
    if (raw is List) {
      return raw
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }
}
