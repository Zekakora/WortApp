import 'package:drift/drift.dart';

/// 训练题目表
///
/// 答案（[answerKeyJson]）与解析（[explanation]）和题干存在同一行，
/// 但**只允许评分链路读取**：`ExerciseDao` 对外只提供两个入口，
/// 答题阶段用 `getPlayback`（不含答案），提交后才用 `getSolutions`。
class ExerciseQuestions extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 所属练习（删除练习时由 DAO 手工级联删除，与项目现有写法一致）
  IntColumn get exerciseId => integer()();

  /// 题目在练习内的稳定 key（AI 侧的 q1/q2…），用于把答题记录对回题目
  TextColumn get questionKey => text()();

  /// 展示顺序（0 基）
  IntColumn get orderIndex => integer()();

  /// 题干类型：single_choice / multiple_choice / true_false / fill_blank
  /// / dictation / ordering / free_text
  TextColumn get questionType => text()();

  TextColumn get prompt => text()();

  /// 题目附带的上下文（如完形填空所在句子）
  TextColumn get contextText => text().nullable()();

  /// 选项列表（JSON 数组；非选择题为空数组）
  TextColumn get optionsJson => text().withDefault(const Constant('[]'))();

  /// 标准答案 / 可接受答案（JSON，见 AnswerKey）
  TextColumn get answerKeyJson => text().withDefault(const Constant('{}'))();

  IntColumn get points => integer().withDefault(const Constant(1))();

  /// 解析（结果页展示）
  TextColumn get explanation => text().withDefault(const Constant(''))();

  /// 开放式题目的评分维度（JSON，见 Rubric）
  TextColumn get rubricJson => text().nullable()();
}
