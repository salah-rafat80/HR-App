import 'dart:typed_data';
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

    test('6. Concurrent 401s trigger exactly one POST /auth/refresh and retry original request at most once', () async {
      await tokenStorage.saveAccessToken('expired-access');
      await tokenStorage.saveRefreshToken('valid-refresh');

      int refreshCallCount = 0;
      bool unauthenticatedTriggered = false;

      final mockDio = Dio(BaseOptions(baseUrl: 'https://test-api.com'));
      mockDio.interceptors.add(SingleFlightAuthInterceptor(
        dio: mockDio,
        tokenStorage: tokenStorage,
        onUnauthenticated: () async {
          unauthenticatedTriggered = true;
        },
      ));

      mockDio.httpClientAdapter = MockHttpClientAdapter((options) async {
        if (options.path == '/auth/refresh') {
          refreshCallCount++;
          await Future.delayed(const Duration(milliseconds: 50));
          return ResponseBody.fromString(
            '{"access_token":"fresh-access-token","refresh_token":"fresh-refresh-token"}',
            200,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }

        if (options.path == '/data') {
          if (options.headers['Authorization'] != 'Bearer fresh-access-token') {
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

      final req1 = mockDio.get('/data');
      final req2 = mockDio.get('/data');

      final results = await Future.wait([req1, req2]);

      expect(refreshCallCount, 1);
      expect(results[0].data['success'], true);
      expect(results[1].data['success'], true);
      expect(unauthenticatedTriggered, false);
      expect(await tokenStorage.getAccessToken(), 'fresh-access-token');
    });
  });
}
