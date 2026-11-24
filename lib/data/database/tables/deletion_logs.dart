import 'package:drift/drift.dart';

/// 删除墓碑表（跨端删除传播用）
///
/// 用户删除单词/词书时在此记录一条"墓碑"（词书名 + 德语原词 + 删除时间），
/// 随备份同步到其他设备；对端根据"该词最后活动时间"决定是否执行删除：
/// - 删除后对端仍在复习/编辑（活动晚于删除时间）→ 驳回删除，词保留
/// - 删除后对端重建了同名词（创建时间晚于删除时间）→ 驳回删除
/// - 否则 → 执行删除（墓碑继续保留，供其他设备传播）
///
/// [german] 为空字符串表示整词书删除。
class DeletionLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deckName => text()();
  TextColumn get german => text().withDefault(const Constant(''))();
  DateTimeColumn get deletedAt => dateTime()();
}
