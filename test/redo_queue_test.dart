import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/algorithms/sm2_algorithm.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/providers/study_provider.dart';

/// 错词重考测试：答错（忘记/模糊）的单词在主列表学完后进入重考队列，
/// 按先进先出重考，答对移出；重考次数超限后放弃；循环模式不使用重考。
void main() {
  late AppDatabase db;
  late StudySessionNotifier notifier;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.deckDao.createDeck(DecksCompanion.insert(
      name: '测试词书',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    notifier = StudySessionNotifier(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> addWord(String german) async {
    return db.wordDao.createWord(WordsCompanion.insert(
      deckId: 1,
      german: german,
      chinese: '释义',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  Future<void> startNormal({int roundLimit = 10}) async {
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 20,
      dailyReviewLimit: 50,
      roundLimit: roundLimit,
    );
  }

  test('答错的单词主列表学完后进入重考，答对后会话结束', () async {
    for (var i = 0; i < 3; i++) {
      await addWord('wort$i');
    }
    await startNormal();

    var s = notifier.state;
    expect(s.error, isNull);
    expect(s.isLooping, isFalse);
    expect(s.words, hasLength(3));
    final missedId = s.words.first.id;

    // 第 1 词答错（忘记）
    await notifier.submitFeedback(FeedbackLevel.forgot);
    s = notifier.state;
    expect(s.redoQueue, [missedId], reason: '答错的词进入重考队列');
    expect(s.isCompleted, isFalse, reason: '还有重考词未答，会话未结束');

    // 第 2、3 词答对
    await notifier.submitFeedback(FeedbackLevel.good);
    await notifier.submitFeedback(FeedbackLevel.good);
    s = notifier.state;
    expect(s.isRedoPhase, isTrue, reason: '主列表学完进入重考阶段');
    expect(s.currentWord?.id, missedId, reason: '重考队首是被答错的词');
    expect(s.progressTitle, contains('重考'), reason: '标题提示重考剩余词数');

    // 重考答对 → 会话结束
    await notifier.submitFeedback(FeedbackLevel.good);
    s = notifier.state;
    expect(s.redoQueue, isEmpty);
    expect(s.isCompleted, isTrue);
    expect(s.completedCount, 4, reason: '3 词 + 1 次重考');
  });

  test('重考阶段再答错回到队尾，超过重考上限后放弃', () async {
    for (var i = 0; i < 2; i++) {
      await addWord('wort$i');
    }
    await startNormal();

    final missedId = notifier.state.words.first.id;

    // 第 1 词答错 → 进入重考队列
    await notifier.submitFeedback(FeedbackLevel.forgot);
    // 第 2 词答对 → 主列表学完，进入重考
    await notifier.submitFeedback(FeedbackLevel.good);
    expect(notifier.state.isRedoPhase, isTrue);

    // 重考再答错 → 回到队尾（第 2 次重考）
    await notifier.submitFeedback(FeedbackLevel.forgot);
    var s = notifier.state;
    expect(s.redoQueue, [missedId]);
    expect(s.redoRetries[missedId], 2, reason: '累计重考 2 次');

    // 重考第 3 次答错 → 超过上限（maxRedoRetries=2）放弃，会话结束
    await notifier.submitFeedback(FeedbackLevel.forgot);
    s = notifier.state;
    expect(s.redoQueue, isEmpty, reason: '超限后放弃该词');
    expect(s.redoRetries.containsKey(missedId), isFalse);
    expect(s.isCompleted, isTrue);
  });

  test('重考答对即移出队列，不再重复出现', () async {
    for (var i = 0; i < 3; i++) {
      await addWord('wort$i');
    }
    await startNormal();

    final ids = notifier.state.words.map((w) => w.id).toList();
    // 全部答错：3 个词都进入重考队列（顺序与主列表一致）
    for (final _ in ids) {
      await notifier.submitFeedback(FeedbackLevel.hard);
    }
    var s = notifier.state;
    expect(s.isRedoPhase, isTrue);
    expect(s.redoQueue.toSet(), ids.toSet());

    // 依次重考答对：每次移出队首
    while (!s.isCompleted) {
      final id = s.currentWord?.id;
      await notifier.submitFeedback(FeedbackLevel.good);
      s = notifier.state;
      if (id != null) {
        expect(s.redoQueue.contains(id), isFalse, reason: '答对的词已移出重考队列');
      }
    }
    expect(s.completedCount, 6, reason: '3 词首轮 + 3 次重考');
  });

  test('循环复习模式不使用错词重考', () async {
    final now = DateTime.now();
    for (var i = 0; i < 3; i++) {
      final id = await addWord('wort$i');
      await db.sm2Dao.createState(Sm2StatesCompanion.insert(
        wordId: id,
        repetitionN: const drift.Value(1),
        intervalDays: const drift.Value(1),
        easeFactor: const drift.Value(2.5),
        nextReview: DateTime.now().add(const Duration(days: 1)),
        createdAt: now,
        updatedAt: now,
      ));
      await db.wordDao.updateLastStudyDate(id);
    }
    await startNormal();

    var s = notifier.state;
    expect(s.isLooping, isTrue);
    await notifier.submitFeedback(FeedbackLevel.forgot);
    s = notifier.state;
    expect(s.redoQueue, isEmpty, reason: '循环模式每大轮覆盖全部单词，无需重考');
    expect(s.isRedoPhase, isFalse);
  });

  test('全部答对的会话不产生重考', () async {
    for (var i = 0; i < 3; i++) {
      await addWord('wort$i');
    }
    await startNormal();

    for (var i = 0; i < 3; i++) {
      await notifier.submitFeedback(FeedbackLevel.good);
    }
    final s = notifier.state;
    expect(s.redoQueue, isEmpty);
    expect(s.isCompleted, isTrue);
    expect(s.completedCount, 3);
  });

  test('模糊（hard）同样触发重考', () async {
    for (var i = 0; i < 2; i++) {
      await addWord('wort$i');
    }
    await startNormal();

    final missedId = notifier.state.words.first.id;
    await notifier.submitFeedback(FeedbackLevel.hard);
    expect(notifier.state.redoQueue, [missedId]);
    expect(notifier.state.accuracy, 0, reason: '模糊计为错误');

    await notifier.submitFeedback(FeedbackLevel.good);
    expect(notifier.state.isRedoPhase, isTrue);
  });
}
