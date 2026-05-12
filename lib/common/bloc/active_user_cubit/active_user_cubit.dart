import 'package:flutter_bloc/flutter_bloc.dart';

class ActiveUserCubit extends Cubit<int?> {
  ActiveUserCubit() : super(null);

  void setActiveUser(int userLocalId) => emit(userLocalId);
}
