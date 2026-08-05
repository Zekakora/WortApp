import 'package:drift/drift.dart';
import 'decks.dart';

/// 单词表
class Words extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deckId => integer().references(Decks, #id)();
  TextColumn get german => text().withLength(min: 1, max: 500)();
  TextColumn get article => text().nullable()(); // der/die/das
  TextColumn get baseForm => text().nullable()();
  TextColumn get wordType => text().nullable()(); // noun/verb/adjective/adverb/other
  TextColumn get chinese => text().withLength(min: 0, max: 1000)();
  TextColumn get example => text().nullable()();
  TextColumn get tags => text().nullable()(); // JSON array or comma-separated
  IntColumn get proficiency => integer().withDefault(const Constant(0))(); // 0-5
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))(); // 收藏标记
  DateTimeColumn get lastStudyDate => dateTime().nullable()();
  // 动词三态
  TextColumn get verbPresent => text().nullable()();
  TextColumn get verbPast => text().nullable()();
  TextColumn get verbPerfect => text().nullable()();
  // 名词变形
  TextColumn get nounGenitive => text().nullable()();
  TextColumn get nounPlural => text().nullable()();
  // 名词类型
  TextColumn get nounType => text().nullable()(); // countable/uncountable/both
  // 形容词
  TextColumn get adjComparative => text().nullable()();
  TextColumn get adjSuperlative => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}
