import 'package:basic_app/common/constants/enum/service_enum.dart';
import 'package:basic_app/core/database/app_database.dart';

class UsersState {
  const UsersState({
    this.status = Status.initial,
    this.users = const [],
    this.page = 1,
    this.hasMore = true,
    this.errorMessage,
    this.snackbarMessage,
  });

  final Status status;
  final List<User> users;
  final int page;
  final bool hasMore;
  final String? errorMessage;
  final String? snackbarMessage;

  UsersState copyWith({
    Status? status,
    List<User>? users,
    int? page,
    bool? hasMore,
    String? errorMessage,
    String? snackbarMessage,
  }) {
    return UsersState(
      status: status ?? this.status,
      users: users ?? this.users,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
      snackbarMessage: snackbarMessage,
    );
  }
}
