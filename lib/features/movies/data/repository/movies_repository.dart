import 'dart:convert';

import 'package:basic_app/core/database/app_database.dart';
import 'package:basic_app/core/database/database_retry_wrapper.dart';
import 'package:basic_app/core/database/tmdb_id_normalize.dart';
import 'package:basic_app/core/internet_connectivity/connectivity_service.dart';
import 'package:basic_app/features/movies/data/models/omdb_api_models.dart';
import 'package:basic_app/features/movies/data/models/omdb_movie_mapper.dart';
import 'package:basic_app/features/movies/data/repository/movie_remote_source.dart';
import 'package:basic_app/features/saved_movies/data/repository/saved_movies_repository.dart';
import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

/// Global movie catalogue fetch + match aggregation. Per-user saves go through [SavedMoviesRepository].
class MoviesRepository {
  MoviesRepository(
      this._db, this._remote, this._savedMovies, this._connectivity);

  final AppDatabase _db;
  final MovieRemoteSource _remote;
  final SavedMoviesRepository _savedMovies;
  final ConnectivityService _connectivity;
  final _logger = Logger();

  /// Delegates to [SavedMoviesRepository] so UI can depend on one movies facade if desired.
  Future<void> toggleSave({
    required int userLocalId,
    required String tmdbId,
  }) =>
      _savedMovies.toggleSave(userLocalId: userLocalId, tmdbId: tmdbId);

  Stream<bool> watchIsMovieSavedForUser({
    required int userLocalId,
    required String tmdbId,
  }) =>
      _savedMovies.watchIsSaved(userLocalId: userLocalId, tmdbId: tmdbId);

  Stream<int> watchMovieSaveCount(String tmdbId) {
    return DatabaseRetryWrapper.retryStream(
      streamFactory: () => _db.watchMovieSaveCount(tmdbId),
    );
  }

  Stream<List<User>> watchUsersForMovie(String tmdbId) {
    return DatabaseRetryWrapper.retryStream(
      streamFactory: () => _db.watchUsersForMovie(tmdbId),
    );
  }

  Stream<List<MovieWithCount>> watchMatches() {
    return DatabaseRetryWrapper.retryStream(
      streamFactory: () => _db.watchMatches(),
    );
  }

  /// OMDB returns up to 10 search hits per request; we may merge several requests per [page].
  static const int omdbSearchPageSize = 10;
  static final int _trendingPageSize =
      omdbSearchPageSize * MovieRemoteSource.trendingSearchQueries.length;

  /// Shared catalogue: no user id. Remote data only refreshes [Movies]; the UI
  /// always receives the same DB-ordered page in online and offline paths.
  ///
  /// Offline-safe: if the remote call fails (airplane mode, exhausted retries,
  /// timeout), we fall back to whatever is already cached in the local DB so
  /// the Movies page keeps showing the last-loaded grid instead of going blank.
  Future<({List<Movy> movies, bool hasMore})> fetchTrendingPage(
      int page) async {
    if (!await _connectivity.isOnline) {
      // Airplane mode: skip dio entirely. No retries, no banner, no failure
      // state — just hand back whatever the DB already has for this page.
      _logger.i('Offline: serving trending page $page from local cache');
      return _cachedTrendingPage(page);
    }

    var remoteHasMore = false;
    try {
      final remote = await _remote.fetchTrendingMovies(page: page);
      final items = remote.items;
      remoteHasMore = remote.hasMore;
      _logger.i(
        'Fetched ${items.length} OMDB movies for page $page '
        '(hasMore=$remoteHasMore)',
      );

      await _upsertTrendingMovies(page: page, items: items);
    } catch (e) {
      _logger.w('Remote movies page $page failed, serving local cache: $e');
    }

    return _cachedTrendingPage(page, remoteHasMore: remoteHasMore);
  }

  Future<void> _upsertTrendingMovies({
    required int page,
    required List<OmdbSearchItemDto> items,
  }) async {
    final seenBatch = <String>{};
    final rows = <MoviesCompanion>[];
    var pageIndex = 0;

    for (final map in items) {
      final tid = normalizeTmdbId(map.imdbID);
      if (tid.isEmpty || !seenBatch.add(tid)) continue;

      rows.add(
        MoviesCompanion.insert(
          tmdbId: tid,
          title: map.title,
          overview: const Value(''),
          posterPath: Value(map.poster == 'N/A' ? '' : map.poster),
          releaseDate: Value(map.year),
          source: const Value('omdb'),
          sortIndex: Value(((page - 1) * _trendingPageSize) + pageIndex),
          rawPayload: Value(jsonEncode(map.toStoredMovieRow())),
        ),
      );
      pageIndex++;
    }

    if (rows.isEmpty) return;

    await DatabaseRetryWrapper.retry(
      operation: () => _db.upsertMovies(rows),
    );
  }

  /// Read previously-stored movies straight from Drift. Used as an offline /
  /// fallback path so the Movies grid never goes empty on a flaky link.
  Future<({List<Movy> movies, bool hasMore})> _cachedTrendingPage(
    int page, {
    bool remoteHasMore = false,
  }) async {
    try {
      final offset = (page - 1) * _trendingPageSize;
      final cached = await DatabaseRetryWrapper.retry(
        operation: () =>
            _db.getMovies(limit: _trendingPageSize, offset: offset),
      );
      return (
        movies: cached,
        hasMore: remoteHasMore || cached.length >= _trendingPageSize,
      );
    } catch (e) {
      _logger.e('Local movies cache read failed: $e');
      return (movies: <Movy>[], hasMore: false);
    }
  }

  Future<Movy?> fetchMovieDetail(String tmdbId) async {
    final normalized = normalizeTmdbId(tmdbId);
    if (normalized.isEmpty) return null;

    try {
      final local = await DatabaseRetryWrapper.retry(
        operation: () => _db.getMovieByTmdbId(normalized),
      );

      // Skip the OMDB detail lookup entirely when offline. The user still gets
      // the cached row (title, poster, year) plus the live DB streams for
      // save count / watchers — i.e. exactly what they had online minus the
      // freshly-fetched plot / rating, which the DB already keeps from prior
      // visits anyway.
      if (!await _connectivity.isOnline) {
        return local;
      }

      try {
        final dto = await _remote.fetchOmdbMovieDetail(imdbId: normalized);
        if (dto.isSuccess) {
          final key = dto.imdbID != null && dto.imdbID!.trim().isNotEmpty
              ? normalizeTmdbId(dto.imdbID!)
              : normalized;
          await DatabaseRetryWrapper.retry(
            operation: () =>
                _db.upsertMovie(dto.toMoviesCompanion(tmdbId: key)),
          );
          return await DatabaseRetryWrapper.retry(
            operation: () => _db.getMovieByTmdbId(key),
          );
        }
      } catch (e) {
        _logger.w('OMDB movie detail failed: $e');
      }

      return local;
    } catch (e) {
      _logger.e('Error fetching movie detail: $e');
      return null;
    }
  }
}
