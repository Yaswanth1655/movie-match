import 'dart:io';

import 'package:basic_app/app/app.dart';
import 'package:basic_app/app/di/injection.dart';
import 'package:basic_app/core/sync/sync_initializer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle, SystemChrome, SystemUiMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,          // top bar transparent
      systemNavigationBarColor: Colors.transparent, // bottom bar transparent
      statusBarIconBrightness: Brightness.light,   // icon colour (dark/light)
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge); 

  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }

  await dotenv.load(fileName: '.env');
  
  final storage = await HydratedStorage.build(
    storageDirectory: await getApplicationDocumentsDirectory(),
  );
  HydratedBloc.storage = storage;
  await configureDependencies();
  await SyncInitializer.setup();

  runApp(const PlatformCommonsApp());
}
