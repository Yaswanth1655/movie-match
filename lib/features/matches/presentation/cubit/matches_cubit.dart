import 'dart:async';

import 'package:basic_app/common/constants/enum/service_enum.dart';
import 'package:basic_app/core/database/app_database.dart';
import 'package:basic_app/features/movies/data/repository/movies_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class MatchesState {
  const MatchesState({
    this.status = Status.initial,
    this.matches = const [],
  });

  final Status status;
  final List<MovieWithCount> matches;

  MatchesState copyWith({
    Status? status,
    List<MovieWithCount>? matches,
  }) {
    return MatchesState(
      status: status ?? this.status,
      matches: matches ?? this.matches,
    );
  }
}

class MatchesCubit extends Cubit<MatchesState> {
  MatchesCubit(this._repo) : super(const MatchesState());

  final MoviesRepository _repo;
  final _logger = Logger();
  StreamSubscription<List<MovieWithCount>>? _sub;

  void watch() {
    if (isClosed) return;
    
    try {
      emit(state.copyWith(status: Status.loading));
      _sub?.cancel();
      _sub = _repo.watchMatches().listen(
        (items) {
          if (!isClosed) {
            emit(state.copyWith(status: Status.success, matches: items));
          }
        },
        onError: (error) {
          _logger.e('Error watching matches: $error');
          if (!isClosed) {
            emit(state.copyWith(status: Status.failure));
          }
        },
      );
    } catch (e) {
      _logger.e('Error setting up matches watch: $e');
      if (!isClosed) {
        emit(state.copyWith(status: Status.failure));
      }
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
