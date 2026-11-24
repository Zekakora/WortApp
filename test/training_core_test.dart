import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/data/database/daos/exercise_dao.dart';
import 'package:wortapp/data/models/training.dart';
import 'package:wortapp/services/training/answer_normalizer.dart';
import 'package:wortapp/services/training/dictation_diff.dart';
import 'package:wortapp/services/training/exercise_schema.dart';
import 'package:wortapp/services/training/grading_service.dart';

/// 训练模块核心逻辑测试：标准化、听写差异、Schema 校验、程序判分、持久化
void main() {
  group('AnswerNormalizer', () {
    test('默认不折叠德语变音符号（ä/ö/ü/ß 属于拼写本身）', () {
      expect(
        AnswerNormalizer.matches('fur', ['für']),
        isFalse,
        reason: 'ä→a 不应被当作正确',
      );
      expect(AnswerNormalizer.matches('Masse', ['Maße']), isFalse);
      expect(AnswerNormalizer.matches('für', ['für']), isTrue);
    });

    test('nfkc 之外的全角字符与特殊空格被统一', () {
      expect(
        AnswerNormalizer.normalize('  Ｂｅｒｌｉｎ ', NormalizeOptions.fillBlank),
        'Berlin',
      );
      expect(
        AnswerNormalizer.normalize('hallo\u00a0Welt', NormalizeOptions.fillBlank),
        'hallo Welt',
      );
    });

    test('大小写默认敏感（名词首字母大写计分）', () {
      expect(AnswerNormalizer.matches('haus', ['Haus']), isFalse);
      expect(
        AnswerNormalizer.matches(
          'haus',
          ['Haus'],
          options: const NormalizeOptions(ignoreCase: true),
        ),
        isTrue,
      );
    });

    test('标点差异默认忽略', () {
      expect(
        AnswerNormalizer.matches('Guten Tag', ['Guten Tag!']),
        isTrue,
      );
    });

    test('允许可接受答案列表与显式宽容折叠', () {
      expect(
        AnswerNormalizer.matches('zum Beispiel', ['zum Beispiel', 'z.B.']),
        isTrue,
      );
      expect(
        AnswerNormalizer.matches(
          'Fussball',
          ['Fußball'],
          options: const NormalizeOptions(allowUmlautFolding: true),
        ),
        isTrue,
        reason: '只有显式打开 allowUmlautFolding 才接受 ss/ß 互换',
      );
    });
  });

  group('DictationDiff', () {
    test('完全正确时 accuracy=1 且没有差异', () {
      final result = DictationDiff.compare(
        'Ich gehe heute nach Hause.',
        'Ich gehe heute nach Hause.',
      );
      expect(result.accuracy, 1);
      expect(result.isPerfect, isTrue);
      expect(result.diffs, isEmpty);
    });

    test('漏词与多词分别标记为 missing / extra', () {
      final result = DictationDiff.compare(
        'Ich heute nach Hause',
        'Ich gehe heute nach Hause',
      );
      expect(result.matchedCount, 4);
      expect(result.expectedCount, 5);
      expect(
        result.diffs.any((d) => d.kind == DictationDiffKind.missing),
        isTrue,
      );
      expect(result.accuracy, closeTo(0.8, 0.001));
    });

    test('错词替换并区分拼写近似与实质错词', () {
      final nearMiss = DictationDiff.compare(
        'Ich gehe heute nach Hause',
        'Ich gehe heute nach Hauze',
      );
      expect(nearMiss.diffs.first.kind, DictationDiffKind.spelling);

      final wrong = DictationDiff.compare(
        'Ich gehe heute nach Schule',
        'Ich gehe heute nach Hause',
      );
      expect(wrong.diffs.first.kind, DictationDiffKind.replaced);
    });

    test('大小写差异单列，不当作错词', () {
      final result = DictationDiff.compare(
        'ich gehe heute nach hause',
        'Ich gehe heute nach Hause',
      );
      expect(result.accuracy, 1, reason: '大小写不影响命中，但会单独报告');
      expect(
        result.diffs.every((d) => d.kind == DictationDiffKind.caseOnly),
        isTrue,
      );
      expect(result.diffs.length, 2);
    });
  });

  group('ExerciseSchema', () {
    Map<String, dynamic> readingJson({
      String? answerOverride,
      int questionCount = 2,
      List<String> options = const ['A. eins', 'B. zwei', 'C. drei'],
    }) {
      return {
        'schemaVersion': 1,
        'skill': 'reading',
        'exerciseType': 'reading_comprehension',
        'level': 'B1',
        'difficulty': 'normal',
        'title': 'Eine neue Wohnung',
        'instructions': 'Lies den Text.',
        'stimulus': {'kind': 'text', 'text': 'Anna sucht eine Wohnung ...'},
        'questions': [
          for (var i = 0; i < questionCount; i++)
            {
              'id': 'q${i + 1}',
              'questionType': 'single_choice',
              'prompt': 'Warum sucht Anna eine Wohnung?',
              'options': options,
              'answerKey': answerOverride == null
                  ? {
                      'correctAnswers': ['B']
                    }
                  : {'correctAnswers': [answerOverride]},
              'points': 1,
              'explanation': 'Im Text steht, dass ...',
            },
        ],
      };
    }

    test('合法输出解析成功，答案字母被解析成 0 基下标', () {
      final result = ExerciseSchema.parse(
        readingJson(),
        expectedType: ExerciseType.readingComprehension,
        expectedLevel: CefrLevel.b1,
        expectedDifficulty: TrainingDifficulty.normal,
        expectedTopic: '住房',
        minQuestions: 2,
      );
      expect(result.ok, isTrue, reason: result.issues.join('; '));
      final exercise = result.exercise!;
      expect(exercise.questions.length, 2);
      expect(exercise.questions.first.answerKey.correctIndices, [1]);
      expect(exercise.maxScore, 2);
    });

    test('答案引用不存在的选项时报错', () {
      final result = ExerciseSchema.parse(
        readingJson(answerOverride: 'F'),
        expectedType: ExerciseType.readingComprehension,
        expectedLevel: CefrLevel.b1,
        expectedDifficulty: TrainingDifficulty.normal,
        expectedTopic: '住房',
      );
      expect(result.ok, isFalse);
      expect(
        result.issues.any((i) => i.message.contains('无法定位')),
        isTrue,
      );
    });

    test('题数不足时报错', () {
      final result = ExerciseSchema.parse(
        readingJson(questionCount: 1),
        expectedType: ExerciseType.readingComprehension,
        expectedLevel: CefrLevel.b1,
        expectedDifficulty: TrainingDifficulty.normal,
        expectedTopic: '住房',
        minQuestions: 5,
      );
      expect(result.ok, isFalse);
      expect(result.issues.any((i) => i.message.contains('题目数量不足')), isTrue);
    });

    test('题型声明与实际请求不一致时报错', () {
      final json = readingJson()..['exerciseType'] = 'reading_cloze';
      final result = ExerciseSchema.parse(
        json,
        expectedType: ExerciseType.readingComprehension,
        expectedLevel: CefrLevel.b1,
        expectedDifficulty: TrainingDifficulty.normal,
        expectedTopic: '住房',
      );
      expect(result.ok, isFalse);
    });

    test('完形填空缺少可接受答案时报错', () {
      final json = {
        'skill': 'reading',
        'exerciseType': 'reading_cloze',
        'stimulus': {'kind': 'text', 'text': 'Anna fährt mit ___ Bus.'},
        'questions': [
          {
            'id': 'q1',
            'questionType': 'fill_blank',
            'prompt': 'Anna fährt mit ___ Bus.',
            'answerKey': {'correctAnswers': []},
            'points': 1,
            'explanation': 'mit + Dativ',
          },
        ],
      };
      final result = ExerciseSchema.parse(
        json,
        expectedType: ExerciseType.readingCloze,
        expectedLevel: CefrLevel.a2,
        expectedDifficulty: TrainingDifficulty.easy,
        expectedTopic: '旅行',
      );
      expect(result.ok, isFalse);
    });

    test('排序题答案必须是完整排列', () {
      Map<String, dynamic> orderingJson(List<int> order) => {
            'skill': 'reading',
            'exerciseType': 'paragraph_ordering',
            'stimulus': {'kind': 'text', 'text': '段落材料'},
            'questions': [
              {
                'id': 'q1',
                'questionType': 'ordering',
                'prompt': 'Ordne die Absätze.',
                'answerKey': {'correctOrder': order},
                'points': 2,
                'explanation': '先总后分',
              },
            ],
          };

      final bad = ExerciseSchema.parse(
        orderingJson([0, 0, 1]),
        expectedType: ExerciseType.paragraphOrdering,
        expectedLevel: CefrLevel.b1,
        expectedDifficulty: TrainingDifficulty.normal,
        expectedTopic: '',
      );
      expect(bad.ok, isFalse);

      final good = ExerciseSchema.parse(
        orderingJson([2, 0, 1]),
        expectedType: ExerciseType.paragraphOrdering,
        expectedLevel: CefrLevel.b1,
        expectedDifficulty: TrainingDifficulty.normal,
        expectedTopic: '',
      );
      expect(good.ok, isTrue, reason: good.issues.join('; '));
    });

    test('写作题缺少 rubric 时使用默认五维评分标准', () {
      final json = {
        'skill': 'writing',
        'exerciseType': 'sentence_building',
        'questions': [
          {
            'id': 'q1',
            'questionType': 'free_text',
            'prompt': 'Bilde einen Satz mit: weil / ich / keine Zeit haben',
            'answerKey': {
              'referenceAnswers': ['Weil ich keine Zeit habe, ...']
            },
            'points': 10,
            'explanation': 'weil 引导从句，动词放句末',
          },
        ],
      };
      final result = ExerciseSchema.parse(
        json,
        expectedType: ExerciseType.sentenceBuilding,
        expectedLevel: CefrLevel.b1,
        expectedDifficulty: TrainingDifficulty.normal,
        expectedTopic: '学习',
      );
      expect(result.ok, isTrue, reason: result.issues.join('; '));
      final rubric = result.exercise!.questions.first.rubric;
      expect(rubric, isNotNull);
      expect(rubric!.dimensions.length, 5);
      expect(rubric.maxScore, 10);
    });
  });

  group('GradingService 程序判分', () {
    final service = GradingService();

    PlaybackQuestion question(QuestionType type, {int points = 1}) =>
        PlaybackQuestion(
          key: 'q1',
          orderIndex: 0,
          type: type,
          prompt: 'prompt',
          options: const ['eins', 'zwei', 'drei'],
          points: points,
        );

    test('单选题对错都给满分/零分', () async {
      final solution = const QuestionSolution(
        key: 'q1',
        type: QuestionType.singleChoice,
        answerKey: AnswerKey(correctIndices: [1]),
      );
      final right = await service.grade(
        question: question(QuestionType.singleChoice),
        solution: solution,
        userAnswer: '1',
        level: CefrLevel.b1,
      );
      expect(right.isCorrect, isTrue);
      expect(right.score, 1);

      final wrong = await service.grade(
        question: question(QuestionType.singleChoice),
        solution: solution,
        userAnswer: '0',
        level: CefrLevel.b1,
      );
      expect(wrong.isCorrect, isFalse);
      expect(wrong.score, 0);
    });

    test('多选题全对满分、漏选给部分分、错选扣分', () async {
      final solution = const QuestionSolution(
        key: 'q1',
        type: QuestionType.multipleChoice,
        answerKey: AnswerKey(correctIndices: [0, 1, 2]),
      );
      final full = await service.grade(
        question: question(QuestionType.multipleChoice, points: 3),
        solution: solution,
        userAnswer: '0,1,2',
        level: CefrLevel.b1,
      );
      expect(full.isCorrect, isTrue);
      expect(full.score, 3);

      final partial = await service.grade(
        question: question(QuestionType.multipleChoice, points: 3),
        solution: solution,
        userAnswer: '0,1',
        level: CefrLevel.b1,
      );
      expect(partial.isPartial, isTrue);
      expect(partial.score, closeTo(2, 0.001));

      final withWrong = await service.grade(
        question: question(QuestionType.multipleChoice, points: 3),
        solution: solution,
        userAnswer: '0,1,2,3',
        level: CefrLevel.b1,
      );
      expect(withWrong.isCorrect, isFalse);
      expect(withWrong.score, closeTo(2, 0.001));
    });

    test('填空题接受多个可接受答案，但区分大小写与变音符号', () async {
      final solution = const QuestionSolution(
        key: 'q1',
        type: QuestionType.fillBlank,
        answerKey: AnswerKey(acceptedAnswers: ['dem', 'dem Bus']),
      );
      expect(
        (await service.grade(
          question: question(QuestionType.fillBlank),
          solution: solution,
          userAnswer: 'dem',
          level: CefrLevel.a2,
        ))
            .isCorrect,
        isTrue,
      );
      expect(
        (await service.grade(
          question: question(QuestionType.fillBlank),
          solution: solution,
          userAnswer: 'Dem',
          level: CefrLevel.a2,
        ))
            .isCorrect,
        isFalse,
      );
    });

    test('听写按词级命中率给分并保留差异明细', () async {
      final solution = const QuestionSolution(
        key: 'q1',
        type: QuestionType.dictation,
        answerKey: AnswerKey(
          acceptedAnswers: ['Ich gehe heute nach Hause'],
        ),
      );
      final grade = await service.grade(
        question: question(QuestionType.dictation, points: 10),
        solution: solution,
        userAnswer: 'Ich gehe heute Hause',
        level: CefrLevel.a2,
      );
      expect(grade.isCorrect, isFalse);
      expect(grade.isPartial, isTrue);
      expect(grade.score, closeTo(8, 0.01));
      expect(grade.feedback!['diffs'], isNotNull);
    });

    test('排序题按排列比对，多种有效顺序都算对', () async {
      final solution = const QuestionSolution(
        key: 'q1',
        type: QuestionType.ordering,
        answerKey: AnswerKey(
          correctOrder: [0, 1, 2],
          acceptedOrders: [
            [0, 2, 1]
          ],
        ),
      );
      final ok = await service.grade(
        question: question(QuestionType.ordering, points: 2),
        solution: solution,
        userAnswer: '0,2,1',
        level: CefrLevel.b1,
      );
      expect(ok.isCorrect, isTrue);
      expect(ok.score, 2);

      final bad = await service.grade(
        question: question(QuestionType.ordering, points: 2),
        solution: solution,
        userAnswer: '2,1,0',
        level: CefrLevel.b1,
      );
      expect(bad.isCorrect, isFalse);
    });

    test('写作题与参考答案一致时直接满分，不调用 AI', () async {
      final solution = const QuestionSolution(
        key: 'q1',
        type: QuestionType.freeText,
        answerKey: AnswerKey(
          referenceAnswers: ['Weil ich keine Zeit habe, komme ich nicht.'],
        ),
      );
      final grade = await service.grade(
        question: question(QuestionType.freeText, points: 10),
        solution: solution,
        userAnswer: 'weil ich keine zeit habe komme ich nicht',
        level: CefrLevel.b1,
      );
      expect(grade.isCorrect, isTrue);
      expect(grade.score, 10);
      expect(grade.graderType, 'program');
    });

    test('写作题没有 AI 服务时不伪造分数', () async {
      final solution = const QuestionSolution(
        key: 'q1',
        type: QuestionType.freeText,
        answerKey: AnswerKey(referenceAnswers: ['Ein ganz anderer Satz.']),
      );
      final grade = await service.grade(
        question: question(QuestionType.freeText, points: 10),
        solution: solution,
        userAnswer: 'Ich habe einen Fehler gemacht.',
        level: CefrLevel.b1,
      );
      expect(grade.graderType, 'unavailable');
      expect(grade.score, 0);
    });

    test('空答案直接 0 分，不请求 AI', () async {
      final solution = const QuestionSolution(
        key: 'q1',
        type: QuestionType.freeText,
        answerKey: AnswerKey(),
      );
      final grade = await service.grade(
        question: question(QuestionType.freeText, points: 10),
        solution: solution,
        userAnswer: '   ',
        level: CefrLevel.b1,
      );
      expect(grade.isCorrect, isFalse);
      expect(grade.score, 0);
      expect(grade.feedback!['empty'], isTrue);
    });
  });

  group('ExerciseDao 持久化', () {
    late AppDatabase db;
    late ExerciseDao dao;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = db.exerciseDao;
    });

    tearDown(() async {
      await db.close();
    });

    GeneratedExercise buildExercise() => const GeneratedExercise(
          skill: TrainingSkill.reading,
          exerciseType: ExerciseType.readingCloze,
          level: CefrLevel.b1,
          difficulty: TrainingDifficulty.normal,
          topic: '住房',
          title: 'Mit dem Bus',
          instructions: 'Fülle die Lücken.',
          stimulusKind: 'text',
          stimulusText: 'Anna fährt mit ___ Bus zur Arbeit.',
          questions: [
            GeneratedQuestion(
              key: 'q1',
              type: QuestionType.fillBlank,
              prompt: 'Anna fährt mit ___ Bus zur Arbeit.',
              contextText: 'Anna fährt mit ___ Bus zur Arbeit.',
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
              explanation: 'Ordinalzahl dekliniert',
            ),
          ],
        );

    test('保存后可回读，答题阶段数据不含答案', () async {
      final id = await dao.saveExercise(
        buildExercise(),
        promptVersion: 'v1',
        aiModel: 'test-model',
      );

      final playback = await dao.getPlayback(id);
      expect(playback, isNotNull);
      expect(playback!.questions.length, 2);
      expect(playback.maxScore, 5);
      expect(playback.exercise.status, 'ready');
      expect(playback.questions.first.contextText, contains('___'));
      expect(playback.questions.first.runtimeType, PlaybackQuestion);

      // 答案只在评分侧可取到
      final solutions = await dao.getSolutions(id);
      expect(solutions['q1']!.answerKey.acceptedAnswers, ['dem']);
      expect(solutions['q2']!.answerKey.acceptedAnswers, ['dritten']);
    });

    test('提交后写入逐题记录与汇总分数，历史可查', () async {
      final id = await dao.saveExercise(
        buildExercise(),
        promptVersion: 'v1',
        aiModel: 'test-model',
      );

      await dao.saveSubmission(
        exerciseId: id,
        durationSeconds: 42,
        attempts: const [
          AttemptInput(
            questionKey: 'q1',
            userAnswer: 'dem',
            grade: QuestionGrade(
              score: 2,
              maxScore: 2,
              isCorrect: true,
            ),
          ),
          AttemptInput(
            questionKey: 'q2',
            userAnswer: 'drei',
            grade: QuestionGrade(score: 0, maxScore: 3, isCorrect: false),
          ),
        ],
      );

      final row = await dao.getById(id);
      expect(row!.status, 'submitted');
      expect(row.totalScore, 2);
      expect(row.maxScore, 5);
      expect(row.durationSeconds, 42);

      final result = await dao.getResultView(id);
      expect(result, isNotNull);
      expect(result!.items.length, 2);
      expect(result.attemptOf('q1')!.isCorrect, isTrue);
      expect(result.attemptOf('q2')!.userAnswer, 'drei');

      final history = await dao.getHistory();
      expect(history.length, 1);
      expect(history.first.ratio, closeTo(0.4, 0.001));
    });

    test('失败的生成记录不进历史列表', () async {
      await dao.saveFailure(
        type: ExerciseType.dictation,
        level: CefrLevel.a2,
        difficulty: TrainingDifficulty.easy,
        topic: '日常生活',
        message: 'AI 返回的内容不是有效 JSON',
        promptVersion: 'v1',
        aiModel: 'test-model',
      );
      expect(await dao.getHistory(), isEmpty);
      expect(
        await dao.getHistory(includeFailed: true),
        hasLength(1),
      );
    });

    test('删除练习会级联删掉题目与答题记录', () async {
      final id = await dao.saveExercise(
        buildExercise(),
        promptVersion: 'v1',
        aiModel: 'test-model',
      );
      await dao.saveSubmission(
        exerciseId: id,
        durationSeconds: 5,
        attempts: const [
          AttemptInput(
            questionKey: 'q1',
            userAnswer: 'dem',
            grade: QuestionGrade(score: 2, maxScore: 2, isCorrect: true),
          ),
        ],
      );

      await dao.deleteExercise(id);
      expect(await dao.getById(id), isNull);
      expect(await dao.getPlayback(id), isNull);
      expect(await dao.getHistory(includeFailed: true), isEmpty);
      final attempts = await db.select(db.exerciseAttempts).get();
      expect(attempts, isEmpty);
    });
  });
}
