import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/words.dart';

part 'word_dao.g.dart';

@DriftAccessor(tables: [Words])
class WordDao extends DatabaseAccessor<AppDatabase> with _$WordDaoMixin {
  WordDao(super.db);

  /// 获取词书中所有单词
  Future<List<Word>> getWordsByDeck(int deckId) {
    return (select(words)..where((t) => t.deckId.equals(deckId))).get();
  }

  /// 从所有词库中随机抽取 [limit] 个单词（用于四选一模式的干扰项选项池）
  Future<List<Word>> getRandomWords(int limit) {
    return (select(words)
          ..orderBy([(t) => OrderingTerm.random()])
          ..limit(limit))
        .get();
  }

  /// 监听词书中单词变化
  Stream<List<Word>> watchWordsByDeck(int deckId) {
    return (select(words)..where((t) => t.deckId.equals(deckId))).watch();
  }

  /// 根据 ID 获取单词
  Future<Word?> getWordById(int id) {
    return (select(words)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 搜索单词（德语或中文）
  Future<List<Word>> searchWords(int deckId, String query) {
    final q = '%${query.toLowerCase()}%';
    return (select(words)
          ..where((t) =>
              t.deckId.equals(deckId) &
              (t.german.lower().like(q) | t.chinese.lower().like(q))))
        .get();
  }

  /// 创建单词
  Future<int> createWord(WordsCompanion entry) {
    return into(words).insert(entry);
  }

  /// 批量创建单词
  Future<void> createWordsBatch(List<WordsCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(words, entries);
    });
  }

  /// 更新单词，返回是否更新成功
  Future<bool> updateWord(WordsCompanion entry) async {
    final count =
        await (update(words)..where((t) => t.id.equals(entry.id.value)))
            .write(entry);
    return count > 0;
  }

  /// 删除单词
  Future<int> deleteWord(int id) {
    return (delete(words)..where((t) => t.id.equals(id))).go();
  }

  /// 删除词书中所有单词
  Future<int> deleteWordsByDeck(int deckId) {
    return (delete(words)..where((t) => t.deckId.equals(deckId))).go();
  }

  /// 获取词书中单词数量
  Future<int> getWordCount(int deckId) async {
    final count = await customSelect(
      'SELECT COUNT(*) as cnt FROM words WHERE deck_id = ?',
      variables: [Variable.withInt(deckId)],
      readsFrom: {words},
    ).getSingle();
    return count.data['cnt'] as int;
  }

  /// 更新单词熟练程度
  Future<void> updateProficiency(int wordId, int proficiency) {
    return (update(words)..where((t) => t.id.equals(wordId))).write(
      WordsCompanion(
        proficiency: Value(proficiency),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 更新单词收藏状态
  Future<void> updateFavorite(int wordId, bool isFavorite) {
    return (update(words)..where((t) => t.id.equals(wordId))).write(
      WordsCompanion(
        isFavorite: Value(isFavorite),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 更新上次学习日期
  Future<void> updateLastStudyDate(int wordId) {
    return (update(words)..where((t) => t.id.equals(wordId))).write(
      WordsCompanion(
        lastStudyDate: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// 获取今日学习过的单词（用于每日新词/复习上限均用尽后继续复习）
  Future<List<Word>> getTodayStudiedWords(int deckId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return (select(words)
          ..where((t) =>
              t.deckId.equals(deckId) &
              t.lastStudyDate.isBiggerOrEqualValue(today)))
        .get();
  }

  /// 根据德国原词查找单词（用于词书内查重）
  Future<Word?> findWordByGerman(int deckId, String german) {
    return (select(words)
          ..where((t) =>
              t.deckId.equals(deckId) &
              t.german.lower().equals(german.toLowerCase())))
        .getSingleOrNull();
  }

  /// 获取词书中所有不重复的词性
  Future<List<String>> getWordTypes(int deckId) async {
    final result = await customSelect(
      'SELECT DISTINCT word_type FROM words WHERE deck_id = ? AND word_type IS NOT NULL',
      variables: [Variable.withInt(deckId)],
      readsFrom: {words},
    ).get();
    return result.map((r) => r.data['word_type'] as String).toList();
  }
}
