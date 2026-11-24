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

  /// 更新单词学习进度（熟练度 + 上次学习日期）
  ///
  /// 熟练度（proficiency，0-5）由 SM-2 重复次数映射而来，供单词列表星标展示。
  /// 注意：与 [updateLastStudyDate] 一样**不更新 updatedAt**——复习活动属于学习
  /// 通道（由 sm2.updatedAt 记录），不视为内容编辑，避免同步时把“复习”误判为
  /// “词义修改”而触发冲突。
  Future<void> updateLearningProgress({
    required int wordId,
    required int proficiency,
  }) {
    return (update(words)..where((t) => t.id.equals(wordId))).write(
      WordsCompanion(
        proficiency: Value(proficiency),
        lastStudyDate: Value(DateTime.now()),
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
  ///
  /// words.german 无唯一约束，词书内可能存在多条同名词（尤其批量 AI
  /// 规范化后）。此处仅需返回任意一条命中记录，必须 limit(1)，
  /// 否则 getSingleOrNull() 在结果 >1 时会抛 StateError: Too many elements。
  Future<Word?> findWordByGerman(int deckId, String german) {
    return (select(words)
          ..where((t) =>
              t.deckId.equals(deckId) &
              t.german.lower().equals(german.toLowerCase()))
          ..limit(1))
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
  ///
  /// ⚠️ 每次调用都会查询并线性扫描整本词书（O(n)）。**不要在循环里逐词调用**
  /// （会让批量操作退化为 O(n²)，数千词可达分钟级）；批量写入请先用
  /// [canonicalKeyIndexInDeck] 建一次索引，循环内直接查表。
  Future<Word?> findWordByCanonicalKeyInDeck(int deckId, String key) async {
    if (key.isEmpty) return null;
    final inDeck = await (select(words)..where((t) => t.deckId.equals(deckId)))
        .get();
    for (final w in inDeck) {
      if (GermanParser.canonicalKey(w.german) == key) return w;
    }
    return null;
  }

  /// 一次性构建词书内「规范化词形 → 单词」索引，供批量写入复用。
  ///
  /// 同步合并（[BackupMerger.applyToDatabase]）与备份导入（[ImportService.importBackup]）
  /// 都需要对每个单词做“词书内规范化查重”。若逐词调用
  /// [findWordByCanonicalKeyInDeck]，每次都会把整本词书重新查出来线性扫描，
  /// 整体退化为 O(n²)（实测约 2500 词≈118 秒，是同步缓慢的主因）。
  /// 这里一次性构建索引为 O(n)，调用方在循环内直接查表即可。
  ///
  /// 同一规范化词形对应多条记录时保留数据库顺序中最先出现的一条，
  /// 与 [findWordByCanonicalKeyInDeck] 的语义一致。新增单词后请把新词补进
  /// 返回的索引（调用方持有可变 Map）。
  Future<Map<String, Word>> canonicalKeyIndexInDeck(int deckId) async {
    final inDeck = await getWordsByDeck(deckId);
    final index = <String, Word>{};
    for (final w in inDeck) {
      final key = GermanParser.canonicalKey(w.german);
      if (key.isEmpty) continue;
      index.putIfAbsent(key, () => w);
    }
    return index;
  }

  /// 一次性构建词书内「德语原词（小写）→ 单词」索引（不做规范化处理）。
  ///
  /// 删除墓碑按「德语原词精确匹配」传播：词书内规范化去重会删掉与保留词
  /// 规范化词形相同的重复条，若墓碑用规范化 key 匹配，会把保留词一并误删，
  /// 因此墓碑匹配必须精确到原词。
  Future<Map<String, Word>> germanIndexInDeck(int deckId) async {
    final inDeck = await getWordsByDeck(deckId);
    final index = <String, Word>{};
    for (final w in inDeck) {
      final key = w.german.trim().toLowerCase();
      if (key.isEmpty) continue;
      index.putIfAbsent(key, () => w);
    }
    return index;
  }
}
