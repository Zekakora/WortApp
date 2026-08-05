// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_stat_dao.dart';

// ignore_for_file: type=lint
mixin _$StudyStatDaoMixin on DatabaseAccessor<AppDatabase> {
  $StudyStatsTable get studyStats => attachedDatabase.studyStats;
  $WordsTable get words => attachedDatabase.words;
  StudyStatDaoManager get managers => StudyStatDaoManager(this);
}

class StudyStatDaoManager {
  final _$StudyStatDaoMixin _db;
  StudyStatDaoManager(this._db);
  $$StudyStatsTableTableManager get studyStats =>
      $$StudyStatsTableTableManager(_db.attachedDatabase, _db.studyStats);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
}
