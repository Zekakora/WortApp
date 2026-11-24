import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/models/training.dart';
import 'package:wortapp/services/training/exercise_schema.dart';

/// 混合练习：一套题里允许听力/语法/写作多种题干类型
void main() {
  group('混合练习 Schema', () {
    test('允许出现的题干类型覆盖全部 7 种', () {
      expect(
        ExerciseSchema.allowedQuestionTypes(ExerciseType.mixedPractice),
        {
          QuestionType.singleChoice,
          QuestionType.multipleChoice,
          QuestionType.trueFalse,
          QuestionType.fillBlank,
          QuestionType.dictation,
          QuestionType.ordering,
          QuestionType.freeText,
        },
      );
    });

    test('不需要统一材料（听写/填空各自带句子）', () {
      expect(ExerciseSchema.needsStimulus(ExerciseType.mixedPractice), isFalse);
    });

    test('听写 + 填空 + 写作混合解析成功，判分方式按每题类型区分', () {
      final json = {
        'schemaVersion': 1,
        'skill': 'mixed',
        'exerciseType': 'mixed_practice',
        'level': 'B1',
        'difficulty': 'normal',
        'title': 'Gemischt üben',
        'instructions': 'Bearbeite alle Aufgaben.',
        'stimulus': {'kind': 'none', 'text': ''},
        'questions': [
          {
            'id': 'q1',
            'questionType': 'dictation',
            'prompt': 'Schreibe den Satz, den du hörst.',
            'context': 'Ich fahre morgen mit dem Zug nach Berlin.',
            'answerKey': {
              'acceptedAnswers': ['Ich fahre morgen mit dem Zug nach Berlin.'],
            },
            'points': 1,
            'explanation': '听写整句',
          },
          {
            'id': 'q2',
            'questionType': 'fill_blank',
            'prompt': 'Ich warte ___ den Bus.',
            'answerKey': {
              'acceptedAnswers': ['auf'],
            },
            'points': 1,
            'explanation': 'warten auf + Akkusativ',
          },
          {
            'id': 'q3',
            'questionType': 'free_text',
            'prompt': 'Bilde einen Satz mit: weil / ich / keine Zeit haben',
            'answerKey': {
              'referenceAnswers': ['Weil ich keine Zeit habe, komme ich nicht.'],
            },
            'points': 10,
            'explanation': 'weil 从句动词放句末',
          },
        ],
      };

      final result = ExerciseSchema.parse(
        json,
        expectedType: ExerciseType.mixedPractice,
        expectedLevel: CefrLevel.b1,
        expectedDifficulty: TrainingDifficulty.normal,
        expectedTopic: '学习',
        minQuestions: 3,
      );

      expect(result.ok, isTrue, reason: result.issues.join('; '));
      final exercise = result.exercise!;
      expect(exercise.questions.length, 3);
      expect(exercise.skill, TrainingSkill.mixed);
      expect(
        exercise.questions.map((q) => q.type),
        [QuestionType.dictation, QuestionType.fillBlank, QuestionType.freeText],
      );
      // 客观题 1+1、写作 10
      expect(exercise.maxScore, 12);
      // 写作题自动拿到默认评分标准
      expect(exercise.questions.last.rubric, isNotNull);
    });
  });
}
