import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:dio/dio.dart';
import '../di/injection.dart';
import 'package:hr_core/core/services/token_storage.dart';

enum SessionStatus {
  initial,
  authenticated,
  unauthenticated,
  sessionUnknown,
}

class SessionState extends Equatable {
  final SessionStatus status;
  final String? errorMessage;

  const SessionState({
    required this.status,
    this.errorMessage,
  });

  factory SessionState.initial() =>
      const SessionState(status: SessionStatus.initial);
  factory SessionState.authenticated() =>
      const SessionState(status: SessionStatus.authenticated);
  factory SessionState.unauthenticated() =>
      const SessionState(status: SessionStatus.unauthenticated);
  factory SessionState.sessionUnknown(String msg) =>
      SessionState(status: SessionStatus.sessionUnknown, errorMessage: msg);

  bool get isAuthenticated => status == SessionStatus.authenticated;

  @override
  List<Object?> get props => [status, errorMessage];
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

  Future<SessionState> checkStoredSession() async {
    final token = await tokenStorage.getToken();
    if (token == null || token.isEmpty) {
      final newState = SessionState.unauthenticated();
      emit(newState);
      return newState;
    }

    final client = dio;
    if (client == null) {
      final newState =
          SessionState.sessionUnknown('HTTP Client not initialized');
      emit(newState);
      return newState;
    }

    try {
      final response = await client.get('/attendance/today');
      if (response.statusCode == 200) {
        final newState = SessionState.authenticated();
        emit(newState);
        return newState;
      } else {
        final newState = SessionState.sessionUnknown(
            'Unexpected response code: ${response.statusCode}');
        emit(newState);
        return newState;
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        await tokenStorage.clearToken();
        final newState = SessionState.unauthenticated();
        emit(newState);
        return newState;
      }

      final newState = SessionState.sessionUnknown(
        'Backend session validation unavailable. Please retry login.',
      );
      emit(newState);
      return newState;
    }
  }

  void setAuthenticated(bool isAuthenticated) {
    if (isAuthenticated) {
      emit(SessionState.authenticated());
    } else {
      emit(SessionState.unauthenticated());
    }
  }

  Future<void> logout() async {
    await tokenStorage.clearToken();
    emit(SessionState.unauthenticated());
  }
}
