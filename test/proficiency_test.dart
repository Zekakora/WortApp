import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wortapp/data/database/app_database.dart';

/// 验证 SM-2 反馈提交会把熟练度（words.proficiency）与 SM-2 重复次数联动，
/// 供单词列表星标展示（修复此前 proficiency 恒为 0 的死字段问题）。
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.deckDao.createDeck(DecksCompanion.insert(
      name: '测试词书',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> addWord(String german) {
    return db.wordDao.createWord(WordsCompanion.insert(
      deckId: 1,
      german: german,
      chinese: '释义',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  Future<int> proficiencyOf(int wordId) async {
    final word = await db.wordDao.getWordById(wordId);
    return word!.proficiency;
  }

  test('首次答对：重复次数 1 → 熟练度 1，同时刷新上次学习日期', () async {
    final id = await addWord('Haus');

    await db.submitStudyFeedback(wordId: id, quality: 4);

    expect(await proficiencyOf(id), 1);
    final word = await db.wordDao.getWordById(id);
    expect(word!.lastStudyDate, isNotNull);
  });

  test('连续答对：熟练度随 SM-2 重复次数递增并封顶 5', () async {
    final id = await addWord('Haus');

    for (var i = 0; i < 6; i++) {
      await db.submitStudyFeedback(wordId: id, quality: 4);
    }

    // 6 次答对 → repetitionN = 6，熟练度封顶 5
    expect(await proficiencyOf(id), 5);
  });

  test('答错（忘记）：重复次数清零 → 熟练度归零', () async {
    final id = await addWord('Haus');
    for (var i = 0; i < 3; i++) {
      await db.submitStudyFeedback(wordId: id, quality: 5);
    }
    expect(await proficiencyOf(id), 3);

    await db.submitStudyFeedback(wordId: id, quality: 0);

    expect(await proficiencyOf(id), 0);
  });

  test('答错（模糊）保留重复序列，熟练度不下降', () async {
    final id = await addWord('Haus');
    for (var i = 0; i < 3; i++) {
      await db.submitStudyFeedback(wordId: id, quality: 4);
    }
    expect(await proficiencyOf(id), 3);

    // 模糊（quality=2）保留 repetitionN，熟练度保持
    await db.submitStudyFeedback(wordId: id, quality: 2);

    expect(await proficiencyOf(id), 3);
  });

  test('重置学习进度后熟练度归零', () async {
    final id = await addWord('Haus');
    await db.submitStudyFeedback(wordId: id, quality: 5);
    expect(await proficiencyOf(id), 1);

    await db.resetAllLearningProgress();

    expect(await proficiencyOf(id), 0);
  });
}
