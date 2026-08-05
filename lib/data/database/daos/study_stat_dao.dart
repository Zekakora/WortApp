import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/study_stats.dart';
import '../tables/words.dart';

part 'study_stat_dao.g.dart';

/// 单词错误统计条目（单词 + 统计汇总）
class StudyStatEntry {
  final int wordId;
  final String german;
  final String chinese;
  final String? article;
  final String? wordType;
  final bool isFavorite;
  final int appearances;
  final int errors;

  const StudyStatEntry({
    required this.wordId,
    required this.german,
    required this.chinese,
    this.article,
    this.wordType,
    this.isFavorite = false,
    required this.appearances,
    required this.errors,
  });

  /// 错误率（出现次数为 0 时按 0 处理）
  double get errorRate => appearances == 0 ? 0 : errors / appearances;
}

/// 每日练习统计 DAO
///
/// 每次答题调用 [recordAttempt] 更新当天记录（出现 +1，错误 +1），
/// 排行榜查询按「今日 / 历史」与「错误次数 / 错误率」维度聚合。
@DriftAccessor(tables: [StudyStats, Words])
class StudyStatDao extends DatabaseAccessor<AppDatabase>
    with _$StudyStatDaoMixin {
  StudyStatDao(super.db);

  /// 记录一次答题：当天出现次数 +1，答错时错误次数 +1
  ///
  /// 同一单词当天首次出现时创建记录，后续累加（wordId + date 唯一）。
  Future<void> recordAttempt({
    required int wordId,
    required bool isError,
  }) {
    return transaction(() async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final existing = await (select(studyStats)
            ..where((t) =>
                t.wordId.equals(wordId) & t.date.equals(today)))
          .getSingleOrNull();

      if (existing == null) {
        await into(studyStats).insert(
          StudyStatsCompanion.insert(
            wordId: wordId,
            date: today,
            appearances: const Value(1),
            errors: Value(isError ? 1 : 0),
          ),
        );
      } else {
        await (update(studyStats)..where((t) => t.id.equals(existing.id)))
            .write(
          StudyStatsCompanion(
            appearances: Value(existing.appearances + 1),
            errors: Value(existing.errors + (isError ? 1 : 0)),
          ),
        );
      }
    });
  }

  /// 获取词书的错误统计
  ///
  /// - [todayOnly] 为 true 时只统计今天，否则聚合全部历史记录
  /// - 同一单词的多日记录会按单词汇总（出现/错误次数求和）
  Future<List<StudyStatEntry>> getStats({
    required int deckId,
    required bool todayOnly,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final sql = StringBuffer('''
      SELECT w.id AS word_id, w.german AS german, w.chinese AS chinese,
             w.article AS article, w.word_type AS word_type,
             w.is_favorite AS is_favorite,
             SUM(s.appearances) AS appearances, SUM(s.errors) AS errors
      FROM study_stats s JOIN words w ON s.word_id = w.id
      WHERE w.deck_id = ?
    ''');
    final variables = <Variable>[Variable.withInt(deckId)];
    if (todayOnly) {
      // 注意：drift 2.31+ 默认以 unix 秒存储 DateTime，
      // 必须用 withDateTime 让 drift 按数据库存储模式自动编码
      sql.write(' AND s.date >= ?');
      variables.add(Variable.withDateTime(today));
    }
    sql.write(' GROUP BY w.id');

    final rows = await customSelect(
      sql.toString(),
      variables: variables,
      readsFrom: {studyStats, words},
    ).get();

    return rows.map((row) {
      final data = row.data;
      return StudyStatEntry(
        wordId: data['word_id'] as int,
        german: data['german'] as String,
        chinese: data['chinese'] as String? ?? '',
        article: data['article'] as String?,
        wordType: data['word_type'] as String?,
        isFavorite: (data['is_favorite'] as int) == 1,
        appearances: data['appearances'] as int,
        errors: data['errors'] as int,
      );
    }).toList();
  }

  /// 删除单词的统计记录
  Future<int> deleteByWordId(int wordId) {
    return (delete(studyStats)..where((t) => t.wordId.equals(wordId))).go();
  }
}
