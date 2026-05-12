import 'package:basic_app/features/matches/presentation/pages/matches_page.dart';
import 'package:basic_app/features/movies/presentation/pages/movie_detail_page.dart';
import 'package:basic_app/features/movies/presentation/pages/movies_page.dart';
import 'package:basic_app/features/startup/presentation/pages/splash_page.dart';
import 'package:basic_app/features/users/presentation/pages/add_user_page.dart';
import 'package:basic_app/features/users/presentation/pages/user_saved_movies_page.dart';
import 'package:basic_app/features/users/presentation/pages/users_page.dart';
import 'package:basic_app/app/router/route_args.dart';
import 'package:flutter/material.dart';

class AppRouter {
  static const users = '/';
  static const addUser = '/add-user';
  static const splash = '/splash';
  static const movies = '/movies';
  static const movieDetail = '/movie-detail';
  static const userSavedMovies = '/user-saved-movies';
  static const matches = '/matches';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());
      case users:
        return MaterialPageRoute(builder: (_) => const UsersPage());
      case addUser:
        return MaterialPageRoute(builder: (_) => const AddUserPage());
      case movies:
        final args = settings.arguments as MoviesRouteArgs;
        return MaterialPageRoute(builder: (_) => MoviesPage(userId: args.userId));
      case movieDetail:
        final args = settings.arguments as MovieDetailRouteArgs;
        return MaterialPageRoute(
          builder: (_) => MovieDetailPage(
            tmdbId: args.tmdbId,
            userId: args.userId,
            initialPosterPath: args.posterPath,
            initialTitle: args.title,
          ),
        );
      case userSavedMovies:
        final args = settings.arguments as SavedMoviesRouteArgs;
        return MaterialPageRoute(
          builder: (_) => UserSavedMoviesPage(userId: args.userId),
        );
      case matches:
        return MaterialPageRoute(builder: (_) => const MatchesPage());
      default:
        return MaterialPageRoute(builder: (_) => const UsersPage());
    }
  }
}
