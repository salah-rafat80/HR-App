import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:hr_core/core/services/token_storage.dart';
import 'package:hr_app_demo/core/services/token_service.dart';
import 'package:hr_app_demo/core/bloc/session_cubit.dart';
import 'package:hr_app_demo/core/di/injection.dart';

class TestTokenStorage implements TokenStorage {
  String? token;
  bool shouldThrowOnWrite = false;

  @override
  Future<void> saveToken(String val) async {
    if (shouldThrowOnWrite) {
      throw Exception('Secure storage unavailable');
    }
    token = val;
  }

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> clearToken() async => token = null;
}

class FakeAdapter implements HttpClientAdapter {
  late ResponseBody Function(RequestOptions options) onRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return onRequest(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Commit 5.1 — Auth Security & Token Persistence', () {
    test('1. JWT is NEVER written to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final storage = TestTokenStorage();
      final tokenService = TokenService(storage: storage);

      await tokenService.saveToken('secure_jwt_123');

      expect(await tokenService.getToken(), equals('secure_jwt_123'));
      expect(prefs.getString('jwt_token'), isNull);
    });

    test('2. Secure-storage failure does NOT fall back to insecure SharedPreferences persistence', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final storage = TestTokenStorage()..shouldThrowOnWrite = true;
      final tokenService = TokenService(storage: storage);

      expect(() => tokenService.saveToken('secret_token'), throwsA(isA<Exception>()));
      expect(prefs.getString('jwt_token'), isNull);
    });

    test('3. Non-401 validation failure (e.g. 500 / timeout) DOES NOT authenticate session', () async {
      final storage = TestTokenStorage()..token = 'existing_valid_format_jwt';
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
      final adapter = FakeAdapter();
      dio.httpClientAdapter = adapter;

      adapter.onRequest = (options) {
        expect(options.path, equals('/attendance/today'));
        return ResponseBody.fromString(
          '{"statusCode": 500, "message": "Database Error"}',
          500,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final sessionCubit = SessionCubit(tokenStorage: storage, dio: dio);
      final state = await sessionCubit.checkStoredSession();

      expect(state.status, equals(SessionStatus.sessionUnknown));
      expect(state.isAuthenticated, isFalse);
      expect(sessionCubit.state.isAuthenticated, isFalse);
    });

    test('4. Missing API_BASE_URL throws StateError and CANNOT call Render silently', () async {
      await getIt.reset();
      expect(() => initDI(), throwsA(isA<StateError>()));
    });
  });
}
