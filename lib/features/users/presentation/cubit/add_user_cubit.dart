import 'package:basic_app/common/constants/enum/service_enum.dart';
import 'package:basic_app/features/users/data/repository/users_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class AddUserState {
  const AddUserState({
    this.status = Status.initial,
    this.message,
  });

  final Status status;
  final String? message;

  AddUserState copyWith({
    Status? status,
    String? message,
  }) {
    return AddUserState(
      status: status ?? this.status,
      message: message,
    );
  }
}

class AddUserCubit extends Cubit<AddUserState> {
  AddUserCubit(this._repo) : super(const AddUserState());

  final UsersRepository _repo;
  final _logger = Logger();

  Future<void> submit({
    required String name,
    required String movieTaste,
    required bool isOffline,
  }) async {
    if (isClosed) return;
    
    try {
      emit(state.copyWith(status: Status.loading));
      await _repo.addUser(name: name, movieTaste: movieTaste, isOffline: isOffline);
      
      if (!isClosed) {
        emit(
          state.copyWith(
            status: Status.success,
            message: isOffline 
                ? 'User saved offline and will sync when online' 
                : 'User added successfully',
          ),
        );
      }
    } catch (e) {
      _logger.e('Error adding user: $e');
      if (!isClosed) {
        emit(state.copyWith(
          status: Status.failure, 
          message: 'Failed to add user. Please try again.',
        ));
      }
    }
  }
}
