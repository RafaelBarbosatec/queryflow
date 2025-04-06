// ignore_for_file: avoid_print

abstract class QueryLogger {
  void d(Object? message);
}

class QueryLoggerDefault implements QueryLogger {
  @override
  void d(Object? message) {
    print('$message\n');
  }
}
