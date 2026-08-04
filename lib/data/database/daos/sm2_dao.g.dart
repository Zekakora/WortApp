// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sm2_dao.dart';

// ignore_for_file: type=lint
mixin _$Sm2DaoMixin on DatabaseAccessor<AppDatabase> {
  $Sm2StatesTable get sm2States => attachedDatabase.sm2States;
  $WordsTable get words => attachedDatabase.words;
  Sm2DaoManager get managers => Sm2DaoManager(this);
}

class Sm2DaoManager {
  final _$Sm2DaoMixin _db;
  Sm2DaoManager(this._db);
  $$Sm2StatesTableTableManager get sm2States =>
      $$Sm2StatesTableTableManager(_db.attachedDatabase, _db.sm2States);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
}
