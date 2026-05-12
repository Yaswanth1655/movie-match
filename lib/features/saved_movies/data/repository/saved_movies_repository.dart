import 'package:basic_app/core/database/app_database.dart';
import 'package:basic_app/core/database/database_retry_wrapper.dart';
import 'package:logger/logger.dart';

/// Per-user saved list and save/unsave actions. All reads are scoped with `userLocalId`.
class SavedMoviesRepository {
  SavedMoviesRepository(this._db);

  final AppDatabase _db;
  final _logger = Logger();

  Stream<List<Movy>> watchForUser(int userLocalId) {
    return DatabaseRetryWrapper.retryStream(
      streamFactory: () => _db.watchSavedMoviesForUser(userLocalId),
    );
  }

  Stream<bool> watchIsSaved({
    required int userLocalId,
    required String tmdbId,
  }) {
    return DatabaseRetryWrapper.retryStream(
      streamFactory: () => _db.watchIsMovieSavedForUser(
        userLocalId: userLocalId,
        tmdbId: tmdbId,
      ),
    );
  }

  Future<void> toggleSave({
    required int userLocalId,
    required String tmdbId,
  }) async {
    try {
      await DatabaseRetryWrapper.retry(
        operation: () => _db.toggleSavedMovie(
          userLocalId: userLocalId,
          tmdbId: tmdbId,
        ),
      );
    } catch (e) {
      _logger.e('Error toggling saved movie: $e');
      rethrow;
    }
  }
}
