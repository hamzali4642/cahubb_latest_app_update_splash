import 'package:logger/logger.dart';

class Log {
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      excludeBox: {Level.info: true, Level.debug: true},
    ),
  );

  static set level(Level level) {
    Logger.level = level;
  }

  static Level get level => Logger.level;

  static void info(String message) {
    _logger.i(message, stackTrace: null);
  }

  static void debug(String message, {Object? error, StackTrace? trace}) {
    _logger.d(message, error: error, stackTrace: trace);
  }

  static void warning(String message) {
    _logger.w(message);
  }

  static void error(String message, Object? error, StackTrace? trace) {
    _logger.e(message, error: error, stackTrace: trace);
  }

  static void loggerCheck() {
    info('This is info log');
    debug('This is debug log');
    warning('This is warning log');
    error('This is error log', Exception(), StackTrace.current);
  }
}
