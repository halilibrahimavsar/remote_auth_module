import 'package:flutter/material.dart';
import 'app.dart';
import 'services/firebase_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? bootstrapError;
  try {
    await FirebaseInitializer.initialize();
  } catch (error, stackTrace) {
    debugPrint('Firebase bootstrap failed: $error\n$stackTrace');
    bootstrapError = error.toString();
  }

  runApp(ExampleApp(bootstrapError: bootstrapError));
}
