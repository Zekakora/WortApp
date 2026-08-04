import 'package:drift/drift.dart';
import 'words.dart';

/// SM-2 算法状态表
class Sm2States extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wordId => integer().references(Words, #id)();
  IntColumn get repetitionN => integer().withDefault(const Constant(0))();
  RealColumn get intervalDays => real().withDefault(const Constant(0.0))();
  RealColumn get easeFactor => real().withDefault(const Constant(2.5))();
  DateTimeColumn get nextReview => dateTime()();
  DateTimeColumn get lastReview => dateTime().nullable()();
  IntColumn get totalReviews => integer().withDefault(const Constant(0))();
  IntColumn get correctStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {wordId},
      ];
}
