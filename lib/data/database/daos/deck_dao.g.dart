// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deck_dao.dart';

// ignore_for_file: type=lint
mixin _$DeckDaoMixin on DatabaseAccessor<AppDatabase> {
  $DecksTable get decks => attachedDatabase.decks;
  $WordsTable get words => attachedDatabase.words;
  $Sm2StatesTable get sm2States => attachedDatabase.sm2States;
  $ConjugationCacheTable get conjugationCache =>
      attachedDatabase.conjugationCache;
  DeckDaoManager get managers => DeckDaoManager(this);
}

class DeckDaoManager {
  final _$DeckDaoMixin _db;
  DeckDaoManager(this._db);
  $$DecksTableTableManager get decks =>
      $$DecksTableTableManager(_db.attachedDatabase, _db.decks);
  $$WordsTableTableManager get words =>
      $$WordsTableTableManager(_db.attachedDatabase, _db.words);
  $$Sm2StatesTableTableManager get sm2States =>
      $$Sm2StatesTableTableManager(_db.attachedDatabase, _db.sm2States);
  $$ConjugationCacheTableTableManager get conjugationCache =>
      $$ConjugationCacheTableTableManager(
        _db.attachedDatabase,
        _db.conjugationCache,
      );
}
