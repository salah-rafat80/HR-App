import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hr_core/core/enums/role_enums.dart';

class SessionCubit extends Cubit<UserRole?> {
  SessionCubit() : super(null);

  void setRole(UserRole role) {
    emit(role);
  }

  void logout() {
    emit(null);
  }
}
