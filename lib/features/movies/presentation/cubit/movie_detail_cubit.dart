import 'dart:async';

import 'package:basic_app/common/constants/enum/service_enum.dart';
import 'package:basic_app/core/database/app_database.dart';
import 'package:basic_app/features/movies/data/repository/movies_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class MovieDetailState {
  const MovieDetailState({
    this.status = Status.initial,
    this.movie,
    this.watchers = const [],
    this.saveCount = 0,
    this.message,
  });

  final Status status;
  final Movy? movie;
  final List<User> watchers;
  final int saveCount;
  final String? message;

  MovieDetailState copyWith({
    Status? status,
    Movy? movie,
    List<User>? watchers,
    int? saveCount,
    String? message,
  }) {
    return MovieDetailState(
      status: status ?? this.status,
      movie: movie ?? this.movie,
      watchers: watchers ?? this.watchers,
      saveCount: saveCount ?? this.saveCount,
      message: message,
    );
  }
}

class MovieDetailCubit extends Cubit<MovieDetailState> {
  MovieDetailCubit(this._repo) : super(const MovieDetailState());

  final MoviesRepository _repo;
  final _logger = Logger();
  StreamSubscription<int>? _countSub;
  StreamSubscription<List<User>>? _usersSub;

  Future<void> init(String tmdbId) async {
    if (isClosed) return;

    try {
      emit(state.copyWith(status: Status.loading));
      final movie = await _repo.fetchMovieDetail(tmdbId);

      _countSub?.cancel();
      _usersSub?.cancel();

      if (isClosed) return;

      if (movie == null) {
        emit(state.copyWith(status: Status.success, movie: null));
        return;
      }

      final id = movie.tmdbId;
      _countSub = _repo.watchMovieSaveCount(id).listen(
        (count) {
          if (!isClosed) {
            emit(state.copyWith(saveCount: count, status: Status.success));
          }
        },
        onError: (error) {
          _logger.e('Error watching save count: $error');
        },
      );

      _usersSub = _repo.watchUsersForMovie(id).listen(
        (users) {
          if (!isClosed) {
            emit(state.copyWith(watchers: users, movie: movie, status: Status.success));
          }
        },
        onError: (error) {
          _logger.e('Error watching users for movie: $error');
        },
      );

      emit(state.copyWith(movie: movie, status: Status.success));
    } catch (e) {
      _logger.e('Error initializing movie detail: $e');
      if (!isClosed) {
        emit(state.copyWith(status: Status.failure, message: 'Failed to load movie details'));
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

  @override
  Future<void> close() {
    _countSub?.cancel();
    _usersSub?.cancel();
    return super.close();
  }
}
