import 'package:remote_auth_module/src/core/storage/secure_storage_service.dart';

/// Persists the user's "Remember Me" preference across cold starts.
///
/// On mobile, Firebase always keeps the session token alive.
/// "Remember Me = false" means: sign the user out on the next cold-launch
/// before showing the login page, giving the feeling of a session-only login.
class RememberMeService {
  RememberMeService({SecureStorageService? storageService})
    : _storage = storageService ?? const SecureStorageService();

  final SecureStorageService _storage;
  static const String _key = 'auth_remember_me';

  /// Saves the [value] of the remember-me toggle.
  Future<void> save({required bool value}) async {
    await _storage.write(key: _key, value: value.toString());
  }

  /// Loads the persisted value. Defaults to `true` if never set —
  /// first-time installs behave as if remember-me is on, which is the
  /// standard expectation for a mobile app.
  Future<bool> load() async {
    final val = await _storage.read(key: _key);
    if (val == null) return true;
    return val == 'true';
  }

  /// Clears the stored preference (e.g., on explicit sign-out).
  Future<void> clear() async {
    await _storage.delete(key: _key);
  }
}
