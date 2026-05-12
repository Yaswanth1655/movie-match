import 'package:basic_app/common/constants/enum/service_enum.dart';
import 'package:basic_app/core/database/app_database.dart';
import 'package:basic_app/features/movies/data/repository/movies_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class MoviesState {
  const MoviesState({
    this.status = Status.initial,
    this.movies = const <Movy>[],
    this.page = 1,
    this.hasMore = true,
    this.loadingMore = false,
    this.message,
  });

  final Status status;
  final List<Movy> movies;
  final int page;
  final bool hasMore;
  /// True while fetching the next OMDB page (initial grid stays visible).
  final bool loadingMore;
  final String? message;

  MoviesState copyWith({
    Status? status,
    List<Movy>? movies,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    String? message,
  }) {
    return MoviesState(
      status: status ?? this.status,
      movies: movies ?? this.movies,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      message: message,
    );
  }
}

class MoviesCubit extends Cubit<MoviesState> {
  MoviesCubit(this._repo) : super(const MoviesState());

  final MoviesRepository _repo;
  final _logger = Logger();

  Future<void> init() async {
    if (isClosed) return;

    try {
      emit(state.copyWith(status: Status.loading, movies: [], page: 1, hasMore: true, loadingMore: false));
      final page = await _repo.fetchTrendingPage(1);
      if (!isClosed) {
        emit(
          state.copyWith(
            status: Status.success,
            movies: page.movies,
            page: 1,
            hasMore: page.hasMore,
            loadingMore: false,
          ),
        );
      }
    } catch (e) {
      _logger.e('Error initializing movies: $e');
      if (!isClosed) {
        emit(state.copyWith(status: Status.failure, message: 'Failed to load movies. Please try again.'));
      }
    }
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || isClosed) return;
    if (state.status == Status.loading && state.movies.isEmpty) return;

    try {
      emit(state.copyWith(loadingMore: true));
      final next = state.page + 1;
      final page = await _repo.fetchTrendingPage(next);

      if (!isClosed) {
        if (page.movies.isEmpty) {
          emit(state.copyWith(loadingMore: false, hasMore: false));
          return;
        }

        final seen = state.movies.map((m) => m.tmdbId).toSet();
        final merged = List<Movy>.from(state.movies);
        for (final m in page.movies) {
          if (seen.add(m.tmdbId)) merged.add(m);
        }

        emit(
          state.copyWith(
            status: Status.success,
            movies: merged,
            page: next,
            hasMore: page.hasMore,
            loadingMore: false,
          ),
        );
      }
    } catch (e) {
      _logger.w('Error loading more movies: $e');
      if (!isClosed) {
        emit(state.copyWith(loadingMore: false));
      }
    }
  }

  Future<void> toggleSave({required int userId, required String tmdbId}) async {
    try {
      await _repo.toggleSave(userLocalId: userId, tmdbId: tmdbId);
    } catch (e) {
      _logger.e('Error toggling save: $e');
    }
  }
}
