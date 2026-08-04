// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_cache_dao.dart';

// ignore_for_file: type=lint
mixin _$AiCacheDaoMixin on DatabaseAccessor<AppDatabase> {
  $AiLookupCacheTable get aiLookupCache => attachedDatabase.aiLookupCache;
  AiCacheDaoManager get managers => AiCacheDaoManager(this);
}

class AiCacheDaoManager {
  final _$AiCacheDaoMixin _db;
  AiCacheDaoManager(this._db);
  $$AiLookupCacheTableTableManager get aiLookupCache =>
      $$AiLookupCacheTableTableManager(_db.attachedDatabase, _db.aiLookupCache);
}
