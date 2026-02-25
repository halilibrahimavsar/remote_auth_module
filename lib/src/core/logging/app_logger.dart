import 'package:logger/logger.dart';

/// Centralized logging for the app.
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, errorMethodCount: 5, lineLength: 80),
  );

  /// Log a message at level [Level.debug].
  static void d(String message, {Object? error}) {
    _logger.d(message, error: error);
  }

  /// Log a message at level [Level.info].
  static void i(String message) {
    _logger.i(message);
  }

  /// Log a message at level [Level.warning].
  static void w(String message, {Object? error}) {
    _logger.w(message, error: error);
  }

  /// Log a message at level [Level.error].
  static void e(String message, {Object? error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
