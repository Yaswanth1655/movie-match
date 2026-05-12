import 'dart:async';

import 'package:basic_app/common/constants/enum/service_enum.dart';
import 'package:basic_app/core/database/app_database.dart';
import 'package:basic_app/features/saved_movies/data/repository/saved_movies_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class SavedMoviesState {
  const SavedMoviesState({
    this.status = Status.initial,
    this.movies = const [],
  });

  final Status status;
  final List<Movy> movies;

  SavedMoviesState copyWith({
    Status? status,
    List<Movy>? movies,
  }) {
    return SavedMoviesState(
      status: status ?? this.status,
      movies: movies ?? this.movies,
    );
  }
}

class SavedMoviesCubit extends Cubit<SavedMoviesState> {
  SavedMoviesCubit(this._repo) : super(const SavedMoviesState());

  final SavedMoviesRepository _repo;
  final _logger = Logger();
  StreamSubscription<List<Movy>>? _sub;

  void watchForUser(int userId) {
    if (isClosed) return;
    
    try {
      emit(state.copyWith(status: Status.loading));
      _sub?.cancel();
      _sub = _repo.watchForUser(userId).listen(
        (movies) {
          if (!isClosed) {
            emit(state.copyWith(status: Status.success, movies: movies));
          }
        },
        onError: (error) {
          _logger.e('Error watching saved movies: $error');
          if (!isClosed) {
            emit(state.copyWith(status: Status.failure));
          }
        },
      );
    } catch (e) {
      _logger.e('Error setting up saved movies watch: $e');
      if (!isClosed) {
        emit(state.copyWith(status: Status.failure));
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
    _sub?.cancel();
    return super.close();
  }
}
