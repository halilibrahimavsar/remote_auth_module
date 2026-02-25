import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper service around [FlutterSecureStorage] to enforce typed usage
/// and clear API boundaries.
class SecureStorageService {
  const SecureStorageService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  /// Writes a value to secure storage.
  Future<void> write({required String key, required String value}) async {
    await _storage.write(key: key, value: value);
  }

  /// Reads a value from secure storage.
  Future<String?> read({required String key}) async {
    return _storage.read(key: key);
  }

  /// Deletes a value from secure storage.
  Future<void> delete({required String key}) async {
    await _storage.delete(key: key);
  }

  /// Deletes all values from secure storage.
  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }
}
