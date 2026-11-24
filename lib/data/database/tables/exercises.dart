import 'package:drift/drift.dart';

/// 训练练习集表（一次生成的整套练习）
///
/// 只存本地：**不参与** JSON 备份与 OneDrive 同步（练习历史不混入 SM-2，
/// 也不进入 decks/words 的同步链路），因此没有墓碑与 LWW 时间戳需求。
class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 技能分类：listening / reading / writing
  TextColumn get skill => text()();

  /// 题型编码（见 ExerciseType.code；改名需做旧记录兼容）
  TextColumn get exerciseType => text()();

  /// CEFR 等级：A1..C2
  TextColumn get level => text()();

  /// 难度：easy / normal / hard
  TextColumn get difficulty => text()();

  /// 主题（中文名，用作 i18n key 与提示词内容）
  TextColumn get topic => text().withDefault(const Constant(''))();

  TextColumn get title => text()();
  TextColumn get instructions => text().withDefault(const Constant(''))();

  /// 材料类型：text / audio / none
  TextColumn get stimulusKind =>
      text().withDefault(const Constant('text'))();

  /// 材料正文（阅读短文 / 听力原文）
  TextColumn get stimulusText => text().withDefault(const Constant(''))();

  /// 状态：ready（已生成待作答）/ submitted（已提交并批改）/ failed
  TextColumn get status => text()();

  IntColumn get totalScore => integer().withDefault(const Constant(0))();

  IntColumn get maxScore => integer().withDefault(const Constant(0))();

  /// 作答耗时（秒），未提交时为 null
  IntColumn get durationSeconds => integer().nullable()();

  TextColumn get errorMessage => text().nullable()();

  /// 生成格式版本（schema）
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  /// 提示词版本（质量排查用）
  TextColumn get promptVersion =>
      text().withDefault(const Constant(''))();

  /// 生成所用模型名（质量排查用，不含任何密钥）
  TextColumn get aiModel => text().withDefault(const Constant(''))();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get submittedAt => dateTime().nullable()();
}
