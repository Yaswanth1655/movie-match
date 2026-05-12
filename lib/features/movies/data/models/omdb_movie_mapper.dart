import 'dart:convert';

import 'package:basic_app/core/database/app_database.dart';
import 'package:basic_app/features/movies/data/models/omdb_api_models.dart';
import 'package:drift/drift.dart';

extension OmdbMovieDetailMapper on OmdbMovieDetailDto {
  /// Upserts by [tmdbId] (IMDb id, e.g. `tt0816692`).
  MoviesCompanion toMoviesCompanion({required String tmdbId}) {
    final release = year?.isNotEmpty == true
        ? year!
        : (released?.isNotEmpty == true ? released! : '');
    final p = poster == null || poster == 'N/A' ? '' : poster!;
    final voteAverage = double.tryParse(imdbRating ?? '');
    return MoviesCompanion.insert(
      tmdbId: tmdbId,
      title: title ?? '',
      overview: Value(plot ?? ''),
      posterPath: Value(p),
      releaseDate: Value(release),
      source: const Value('omdb'),
      rawPayload: Value(jsonEncode({
        ...toJson(),
        'voteAverage': voteAverage,
      })),
    );
  }
}
