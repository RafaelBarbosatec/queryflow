// ignore_for_file: avoid_print

abstract class QueryLogger {
  void d(Object? message);
  void i(Object? message);
  void s(Object? message);
  void e(Object? message);
}

class QueryLoggerDefault implements QueryLogger {
  @override
  void d(Object? message) {
    print('$message');
  }

  @override
  void i(Object? message) {
    print('\x1B[34m💡 $message\x1B[0m');
  }

  @override
  void s(Object? message) {
    print('\x1B[32m⚡ $message\x1B[0m');
  }

  @override
  void e(Object? message) {
    print('\x1B[31m🚨 $message\x1B[0m');
  }
}

/// Logger that discards every message.
///
/// Used by default when `debug` is `false` so that library consumers do not get
/// unsolicited output. Errors still surface as thrown exceptions.
class QueryLoggerSilent implements QueryLogger {
  const QueryLoggerSilent();

  @override
  void d(Object? message) {}

  @override
  void i(Object? message) {}

  @override
  void s(Object? message) {}

  @override
  void e(Object? message) {}
}
