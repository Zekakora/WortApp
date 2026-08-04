import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/conjugation_cache.dart';

part 'conjugation_dao.g.dart';

@DriftAccessor(tables: [ConjugationCache])
class ConjugationDao extends DatabaseAccessor<AppDatabase>
    with _$ConjugationDaoMixin {
  ConjugationDao(super.db);

  /// 获取单词的变位缓存
  Future<ConjugationCacheData?> getByWordId(int wordId) {
    return (select(conjugationCache)..where((t) => t.wordId.equals(wordId)))
        .getSingleOrNull();
  }

  /// 创建或更新变位缓存
  Future<void> upsert(int wordId, String json, {String source = 'ai'}) {
    return into(conjugationCache).insert(
      ConjugationCacheCompanion.insert(
        wordId: wordId,
        conjugationJson: json,
        source: Value(source),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      onConflict: DoUpdate(
        (old) => ConjugationCacheCompanion(
          conjugationJson: Value(json),
          source: Value(source),
          updatedAt: Value(DateTime.now()),
        ),
        // 必须显式指定冲突目标为 wordId 唯一键，
        // 否则 drift 默认使用主键 id 作为冲突目标，重复保存会抛 2067 唯一约束错误
        target: [conjugationCache.wordId],
      ),
    );
  }

  /// 删除变位缓存
  Future<int> deleteByWordId(int wordId) {
    return (delete(conjugationCache)..where((t) => t.wordId.equals(wordId)))
        .go();
  }

  /// 批量删除多个单词的变位缓存
  Future<int> deleteByWordIds(List<int> wordIds) async {
    if (wordIds.isEmpty) return 0;
    return (delete(conjugationCache)..where((t) => t.wordId.isIn(wordIds)))
        .go();
  }

  /// 获取所有有变位缓存的单词 ID
  Future<List<int>> getCachedWordIds() async {
    final result = await customSelect(
      'SELECT word_id FROM conjugation_cache',
      readsFrom: {conjugationCache},
    ).get();
    return result.map((r) => r.data['word_id'] as int).toList();
  }

  /// 获取词书中所有单词的变位缓存（wordId → 缓存记录）
  Future<Map<int, ConjugationCacheData>> getCachedByDeck(int deckId) async {
    final result = await customSelect(
      'SELECT c.id, c.word_id, c.conjugation_json, c.source, '
      'c.created_at, c.updated_at '
      'FROM conjugation_cache c '
      'INNER JOIN words w ON w.id = c.word_id '
      'WHERE w.deck_id = ?',
      variables: [Variable.withInt(deckId)],
      readsFrom: {conjugationCache, db.words},
    ).get();

    final cacheMap = <int, ConjugationCacheData>{};
    for (final row in result) {
      final data = row.data;
      cacheMap[data['word_id'] as int] = ConjugationCacheData(
        id: data['id'] as int,
        wordId: data['word_id'] as int,
        conjugationJson: data['conjugation_json'] as String,
        source: data['source'] as String,
        createdAt: _asDateTime(data['created_at']),
        updatedAt: _asDateTime(data['updated_at']),
      );
    }
    return cacheMap;
  }

  /// customSelect 返回的日期可能是 DateTime 或整数时间戳，统一转换。
  /// drift 默认将 DateTime 按 Unix 秒存储，读取时需乘以 1000 转毫秒；
  /// 同时兼容部分场景直接返回毫秒时间戳的情况。
  DateTime _asDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is int) {
      final epochMs = value.abs() >= 100000000000 ? value : value * 1000;
      return DateTime.fromMillisecondsSinceEpoch(epochMs);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
