import 'package:basic_app/core/database/app_database.dart';
import 'package:basic_app/core/database/database_retry_wrapper.dart';
import 'package:basic_app/core/internet_connectivity/connectivity_service.dart';
import 'package:basic_app/features/users/data/models/reqres_api_models.dart';
import 'package:basic_app/features/users/data/models/reqres_user_mapper.dart';
import 'package:basic_app/features/users/data/repository/reqres_user_remote_source.dart';
import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

class UsersRepository {
  UsersRepository(this._db, this._remote, this._connectivity);

  final AppDatabase _db;
  final ReqresUserRemoteSource _remote;
  final ConnectivityService _connectivity;
  final _logger = Logger();
  final Map<int, ReqresUsersPageResponse> _pageCache = {};
  final Map<int, Future<ReqresUsersPageResponse>> _inFlightPages = {};

  /// Serializes [syncPendingUsers] so a connectivity-flap, app-start, and
  /// WorkManager wake-up that overlap can never POST the same pending user
  /// twice (which would otherwise produce duplicate server records).
  Future<void>? _syncInFlight;

  /// True while a sync pass is actively talking to the server. Cubits expose
  /// this so the UI can render a non-blocking "syncing…" indicator.
  bool get isSyncing => _syncInFlight != null;

  /// Whether any local rows still need a `serverId`. Cheap; used by SyncCubit
  /// to decide whether to kick off a sync on construction/foreground.
  Future<bool> hasPendingUsers() async {
    try {
      final pending = await DatabaseRetryWrapper.retry(
        operation: () => _db.getPendingUsers(),
      );
      return pending.isNotEmpty;
    } catch (e) {
      _logger.w('hasPendingUsers check failed: $e');
      return false;
    }
  }

  Stream<List<User>> watchUsers() {
    return DatabaseRetryWrapper.retryStream(
      streamFactory: () => _db.watchUsers(),
    );
  }

  Future<ReqresUsersPageResponse> fetchUsersPage(int page) async {
    try {
      final cached = _pageCache[page];
      if (cached != null) {
        _logger.i('Skipping duplicate fetch for users page $page');
        return cached;
      }

      if (!await _connectivity.isOnline) {
        // Airplane mode: don't even queue a fetch. The DB stream
        // ([watchUsers]) is what populates the UI; we just return a
        // synthetic "no remote data this round" response so the cubit can
        // settle into Success without flashing loading / failure.
        _logger.i('Offline: skipping remote fetch for users page $page');
        return _offlineUsersPage(page);
      }

      final inFlight = _inFlightPages[page];
      if (inFlight != null) {
        _logger.i('Joining in-flight fetch for users page $page');
        return inFlight;
      }

      final request = _fetchAndStoreUsersPage(page);
      _inFlightPages[page] = request;
      return await request;
    } finally {
      _inFlightPages.remove(page);
    }
  }

  /// Synthetic "we tried, no network, that's fine" response.
  ///
  /// `totalPages = page + 1` keeps `hasNextPage == true`, so when the device
  /// comes back online and the user scrolls, pagination resumes naturally
  /// instead of being permanently capped at the last offline page index.
  /// Not cached — the next call after reconnect must actually hit the API.
  ReqresUsersPageResponse _offlineUsersPage(int page) {
    return ReqresUsersPageResponse(
      page: page,
      perPage: 0,
      total: 0,
      totalPages: page + 1,
      data: const [],
    );
  }

  Future<ReqresUsersPageResponse> _fetchAndStoreUsersPage(int page) async {
    try {
      final result = await _remote.fetchUsers(page: page);
      final uniqueUsers = <ReqresUserDto>[];
      final seenIds = <int>{};
      final seenEmails = <String>{};

      for (final dto in result.data) {
        final emailKey = dto.email.trim().toLowerCase();
        final addedById = dto.id > 0 && seenIds.add(dto.id);
        final addedByEmail = emailKey.isNotEmpty && seenEmails.add(emailKey);
        if (addedById || addedByEmail) {
          uniqueUsers.add(dto);
        }
      }

      _logger.i('Fetched ${uniqueUsers.length} unique users from page $page');
      for (final dto in uniqueUsers) {
        await DatabaseRetryWrapper.retry(
          operation: () async {
            final existing = await _findExistingRemoteUser(dto);
            if (existing == null) {
              return _db.upsertUser(dto.toUsersCompanion());
            }

            return (_db.update(_db.users)
                  ..where((u) => u.localId.equals(existing.localId)))
                .write(
              UsersCompanion(
                firstName: Value(dto.firstName),
                lastName: Value(dto.lastName),
                avatar: Value(dto.avatar),
                email: Value(dto.email),
                serverId: Value(dto.id > 0 ? dto.id : null),
                pendingSync: const Value(false),
                updatedAt: Value(DateTime.now()),
              ),
            );
          },
        );
      }

      _pageCache[page] = result;
      return result;
    } catch (e) {
      _logger.e('Error fetching users page: $e');
      rethrow;
    }
  }

  Future<User?> _findExistingRemoteUser(ReqresUserDto dto) async {
    return DatabaseRetryWrapper.retry(
      operation: () async {
        if (dto.id > 0) {
          final byServerId = await (_db.select(_db.users)
                ..where((u) => u.serverId.equals(dto.id)))
              .get();
          if (byServerId.isNotEmpty) {
            return byServerId.first;
          }
        }

        final email = dto.email.trim();
        if (email.isNotEmpty) {
          final byEmail = await (_db.select(_db.users)
                ..where((u) => u.email.equals(email)))
              .get();
          if (byEmail.isNotEmpty) {
            return byEmail.first;
          }
        }

        return null;
      },
    );
  }

  Future<User> addUser({
    required String name,
    required String movieTaste,
    required bool isOffline,
  }) async {
    try {
      final split = name.split(' ');
      final first = split.isEmpty ? name : split.first;
      final last = split.length > 1 ? split.sublist(1).join(' ') : '';

      // Treat a stale "online" UI snapshot as offline if the centralized
      // service says we have no network. Saves the row locally with
      // pendingSync=true so SyncCubit picks it up on the next reconnect,
      // and avoids a doomed POST + retry storm + reconnecting banner.
      final effectiveOffline = isOffline || !await _connectivity.isOnline;

      final id = await DatabaseRetryWrapper.retry(
        operation: () => _db.into(_db.users).insert(
              UsersCompanion.insert(
                firstName: first,
                lastName: Value(last),
                movieTaste: Value(movieTaste),
                pendingSync: Value(effectiveOffline),
              ),
            ),
      );

      if (!effectiveOffline) {
        try {
          final response =
              await _remote.createUser(name: name, job: movieTaste);
          final serverId = int.tryParse(response.id ?? '');
          _logger.f(
              'server user ${response.name} with id ${response.id} - $serverId');
          if (serverId != null) {
            await DatabaseRetryWrapper.retry(
              operation: () => (_db.update(_db.users)
                    ..where((u) => u.localId.equals(id)))
                  .write(
                UsersCompanion(
                  serverId: Value(serverId),
                  pendingSync: const Value(false),
                ),
              ),
            );
          }
        } catch (e) {
          _logger.w(
              'Failed to sync user to server immediately, will retry later: $e');
          await DatabaseRetryWrapper.retry(
            operation: () => (_db.update(_db.users)
                  ..where((u) => u.localId.equals(id)))
                .write(
              const UsersCompanion(pendingSync: Value(true)),
            ),
          );
        }
      }

      return await DatabaseRetryWrapper.retry(
        operation: () => (_db.select(_db.users)
              ..where((u) => u.localId.equals(id)))
            .getSingle(),
      );
    } catch (e) {
      _logger.e('Error adding user: $e');
      rethrow;
    }
  }

  /// Push every locally-created (`pendingSync == true`) user up to the server,
  /// stamp the returned id back onto the local row, and clear the pending flag.
  ///
  /// Idempotent and concurrency-safe:
  ///   * A second caller while a sync is in progress joins the same future
  ///     instead of starting another pass.
  ///   * Each row is re-read from the DB right before POSTing so that, if
  ///     another path already synced it, we skip the duplicate POST.
  ///   * `SavedMovies` rows are unaffected — they FK on `localId`, which never
  ///     changes, so links stay valid before *and* after sync.
  Future<void> syncPendingUsers() {
    final existing = _syncInFlight;
    if (existing != null) {
      _logger.i('Sync already in progress, joining existing run');
      return existing;
    }
    final fut = _runPendingSync();
    _syncInFlight = fut;
    return fut.whenComplete(() {
      _syncInFlight = null;
    });
  }

  Future<void> _runPendingSync() async {
    try {
      final pending = await DatabaseRetryWrapper.retry(
        operation: () => _db.getPendingUsers(),
      );
      if (pending.isEmpty) return;

      if (!await _connectivity.isOnline) {
        // Don't even attempt POSTs. The next online transition (or the next
        // WorkManager wake-up that *is* online) will pick these up again.
        _logger.i(
          'Offline: deferring sync of ${pending.length} pending user(s)',
        );
        return;
      }

      _logger.i('Syncing ${pending.length} pending user(s)');

      for (final user in pending) {
        // Re-read the row right before the network call. Another sync pass
        // (e.g. the workmanager isolate) may have just finished it.
        final fresh = await DatabaseRetryWrapper.retry(
          operation: () => (_db.select(_db.users)
                ..where((u) => u.localId.equals(user.localId)))
              .getSingleOrNull(),
        );
        if (fresh == null || !fresh.pendingSync || fresh.serverId != null) {
          continue;
        }

        try {
          final response = await _remote.createUser(
            name: '${fresh.firstName} ${fresh.lastName}'.trim(),
            job: fresh.movieTaste,
          );
          final serverId = int.tryParse(response.id ?? '');
          await DatabaseRetryWrapper.retry(
            operation: () => (_db.update(_db.users)
                  ..where((u) => u.localId.equals(fresh.localId)))
                .write(
              UsersCompanion(
                serverId: Value(serverId),
                pendingSync: const Value(false),
                updatedAt: Value(DateTime.now()),
              ),
            ),
          );
          _logger.i(
            'Synced user localId=${fresh.localId} -> serverId=$serverId '
            '(saved-movies links via localId remain intact)',
          );
        } catch (e) {
          // Leave pendingSync = true so the next pass picks it up. Bad-network
          // simulation will exhaust Dio retries here; that's expected — we
          // simply try again on the next connectivity event / startup.
          _logger.w('Sync of user ${fresh.localId} failed, will retry: $e');
        }
      }
    } catch (e) {
      _logger.e('Error during pending-users sync: $e');
    }
  }
}
