import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:hr_core/core/services/token_storage.dart';
import 'package:hr_core/core/network/auth_interceptor.dart';
import '../lib/core/bloc/session_cubit.dart';

class MockTokenStorage implements TokenStorage {
  String? accessToken;
  String? refreshToken;

  @override
  Future<void> saveAccessToken(String token) async => accessToken = token;

  @override
  Future<String?> getAccessToken() async => accessToken;

  @override
  Future<void> clearAccessToken() async => accessToken = null;

  @override
  Future<void> saveRefreshToken(String token) async => refreshToken = token;

  @override
  Future<String?> getRefreshToken() async => refreshToken;

  @override
  Future<void> clearRefreshToken() async => refreshToken = null;

  @override
  Future<void> clearAllTokens() async {
    accessToken = null;
    refreshToken = null;
  }

  @override
  Future<void> saveToken(String token) => saveAccessToken(token);

  @override
  Future<String?> getToken() => getAccessToken();

  @override
  Future<void> clearToken() => clearAllTokens();
}

void main() {
  group('Persistent Session Security & Correctness Suite', () {
    late MockTokenStorage tokenStorage;

    beforeEach() {
      tokenStorage = MockTokenStorage();
    }

    test('1. SecureTokenStorage manages access_token and refresh_token independently without SharedPreferences', () async {
      tokenStorage = MockTokenStorage();
      await tokenStorage.saveAccessToken('acc-token-123');
      await tokenStorage.saveRefreshToken('ref-token-456');

      expect(await tokenStorage.getAccessToken(), 'acc-token-123');
      expect(await tokenStorage.getRefreshToken(), 'ref-token-456');

      await tokenStorage.clearAllTokens();

      expect(await tokenStorage.getAccessToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);
    });

    test('2. Logout clears both access and refresh tokens completely', () async {
      tokenStorage = MockTokenStorage();
      await tokenStorage.saveAccessToken('access-xyz');
      await tokenStorage.saveRefreshToken('refresh-xyz');

      final sessionCubit = SessionCubit(tokenStorage: tokenStorage);
      await sessionCubit.logout();

      expect(sessionCubit.state.status, SessionStatus.unauthenticated);
      expect(await tokenStorage.getAccessToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);
    });

    test('3. Network failure during checkStoredSession retains tokens and emits sessionUnknown', () async {
      tokenStorage = MockTokenStorage();
      await tokenStorage.saveAccessToken('valid-access');
      await tokenStorage.saveRefreshToken('valid-refresh');

      final mockDio = Dio();
      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          return handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.connectionTimeout,
              error: 'Connection timeout',
            ),
          );
        },
      ));

      final sessionCubit = SessionCubit(tokenStorage: tokenStorage, dio: mockDio);
      final state = await sessionCubit.checkStoredSession();

      expect(state.status, SessionStatus.sessionUnknown);
      expect(await tokenStorage.getAccessToken(), 'valid-access');
      expect(await tokenStorage.getRefreshToken(), 'valid-refresh');
    });
  });
}
