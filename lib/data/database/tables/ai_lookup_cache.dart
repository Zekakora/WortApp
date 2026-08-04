import 'package:drift/drift.dart';

/// AI查词缓存表
class AiLookupCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get word => text().withLength(min: 1, max: 500)();
  TextColumn get resultJson => text()(); // 完整的AI查词结果JSON
  TextColumn get engine => text().withDefault(const Constant('ai'))(); // 引擎类型
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {word, engine},
      ];
}
