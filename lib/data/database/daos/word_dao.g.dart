// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'word_dao.dart';

// ignore_for_file: type=lint
mixin _$WordDaoMixin on DatabaseAccessor<AppDatabase> {
  $DecksTable get decks => attachedDatabase.decks;
  $WordsTable get words => attachedDatabase.words;
  WordDaoManager get managers => WordDaoManager(this);
}

class WordDaoManager {
  final _$WordDaoMixin _db;
  WordDaoManager(this._db);
  $$DecksTableTableManager get decks =>
      $$DecksTableTableManager(_db.attachedDatabase, _db.decks);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
}
