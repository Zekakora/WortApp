import 'package:drift/drift.dart';

/// AI 释义请求状态表
///
/// 记录每个单词最近一次 AI 释义请求的结果（成功/失败），
/// 供「数据管理」页面展示与一键重试。
/// 与 ai_lookup_cache 一样以「单词原文 + 引擎」为唯一键，
/// 同一单词在不同词书间共享同一份状态。
class AiRequestStatus extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get word => text().withLength(min: 1, max: 500)();
  TextColumn get engine => text().withDefault(const Constant('ai'))(); // 引擎类型
  TextColumn get status => text()(); // success / failed
  TextColumn get errorMessage => text().nullable()(); // 失败原因（可选）
  DateTimeColumn get lastRequestAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {word, engine},
      ];
}
