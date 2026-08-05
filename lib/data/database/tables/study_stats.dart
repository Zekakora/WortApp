import 'package:drift/drift.dart';
import 'words.dart';

/// 每日单词练习统计表
///
/// 每个单词每天一条记录：记录当天出现次数（appearances）与
/// 错误次数（errors，忘记/模糊计为错误），用于学习模式底部
/// 的错误统计排行榜（今日/历史）。
class StudyStats extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wordId => integer().references(Words, #id)();
  /// 学习日期（当天 00:00:00）
  DateTimeColumn get date => dateTime()();
  /// 当天出现次数
  IntColumn get appearances => integer().withDefault(const Constant(0))();
  /// 当天错误次数
  IntColumn get errors => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {wordId, date},
      ];
}
