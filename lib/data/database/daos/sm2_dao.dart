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
      variables: [Variable.withInt(today.millisecondsSinceEpoch)],
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
