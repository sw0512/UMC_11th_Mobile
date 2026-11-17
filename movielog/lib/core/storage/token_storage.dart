import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<void> saveAccessToken(String token);
  Future<String?> readAccessToken();
  Future<void> deleteAccessToken();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);
  final FlutterSecureStorage _storage;
  static const key = 'movielog.access_token';
  @override
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: key, value: token);
  @override
  Future<String?> readAccessToken() => _storage.read(key: key);
  @override
  Future<void> deleteAccessToken() => _storage.delete(key: key);
}
