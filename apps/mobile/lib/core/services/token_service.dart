import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../di/injection.dart';

class TokenService {
  final FlutterSecureStorage _storage;
  String? _inMemoryToken;

  TokenService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'jwt_token';
  static const _userKey = 'authenticated_user';

  Future<void> saveToken(String token) async {
    _inMemoryToken = token;
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {}
    try {
      if (getIt.isRegistered<SharedPreferences>()) {
        final prefs = getIt<SharedPreferences>();
        await prefs.setString(_tokenKey, token);
      }
    } catch (_) {}
  }

  Future<String?> getToken() async {
    if (_inMemoryToken != null) return _inMemoryToken;
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token != null && token.isNotEmpty) {
        _inMemoryToken = token;
        return token;
      }
    } catch (_) {}

    try {
      if (getIt.isRegistered<SharedPreferences>()) {
        final prefs = getIt<SharedPreferences>();
        final token = prefs.getString(_tokenKey);
        if (token != null && token.isNotEmpty) {
          _inMemoryToken = token;
          return token;
        }
      }
    } catch (_) {}

    return _inMemoryToken;
  }

  Future<void> saveUserRaw(String userJson) async {
    try {
      await _storage.write(key: _userKey, value: userJson);
    } catch (_) {}
  }

  Future<String?> getUserRaw() async {
    try {
      return await _storage.read(key: _userKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearToken() async {
    _inMemoryToken = null;
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    } catch (_) {}
    try {
      if (getIt.isRegistered<SharedPreferences>()) {
        final prefs = getIt<SharedPreferences>();
        await prefs.remove(_tokenKey);
      }
    } catch (_) {}
  }
}
