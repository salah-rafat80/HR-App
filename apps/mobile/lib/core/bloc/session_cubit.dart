import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';

import '../di/injection.dart';

import 'package:hr_core/core/services/token_storage.dart';

enum SessionStatus { initial, authenticated, unauthenticated, sessionUnknown }

class UserProfile extends Equatable {
  final String id;
  final String employeeCode;
  final String name;
  final String email;
  final String role;
  final String? department;
  final String? title;

  const UserProfile({
    required this.id,
    required this.employeeCode,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.title,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      employeeCode: json['employeeCode']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? 'employee',
      department: json['department']?.toString(),
      title: json['title']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, employeeCode, name, email, role, department, title];
}

class SessionState extends Equatable {
  final SessionStatus status;
  final String? errorMessage;
  final String? role;
  final UserProfile? userProfile;

  const SessionState({
    required this.status,
    this.errorMessage,
    this.role,
    this.userProfile,
  });

  factory SessionState.initial() =>
      const SessionState(status: SessionStatus.initial);
  factory SessionState.authenticated({String? role, UserProfile? userProfile}) =>
      SessionState(
        status: SessionStatus.authenticated,
        role: role ?? userProfile?.role,
        userProfile: userProfile,
      );
  factory SessionState.unauthenticated() =>
      const SessionState(status: SessionStatus.unauthenticated);
  factory SessionState.sessionUnknown(String msg) =>
      SessionState(status: SessionStatus.sessionUnknown, errorMessage: msg);

  bool get isAuthenticated => status == SessionStatus.authenticated;

  @override
  List<Object?> get props => [status, errorMessage, role, userProfile];
}

class SessionCubit extends Cubit<SessionState> {
  final TokenStorage? _tokenStorage;
  final Dio? _dio;

  SessionCubit({TokenStorage? tokenStorage, Dio? dio})
    : _tokenStorage = tokenStorage,
      _dio = dio,
      super(SessionState.initial());

  TokenStorage get tokenStorage =>
      _tokenStorage ??
      (getIt.isRegistered<TokenStorage>()
          ? getIt<TokenStorage>()
          : SecureTokenStorage());

  Dio? get dio => _dio ?? (getIt.isRegistered<Dio>() ? getIt<Dio>() : null);

  UserProfile? _parseProfile(dynamic data) {
    if (data is Map<String, dynamic>) {
      return UserProfile.fromJson(data);
    } else if (data is Map) {
      return UserProfile.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  Future<SessionState> checkStoredSession() async {
    final accessToken = await tokenStorage.getAccessToken();
    final refreshToken = await tokenStorage.getRefreshToken();

    if ((accessToken == null || accessToken.isEmpty) &&
        (refreshToken == null || refreshToken.isEmpty)) {
      final newState = SessionState.unauthenticated();
      emit(newState);
      return newState;
    }

    final client = dio;
    if (client == null) {
      final newState = SessionState.sessionUnknown(
        'HTTP Client not initialized',
      );
      emit(newState);
      return newState;
    }

    // Step 1: Try GET /auth/me with existing access token
    if (accessToken != null && accessToken.isNotEmpty) {
      try {
        final response = await client.get('/auth/me');
        if (response.statusCode == 200) {
          final profile = _parseProfile(response.data);
          final newState = SessionState.authenticated(
            role: profile?.role ?? _roleFromAuthMe(response.data),
            userProfile: profile,
          );
          emit(newState);
          return newState;
        }
      } catch (e) {
        if (e is DioException) {
          if (e.response?.statusCode == 401) {
            // Access token expired/invalid, try refresh token below
          } else {
            // Network error / timeout / 5xx -> retain tokens, return sessionUnknown
            final newState = SessionState.sessionUnknown(
              'Backend session validation unavailable. Please retry verification.',
            );
            emit(newState);
            return newState;
          }
        } else {
          final newState = SessionState.sessionUnknown(
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

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            await tokenStorage.saveAccessToken(newAccessToken);
            if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
              await tokenStorage.saveRefreshToken(newRefreshToken);
            }
            final me = await client.get('/auth/me');
            final profile = _parseProfile(me.data);
            final newState = SessionState.authenticated(
              role: profile?.role ?? _roleFromAuthMe(me.data),
              userProfile: profile,
            );
            emit(newState);
            return newState;
          }
        }
      } catch (e) {
        if (e is DioException) {
          if (e.response?.statusCode == 401) {
            // Refresh token invalid/expired/inactive user -> clear tokens
            await tokenStorage.clearAllTokens();
            final newState = SessionState.unauthenticated();
            emit(newState);
            return newState;
          }
        }
        // Network error / timeout / 5xx -> retain tokens, return sessionUnknown
        final newState = SessionState.sessionUnknown(
          'Backend session validation unavailable. Please retry verification.',
        );
        emit(newState);
        return newState;
      }
    }

    // Neither token worked
    await tokenStorage.clearAllTokens();
    final newState = SessionState.unauthenticated();
    emit(newState);
    return newState;
  }

  String? _roleFromAuthMe(dynamic data) {
    if (data is Map) return data['role']?.toString();
    return null;
  }

  void setAuthenticated(bool isAuthenticated, {String? role, UserProfile? userProfile, dynamic userData}) {
    if (isAuthenticated) {
      final profile = userProfile ?? _parseProfile(userData);
      emit(SessionState.authenticated(role: role ?? profile?.role, userProfile: profile));
    } else {
      emit(SessionState.unauthenticated());
    }
  }

  Future<void> logout() async {
    await tokenStorage.clearAllTokens();
    emit(SessionState.unauthenticated());
  }
}
