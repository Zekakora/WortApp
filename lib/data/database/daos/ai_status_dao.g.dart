// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_status_dao.dart';

// ignore_for_file: type=lint
mixin _$AiStatusDaoMixin on DatabaseAccessor<AppDatabase> {
  $AiRequestStatusTable get aiRequestStatus => attachedDatabase.aiRequestStatus;
  AiStatusDaoManager get managers => AiStatusDaoManager(this);
}

class AiStatusDaoManager {
  final _$AiStatusDaoMixin _db;
  AiStatusDaoManager(this._db);
  $$AiRequestStatusTableTableManager get aiRequestStatus =>
      $$AiRequestStatusTableTableManager(
        _db.attachedDatabase,
        _db.aiRequestStatus,
      );
}
