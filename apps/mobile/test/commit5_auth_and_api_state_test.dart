import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:hr_core/core/services/token_storage.dart';
import 'package:hr_app_demo/core/services/token_service.dart';
import 'package:hr_app_demo/core/bloc/session_cubit.dart';
import 'package:hr_app_demo/core/di/injection.dart';
import 'package:hr_core/features/kpi/data/datasources/api_kpi_repository_impl.dart';
import 'package:hr_core/features/payroll/data/datasources/api_payroll_repository_impl.dart';

class MockTokenStorage implements TokenStorage {
  String? token;
  String? refreshToken;

  @override
  Future<void> saveToken(String val) async => token = val;
  @override
  Future<String?> getToken() async => token;
  @override
  Future<void> clearToken() async => token = null;

  @override
  Future<void> saveAccessToken(String val) async => token = val;
  @override
  Future<String?> getAccessToken() async => token;
  @override
  Future<void> clearAccessToken() async => token = null;

  @override
  Future<void> saveRefreshToken(String val) async => refreshToken = val;
  @override
  Future<String?> getRefreshToken() async => refreshToken;
  @override
  Future<void> clearRefreshToken() async => refreshToken = null;

  @override
  Future<void> clearAllTokens() async {
    token = null;
    refreshToken = null;
  }
}

class FakeHttpClientAdapter implements HttpClientAdapter {
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
  late MockTokenStorage tokenStorage;
  late TokenService tokenService;
  late SessionCubit sessionCubit;
  late Dio dio;
  late FakeHttpClientAdapter adapter;

  setUp(() {
    getIt.reset();
    tokenStorage = MockTokenStorage();
    tokenService = TokenService(storage: tokenStorage);
    sessionCubit = SessionCubit(tokenStorage: tokenStorage);
    adapter = FakeHttpClientAdapter();

    dio = Dio(BaseOptions(baseUrl: 'http://localhost:3000'));
    dio.httpClientAdapter = adapter;

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!options.path.contains('/auth/login')) {
          final t = await tokenStorage.getToken();
          if (t != null && t.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $t';
          }
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401 &&
            !error.requestOptions.path.contains('/auth/login')) {
          await tokenStorage.clearToken();
          sessionCubit.setAuthenticated(false);
        }
        return handler.next(error);
      },
    ));

    getIt.registerSingleton<TokenStorage>(tokenStorage);
    getIt.registerSingleton<TokenService>(tokenService);
    getIt.registerSingleton<SessionCubit>(sessionCubit);
    getIt.registerSingleton<Dio>(dio);
  });

  group('Commit 5 - Auth Contract & Token Storage', () {
    test('Successful employeeCode/password login stores token', () async {
      adapter.onRequest = (options) {
        expect(options.path, equals('/auth/login'));
        expect(options.data['employeeCode'], equals('EMP001'));
        expect(options.data['password'], equals('secret123'));
        return ResponseBody.fromString(
          '{"access_token": "valid_jwt_token", "user": {"id": "usr_1", "employeeCode": "EMP001"}}',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final response = await dio.post('/auth/login', data: {
        'employeeCode': 'EMP001',
        'password': 'secret123',
      });

      final token = response.data['access_token'];
      await tokenService.saveToken(token);
      sessionCubit.setAuthenticated(true);

      expect(await tokenService.getToken(), equals('valid_jwt_token'));
      expect(sessionCubit.state.isAuthenticated, isTrue);
    });

    test('Failed login (401) does NOT store token and retains unauthenticated state', () async {
      adapter.onRequest = (options) {
        return ResponseBody.fromString(
          '{"statusCode": 401, "message": "Invalid employee code or password"}',
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      try {
        await dio.post('/auth/login', data: {
          'employeeCode': 'BAD_CODE',
          'password': 'wrong',
        });
        fail('Should throw DioException');
      } catch (e) {
        expect(e, isA<DioException>());
      }

      expect(await tokenService.getToken(), isNull);
      expect(sessionCubit.state.isAuthenticated, isFalse);
    });

    test('401 response on protected endpoint clears token and resets session', () async {
      await tokenService.saveToken('expired_token');
      sessionCubit.setAuthenticated(true);

      adapter.onRequest = (options) {
        expect(options.headers['Authorization'], equals('Bearer expired_token'));
        return ResponseBody.fromString(
          '{"statusCode": 401, "message": "Unauthorized"}',
          401,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      try {
        await dio.get('/attendance/today');
      } catch (_) {}

      expect(await tokenService.getToken(), isNull);
      expect(sessionCubit.state.isAuthenticated, isFalse);
    });

    test('Logout clears token and resets session state', () async {
      await tokenService.saveToken('active_token');
      sessionCubit.setAuthenticated(true);

      await sessionCubit.logout();

      expect(await tokenService.getToken(), isNull);
      expect(sessionCubit.state.isAuthenticated, isFalse);
    });
  });

  group('Commit 5 - API State Distinction (Empty vs Error)', () {
    test('Empty KPI API response returns empty list [] without throwing or returning demo data', () async {
      adapter.onRequest = (options) {
        return ResponseBody.fromString(
          '[]',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final kpiRepo = ApiKpiRepositoryImpl(dio: dio);
      final kpis = await kpiRepo.getCurrentKpis();

      expect(kpis, isEmpty);
    });

    test('Empty Payroll API response returns empty list [] without throwing or returning demo data', () async {
      adapter.onRequest = (options) {
        return ResponseBody.fromString(
          '[]',
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final payrollRepo = ApiPayrollRepositoryImpl(dio: dio);
      final payslips = await payrollRepo.getPayslips();

      expect(payslips, isEmpty);
    });

    test('API Error on KPI request throws DioException (enabling ErrorState UI with retry)', () async {
      adapter.onRequest = (options) {
        return ResponseBody.fromString(
          '{"statusCode": 500, "message": "Internal Server Error"}',
          500,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      };

      final kpiRepo = ApiKpiRepositoryImpl(dio: dio);

      expect(() => kpiRepo.getCurrentKpis(), throwsA(isA<DioException>()));
    });
  });
}
