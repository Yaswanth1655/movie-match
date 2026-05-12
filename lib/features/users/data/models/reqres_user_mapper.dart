import 'package:basic_app/core/database/app_database.dart';
import 'package:basic_app/features/users/data/models/reqres_api_models.dart';
import 'package:drift/drift.dart';

extension ReqresUserDtoMapper on ReqresUserDto {
  /// Maps API user row into local Drift upsert (server-backed user).
  UsersCompanion toUsersCompanion() {
    return UsersCompanion.insert(
      firstName: firstName,
      lastName: Value(lastName),
      avatar: Value(avatar),
      email: Value(email),
      serverId: Value(id > 0 ? id : null),
      pendingSync: const Value(false),
    );
  }
}
