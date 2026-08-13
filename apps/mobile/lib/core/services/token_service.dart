import 'package:hr_core/core/services/token_storage.dart';

class TokenService {
  final TokenStorage _storage;

  TokenService({TokenStorage? storage})
      : _storage = storage ?? SecureTokenStorage();

  Future<void> saveToken(String token) async {
    await _storage.saveToken(token);
  }

  Future<String?> getToken() async {
    return await _storage.getToken();
  }

  Future<void> clearToken() async {
    await _storage.clearToken();
  }
}
