import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:hr_core/core/services/token_storage.dart';
import 'package:hr_web/core/bloc/session_cubit.dart';

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
  group('Web Persistent Session & Security Suite', () {
    late MockTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = MockTokenStorage();
    });

    test('1. Restored role "hr" maps consistently to UserRole.hrAdmin matching fresh-login behavior', () async {
      tokenStorage = MockTokenStorage();
      await tokenStorage.saveAccessToken('valid-access-token');

      final mockDio = Dio();
      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/auth/me') {
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'id': 'user-hr-1',
                  'employeeCode': 'HR-001',
                  'role': 'hr',
                },
              ),
            );
          }
          return handler.next(options);
        },
      ));

      final sessionCubit = SessionCubit(tokenStorage: tokenStorage, dio: mockDio);
      final state = await sessionCubit.checkStoredSession();

      expect(state.status, WebSessionStatus.authenticated);
      expect(state.role, UserRole.hrAdmin);
    });

    test('2. Web session restore falls back to POST /auth/refresh when GET /auth/me returns 401', () async {
      tokenStorage = MockTokenStorage();
      await tokenStorage.saveAccessToken('expired-access');
      await tokenStorage.saveRefreshToken('valid-refresh');

      final mockDio = Dio();
      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/auth/me') {
            return handler.reject(DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 401),
            ));
          }
          if (options.path == '/auth/refresh') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'access_token': 'new-access-token',
                'refresh_token': 'new-refresh-token',
                'user': {'id': 'user-1', 'role': 'manager'},
              },
            ));
          }
          return handler.next(options);
        },
      ));

      final sessionCubit = SessionCubit(tokenStorage: tokenStorage, dio: mockDio);
      final state = await sessionCubit.checkStoredSession();

      expect(state.status, WebSessionStatus.authenticated);
      expect(state.role, UserRole.manager);
      expect(await tokenStorage.getAccessToken(), 'new-access-token');
      expect(await tokenStorage.getRefreshToken(), 'new-refresh-token');
    });

    test('3. Web session network error during refresh retains tokens and emits sessionUnknown', () async {
      tokenStorage = MockTokenStorage();
      await tokenStorage.saveAccessToken('expired-access');
      await tokenStorage.saveRefreshToken('valid-refresh');

      final mockDio = Dio();
      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/auth/me') {
            return handler.reject(DioException(
              requestOptions: options,
              response: Response(requestOptions: options, statusCode: 401),
            ));
          }
          if (options.path == '/auth/refresh') {
            return handler.reject(DioException(
              requestOptions: options,
              type: DioExceptionType.connectionTimeout,
              error: 'Connection timeout',
            ));
          }
          return handler.next(options);
        },
      ));

      final sessionCubit = SessionCubit(tokenStorage: tokenStorage, dio: mockDio);
      final state = await sessionCubit.checkStoredSession();

      expect(state.status, WebSessionStatus.sessionUnknown);
      expect(await tokenStorage.getAccessToken(), 'expired-access');
      expect(await tokenStorage.getRefreshToken(), 'valid-refresh');
    });

    test('4. Web session logout clears all stored tokens', () async {
      tokenStorage = MockTokenStorage();
      await tokenStorage.saveAccessToken('web-access');
      await tokenStorage.saveRefreshToken('web-refresh');

      final sessionCubit = SessionCubit(tokenStorage: tokenStorage);
      await sessionCubit.logout();

      expect(sessionCubit.state.status, WebSessionStatus.unauthenticated);
      expect(await tokenStorage.getAccessToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);
    });
  });
}
