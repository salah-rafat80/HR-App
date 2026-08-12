import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../di/injection.dart';

class SessionCubit extends Cubit<bool> {
  SessionCubit() : super(false);

  Future<bool> checkStoredSession() async {
    final prefs = getIt<SharedPreferences>();
    final token = prefs.getString('jwt_token');
    final isAuthenticated = token != null && token.isNotEmpty;
    emit(isAuthenticated);
    return isAuthenticated;
  }

  void setAuthenticated(bool isAuthenticated) {
    emit(isAuthenticated);
  }
}
