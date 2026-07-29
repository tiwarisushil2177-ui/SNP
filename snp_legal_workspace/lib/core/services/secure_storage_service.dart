import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Thin wrapper around FlutterSecureStorage for typed, consistent access.
/// Tokens and credentials never leave encrypted storage on device.
class SecureStorageService {
  SecureStorageService(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteAll() => _storage.deleteAll();
}
