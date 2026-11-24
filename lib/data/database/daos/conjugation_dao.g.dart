// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conjugation_dao.dart';

// ignore_for_file: type=lint
mixin _$ConjugationDaoMixin on DatabaseAccessor<AppDatabase> {
  $DecksTable get decks => attachedDatabase.decks;
  $WordsTable get words => attachedDatabase.words;
  $ConjugationCacheTable get conjugationCache =>
      attachedDatabase.conjugationCache;
  ConjugationDaoManager get managers => ConjugationDaoManager(this);
}

class ConjugationDaoManager {
  final _$ConjugationDaoMixin _db;
  ConjugationDaoManager(this._db);
  $$DecksTableTableManager get decks =>
      $$DecksTableTableManager(_db.attachedDatabase, _db.decks);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
  $$ConjugationCacheTableTableManager get conjugationCache =>
      $$ConjugationCacheTableTableManager(
        _db.attachedDatabase,
        _db.conjugationCache,
      );
}
