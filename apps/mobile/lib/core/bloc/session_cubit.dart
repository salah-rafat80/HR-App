import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../di/injection.dart';
import '../services/token_service.dart';

class SessionCubit extends Cubit<bool> {
  final TokenService? _tokenService;
  final Dio? _dio;

  SessionCubit({TokenService? tokenService, Dio? dio})
      : _tokenService = tokenService,
        _dio = dio,
        super(false);

  TokenService get tokenService =>
      _tokenService ??
      (getIt.isRegistered<TokenService>()
          ? getIt<TokenService>()
          : TokenService());

  Dio? get dio => _dio ?? (getIt.isRegistered<Dio>() ? getIt<Dio>() : null);

  Future<bool> checkStoredSession() async {
    final token = await tokenService.getToken();
    if (token == null || token.isEmpty) {
      emit(false);
      return false;
    }

    final d = dio;
    if (d != null) {
      try {
        final response = await d.get('/attendance/today');
        if (response.statusCode == 200) {
          emit(true);
          return true;
        }
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 401) {
          await tokenService.clearToken();
          emit(false);
          return false;
        }
      }
    }

    emit(true);
    return true;
  }

  void setAuthenticated(bool isAuthenticated) {
    emit(isAuthenticated);
  }

  Future<void> logout() async {
    await tokenService.clearToken();
    emit(false);
  }
}
