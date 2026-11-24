import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/data/database/daos/exercise_dao.dart';
import 'package:wortapp/data/models/training.dart';
import 'package:wortapp/data/models/writing_knowledge.dart';
import 'package:wortapp/services/training/writing_insight.dart';

/// 错题重练（本地克隆）与写作知识点统计
void main() {
  group('错题重练', () {
    late AppDatabase db;
    late ExerciseDao dao;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = db.exerciseDao;
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> saveExercise() => dao.saveExercise(
      const GeneratedExercise(
        skill: TrainingSkill.reading,
        exerciseType: ExerciseType.readingCloze,
        level: CefrLevel.b1,
        difficulty: TrainingDifficulty.normal,
        topic: '住房',
        title: 'Mit dem Bus',
        instructions: 'Fülle die Lücken.',
        stimulusKind: 'text',
        stimulusText: 'Anna fährt mit ___ Bus.',
        questions: [
          GeneratedQuestion(
            key: 'q1',
            type: QuestionType.fillBlank,
            prompt: 'Anna fährt mit ___ Bus.',
            points: 2,
            answerKey: AnswerKey(acceptedAnswers: ['dem']),
            explanation: 'mit + Dativ',
          ),
          GeneratedQuestion(
            key: 'q2',
            type: QuestionType.fillBlank,
            prompt: 'Sie steigt an der ___ Haltestelle aus.',
            points: 3,
            answerKey: AnswerKey(acceptedAnswers: ['dritten']),
            explanation: 'Ordinalzahl',
          ),
        ],
      ),
      promptVersion: 'v1',
      aiModel: 'test',
    );

    test('只克隆答错的题，新练习可直接作答，原练习不变', () async {
      final originalId = await saveExercise();
      await dao.saveSubmission(
        exerciseId: originalId,
        durationSeconds: 30,
        attempts: const [
          AttemptInput(
            questionKey: 'q1',
            userAnswer: 'dem',
            grade: QuestionGrade(score: 2, maxScore: 2, isCorrect: true),
          ),
          AttemptInput(
            questionKey: 'q2',
            userAnswer: 'dritte',
            grade: QuestionGrade(score: 0, maxScore: 3, isCorrect: false),
          ),
        ],
      );

      final newId = await dao.cloneWrongQuestions(originalId);
      expect(newId, isNotNull);
      expect(newId, isNot(originalId));

      final playback = await dao.getPlayback(newId!);
      expect(playback, isNotNull);
      expect(playback!.questions.length, 1, reason: '只带走错题 q2');
      expect(playback.questions.first.key, 'q2');
      expect(playback.maxScore, 3);
      expect(playback.exercise.status, 'ready');
      expect(playback.exercise.stimulusText, contains('Anna fährt'));

      // 答案一起复制，重做后还能正常批改
      final solutions = await dao.getSolutions(newId);
      expect(solutions['q2']!.answerKey.acceptedAnswers, ['dritten']);

      // 原练习仍是已提交状态，分数不变
      final original = await dao.getById(originalId);
      expect(original!.status, 'submitted');
      expect(original.totalScore, 2);
    });

    test('全对时没有错题可克隆', () async {
      final originalId = await saveExercise();
      await dao.saveSubmission(
        exerciseId: originalId,
        durationSeconds: 10,
        attempts: const [
          AttemptInput(
            questionKey: 'q1',
            userAnswer: 'dem',
            grade: QuestionGrade(score: 2, maxScore: 2, isCorrect: true),
          ),
          AttemptInput(
            questionKey: 'q2',
            userAnswer: 'dritten',
            grade: QuestionGrade(score: 3, maxScore: 3, isCorrect: true),
          ),
        ],
      );
      expect(await dao.cloneWrongQuestions(originalId), isNull);
    });

    test('部分正确的题也会进入错题练习', () async {
      final originalId = await saveExercise();
      await dao.saveSubmission(
        exerciseId: originalId,
        durationSeconds: 10,
        attempts: const [
          AttemptInput(
            questionKey: 'q1',
            userAnswer: 'den',
            grade: QuestionGrade(
              score: 1,
              maxScore: 2,
              isCorrect: false,
              isPartial: true,
            ),
          ),
          AttemptInput(
            questionKey: 'q2',
            userAnswer: 'dritten',
            grade: QuestionGrade(score: 3, maxScore: 3, isCorrect: true),
          ),
        ],
      );
      final newId = await dao.cloneWrongQuestions(originalId);
      expect(newId, isNotNull);
      final playback = await dao.getPlayback(newId!);
      expect(playback!.questions.map((q) => q.key), ['q1']);
    });
  });

  group('写作知识点统计', () {
    WritingAttemptRow row({
      required int exerciseId,
      required DateTime createdAt,
      required List<Map<String, dynamic>> corrections,
    }) {
      return WritingAttemptRow(
        attempt: ExerciseAttempt(
          id: exerciseId * 10,
          exerciseId: exerciseId,
          questionId: exerciseId,
          userAnswer: 'text',
          score: 3,
          maxScore: 10,
          isCorrect: false,
          isPartial: true,
          graderType: 'ai',
          feedbackJson: jsonEncode({'corrections': corrections}),
          submittedAt: createdAt,
        ),
        exerciseId: exerciseId,
        exerciseType: 'sentence_building',
        createdAt: createdAt,
      );
    }

    test('按知识点聚合次数，并保留最近一次例子', () {
      final rows = [
        row(
          exerciseId: 1,
          createdAt: DateTime(2026, 11, 20),
          corrections: [
            {
              'original': 'Wenn ich Zeit hätte, würde ich kommen.',
              'suggestion': 'Wenn ich Zeit hätte, käme ich.',
              'reason': 'Konjunktiv II',
              'knowledge': 'konjunktiv_ii',
            },
            {
              'original': 'ich gehe',
              'suggestion': 'Ich gehe',
              'reason': '大写',
              'knowledge': 'spelling',
            },
          ],
        ),
        row(
          exerciseId: 2,
          createdAt: DateTime(2026, 11, 24),
          corrections: [
            {
              'original': 'er hat gegangen',
              'suggestion': 'er ist gegangen',
              'reason': '助动词',
              'knowledge': 'verb_tense',
            },
            {
              'original': 'wenn ich Zeit hätte',
              'suggestion': 'hätte ich Zeit',
              'reason': '语序',
              'knowledge': 'konjunktiv_ii',
            },
          ],
        ),
      ];

      final insight = buildWritingKnowledgeInsight(rows);

      expect(insight.exerciseCount, 2);
      expect(insight.attemptCount, 2);
      expect(insight.correctionCount, 4);
      expect(insight.points.first.knowledge, WritingKnowledge.konjunktivII);
      expect(insight.points.first.count, 2);
      // 例子取最近那条
      expect(insight.points.first.lastOriginal, 'wenn ich Zeit hätte');
      expect(insight.points.first.lastSeen, DateTime(2026, 11, 24));
      expect(
        insight.points.map((p) => p.knowledge),
        containsAll([
          WritingKnowledge.konjunktivII,
          WritingKnowledge.spelling,
          WritingKnowledge.verbTense,
        ]),
      );
    });

    test('未知知识点归入「其他」，空数据返回空统计', () {
      final insight = buildWritingKnowledgeInsight([
        row(
          exerciseId: 3,
          createdAt: DateTime(2026, 11, 24),
          corrections: [
            {'original': 'a', 'suggestion': 'b', 'knowledge': 'not_a_code'},
          ],
        ),
      ]);
      expect(insight.points.single.knowledge, WritingKnowledge.other);

      final empty = buildWritingKnowledgeInsight(const []);
      expect(empty.isEmpty, isTrue);
      expect(empty.correctionCount, 0);
    });

    test('损坏的 feedback 不会让统计崩溃', () {
      final insight = buildWritingKnowledgeInsight([
        WritingAttemptRow(
          attempt: ExerciseAttempt(
            id: 1,
            exerciseId: 1,
            questionId: 1,
            userAnswer: '',
            score: 0,
            maxScore: 10,
            isCorrect: false,
            isPartial: false,
            graderType: 'ai',
            feedbackJson: '{not json',
            submittedAt: DateTime(2026, 11, 24),
          ),
          exerciseId: 1,
          exerciseType: 'free_writing',
          createdAt: DateTime(2026, 11, 24),
        ),
      ]);
      expect(insight.isEmpty, isTrue);
      expect(insight.exerciseCount, 1);
    });
  });
}
