// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conjugation_dao.dart';

// ignore_for_file: type=lint
mixin _$ConjugationDaoMixin on DatabaseAccessor<AppDatabase> {
  $ConjugationCacheTable get conjugationCache =>
      attachedDatabase.conjugationCache;
  ConjugationDaoManager get managers => ConjugationDaoManager(this);
}

class ConjugationDaoManager {
  final _$ConjugationDaoMixin _db;
  ConjugationDaoManager(this._db);
  $$ConjugationCacheTableTableManager get conjugationCache =>
      $$ConjugationCacheTableTableManager(
        _db.attachedDatabase,
        _db.conjugationCache,
      );
}
