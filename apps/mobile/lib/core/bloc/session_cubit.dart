import 'package:flutter_bloc/flutter_bloc.dart';

class SessionCubit extends Cubit<bool> {
  SessionCubit() : super(false);

  void setAuthenticated(bool isAuthenticated) {
    emit(isAuthenticated);
  }
}
