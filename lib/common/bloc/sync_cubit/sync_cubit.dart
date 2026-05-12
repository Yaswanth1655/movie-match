import 'dart:async';

import 'package:basic_app/common/bloc/connectivity_cubit/connectivity_cubit.dart';
import 'package:basic_app/features/users/data/repository/users_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Drives background sync of locally-created users to the server.
///
/// Triggers a sync pass:
///   * Once on construction (covers cold-starts where the device was offline
///     during a previous session and is now online again).
///   * Every time connectivity transitions to `online` (with a small debounce
///     to ride out wifi flaps caused by the 30% blocked-call simulation).
///
/// State is `true` while a sync pass is actively running, so the app shell can
/// piggy-back on the same "reconnecting…" banner used by HTTP retries.
class SyncCubit extends Cubit<bool> {
  SyncCubit(this._usersRepository, this._connectivityCubit) : super(false) {
    _connectivitySub = _connectivityCubit.stream.listen((connected) {
      if (connected) _scheduleSync();
    });
    // Cold-start: if we're already online and there are leftovers, push them
    // up right away without waiting for a connectivity event.
    if (_connectivityCubit.state) {
      _scheduleSync();
    }
  }

  final UsersRepository _usersRepository;
  final ConnectivityCubit _connectivityCubit;
  StreamSubscription<bool>? _connectivitySub;
  Timer? _debounce;

  /// Coalesce bursty connectivity events (typical of a flaky link) into a
  /// single sync pass ~600ms after the link looks stable.
  void _scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _runSync);
  }

  Future<void> _runSync() async {
    if (isClosed) return;
    // Belt-and-suspenders: even if a caller hits `triggerNow()` while we're
    // offline (e.g. pull-to-refresh in airplane mode), don't flip the
    // "Syncing…" banner on. The repo itself also short-circuits, but
    // suppressing the cubit emit keeps the UI fully quiet.
    if (!_connectivityCubit.state) return;

    final hasPending = await _usersRepository.hasPendingUsers();
    if (!hasPending) return;

    if (isClosed) return;
    emit(true);
    try {
      await _usersRepository.syncPendingUsers();
    } finally {
      if (!isClosed) emit(false);
    }
  }

  /// Imperative trigger — useful from "Pull to refresh" or after a successful
  /// offline add. Safe to call repeatedly; underlying repo has a mutex.
  Future<void> triggerNow() => _runSync();

  @override
  Future<void> close() {
    _debounce?.cancel();
    _connectivitySub?.cancel();
    return super.close();
  }
}
