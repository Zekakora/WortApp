import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/algorithms/sm2_algorithm.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/providers/study_provider.dart';

/// 每词「连续答对 X 次才算学会」
void main() {
  late AppDatabase db;
  late StudySessionNotifier notifier;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.deckDao.createDeck(
      DecksCompanion.insert(
        name: '测试词书',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    notifier = StudySessionNotifier(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> addWord(String german) => db.wordDao.createWord(
    WordsCompanion.insert(
      deckId: 1,
      german: german,
      chinese: '释义',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  );

  Future<void> start({int goal = 1}) => notifier.startSession(
    deckId: 1,
    dailyNewLimit: 20,
    dailyReviewLimit: 50,
    roundLimit: 10,
    consecutiveGoal: goal,
  );

  test('goal=1 时保持原有行为：答对一次即通过，无重考队列', () async {
    await addWord('wort1');
    await start();
    expect(notifier.state.consecutiveGoal, 1);

    await notifier.submitFeedback(FeedbackLevel.good);
    final s = notifier.state;
    expect(s.redoQueue, isEmpty);
    expect(s.isCompleted, isTrue);
  });

  test('goal=2 时答对一次还不够，进入重考队列，连对两次才结束', () async {
    final id = await addWord('wort1');
    await start(goal: 2);
    expect(notifier.state.consecutiveGoal, 2);

    // 第 1 次答对：计数 1/2，词回到队列
    await notifier.submitFeedback(FeedbackLevel.good);
    var s = notifier.state;
    expect(s.redoQueue, [id]);
    expect(s.sessionStreak[id], 1);
    expect(s.isCompleted, isFalse);

    // 第 2 次答对：达成 2 次，会话结束
    await notifier.submitFeedback(FeedbackLevel.good);
    s = notifier.state;
    expect(s.sessionStreak[id], 2);
    expect(s.redoQueue, isEmpty);
    expect(s.isCompleted, isTrue);
  });

  test('答错会清零连续计数', () async {
    final id = await addWord('wort1');
    await start(goal: 2);

    await notifier.submitFeedback(FeedbackLevel.good); // 1/2
    expect(notifier.state.sessionStreak[id], 1);

    await notifier.submitFeedback(FeedbackLevel.forgot); // 清零
    expect(notifier.state.sessionStreak[id], 0);
    expect(notifier.state.isCompleted, isFalse);

    await notifier.submitFeedback(FeedbackLevel.good); // 1/2
    expect(notifier.state.sessionStreak[id], 1);
    expect(notifier.state.isCompleted, isFalse);

    await notifier.submitFeedback(FeedbackLevel.good); // 2/2
    expect(notifier.state.sessionStreak[id], 2);
    expect(notifier.state.isCompleted, isTrue);
  });

  test('多个词各自独立计数', () async {
    final first = await addWord('wort1');
    final second = await addWord('wort2');
    await start(goal: 2);

    await notifier.submitFeedback(FeedbackLevel.good); // w1 1/2
    await notifier.submitFeedback(FeedbackLevel.good); // w2 1/2
    var s = notifier.state;
    expect(s.redoQueue, [first, second]);
    expect(s.sessionStreak[first], 1);
    expect(s.sessionStreak[second], 1);

    await notifier.submitFeedback(FeedbackLevel.good); // w1 2/2
    s = notifier.state;
    expect(s.sessionStreak[first], 2);
    expect(s.redoQueue, [second]);

    await notifier.submitFeedback(FeedbackLevel.good); // w2 2/2
    s = notifier.state;
    expect(s.isCompleted, isTrue);
  });
}
