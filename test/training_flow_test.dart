import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/data/database/daos/exercise_dao.dart';
import 'package:wortapp/data/models/training.dart';
import 'package:wortapp/providers/training_provider.dart';
import 'package:wortapp/services/ai/ai_service.dart';
import 'package:wortapp/services/training/exercise_generator.dart';
import 'package:wortapp/services/training/grading_service.dart';

/// 生成 → 答题 → 提交 的集成链路（用假 AI，不联网）
class _FakeAIService implements AIService {
  final String response;
  int calls = 0;
  bool? lastJsonMode;
  int? lastMaxTokens;

  _FakeAIService(this.response);

  @override
  Future<String> chat({
    required String systemPrompt,
    required String userMessage,
    double temperature = 0.7,
    int maxTokens = 2048,
    bool jsonMode = false,
    Duration? timeout,
  }) async {
    calls++;
    lastJsonMode = jsonMode;
    lastMaxTokens = maxTokens;
    return response;
  }
}

/// 第一次返回坏 JSON、第二次返回好 JSON，用于验证重试
class _RetryAIService implements AIService {
  final String bad;
  final String good;
  int calls = 0;

  _RetryAIService(this.bad, this.good);

  @override
  Future<String> chat({
    required String systemPrompt,
    required String userMessage,
    double temperature = 0.7,
    int maxTokens = 2048,
    bool jsonMode = false,
    Duration? timeout,
  }) async {
    calls++;
    return calls == 1 ? bad : good;
  }
}

String _clozePayload() => '''
{
  "schemaVersion": 1,
  "skill": "reading",
  "exerciseType": "reading_cloze",
  "level": "B1",
  "difficulty": "normal",
  "title": "Mit dem Bus",
  "instructions": "Fülle die Lücken.",
  "stimulus": {"kind": "text", "text": "Anna fährt mit ___ Bus. Sie steigt an der ___ Haltestelle aus."},
  "questions": [
    {
      "id": "q1",
      "questionType": "fill_blank",
      "prompt": "Anna fährt mit ___ Bus.",
      "answerKey": {"acceptedAnswers": ["dem"]},
      "points": 2,
      "explanation": "mit + Dativ"
    },
    {
      "id": "q2",
      "questionType": "fill_blank",
      "prompt": "Sie steigt an der ___ Haltestelle aus.",
      "answerKey": {"acceptedAnswers": ["dritten", "dritten "]},
      "points": 3,
      "explanation": "Ordinalzahl im Dativ"
    }
  ]
}
''';

void main() {
  group('生成链路（假 AI）', () {
    late AppDatabase db;
    late ExerciseDao dao;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      dao = db.exerciseDao;
    });

    tearDown(() async {
      await db.close();
    });

    ExerciseGenerationRequest request({int count = 2}) =>
        ExerciseGenerationRequest(
          type: ExerciseType.readingCloze,
          level: CefrLevel.b1,
          difficulty: TrainingDifficulty.normal,
          topic: '住房',
          questionCount: count,
        );

    test('生成成功即落库，可读取不含答案的答题数据', () async {
      final ai = _FakeAIService(_clozePayload());
      final generator = ExerciseGenerator(
        aiService: ai,
        dao: dao,
        aiModel: 'fake-model',
      );

      final result = await generator.generate(request());

      expect(result.ok, isTrue, reason: result.error);
      expect(ai.calls, 1);
      expect(ai.lastJsonMode, isTrue, reason: '首次尝试应开启 JSON 模式');
      expect(ai.lastMaxTokens! >= 2048, isTrue);

      final playback = await dao.getPlayback(result.exerciseId!);
      expect(playback, isNotNull);
      expect(playback!.questions.length, 2);
      expect(playback.maxScore, 5);
      expect(playback.exercise.promptVersion, 'v1');
      expect(playback.exercise.aiModel, 'fake-model');
    });

    test('坏 JSON 会自动重试一次，成功后不重复落库', () async {
      final ai = _RetryAIService('抱歉，我无法生成。', _clozePayload());
      final generator = ExerciseGenerator(aiService: ai, dao: dao);

      final result = await generator.generate(request());

      expect(result.ok, isTrue, reason: result.error);
      expect(ai.calls, 2);
      expect(await dao.getHistory(includeFailed: true), hasLength(1));
    });

    test('两次都失败时返回可读错误并记录 failed 行', () async {
      final ai = _RetryAIService('不是 JSON', '仍然不是 JSON');
      final generator = ExerciseGenerator(aiService: ai, dao: dao);

      final result = await generator.generate(request());

      expect(result.ok, isFalse);
      expect(result.error, isNotNull);
      expect(await dao.getHistory(includeFailed: true), hasLength(1));
      expect(await dao.getHistory(), isEmpty);
    });

    test('题数不足时按校验失败处理', () async {
      final ai = _FakeAIService(_clozePayload());
      final generator = ExerciseGenerator(aiService: ai, dao: dao);

      final result = await generator.generate(request(count: 5));

      expect(result.ok, isFalse);
      expect(result.error, contains('题目数量不足'));
    });

    test('从生成到提交的完整会话：程序判分并写入结果', () async {
      final ai = _FakeAIService(_clozePayload());
      final generator = ExerciseGenerator(aiService: ai, dao: dao);
      final grading = GradingService();

      final notifier = TrainingSessionNotifier(db, generator, grading);

      final exerciseId = await notifier.start(request());
      expect(exerciseId, isNotNull);
      expect(notifier.state.hasExercise, isTrue);
      expect(notifier.state.total, 2);
      expect(notifier.state.isBusy, isFalse);
      // 听力/阅读的题干都在，但答案不在答题状态里
      expect(notifier.state.answers, isEmpty);

      notifier.setAnswer('q1', 'dem');
      notifier.setAnswer('q2', 'zweiten');
      expect(notifier.state.answeredRatio, 1);

      final submittedId = await notifier.submit();
      expect(submittedId, exerciseId);

      final view = await dao.getResultView(exerciseId!);
      expect(view, isNotNull);
      final first = view!.attemptOf('q1')!;
      final second = view.attemptOf('q2')!;
      expect(first.isCorrect, isTrue);
      expect(first.score, 2);
      expect(second.isCorrect, isFalse);
      expect(second.score, 0);

      final row = await dao.getById(exerciseId);
      expect(row!.status, 'submitted');
      expect(row.totalScore, 2);
      expect(row.maxScore, 5);

      // 提交后草稿被清理
      expect(await db.getSetting('training_draft_$exerciseId'), isNull);
    });

    test('未配置 AI 时给出可读错误而不是抛异常', () async {
      final notifier = TrainingSessionNotifier(db, null, GradingService());
      final id = await notifier.start(request());
      expect(id, isNull);
      expect(notifier.state.error, isNotNull);
    });

    test('草稿保存后可恢复', () async {
      final ai = _FakeAIService(_clozePayload());
      final generator = ExerciseGenerator(aiService: ai, dao: dao);
      final notifier = TrainingSessionNotifier(db, generator, GradingService());

      final id = await notifier.start(request());
      notifier.setAnswer('q1', 'dem');
      await notifier.saveDraft();

      final reopened = TrainingSessionNotifier(db, generator, GradingService());
      await reopened.load(id!);
      expect(reopened.state.answers['q1'], 'dem');
    });
  });
}
