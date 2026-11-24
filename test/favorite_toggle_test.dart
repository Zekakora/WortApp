import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';
import 'package:wortapp/providers/study_provider.dart';

/// 学习会话内切换收藏：落库并即时刷新当前会话单词状态
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

  test('切换收藏落库并刷新会话内单词', () async {
    await addWord('Haus');
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 20,
      dailyReviewLimit: 50,
    );

    final wordId = notifier.state.words.single.id;
    expect(notifier.state.currentWord!.isFavorite, isFalse);

    await notifier.toggleFavorite(wordId);
    expect(notifier.state.currentWord!.isFavorite, isTrue,
        reason: '会话内单词状态即时刷新');
    final persisted = await db.wordDao.getWordById(wordId);
    expect(persisted!.isFavorite, isTrue, reason: '收藏已落库');

    await notifier.toggleFavorite(wordId);
    expect(notifier.state.currentWord!.isFavorite, isFalse);
  });

  test('收藏不更新单词 updatedAt（同步中收藏取并集，不被误判为内容编辑）', () async {
    await addWord('Haus');
    await notifier.startSession(
      deckId: 1,
      dailyNewLimit: 20,
      dailyReviewLimit: 50,
    );

    final wordId = notifier.state.words.single.id;
    final before = (await db.wordDao.getWordById(wordId))!.updatedAt;
    await notifier.toggleFavorite(wordId);
    final after = (await db.wordDao.getWordById(wordId))!.updatedAt;
    expect(after, before, reason: '收藏不应刷新 updatedAt');
  });
}
