import 'package:flutter_bloc/flutter_bloc.dart';
import '../enums/role_enums.dart';

class SessionCubit extends Cubit<UserRole> {
  SessionCubit() : super(UserRole.employee);

  void setRole(UserRole role) {
    emit(role);
  }
}
