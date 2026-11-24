import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/algorithms/sm2_algorithm.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/providers/study_provider.dart';

/// 随机背词开关测试：
/// - 关闭时按单词本顺序抽取（受每轮单词数截断）
/// - 开启时在截断前打乱词池，抽到哪些词与出现顺序均随机
/// - 切换开关后不恢复旧会话快照，重新抓词
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

  Future<void> start({
    bool randomPick = false,
    int roundLimit = 5,
  }) {
    return notifier.startSession(
      deckId: 1,
      dailyNewLimit: 20,
      dailyReviewLimit: 50,
      roundLimit: roundLimit,
      randomPick: randomPick,
    );
  }

  test('关闭随机背词：按单词本顺序抽取前 N 个', () async {
    final ids = <int>[];
    for (var i = 0; i < 40; i++) {
      ids.add(await addWord('wort$i'));
    }

    await start(randomPick: false, roundLimit: 5);
    final drawn = notifier.state.words.map((w) => w.id).toList();
    expect(drawn, hasLength(5));
    expect(drawn, ids.take(5).toList(), reason: '未开启随机时应按单词本顺序抽取');
  });

  test('开启随机背词：抽词打乱，不再固定为单词本前 N 个', () async {
    final ids = <int>[];
    for (var i = 0; i < 40; i++) {
      ids.add(await addWord('wort$i'));
    }
    final firstFive = ids.take(5).toSet();
    final newPool = ids.take(20).toSet();

    var sawDifferent = false;
    for (var round = 0; round < 20; round++) {
      await start(randomPick: true, roundLimit: 5);
      final drawn = notifier.state.words.map((w) => w.id);
      expect(drawn, hasLength(5));
      expect(drawn.toSet().difference(newPool), isEmpty,
          reason: '抽取的词应来自新词池');
      if (drawn.toSet().difference(firstFive).isNotEmpty) {
        sawDifferent = true;
        break;
      }
    }
    expect(sawDifferent, isTrue,
        reason: '开启随机背词后应出现非单词本前 N 个的抽取结果');
  });

  test('切换随机开关后不恢复旧会话快照，重新抓词', () async {
    for (var i = 0; i < 40; i++) {
      await addWord('wort$i');
    }

    // 关闭随机：学 1 个词，产生会话快照
    await start(randomPick: false, roundLimit: 5);
    await notifier.submitFeedback(FeedbackLevel.good);
    expect(notifier.state.completedCount, 1);

    // 开启随机：视为不同会话，不续学旧快照
    await start(randomPick: true, roundLimit: 5);
    final s = notifier.state;
    expect(s.error, isNull);
    expect(s.currentIndex, 0, reason: '切换随机开关后重新抓词');
    expect(s.completedCount, 0);
  });
}
