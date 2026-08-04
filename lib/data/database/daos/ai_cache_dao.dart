import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/ai_lookup_cache.dart';

part 'ai_cache_dao.g.dart';

@DriftAccessor(tables: [AiLookupCache])
class AiCacheDao extends DatabaseAccessor<AppDatabase> with _$AiCacheDaoMixin {
  AiCacheDao(super.db);

  /// 获取缓存的AI查词结果
  Future<AiLookupCacheData?> getCachedResult(String word, {String engine = 'ai'}) async {
    return (select(aiLookupCache)
          ..where((t) => t.word.equals(word) & t.engine.equals(engine))
          ..limit(1))
        .getSingleOrNull();
  }

  /// 保存AI查词结果到缓存
  Future<void> saveToCache({
    required String word,
    required String resultJson,
    String engine = 'ai',
  }) async {
    final now = DateTime.now();
    await into(aiLookupCache).insert(
      AiLookupCacheCompanion.insert(
        word: word,
        resultJson: resultJson,
        engine: Value(engine),
        createdAt: now,
        updatedAt: now,
      ),
      onConflict: DoUpdate(
        (old) => AiLookupCacheCompanion(
          resultJson: Value(resultJson),
          updatedAt: Value(now),
        ),
        // 必须显式指定冲突目标为 (word, engine) 唯一键，
        // 否则 drift 默认使用主键 id 作为冲突目标，重复保存会抛 2067 唯一约束错误
        target: [aiLookupCache.word, aiLookupCache.engine],
      ),
    );
  }

  /// 删除缓存
  Future<void> deleteCache(String word, {String engine = 'ai'}) async {
    await (delete(aiLookupCache)
          ..where((t) => t.word.equals(word) & t.engine.equals(engine)))
        .go();
  }

  /// 清空所有缓存
  Future<void> clearAll() async {
    await delete(aiLookupCache).go();
  }
}
