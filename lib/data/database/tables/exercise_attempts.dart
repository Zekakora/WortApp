import 'package:drift/drift.dart';

/// 逐题答题记录表
///
/// 每题一行（一次练习只允许提交一次，重新练习会生成新的练习记录），
/// [feedbackJson] 保存听写差异 / Rubric 明细等结构化反馈。
class ExerciseAttempts extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get exerciseId => integer()();

  IntColumn get questionId => integer()();

  /// 用户原始答案（自由文本原样保存，不标准化）
  TextColumn get userAnswer => text().withDefault(const Constant(''))();

  RealColumn get score => real().withDefault(const Constant(0))();

  RealColumn get maxScore => real().withDefault(const Constant(1))();

  BoolColumn get isCorrect => boolean().withDefault(const Constant(false))();

  BoolColumn get isPartial => boolean().withDefault(const Constant(false))();

  /// 判分方式：program / ai / unavailable（AI 失败，分数暂不可用）
  TextColumn get graderType => text().withDefault(const Constant('program'))();

  TextColumn get feedbackJson => text().nullable()();

  DateTimeColumn get submittedAt => dateTime()();
}
