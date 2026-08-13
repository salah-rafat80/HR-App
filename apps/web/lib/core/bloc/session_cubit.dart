import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:hr_core/core/services/token_storage.dart';
import '../di/injection.dart';

enum WebSessionStatus {
  initial,
  authenticated,
  unauthenticated,
  sessionUnknown,
}

class WebSessionState extends Equatable {
  final WebSessionStatus status;
  final UserRole? role;
  final String? errorMessage;

  const WebSessionState({
    required this.status,
    this.role,
    this.errorMessage,
  });

  factory WebSessionState.initial() =>
      const WebSessionState(status: WebSessionStatus.initial);
  factory WebSessionState.authenticated(UserRole role) =>
      WebSessionState(status: WebSessionStatus.authenticated, role: role);
  factory WebSessionState.unauthenticated() =>
      const WebSessionState(status: WebSessionStatus.unauthenticated);
  factory WebSessionState.sessionUnknown(String msg) =>
      WebSessionState(status: WebSessionStatus.sessionUnknown, errorMessage: msg);

  bool get isAuthenticated => status == WebSessionStatus.authenticated;

  @override
  List<Object?> get props => [status, role, errorMessage];
}

class SessionCubit extends Cubit<WebSessionState> {
  final TokenStorage? _tokenStorage;
  final Dio? _dio;

  SessionCubit({TokenStorage? tokenStorage, Dio? dio})
      : _tokenStorage = tokenStorage,
        _dio = dio,
        super(WebSessionState.initial());

  TokenStorage get tokenStorage =>
      _tokenStorage ??
      (getIt.isRegistered<TokenStorage>()
          ? getIt<TokenStorage>()
          : SecureTokenStorage());

  Dio? get dio => _dio ?? (getIt.isRegistered<Dio>() ? getIt<Dio>() : null);

  Future<WebSessionState> checkStoredSession() async {
    final token = await tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      final newState = WebSessionState.unauthenticated();
      emit(newState);
      return newState;
    }

    final client = dio;
    if (client == null) {
      final newState =
          WebSessionState.sessionUnknown('HTTP Client not initialized');
      emit(newState);
      return newState;
    }

    try {
      final response = await client.get('/attendance/today');
      if (response.statusCode == 200) {
        final newState = WebSessionState.authenticated(UserRole.hrAdmin);
        emit(newState);
        return newState;
      } else {
        final newState = WebSessionState.sessionUnknown(
            'Unexpected response code: ${response.statusCode}');
        emit(newState);
        return newState;
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        await tokenStorage.clearToken();
        final newState = WebSessionState.unauthenticated();
        emit(newState);
        return newState;
      }

      final newState = WebSessionState.sessionUnknown(
        'Backend session validation unavailable. Please retry login.',
      );
      emit(newState);
      return newState;
    }
  }

  void setAuthenticatedRole(UserRole role) {
    emit(WebSessionState.authenticated(role));
  }

  Future<void> logout() async {
    await tokenStorage.clearToken();
    emit(WebSessionState.unauthenticated());
  }
}
