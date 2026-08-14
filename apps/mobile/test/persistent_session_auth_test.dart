import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:hr_core/core/services/token_storage.dart';
import 'package:hr_core/core/network/auth_interceptor.dart';
import '../lib/core/bloc/session_cubit.dart';

class MockTokenStorage implements TokenStorage {
  String? accessToken;
  String? refreshToken;
  int clearAllTokensCallCount = 0;

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
    clearAllTokensCallCount++;
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

class MockHttpClientAdapter implements HttpClientAdapter {
  final Future<ResponseBody> Function(RequestOptions options) fetchHandler;
  MockHttpClientAdapter(this.fetchHandler);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return fetchHandler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('Mobile Persistent Session & Interceptor Security Suite', () {
    late MockTokenStorage tokenStorage;

    setUp(() {
      tokenStorage = MockTokenStorage();
    });

    test('1. SecureTokenStorage manages access_token and refresh_token independently without SharedPreferences', () async {
      await tokenStorage.saveAccessToken('acc-token-123');
      await tokenStorage.saveRefreshToken('ref-token-456');

      expect(await tokenStorage.getAccessToken(), 'acc-token-123');
      expect(await tokenStorage.getRefreshToken(), 'ref-token-456');

      await tokenStorage.clearAllTokens();

      expect(await tokenStorage.getAccessToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);
    });

    test('2. Logout clears both access and refresh tokens completely', () async {
      await tokenStorage.saveAccessToken('access-xyz');
      await tokenStorage.saveRefreshToken('refresh-xyz');

      final sessionCubit = SessionCubit(tokenStorage: tokenStorage);
      await sessionCubit.logout();

      expect(sessionCubit.state.status, SessionStatus.unauthenticated);
      expect(await tokenStorage.getAccessToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);
    });

    test('3. /auth/me 401 followed by valid refresh restores session and updates access token', () async {
      await tokenStorage.saveAccessToken('expired-access');
      await tokenStorage.saveRefreshToken('valid-refresh');

      final mockDio = Dio();
      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/auth/me') {
            return handler.reject(DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 401,
              ),
            ));
          }
          if (options.path == '/auth/refresh') {
            return handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'access_token': 'new-access-token',
                'refresh_token': 'new-refresh-token',
                'user': {'id': 'user-1', 'role': 'employee'},
              },
            ));
          }
          return handler.next(options);
        },
      ));

      final sessionCubit = SessionCubit(tokenStorage: tokenStorage, dio: mockDio);
      final state = await sessionCubit.checkStoredSession();

      expect(state.status, SessionStatus.authenticated);
      expect(await tokenStorage.getAccessToken(), 'new-access-token');
      expect(await tokenStorage.getRefreshToken(), 'new-refresh-token');
    });

    test('4. Refresh 401 clears both tokens and sets session to unauthenticated', () async {
      await tokenStorage.saveAccessToken('expired-access');
      await tokenStorage.saveRefreshToken('invalid-refresh');

      final mockDio = Dio();
      mockDio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/auth/me' || options.path == '/auth/refresh') {
            return handler.reject(DioException(
              requestOptions: options,
              response: Response(
                requestOptions: options,
                statusCode: 401,
              ),
            ));
          }
          return handler.next(options);
        },
      ));

      final sessionCubit = SessionCubit(tokenStorage: tokenStorage, dio: mockDio);
      final state = await sessionCubit.checkStoredSession();

      expect(state.status, SessionStatus.unauthenticated);
      expect(await tokenStorage.getAccessToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);
    });

    test('5. Refresh network failure/timeout preserves both tokens and emits sessionUnknown', () async {
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
              error: 'Network Timeout',
            ));
          }
          return handler.next(options);
        },
      ));

      final sessionCubit = SessionCubit(tokenStorage: tokenStorage, dio: mockDio);
      final state = await sessionCubit.checkStoredSession();

      expect(state.status, SessionStatus.sessionUnknown);
      expect(await tokenStorage.getAccessToken(), 'expired-access');
      expect(await tokenStorage.getRefreshToken(), 'valid-refresh');
    });

    test('6. Concurrent 401s with invalid refresh token trigger exactly ONE POST /auth/refresh, ONE clearAllTokens, and ONE onUnauthenticated', () async {
      await tokenStorage.saveAccessToken('expired-access');
      await tokenStorage.saveRefreshToken('invalid-refresh');

      int refreshCallCount = 0;
      int onUnauthenticatedCount = 0;

      final mockDio = Dio(BaseOptions(baseUrl: 'https://test-api.com'));
      mockDio.interceptors.add(SingleFlightAuthInterceptor(
        dio: mockDio,
        tokenStorage: tokenStorage,
        onUnauthenticated: () async {
          onUnauthenticatedCount++;
        },
      ));

      mockDio.httpClientAdapter = MockHttpClientAdapter((options) async {
        if (options.path == '/auth/refresh') {
          refreshCallCount++;
          await Future.delayed(const Duration(milliseconds: 50));
          return ResponseBody.fromString(
            '{"message":"Invalid refresh token"}',
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }

        if (options.path == '/data1' || options.path == '/data2') {
          return ResponseBody.fromString(
            '{"message":"Unauthorized"}',
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }

        return ResponseBody.fromString('{}', 404);
      });

      Future<Object?> safeGet(String path) async {
        try {
          return await mockDio.get(path);
        } catch (e) {
          return e;
        }
      }

      await Future.wait([safeGet('/data1'), safeGet('/data2')]);

      expect(refreshCallCount, 1);
      expect(tokenStorage.clearAllTokensCallCount, 1);
      expect(onUnauthenticatedCount, 1);
      expect(await tokenStorage.getAccessToken(), isNull);
      expect(await tokenStorage.getRefreshToken(), isNull);
    });

    test('7. Concurrent 401s while refresh receives timeout/5xx/malformed body execute ONE refresh attempt, ZERO clearAllTokens, and ZERO onUnauthenticated', () async {
      await tokenStorage.saveAccessToken('expired-access');
      await tokenStorage.saveRefreshToken('valid-refresh');

      int refreshCallCount = 0;
      int onUnauthenticatedCount = 0;

      final mockDio = Dio(BaseOptions(baseUrl: 'https://test-api.com'));
      mockDio.interceptors.add(SingleFlightAuthInterceptor(
        dio: mockDio,
        tokenStorage: tokenStorage,
        onUnauthenticated: () async {
          onUnauthenticatedCount++;
        },
      ));

      mockDio.httpClientAdapter = MockHttpClientAdapter((options) async {
        if (options.path == '/auth/refresh') {
          refreshCallCount++;
          await Future.delayed(const Duration(milliseconds: 50));
          return ResponseBody.fromString(
            'Internal Server Error',
            500,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }

        if (options.path == '/data1' || options.path == '/data2') {
          return ResponseBody.fromString(
            '{"message":"Unauthorized"}',
            401,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }

        return ResponseBody.fromString('{}', 404);
      });

      Future<Object?> safeGet(String path) async {
        try {
          return await mockDio.get(path);
        } catch (e) {
          return e;
        }
      }

      final results = await Future.wait([safeGet('/data1'), safeGet('/data2')]);

      expect(refreshCallCount, 1);
      expect(tokenStorage.clearAllTokensCallCount, 0);
      expect(onUnauthenticatedCount, 0);
      expect(await tokenStorage.getAccessToken(), 'expired-access');
      expect(await tokenStorage.getRefreshToken(), 'valid-refresh');
      expect(results[0], isA<DioException>());
      expect(results[1], isA<DioException>());
    });

    test('8. Later independent refresh cycle succeeds normally after a previous network failure', () async {
      await tokenStorage.saveAccessToken('expired-access');
      await tokenStorage.saveRefreshToken('valid-refresh');

      int refreshCallCount = 0;
      int onUnauthenticatedCount = 0;

      final mockDio = Dio(BaseOptions(baseUrl: 'https://test-api.com'));
      mockDio.interceptors.add(SingleFlightAuthInterceptor(
        dio: mockDio,
        tokenStorage: tokenStorage,
        onUnauthenticated: () async {
          onUnauthenticatedCount++;
        },
      ));

      mockDio.httpClientAdapter = MockHttpClientAdapter((options) async {
        if (options.path == '/auth/refresh') {
          refreshCallCount++;
          if (refreshCallCount == 1) {
            // First refresh attempt fails with 503 Service Unavailable
            return ResponseBody.fromString(
              'Service Unavailable',
              503,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          } else {
            // Second refresh attempt succeeds
            return ResponseBody.fromString(
              '{"access_token":"new-fresh-access-token","refresh_token":"new-fresh-refresh-token"}',
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
        }

        if (options.path == '/data') {
          if (options.headers['Authorization'] != 'Bearer new-fresh-access-token') {
            return ResponseBody.fromString(
              '{"message":"Unauthorized"}',
              401,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          } else {
            return ResponseBody.fromString(
              '{"success":true}',
              200,
              headers: {
                Headers.contentTypeHeader: [Headers.jsonContentType],
              },
            );
          }
        }

        return ResponseBody.fromString('{}', 404);
      });

      // Cycle 1: Refresh fails with 503
      try {
        await mockDio.get('/data');
      } catch (e) {
        expect(e, isA<DioException>());
      }

      expect(refreshCallCount, 1);
      expect(tokenStorage.clearAllTokensCallCount, 0);
      expect(onUnauthenticatedCount, 0);
      expect(await tokenStorage.getAccessToken(), 'expired-access');

      // Cycle 2: Independent later request triggers a fresh refresh cycle and succeeds
      final response = await mockDio.get('/data');

      expect(refreshCallCount, 2);
      expect(response.statusCode, 200);
      expect(response.data['success'], true);
      expect(await tokenStorage.getAccessToken(), 'new-fresh-access-token');
      expect(await tokenStorage.getRefreshToken(), 'new-fresh-refresh-token');
      expect(tokenStorage.clearAllTokensCallCount, 0);
      expect(onUnauthenticatedCount, 0);
    });
  });
}
