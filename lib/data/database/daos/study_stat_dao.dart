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

  /// 获取词书中「今日错词」的单词 id 集合
  ///
  /// 今日错词判定：今天有答题记录，且正确次数（出现次数 - 错误次数）
  /// 少于 [minCorrect]（默认 3 次）。用于学习模式「只抓今日错词」
  /// 抓词策略，与错误统计排行榜共用 study_stats 数据。
  Future<Set<int>> getTodayWeakWordIds({
    required int deckId,
    int minCorrect = 3,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rows = await customSelect(
      '''
      SELECT w.id AS word_id
      FROM study_stats s JOIN words w ON s.word_id = w.id
      WHERE w.deck_id = ? AND s.date >= ?
      GROUP BY w.id
      HAVING SUM(s.appearances) - SUM(s.errors) < ?
      ''',
      variables: [
        Variable.withInt(deckId),
        Variable.withDateTime(today),
        Variable.withInt(minCorrect),
      ],
      readsFrom: {studyStats, words},
    ).get();
    return rows.map((row) => row.data['word_id'] as int).toSet();
  }

  /// 获取词书中「今日答错过」的单词 id 集合
  ///
  /// 今日答错过判定：今天有答题记录且错误次数（忘记/模糊）> 0。
  /// 学习模式「只抓今日错词」以此为准：只有真正答错过（忘记/模糊）的
  /// 词才进入错词复习，答对不会把词挤出列表；毕业标准由复习轮次
  /// 「连续干净轮数」控制（见 StudySessionNotifier）。
  Future<Set<int>> getTodayWrongWordIds({required int deckId}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rows = await customSelect(
      '''
      SELECT w.id AS word_id
      FROM study_stats s JOIN words w ON s.word_id = w.id
      WHERE w.deck_id = ? AND s.date >= ?
      GROUP BY w.id
      HAVING SUM(s.errors) > 0
      ''',
      variables: [
        Variable.withInt(deckId),
        Variable.withDateTime(today),
      ],
      readsFrom: {studyStats, words},
    ).get();
    return rows.map((row) => row.data['word_id'] as int).toSet();
  }

  /// 获取所有有学习记录的日期（去重、降序），用于连续打卡统计
  ///
  /// 打卡判定：只要当天有过任意答题记录（recordAttempt 写入）即视为已打卡。
  Future<List<DateTime>> getDistinctStudyDates() async {
    final rows = await (select(studyStats)
          ..orderBy([(t) => OrderingTerm.desc(t.date)]))
        .get();
    // 同一日期可能有多条记录（不同单词），按日期去重
    return rows.map((r) => r.date).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
  }

  /// 删除单词的统计记录
  Future<int> deleteByWordId(int wordId) {
    return (delete(studyStats)..where((t) => t.wordId.equals(wordId))).go();
  }
}
