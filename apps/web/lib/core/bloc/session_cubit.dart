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
    final accessToken = await tokenStorage.getAccessToken();
    final refreshToken = await tokenStorage.getRefreshToken();

    if ((accessToken == null || accessToken.isEmpty) &&
        (refreshToken == null || refreshToken.isEmpty)) {
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

    // Step 1: Try GET /auth/me with existing access token
    if (accessToken != null && accessToken.isNotEmpty) {
      try {
        final response = await client.get('/auth/me');
        if (response.statusCode == 200 && response.data != null) {
          final roleStr = response.data['role'] as String?;
          final role = parseUserRole(roleStr);
          final newState = WebSessionState.authenticated(role);
          emit(newState);
          return newState;
        }
      } catch (e) {
        if (e is DioException) {
          if (e.response?.statusCode == 401) {
            // Access token expired, try refresh token below
          } else {
            // Network error / timeout / 5xx -> retain tokens, return sessionUnknown
            final newState = WebSessionState.sessionUnknown(
              'Backend session validation unavailable. Please retry verification.',
            );
            emit(newState);
            return newState;
          }
        } else {
          final newState = WebSessionState.sessionUnknown(
            'Backend session validation unavailable. Please retry verification.',
          );
          emit(newState);
          return newState;
        }
      }
    }

    // Step 2: Try POST /auth/refresh with refresh token
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        final response = await client.post(
          '/auth/refresh',
          data: {'refresh_token': refreshToken},
        );
        if (response.statusCode == 200 && response.data != null) {
          final newAccessToken = response.data['access_token'] as String?;
          final newRefreshToken = response.data['refresh_token'] as String?;
          final userData = response.data['user'];

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            await tokenStorage.saveAccessToken(newAccessToken);
            if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
              await tokenStorage.saveRefreshToken(newRefreshToken);
            }
            final roleStr = userData != null ? userData['role'] as String? : null;
            final role = parseUserRole(roleStr);
            final newState = WebSessionState.authenticated(role);
            emit(newState);
            return newState;
          }
        }
      } catch (e) {
        if (e is DioException) {
          if (e.response?.statusCode == 401) {
            await tokenStorage.clearAllTokens();
            final newState = WebSessionState.unauthenticated();
            emit(newState);
            return newState;
          }
        }
        final newState = WebSessionState.sessionUnknown(
          'Backend session validation unavailable. Please retry verification.',
        );
        emit(newState);
        return newState;
      }
    }

    await tokenStorage.clearAllTokens();
    final newState = WebSessionState.unauthenticated();
    emit(newState);
    return newState;
  }

  void setAuthenticatedRole(UserRole role) {
    emit(WebSessionState.authenticated(role));
  }

  Future<void> logout() async {
    await tokenStorage.clearAllTokens();
    emit(WebSessionState.unauthenticated());
  }

  UserRole parseUserRole(String? roleStr) {
    switch (roleStr?.toLowerCase()) {
      case 'team_lead':
      case 'teamlead':
        return UserRole.teamLead;
      case 'manager':
        return UserRole.manager;
      case 'hr_admin':
      case 'hradmin':
      case 'hr':
        return UserRole.hrAdmin;
      case 'super_admin':
      case 'superadmin':
      case 'admin':
        return UserRole.superAdmin;
      case 'c_level':
      case 'clevel':
        return UserRole.cLevel;
      case 'employee':
      default:
        return UserRole.employee;
    }
  }
}
