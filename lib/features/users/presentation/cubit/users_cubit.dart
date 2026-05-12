import 'dart:async';

import 'package:basic_app/common/constants/enum/service_enum.dart';
import 'package:basic_app/features/users/data/repository/users_repository.dart';
import 'package:basic_app/features/users/presentation/cubit/users_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class UsersCubit extends Cubit<UsersState> {
  UsersCubit(this._repo) : super(const UsersState()) {
    try {
      _sub = _repo.watchUsers().listen(
        (users) {
          if (!isClosed) {
            emit(state.copyWith(users: users));
          }
        },
        onError: (error) {
          _logger.e('Error watching users: $error');
        },
      );
    } catch (e) {
      _logger.e('Error setting up users stream: $e');
    }
  }

  final UsersRepository _repo;
  final _logger = Logger();
  StreamSubscription? _sub;

  Future<void> init() async {
    if (state.status == Status.loading) return;
    if (isClosed) return;
    
    try {
      emit(state.copyWith(status: Status.loading));
      final result = await _repo.fetchUsersPage(1);
      if (!isClosed) {
        emit(state.copyWith(
          status: Status.success,
          page: result.page,
          hasMore: result.hasNextPage,
        ));
      }
    } catch (e) {
      _logger.e('Error initializing users: $e');
      if (!isClosed) {
        emit(state.copyWith(status: Status.failure, errorMessage: 'Failed to load users. Please try again.'));
      }
    }
  }

  Future<void> loadNextPage() async {
    if (!state.hasMore || state.status == Status.loading || isClosed) return;
    
    try {
      emit(state.copyWith(status: Status.loading));
      final nextPage = state.page + 1;
      final result = await _repo.fetchUsersPage(nextPage);

      if (!isClosed) {
        emit(state.copyWith(
          status: Status.success,
          page: result.page,
          hasMore: result.hasNextPage,
        ));
      }
    } catch (e) {
      _logger.w('Error loading next page: $e');
      if (!isClosed) {
        emit(state.copyWith(status: Status.success));
      }
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
