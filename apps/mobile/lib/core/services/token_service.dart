import 'package:hr_core/core/services/token_storage.dart';

class TokenService {
  final TokenStorage _storage;

  TokenService({TokenStorage? storage})
      : _storage = storage ?? SecureTokenStorage();

  Future<void> saveAccessToken(String token) async {
    await _storage.saveAccessToken(token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.getAccessToken();
  }

  Future<void> clearAccessToken() async {
    await _storage.clearAccessToken();
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.saveRefreshToken(token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.getRefreshToken();
  }

  Future<void> clearRefreshToken() async {
    await _storage.clearRefreshToken();
  }

  Future<void> clearAllTokens() async {
    await _storage.clearAllTokens();
  }

  Future<void> saveToken(String token) => saveAccessToken(token);
  Future<String?> getToken() => getAccessToken();
  Future<void> clearToken() => clearAllTokens();
}
