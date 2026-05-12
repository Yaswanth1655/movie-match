import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

/// Single source of truth for "does this device currently have any network
/// adapter active?". Repositories MUST consult [isOnline] before issuing any
/// remote HTTP call so airplane-mode sessions never burn battery on doomed
/// dio retries, never flash the "Reconnecting…" banner, and never emit
/// failure states caused purely by an absent network.
///
/// Intentionally does NOT confirm real internet reachability — captive-portal
/// wifi or the 30% packet-drop simulator will still report online here. The
/// dio retry interceptor handles "I have a link but packets are dropped";
/// this service handles "I'm in airplane mode".
class ConnectivityService {
  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity() {
    _streamSub = _connectivity.onConnectivityChanged.listen(_handleResults);
    _bootstrap();
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _streamSub;

  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  /// Optimistic default: assume online until the first adapter check completes.
  /// This avoids a cold-start flash of "offline" while the plugin is warming up.
  bool _online = true;
  bool _bootstrapped = false;
  Future<void>? _bootstrapFuture;

  /// Best-effort synchronous snapshot. Callers that can `await` should prefer
  /// [isOnline] so the first call after cold-start blocks until the real
  /// adapter state is known.
  bool get isOnlineSync => _online;

  /// Returns the current online state, ensuring the first call after process
  /// start awaits a real connectivity probe. Subsequent calls are O(1).
  Future<bool> get isOnline async {
    if (!_bootstrapped) {
      await (_bootstrapFuture ?? Future<void>.value());
    }
    return _online;
  }

  /// Broadcast stream of distinct online → offline (or vice versa) transitions.
  /// Does NOT replay the current value; subscribers that need the current
  /// snapshot can read [isOnlineSync] before listening.
  Stream<bool> get onStatusChange => _controller.stream;

  Future<void> _bootstrap() {
    return _bootstrapFuture ??= () async {
      try {
        final results = await _connectivity.checkConnectivity();
        _handleResults(results);
      } catch (_) {
        // Plugin unavailable (tests, isolates) — fall back to optimistic.
      } finally {
        _bootstrapped = true;
      }
    }();
  }

  void _handleResults(List<ConnectivityResult> results) {
    final latest = results.isNotEmpty ? results.last : ConnectivityResult.none;
    final connected = latest != ConnectivityResult.none;
    if (_bootstrapped && connected == _online) return;
    _online = connected;
    if (!_controller.isClosed) _controller.add(connected);
  }

  Future<void> dispose() async {
    await _streamSub?.cancel();
    if (!_controller.isClosed) await _controller.close();
  }
}
