import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// Centralized logger for the application
///
/// Provides structured logging with different levels:
/// - trace: Detailed information, typically only of interest when diagnosing problems
/// - debug: Detailed information, typically of interest only when diagnosing problems
/// - info: Informational messages highlighting the progress of the application
/// - warning: Warning messages for potentially harmful situations
/// - error: Error events that might still allow the application to continue
/// - fatal: Very severe error events that might cause the application to abort
class AppLogger {
  static Logger? _instance;

  static Logger get instance {
    _instance ??= Logger(
      printer: PrettyPrinter(
        methodCount: 2, // Number of method calls to be displayed
        errorMethodCount: 8, // Number of method calls if stacktrace is provided
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      level: kDebugMode ? Level.debug : Level.warning,
    );
    return _instance!;
  }

  /// Log a trace message
  static void trace(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.t(message, error: error, stackTrace: stackTrace);
  }

  /// Log a debug message
  static void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log an info message
  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log a warning message
  static void warning(
    dynamic message, [
    dynamic error,
    StackTrace? stackTrace,
  ]) {
    instance.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log an error message
  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log a fatal error message
  static void fatal(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.f(message, error: error, stackTrace: stackTrace);
  }
}
