import 'package:basic_app/core/sync/sync_worker.dart';
import 'package:workmanager/workmanager.dart';

class SyncInitializer {
  const SyncInitializer._();

  static Future<void> setup() async {
    await Workmanager().initialize(workmanagerCallbackDispatcher);
    await Workmanager().registerPeriodicTask(
      'platform-commons-sync',
      syncPendingUsersTask,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}
