import 'dart:async';

import 'package:basic_app/core/internet_connectivity/connectivity_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Thin BLoC adapter over [ConnectivityService] so widgets can react via
/// `BlocBuilder`/`context.read` without coupling to the lower-level service.
///
/// State is `true` when the device has any active network adapter, `false`
/// otherwise. Mirrors [ConnectivityService.isOnlineSync] exactly — both the
/// repository layer (which gates remote calls) and the UI (which renders
/// banners / status chips) read from the same source of truth.
class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit(this._service) : super(_service.isOnlineSync) {
    _streamSub = _service.onStatusChange.listen((online) {
      if (!isClosed && online != state) emit(online);
    });
    // Cold-start: the service hadn't finished its bootstrap probe yet when
    // we read `isOnlineSync` above. Re-sync once the async result lands so
    // a freshly-launched airplane-mode session reports offline immediately.
    _service.isOnline.then((online) {
      if (!isClosed && online != state) emit(online);
    });
  }

  final ConnectivityService _service;
  StreamSubscription<bool>? _streamSub;

  @override
  Future<void> close() {
    _streamSub?.cancel();
    return super.close();
  }
}
