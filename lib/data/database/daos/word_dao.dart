import 'package:drift/drift.dart';
import '../../../core/utils/german_parser.dart';
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

  /// 获取全部词书中的全部单词（用于全局查重）
  Future<List<Word>> getAllWords() {
    return (select(words)).get();
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

  /// 按 ID 集合批量获取单词（顺序不保证，用于避免逐 ID 查询的 N+1）
  Future<List<Word>> getWordsByIds(List<int> ids) {
    if (ids.isEmpty) return Future.value(const []);
    return (select(words)..where((t) => t.id.isIn(ids))).get();
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
  ///
  /// 必须在 [WordsCompanion] 中携带 `id`；缺失时抛 [ArgumentError]，
  /// 避免 `Value.absent().value` 抛出的晦涩 TypeError 被上层静默吞掉。
  Future<bool> updateWord(WordsCompanion entry) async {
    if (!entry.id.present) {
      throw ArgumentError('updateWord 必须携带 id，实际调用缺少 id 字段');
    }
    final count =
        await (update(words)..where((t) => t.id.equals(entry.id.value)))
            .write(entry);
    return count > 0;
  }

  /// 删除单词
  Future<int> deleteWord(int id) {
    return (delete(words)..where((t) => t.id.equals(id))).go();
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
  /// 注意：不更新 updatedAt——收藏在同步中取并集，无需时间戳，
  /// 且避免收藏动作被误判为词义内容编辑
  Future<void> updateFavorite(int wordId, bool isFavorite) {
    return (update(words)..where((t) => t.id.equals(wordId))).write(
      WordsCompanion(
        isFavorite: Value(isFavorite),
      ),
    );
  }

  /// 更新上次学习日期
  /// 注意：不更新 updatedAt——复习活动属于学习通道（由 sm2.updatedAt 记录），
  /// 不视为内容编辑，避免同步时把“复习”误判为“词义修改”而触发冲突
  Future<void> updateLastStudyDate(int wordId) {
    return (update(words)..where((t) => t.id.equals(wordId))).write(
      WordsCompanion(
        lastStudyDate: Value(DateTime.now()),
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

  /// 全局查重：返回所有词书中第一个规范化词形与 [key] 相同的单词（不分词书）
  ///
  /// 规范化词形见 [GermanParser.canonicalKey]：剥离冠词/复数后缀、保留大小写。
  Future<Word?> findWordByCanonicalKey(String key) async {
    if (key.isEmpty) return null;
    final all = await (select(words)).get();
    for (final w in all) {
      if (GermanParser.canonicalKey(w.german) == key) return w;
    }
    return null;
  }

  /// 词书内查重：返回词书内规范化词形与 [key] 相同的单词
  ///
  /// 与 [findWordByGerman] 的区别：`der Hund` / `Hund` 等带冠词变体会被归为同一词。
  Future<Word?> findWordByCanonicalKeyInDeck(int deckId, String key) async {
    if (key.isEmpty) return null;
    final inDeck = await (select(words)..where((t) => t.deckId.equals(deckId)))
        .get();
    for (final w in inDeck) {
      if (GermanParser.canonicalKey(w.german) == key) return w;
    }
    return null;
  }
}
