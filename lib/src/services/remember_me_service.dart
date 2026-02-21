import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's "Remember Me" preference across cold starts.
///
/// On mobile, Firebase always keeps the session token alive.
/// "Remember Me = false" means: sign the user out on the next cold-launch
/// before showing the login page, giving the feeling of a session-only login.
class RememberMeService {
  static const String _key = 'auth_remember_me';

  /// Saves the [value] of the remember-me toggle.
  Future<void> save({required bool value}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  /// Loads the persisted value. Defaults to `true` if never set —
  /// first-time installs behave as if remember-me is on, which is the
  /// standard expectation for a mobile app.
  Future<bool> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  /// Clears the stored preference (e.g., on explicit sign-out).
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
