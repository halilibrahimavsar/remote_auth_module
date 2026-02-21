import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

class FirebaseInitializer {
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on UnsupportedError {
      if (!kIsWeb) {
        rethrow;
      }

      final options = _firebaseWebOptionsFromDefines();
      if (options == null) {
        rethrow;
      }
      await Firebase.initializeApp(options: options);
    } catch (_) {
      if (!kIsWeb || !_isPlaceholderWebConfig(DefaultFirebaseOptions.web)) {
        rethrow;
      }

      final options = _firebaseWebOptionsFromDefines();
      if (options == null) {
        rethrow;
      }
      await Firebase.initializeApp(options: options);
    }
  }

  static FirebaseOptions? _firebaseWebOptionsFromDefines() {
    const apiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
    const messagingSenderId = String.fromEnvironment(
      'FIREBASE_WEB_MESSAGING_SENDER_ID',
    );
    const projectId = String.fromEnvironment('FIREBASE_WEB_PROJECT_ID');
    const authDomain = String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN');
    const storageBucket = String.fromEnvironment('FIREBASE_WEB_STORAGE_BUCKET');
    const measurementId = String.fromEnvironment('FIREBASE_WEB_MEASUREMENT_ID');

    if (apiKey.isEmpty ||
        appId.isEmpty ||
        messagingSenderId.isEmpty ||
        projectId.isEmpty) {
      return null;
    }

    String? optional(String value) => value.isEmpty ? null : value;

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: optional(authDomain),
      storageBucket: optional(storageBucket),
      measurementId: optional(measurementId),
    );
  }

  static bool _isPlaceholderWebConfig(FirebaseOptions options) {
    return options.apiKey == 'API_KEY' ||
        options.appId == 'APP_ID' ||
        options.projectId == 'PROJECT_ID';
  }
}
