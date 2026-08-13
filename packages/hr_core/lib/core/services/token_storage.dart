import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class TokenStorage {
  Future<void> saveToken(String token);
  Future<String?> getToken();
  Future<void> clearToken();
}

class SecureTokenStorage implements TokenStorage {
  final FlutterSecureStorage _secureStorage;
  static const _tokenKey = 'jwt_token';

  SecureTokenStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  @override
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  @override
  Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }
}
