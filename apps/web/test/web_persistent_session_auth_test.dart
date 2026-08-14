import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:hr_core/core/enums/role_enums.dart';
import 'package:hr_core/core/services/token_storage.dart';
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
  group('Web Persistent Session & Security Suite', () {
    late MockTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = MockTokenStorage();
    });

    test('1. Web session cubit parses role correctly and emits authenticated with restored role', () async {
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
                  'id': 'user-1',
                  'employeeCode': 'EMP-001',
                  'role': 'super_admin',
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
      expect(state.role, UserRole.superAdmin);
    });

    test('2. Web session logout clears all stored tokens', () async {
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
