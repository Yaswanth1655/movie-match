import 'dart:io';

import 'package:basic_app/core/database/app_database.dart';
import 'package:basic_app/core/internet_connectivity/connectivity_service.dart';
import 'package:basic_app/data/source/network/network_api_service.dart';
import 'package:basic_app/features/users/data/repository/reqres_user_remote_source.dart';
import 'package:basic_app/features/users/data/repository/users_repository.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:workmanager/workmanager.dart';

const String syncPendingUsersTask = 'sync_pending_users_task';

@pragma('vm:entry-point')
void workmanagerCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == syncPendingUsersTask) {
      if (Platform.isAndroid) {
        await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      }
      final db = AppDatabase();
      final connectivity = ConnectivityService();
      final remote = ReqresUserRemoteSource(Network());
      final repo = UsersRepository(db, remote, connectivity);
      try {
        await repo.syncPendingUsers();
      } finally {
        await connectivity.dispose();
        await db.close();
      }
      return Future.value(true);
    }

    return Future.value(false);
  });
}
