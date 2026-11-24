import 'dart:convert';

import 'package:drift/drift.dart';

import '../../../data/models/training.dart';
import '../../../services/training/exercise_schema.dart';
import '../app_database.dart';
import '../tables/exercise_attempts.dart';
import '../tables/exercise_questions.dart';
import '../tables/exercises.dart';

part 'exercise_dao.g.dart';

/// 答题阶段的数据包：**只有题干，没有答案**
class ExercisePlayback {
  final Exercise exercise;
  final List<PlaybackQuestion> questions;

  const ExercisePlayback({required this.exercise, required this.questions});

  int get maxScore =>
      questions.fold(0, (sum, q) => sum + q.points);

  ExerciseType get type => ExerciseType.fromCode(exercise.exerciseType);
}

/// 单题 + 答案（仅提交后可见）
class ExerciseQuestionView {
  final PlaybackQuestion question;
  final QuestionSolution solution;

  const ExerciseQuestionView({
    required this.question,
    required this.solution,
  });
}

/// 结果页数据包：题目 + 答案 + 解析 + 用户答案与判分
class ExerciseResultView {
  final Exercise exercise;
  final List<ExerciseQuestionView> items;
  final Map<String, ExerciseAttempt> attemptsByKey;

  const ExerciseResultView({
    required this.exercise,
    required this.items,
    required this.attemptsByKey,
  });

  ExerciseAttempt? attemptOf(String questionKey) =>
      attemptsByKey[questionKey];
}

/// 一次提交里单题的批改结果
class AttemptInput {
  final String questionKey;
  final String userAnswer;
  final QuestionGrade grade;

  const AttemptInput({
    required this.questionKey,
    required this.userAnswer,
    required this.grade,
  });
}

/// 训练练习 DAO
///
/// 职责边界：
/// - 答题页只能拿到 [getPlayback]（无答案），避免"提交前泄露正确答案"；
/// - [getResultView] / [getSolutions] 只在提交后调用；
/// - 练习历史只存本地，不参与备份与同步。
@DriftAccessor(tables: [Exercises, ExerciseQuestions, ExerciseAttempts])
class ExerciseDao extends DatabaseAccessor<AppDatabase>
    with _$ExerciseDaoMixin {
  ExerciseDao(super.db);

  // ---- 写入 ----

  /// 保存一份新生成的练习（练习 + 题目，事务）
  Future<int> saveExercise(
    GeneratedExercise generated, {
    required String promptVersion,
    required String aiModel,
  }) {
    return transaction(() async {
      final exerciseId = await into(exercises).insert(
        ExercisesCompanion.insert(
          skill: generated.skill.code,
          exerciseType: generated.exerciseType.code,
          level: generated.level.code,
          difficulty: generated.difficulty.code,
          topic: Value(generated.topic),
          title: generated.title,
          instructions: Value(generated.instructions),
          stimulusKind: Value(generated.stimulusKind),
          stimulusText: Value(generated.stimulusText),
          status: 'ready',
          maxScore: Value(generated.maxScore),
          schemaVersion: Value(ExerciseSchema.currentVersion),
          promptVersion: Value(promptVersion),
          aiModel: Value(aiModel),
          createdAt: DateTime.now(),
        ),
      );

      for (var index = 0; index < generated.questions.length; index++) {
        final q = generated.questions[index];
        await into(exerciseQuestions).insert(
          ExerciseQuestionsCompanion.insert(
            exerciseId: exerciseId,
            questionKey: q.key,
            orderIndex: index,
            questionType: q.type.code,
            prompt: q.prompt,
            contextText: Value(q.contextText),
            optionsJson: Value(jsonEncode(q.options)),
            answerKeyJson: Value(jsonEncode(q.answerKey.toJson())),
            points: Value(q.points),
            explanation: Value(q.explanation),
            rubricJson: Value(q.rubric == null || q.rubric!.isEmpty
                ? null
                : jsonEncode(q.rubric!.toJson())),
          ),
        );
      }

      return exerciseId;
    });
  }

  /// 记录生成失败（保留失败记录便于排查，不进入历史列表）
  Future<int> saveFailure({
    required ExerciseType type,
    required CefrLevel level,
    required TrainingDifficulty difficulty,
    required String topic,
    required String message,
    required String promptVersion,
    required String aiModel,
  }) {
    return into(exercises).insert(
      ExercisesCompanion.insert(
        skill: type.skill.code,
        exerciseType: type.code,
        level: level.code,
        difficulty: difficulty.code,
        topic: Value(topic),
        title: type.titleZh,
        status: 'failed',
        errorMessage: Value(message),
        promptVersion: Value(promptVersion),
        aiModel: Value(aiModel),
        createdAt: DateTime.now(),
      ),
    );
  }

  /// 保存一次提交的批改结果（逐题记录 + 汇总，事务）
  Future<void> saveSubmission({
    required int exerciseId,
    required List<AttemptInput> attempts,
    required int durationSeconds,
  }) {
    return transaction(() async {
      final questions = await (select(exerciseQuestions)
            ..where((t) => t.exerciseId.equals(exerciseId)))
          .get();
      final byKey = {
        for (final q in questions) q.questionKey: q,
      };

      var totalScore = 0.0;
      var maxScore = 0.0;
      final now = DateTime.now();

      for (final input in attempts) {
        final question = byKey[input.questionKey];
        if (question == null) continue;
        maxScore += input.grade.maxScore;
        totalScore += input.grade.score;
        await into(exerciseAttempts).insert(
          ExerciseAttemptsCompanion.insert(
            exerciseId: exerciseId,
            questionId: question.id,
            userAnswer: Value(input.userAnswer),
            score: Value(input.grade.score),
            maxScore: Value(input.grade.maxScore),
            isCorrect: Value(input.grade.isCorrect),
            isPartial: Value(input.grade.isPartial),
            graderType: Value(input.grade.graderType),
            feedbackJson: Value(input.grade.feedback == null
                ? null
                : jsonEncode(input.grade.feedback)),
            submittedAt: now,
          ),
        );
      }

      await (update(exercises)..where((t) => t.id.equals(exerciseId))).write(
        ExercisesCompanion(
          status: const Value('submitted'),
          totalScore: Value(totalScore.round()),
          maxScore: Value(maxScore.round()),
          submittedAt: Value(now),
          durationSeconds: Value(durationSeconds),
        ),
      );
    });
  }

  // ---- 读取（答题阶段：无答案） ----

  Future<Exercise?> getById(int exerciseId) =>
      (select(exercises)..where((t) => t.id.equals(exerciseId)))
          .getSingleOrNull();

  /// 答题用：只返回题干与选项，**不含答案与解析**
  Future<ExercisePlayback?> getPlayback(int exerciseId) async {
    final row = await getById(exerciseId);
    if (row == null) return null;
    final rows = await (select(exerciseQuestions)
          ..where((t) => t.exerciseId.equals(exerciseId))
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .get();
    return ExercisePlayback(
      exercise: row,
      questions: rows.map((r) {
        final type = QuestionType.fromCode(r.questionType);
        return PlaybackQuestion(
          key: r.questionKey,
          orderIndex: r.orderIndex,
          type: type,
          prompt: r.prompt,
          options: _decodeStringList(r.optionsJson),
          // 听写题：句子只作为朗读文本，不作为可展示上下文，避免"答案显示在题面上"
          contextText: type == QuestionType.dictation ? null : r.contextText,
          audioText: type == QuestionType.dictation ? r.contextText : null,
          points: r.points,
        );
      }).toList(),
    );
  }

  // ---- 读取（提交后：含答案） ----

  /// 评分用：题目 key → 答案与解析
  Future<Map<String, QuestionSolution>> getSolutions(int exerciseId) async {
    final rows = await (select(exerciseQuestions)
          ..where((t) => t.exerciseId.equals(exerciseId))
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .get();
    return {
      for (final r in rows)
        r.questionKey: QuestionSolution(
          key: r.questionKey,
          type: QuestionType.fromCode(r.questionType),
          answerKey: _decodeAnswerKey(r.answerKeyJson),
          explanation: r.explanation,
          rubric: r.rubricJson == null ? null : _decodeRubric(r.rubricJson!),
        ),
    };
  }

  /// 结果页用：题目 + 答案 + 用户答案与判分
  Future<ExerciseResultView?> getResultView(int exerciseId) async {
    final playback = await getPlayback(exerciseId);
    if (playback == null) return null;

    final solutionRows = await (select(exerciseQuestions)
          ..where((t) => t.exerciseId.equals(exerciseId))
          ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]))
        .get();
    final attemptRows = await (select(exerciseAttempts)
          ..where((t) => t.exerciseId.equals(exerciseId)))
        .get();
    final questionById = {
      for (final r in solutionRows) r.id: r.questionKey,
    };

    return ExerciseResultView(
      exercise: playback.exercise,
      items: [
        for (final q in playback.questions)
          ExerciseQuestionView(
            question: q,
            solution: QuestionSolution(
              key: q.key,
              type: q.type,
              answerKey: _decodeAnswerKey(
                solutionRows
                    .firstWhere((r) => r.questionKey == q.key)
                    .answerKeyJson,
              ),
              explanation: solutionRows
                  .firstWhere((r) => r.questionKey == q.key)
                  .explanation,
              rubric: _rubricOf(solutionRows, q.key),
            ),
          ),
      ],
      attemptsByKey: {
        for (final a in attemptRows)
          if (questionById[a.questionId] != null)
            questionById[a.questionId]!: a,
      },
    );
  }

  Rubric? _rubricOf(List<ExerciseQuestion> rows, String key) {
    for (final row in rows) {
      if (row.questionKey == key && row.rubricJson != null) {
        return _decodeRubric(row.rubricJson!);
      }
    }
    return null;
  }

  /// 历史列表（默认按时间倒序；可按技能筛选）
  Future<List<ExerciseHistoryEntry>> getHistory({
    TrainingSkill? skill,
    bool includeFailed = false,
    int limit = 200,
  }) async {
    final query = select(exercises);
    if (skill != null) {
      query.where((t) => t.skill.equals(skill.code));
    }
    if (!includeFailed) {
      query.where((t) => t.status.equals('submitted'));
    }
    query
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
      ..limit(limit);

    final rows = await query.get();
    return rows.map(_toEntry).toList();
  }

  /// 未完成的练习（已生成未提交，可继续作答）
  Future<List<ExerciseHistoryEntry>> getUnfinished({int limit = 20}) async {
    final rows = await (select(exercises)
          ..where((t) => t.status.equals('ready'))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
    return rows.map(_toEntry).toList();
  }

  static ExerciseHistoryEntry _toEntry(Exercise r) => ExerciseHistoryEntry(
        id: r.id,
        skill: TrainingSkill.fromCode(r.skill),
        exerciseType: ExerciseType.fromCode(r.exerciseType),
        level: CefrLevel.fromCode(r.level),
        difficulty: TrainingDifficulty.fromCode(r.difficulty),
        topic: r.topic,
        title: r.title,
        status: r.status,
        totalScore: r.totalScore,
        maxScore: r.maxScore,
        createdAt: r.createdAt,
        submittedAt: r.submittedAt,
      );

  /// 最近一次已提交的练习（用于首页"继续 / 再练一次"）
  Future<ExerciseHistoryEntry?> getLatest({TrainingSkill? skill}) async {
    final list = await getHistory(skill: skill, limit: 1);
    return list.isEmpty ? null : list.first;
  }

  /// 统计各技能的已提交练习数
  Future<Map<TrainingSkill, int>> countBySkill() async {
    final rows = await customSelect(
      "SELECT skill, COUNT(*) AS c FROM exercises WHERE status = 'submitted' GROUP BY skill",
      readsFrom: {exercises},
    ).get();
    final result = <TrainingSkill, int>{};
    for (final row in rows) {
      result[TrainingSkill.fromCode(row.data['skill'] as String)] =
          row.data['c'] as int;
    }
    return result;
  }

  // ---- 删除 ----

  /// 删除一次练习及其题目、答题记录（练习历史仅本地，删除即彻底删除）
  Future<void> deleteExercise(int exerciseId) {
    return transaction(() async {
      await (delete(exerciseAttempts)
            ..where((t) => t.exerciseId.equals(exerciseId)))
          .go();
      await (delete(exerciseQuestions)
            ..where((t) => t.exerciseId.equals(exerciseId)))
          .go();
      await (delete(exercises)..where((t) => t.id.equals(exerciseId))).go();
    });
  }

  /// 清空全部训练历史
  Future<void> deleteAll() {
    return transaction(() async {
      await delete(exerciseAttempts).go();
      await delete(exerciseQuestions).go();
      await delete(exercises).go();
    });
  }

  // ---- JSON 解码 ----

  static List<String> _decodeStringList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {
      // 忽略损坏数据，按空列表处理
    }
    return const [];
  }

  static AnswerKey _decodeAnswerKey(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return AnswerKey.fromJson(decoded);
      if (decoded is Map) {
        return AnswerKey.fromJson(Map<String, dynamic>.from(decoded));
      }
    } catch (_) {
      // 忽略损坏数据
    }
    return AnswerKey.empty;
  }

  static Rubric? _decodeRubric(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return Rubric.fromJson(decoded);
      if (decoded is Map) return Rubric.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      // 忽略损坏数据
    }
    return null;
  }
}
