import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hr_core/core/services/token_storage.dart';
import 'package:hr_app_demo/core/bloc/session_cubit.dart';

class TestTokenStorage implements TokenStorage {
  String? _token;
  String? _refreshToken;
  TestTokenStorage(this._token);

  @override
  Future<void> saveToken(String token) async => _token = token;
  @override
  Future<String?> getToken() async => _token;
  @override
  Future<void> clearToken() async => _token = null;

  @override
  Future<void> saveAccessToken(String token) async => _token = token;
  @override
  Future<String?> getAccessToken() async => _token;
  @override
  Future<void> clearAccessToken() async => _token = null;

  @override
  Future<void> saveRefreshToken(String token) async => _refreshToken = token;
  @override
  Future<String?> getRefreshToken() async => _refreshToken;
  @override
  Future<void> clearRefreshToken() async => _refreshToken = null;

  @override
  Future<void> clearAllTokens() async {
    _token = null;
    _refreshToken = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
      'F-002 Session Test: checkStoredSession returns SessionState correctly based on token & storage',
      () async {
    final tokenStorage = TestTokenStorage('sample_jwt_123');
    final getIt = GetIt.instance;
    await getIt.reset();
    getIt.registerSingleton<TokenStorage>(tokenStorage);

    final sessionCubit = SessionCubit(tokenStorage: tokenStorage);

    final state1 = await sessionCubit.checkStoredSession();
    expect(state1.status, equals(SessionStatus.sessionUnknown));

    await tokenStorage.clearToken();
    final state2 = await sessionCubit.checkStoredSession();
    expect(state2.status, equals(SessionStatus.unauthenticated));
    expect(sessionCubit.state.isAuthenticated, isFalse);
  });
}
