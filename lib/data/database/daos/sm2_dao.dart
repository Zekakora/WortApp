import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sm2_states.dart';
import '../tables/words.dart';

part 'sm2_dao.g.dart';

@DriftAccessor(tables: [Sm2States, Words])
class Sm2Dao extends DatabaseAccessor<AppDatabase> with _$Sm2DaoMixin {
  Sm2Dao(super.db);

  /// 获取单词的 SM-2 状态
  Future<Sm2State?> getStateByWordId(int wordId) {
    return (select(sm2States)..where((t) => t.wordId.equals(wordId)))
        .getSingleOrNull();
  }

  /// 创建 SM-2 状态
  Future<int> createState(Sm2StatesCompanion entry) {
    return into(sm2States).insert(entry);
  }

  /// 更新 SM-2 状态
  Future<bool> updateState(Sm2StatesCompanion entry) {
    return update(sm2States).replace(entry);
  }

  /// 获取今日待复习单词数量
  Future<int> getDueReviewCount() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final count = await customSelect(
      'SELECT COUNT(*) as cnt FROM sm2_states WHERE next_review <= ?',
      // 注意：drift 2.31+ 默认以 unix 秒存储 DateTime，
      // 必须用 withDateTime 让 drift 按数据库存储模式自动编码（不能用毫秒）
      variables: [Variable.withDateTime(today)],
      readsFrom: {sm2States},
    ).getSingle();
    return count.data['cnt'] as int;
  }

  /// 获取今日待复习的单词 ID 列表
  Future<List<int>> getDueReviewWordIds({int? limit}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final query = select(sm2States)
      ..where((t) => t.nextReview.isSmallerOrEqualValue(today))
      ..orderBy([(t) => OrderingTerm.asc(t.nextReview)]);
    if (limit != null) {
      query.limit(limit);
    }
    final states = await query.get();
    return states.map((s) => s.wordId).toList();
  }

  /// 获取新词（没有 SM-2 状态的单词）的 ID 列表
  Future<List<int>> getNewWordIds(int deckId, {int? limit}) async {
    final sql = StringBuffer(
      'SELECT w.id FROM words w LEFT JOIN sm2_states s ON w.id = s.word_id WHERE w.deck_id = ? AND s.id IS NULL',
    );
    final variables = <Variable>[Variable.withInt(deckId)];
    if (limit != null) {
      sql.write(' LIMIT ?');
      variables.add(Variable.withInt(limit));
    }
    final result = await customSelect(
      sql.toString(),
      variables: variables,
      readsFrom: {words, sm2States},
    ).get();
    return result.map((r) => r.data['id'] as int).toList();
  }

  /// 获取今日首次学习（作为新词）的单词数量
  ///
  /// 首次学习时 sm2_states.created_at 即创建时间，用于扣除"每日新词上限"
  /// 中今日已学数量，确保多次进入学习模式不会超限抽取新词
  Future<int> getTodayNewStudiedCount(int deckId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = await customSelect(
      'SELECT COUNT(*) as cnt FROM sm2_states s '
      'JOIN words w ON s.word_id = w.id '
      'WHERE w.deck_id = ? AND s.created_at >= ?',
      // 注意：drift 2.31+ 默认以 unix 秒存储 DateTime，
      // 必须用 withDateTime 让 drift 按数据库存储模式自动编码（不能用毫秒）
      variables: [
        Variable.withInt(deckId),
        Variable.withDateTime(today),
      ],
      readsFrom: {sm2States, words},
    ).getSingle();
    return result.data['cnt'] as int;
  }

  /// 获取今日复习（非首次）的单词数量
  ///
  /// 用于扣除"每日复习上限"中今日已学数量，确保多次进入学习模式不会超限
  Future<int> getTodayReviewStudiedCount(int deckId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = await customSelect(
      'SELECT COUNT(*) as cnt FROM sm2_states s '
      'JOIN words w ON s.word_id = w.id '
      'WHERE w.deck_id = ? AND s.created_at < ? AND s.last_review >= ?',
      // 注意：drift 2.31+ 默认以 unix 秒存储 DateTime，
      // 必须用 withDateTime 让 drift 按数据库存储模式自动编码（不能用毫秒）
      variables: [
        Variable.withInt(deckId),
        Variable.withDateTime(today),
        Variable.withDateTime(today),
      ],
      readsFrom: {sm2States, words},
    ).getSingle();
    return result.data['cnt'] as int;
  }

  /// 删除单词的 SM-2 状态
  Future<int> deleteByWordId(int wordId) {
    return (delete(sm2States)..where((t) => t.wordId.equals(wordId))).go();
  }

  /// 删除词书中所有 SM-2 状态
  Future<void> deleteByDeckId(int deckId) async {
    // 注意：customStatement 的参数是原始值列表，不能传 Variable 对象（Web 端会报 Unknown db value）
    await customStatement(
      'DELETE FROM sm2_states WHERE word_id IN (SELECT id FROM words WHERE deck_id = ?)',
      [deckId],
    );
  }
}
