class MoviesRouteArgs {
  const MoviesRouteArgs(this.userId);
  final int userId;
}

class MovieDetailRouteArgs {
  const MovieDetailRouteArgs({
    required this.tmdbId,
    required this.userId,
    this.posterPath,
    this.title,
  });
  /// IMDb-style id stored in [Movies.tmdbId], e.g. `tt0816692`.
  final String tmdbId;
  final int userId;
  /// Poster URL from the list/card so the detail route can show a [Hero] before the API returns.
  final String? posterPath;
  final String? title;
}

class SavedMoviesRouteArgs {
  const SavedMoviesRouteArgs(this.userId);
  final int userId;
}
