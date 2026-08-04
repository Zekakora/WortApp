import 'package:drift/drift.dart';
import 'words.dart';

/// 变位缓存表
class ConjugationCache extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wordId => integer().references(Words, #id)();
  TextColumn get conjugationJson => text()(); // 完整变位 JSON
  TextColumn get source => text().withDefault(const Constant('ai'))(); // ai/manual
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {wordId},
      ];
}
