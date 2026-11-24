/// 批改服务（任务书 §5）
///
/// 分流原则：**客观题一律程序判分**，只有开放式写作才调用 AI Rubric。
/// - 单选 / 多选 / 判断 / 排序 / 填空 / 听写 → 纯 Dart，可单测、可离线；
/// - 写作类（句子构造 / 语法改错 / 翻译 / 情景 / 自由写作）→ AI 按 Rubric 评分，
///   但**先做一次确定性检查**：与参考答案标准化后一致直接给满分，省一次调用。
///
/// 失败语义：AI 评分失败返回 [QuestionGrade.unavailable]，分数记 0 且标记
/// `graderType = 'unavailable'`，绝不伪造分数；用户答案已由 DAO 保存。
library;

import 'package:flutter/foundation.dart';

import '../../core/i18n/app_localizations.dart';
import '../../data/models/training.dart';
import '../ai/ai_service.dart';
import 'ai_json.dart';
import 'answer_normalizer.dart';
import 'dictation_diff.dart';

/// 批改服务
class GradingService {
  final AIService? aiService;

  GradingService({this.aiService});

  /// 批改单题
  ///
  /// [userAnswer] 的编码约定由 UI 决定：
  /// - 选择题 / 排序题：逗号分隔的 0 基下标（如 `1`、`0,2`、`2,0,1`）
  /// - 判断题：`true` / `false`
  /// - 填空 / 听写 / 写作：原始文本
  Future<QuestionGrade> grade({
    required PlaybackQuestion question,
    required QuestionSolution solution,
    required String userAnswer,
    required CefrLevel level,
    String topic = '',
  }) async {
    switch (question.type) {
      case QuestionType.singleChoice:
        return _gradeSingleChoice(question, solution, userAnswer);
      case QuestionType.multipleChoice:
        return _gradeMultipleChoice(question, solution, userAnswer);
      case QuestionType.trueFalse:
        return _gradeTrueFalse(question, solution, userAnswer);
      case QuestionType.fillBlank:
        return _gradeFillBlank(question, solution, userAnswer);
      case QuestionType.dictation:
        return _gradeDictation(question, solution, userAnswer);
      case QuestionType.ordering:
        return _gradeOrdering(question, solution, userAnswer);
      case QuestionType.freeText:
        return _gradeFreeText(
          question,
          solution,
          userAnswer,
          level: level,
          topic: topic,
        );
    }
  }

  // ---- 客观题 ----

  QuestionGrade _gradeSingleChoice(
    PlaybackQuestion question,
    QuestionSolution solution,
    String userAnswer,
  ) {
    final expected = solution.answerKey.correctIndices;
    final selected = _parseIndices(userAnswer);
    final maxScore = question.points.toDouble();

    if (expected.isEmpty) {
      return QuestionGrade.unavailable(maxScore);
    }
    final correct = selected.length == 1 && selected.first == expected.first;
    return QuestionGrade(
      score: correct ? maxScore : 0,
      maxScore: maxScore,
      isCorrect: correct,
      feedback: {
        'selectedIndex': selected.isEmpty ? null : selected.first,
        'correctIndex': expected.first,
        if (expected.first < question.options.length)
          'correctOption': question.options[expected.first],
      },
    );
  }

  QuestionGrade _gradeMultipleChoice(
    PlaybackQuestion question,
    QuestionSolution solution,
    String userAnswer,
  ) {
    final expected = solution.answerKey.correctIndices.toSet();
    final selected = _parseIndices(userAnswer).toSet();
    final maxScore = question.points.toDouble();

    if (expected.isEmpty) return QuestionGrade.unavailable(maxScore);

    final hits = selected.intersection(expected).length;
    final wrong = selected.difference(expected).length;
    final missed = expected.difference(selected).length;

    // 全对得分；有漏选/错选按 (命中 - 错选) / 正确答案数 折算，最低 0
    final ratio = (hits - wrong) / expected.length;
    final score = (maxScore * ratio).clamp(0.0, maxScore);
    final isCorrect = wrong == 0 && missed == 0;

    return QuestionGrade(
      score: isCorrect ? maxScore : score,
      maxScore: maxScore,
      isCorrect: isCorrect,
      isPartial: !isCorrect && score > 0,
      feedback: {
        'correctIndices': (expected.toList()..sort()),
        'selectedIndices': (selected.toList()..sort()),
        'missedCount': missed,
        'wrongCount': wrong,
      },
    );
  }

  QuestionGrade _gradeTrueFalse(
    PlaybackQuestion question,
    QuestionSolution solution,
    String userAnswer,
  ) {
    final maxScore = question.points.toDouble();
    final expected = solution.answerKey.acceptedAnswers.isEmpty
        ? null
        : solution.answerKey.acceptedAnswers.first.toLowerCase();
    final normalizedUser = _normalizeBool(userAnswer);

    if (expected == null) return QuestionGrade.unavailable(maxScore);
    final expectedBool = _normalizeBool(expected);
    if (expectedBool == null) return QuestionGrade.unavailable(maxScore);

    final correct = normalizedUser == expectedBool;
    return QuestionGrade(
      score: correct ? maxScore : 0,
      maxScore: maxScore,
      isCorrect: correct,
      feedback: {'expected': expectedBool},
    );
  }

  QuestionGrade _gradeFillBlank(
    PlaybackQuestion question,
    QuestionSolution solution,
    String userAnswer,
  ) {
    final maxScore = question.points.toDouble();
    final accepted = solution.answerKey.acceptedAnswers;
    if (accepted.isEmpty) return QuestionGrade.unavailable(maxScore);

    final correct = AnswerNormalizer.matches(
      userAnswer,
      accepted,
      options: NormalizeOptions.fillBlank,
    );
    return QuestionGrade(
      score: correct ? maxScore : 0,
      maxScore: maxScore,
      isCorrect: correct,
      feedback: {
        'expected': solution.answerKey.primaryAnswer,
        'acceptedAnswers': accepted,
      },
    );
  }

  /// 听写：词级差异，按命中率给分（漏写/错写扣分，多写不额外扣分但要报告）
  QuestionGrade _gradeDictation(
    PlaybackQuestion question,
    QuestionSolution solution,
    String userAnswer,
  ) {
    final maxScore = question.points.toDouble();
    final expected = solution.answerKey.primaryAnswer;
    if (expected == null || expected.trim().isEmpty) {
      return QuestionGrade.unavailable(maxScore);
    }

    final diff = DictationDiff.compare(userAnswer, expected);
    final score = (maxScore * diff.accuracy).clamp(0.0, maxScore);
    final isCorrect = diff.isPerfect;

    return QuestionGrade(
      score: isCorrect ? maxScore : score,
      maxScore: maxScore,
      isCorrect: isCorrect,
      isPartial: !isCorrect && score > 0,
      feedback: {
        'expectedText': expected,
        ...diff.toJson(),
      },
    );
  }

  QuestionGrade _gradeOrdering(
    PlaybackQuestion question,
    QuestionSolution solution,
    String userAnswer,
  ) {
    final maxScore = question.points.toDouble();
    final correctOrder = solution.answerKey.correctOrder;
    final accepted = [
      if (correctOrder.isNotEmpty) correctOrder,
      ...solution.answerKey.acceptedOrders,
    ];
    if (accepted.isEmpty) return QuestionGrade.unavailable(maxScore);

    final selected = _parseIndices(userAnswer);
    final isCorrect = accepted.any((order) => _sameOrder(order, selected));

    // 部分正确：位置正确的项占比（仅用于反馈展示，不给部分分以外的东西）
    final primary = accepted.first;
    var positionHits = 0;
    for (var i = 0; i < selected.length && i < primary.length; i++) {
      if (selected[i] == primary[i]) positionHits++;
    }
    final ratio =
        primary.isEmpty ? 0.0 : positionHits / primary.length;

    return QuestionGrade(
      score: isCorrect ? maxScore : 0,
      maxScore: maxScore,
      isCorrect: isCorrect,
      feedback: {
        'correctOrder': primary,
        'selectedOrder': selected,
        'positionAccuracy': ratio,
      },
    );
  }

  // ---- 写作类 ----

  Future<QuestionGrade> _gradeFreeText(
    PlaybackQuestion question,
    QuestionSolution solution,
    String userAnswer, {
    required CefrLevel level,
    required String topic,
  }) async {
    final maxScore = question.points.toDouble();
    final trimmed = userAnswer.trim();
    if (trimmed.isEmpty) {
      return QuestionGrade(
        score: 0,
        maxScore: maxScore,
        isCorrect: false,
        feedback: const {'empty': true},
      );
    }

    // 先做确定性检查：与参考答案标准化一致 → 满分，不调用 AI
    final references = solution.answerKey.referenceAnswers.isNotEmpty
        ? solution.answerKey.referenceAnswers
        : solution.answerKey.acceptedAnswers;
    if (references.isNotEmpty &&
        AnswerNormalizer.matches(
          trimmed,
          references,
          options: const NormalizeOptions(
            ignoreCase: true,
            ignorePunctuation: true,
          ),
        )) {
      return QuestionGrade(
        score: maxScore,
        maxScore: maxScore,
        isCorrect: true,
        graderType: 'program',
        feedback: const {'matchedReference': true},
      );
    }

    final aiService = this.aiService;
    if (aiService == null) {
      return QuestionGrade.unavailable(maxScore);
    }

    final rubric = (solution.rubric == null || solution.rubric!.isEmpty)
        ? _defaultRubric
        : solution.rubric!;

    try {
      final raw = await aiService.chat(
        systemPrompt: _rubricSystemPrompt(rubric),
        userMessage: _rubricUserMessage(
          question: question,
          solution: solution,
          userAnswer: trimmed,
          level: level,
          topic: topic,
        ),
        temperature: 0.2,
        maxTokens: 1600,
        jsonMode: true,
        timeout: const Duration(seconds: 120),
      );

      final decoded = decodeJsonObject(raw);
      if (decoded == null) {
        debugPrint('AI 评分返回非 JSON: $raw');
        return QuestionGrade.unavailable(maxScore);
      }

      return _buildRubricGrade(
        decoded: decoded,
        rubric: rubric,
        maxScore: maxScore,
      );
    } catch (e) {
      debugPrint('AI 评分失败: $e');
      return QuestionGrade.unavailable(maxScore);
    }
  }

  /// 把 AI 的 Rubric 结果收敛成合法分数与结构化反馈
  QuestionGrade _buildRubricGrade({
    required Map<String, dynamic> decoded,
    required Rubric rubric,
    required double maxScore,
  }) {
    final dimensions = <Map<String, dynamic>>[];
    var dimensionSum = 0.0;

    final rawDimensions = decoded['dimensions'];
    if (rawDimensions is List) {
      for (final item in rawDimensions.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        final name = map['name']?.toString() ?? '';
        final maxScoreOfDimension = _asNum(map['maxScore']) ??
            _rubricMaxOf(rubric, name) ??
            0;
        if (maxScoreOfDimension <= 0) continue;
        final score = (_asNum(map['score']) ?? 0)
            .clamp(0.0, maxScoreOfDimension.toDouble());
        dimensionSum += score;
        dimensions.add({
          'name': name,
          'score': score,
          'maxScore': maxScoreOfDimension,
          'feedback': map['feedback']?.toString() ?? '',
        });
      }
    }

    // 模型没给维度分：视为评分失败（不能凭空造分）
    if (dimensions.isEmpty) {
      return QuestionGrade.unavailable(maxScore);
    }

    final rubricMax = dimensions.fold<double>(
      0,
      (sum, d) => sum + (d['maxScore'] as num).toDouble(),
    );
    final ratio = rubricMax <= 0 ? 0.0 : (dimensionSum / rubricMax).clamp(0.0, 1.0);
    final score = double.parse((maxScore * ratio).toStringAsFixed(2));

    final corrections = <Map<String, dynamic>>[];
    final rawCorrections = decoded['corrections'];
    if (rawCorrections is List) {
      for (final item in rawCorrections.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        final original = map['original']?.toString() ?? '';
        final suggestion = map['suggestion']?.toString() ?? '';
        if (original.isEmpty && suggestion.isEmpty) continue;
        corrections.add({
          'original': original,
          'suggestion': suggestion,
          'reason': map['reason']?.toString() ?? '',
          'category': map['category']?.toString() ?? 'grammar',
          'certain': map['certain'] is bool ? map['certain'] : true,
        });
      }
    }

    return QuestionGrade(
      score: score,
      maxScore: maxScore,
      isCorrect: ratio >= 0.9,
      isPartial: ratio > 0 && ratio < 0.9,
      graderType: 'ai',
      feedback: {
        'dimensions': dimensions,
        'corrections': corrections,
        'overallFeedback': decoded['overallFeedback']?.toString() ?? '',
        'ratio': ratio,
      },
    );
  }

  static const Rubric _defaultRubric = Rubric(dimensions: [
    RubricDimension(name: 'grammar', maxScore: 3),
    RubricDimension(name: 'vocabulary', maxScore: 2),
    RubricDimension(name: 'sentenceStructure', maxScore: 2),
    RubricDimension(name: 'taskCompletion', maxScore: 2),
    RubricDimension(name: 'naturalness', maxScore: 1),
  ]);

  static num? _rubricMaxOf(Rubric rubric, String name) {
    for (final d in rubric.dimensions) {
      if (d.name == name) return d.maxScore;
    }
    return null;
  }

  static num? _asNum(dynamic raw) {
    if (raw is num) return raw;
    if (raw is String) return num.tryParse(raw.trim());
    return null;
  }

  String _rubricSystemPrompt(Rubric rubric) {
    final dimensions = rubric.dimensions
        .map((d) => '"${d.name}"（满分 ${d.maxScore}）')
        .join('、');
    return '''
你是严谨的德语写作教师。请按给定维度给学生的德语答案打分，并只返回一个 JSON 对象。

评分维度：$dimensions

要求：
1. 逐维度给分，分数必须在 0 到该维度满分之间，总分不需要你算。
2. 必须区分「确定错误」与「可接受的风格差异」：仅因与参考答案措辞不同不判错。
3. corrections 只列真正的修改建议，给出 original（学生原文片段）、suggestion（修改后）、
   reason（原因）、category（grammar/vocabulary/structure/style）、certain（true=确定错误，false=建议）。
4. ${_feedbackLanguageDirective()}
5. 输出结构：
{
  "dimensions": [{"name": "grammar", "score": 2, "maxScore": 3, "feedback": "具体说明"}],
  "corrections": [{"original": "...", "suggestion": "...", "reason": "...", "category": "grammar", "certain": true}],
  "overallFeedback": "整体评价与改进建议"
}''';
  }

  String _feedbackLanguageDirective() {
    switch (AppLocale.code) {
      case AppLocale.en:
        return 'feedback / reason / overallFeedback 用英文书写；original 与 suggestion 保留德语原文。';
      case AppLocale.de:
        return 'feedback / reason / overallFeedback auf Deutsch; original und suggestion bleiben auf Deutsch.';
      default:
        return 'feedback / reason / overallFeedback 用简体中文书写；original 与 suggestion 保留德语原文。';
    }
  }

  String _rubricUserMessage({
    required PlaybackQuestion question,
    required QuestionSolution solution,
    required String userAnswer,
    required CefrLevel level,
    required String topic,
  }) {
    final buffer = StringBuffer()
      ..writeln('等级：${level.code}')
      ..writeln(topic.isEmpty ? '主题：不限' : '主题：$topic')
      ..writeln('题目要求：${question.prompt}');
    if (question.contextText != null && question.contextText!.isNotEmpty) {
      buffer.writeln('上下文：${question.contextText}');
    }
    if (solution.answerKey.referenceAnswers.isNotEmpty) {
      buffer.writeln('参考答案（仅作参考，不是唯一正确标准）：'
          '${solution.answerKey.referenceAnswers.join(' / ')}');
    }
    buffer.writeln('学生答案：');
    buffer.writeln(userAnswer);
    return buffer.toString();
  }

  // ---- 工具 ----

  static List<int> _parseIndices(String raw) {
    if (raw.trim().isEmpty) return const [];
    return raw
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();
  }

  static bool _sameOrder(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool? _normalizeBool(String raw) {
    final value = raw.trim().toLowerCase();
    if (value == 'true' || value == 'richtig' || value == '正确' || value == '1') {
      return true;
    }
    if (value == 'false' ||
        value == 'falsch' ||
        value == '错误' ||
        value == '0') {
      return false;
    }
    return null;
  }
}
