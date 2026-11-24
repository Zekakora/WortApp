// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_stat_dao.dart';

// ignore_for_file: type=lint
mixin _$StudyStatDaoMixin on DatabaseAccessor<AppDatabase> {
  $DecksTable get decks => attachedDatabase.decks;
  $WordsTable get words => attachedDatabase.words;
  $StudyStatsTable get studyStats => attachedDatabase.studyStats;
  StudyStatDaoManager get managers => StudyStatDaoManager(this);
}

class StudyStatDaoManager {
  final _$StudyStatDaoMixin _db;
  StudyStatDaoManager(this._db);
  $$DecksTableTableManager get decks =>
      $$DecksTableTableManager(_db.attachedDatabase, _db.decks);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
  $$StudyStatsTableTableManager get studyStats =>
      $$StudyStatsTableTableManager(_db.attachedDatabase, _db.studyStats);
}
