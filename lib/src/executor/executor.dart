/// Marker interface implemented by executors that are already bound to an
/// active transaction.
///
/// Callers can use `executor is TransactionExecutor` to detect this case and
/// run statements directly on the current transaction instead of opening a
/// nested one.
abstract class TransactionExecutor {}

abstract class Executor {
  Future<void> connect();
  Future<void> close();
  Future<T> executeTransation<T>(
    Future<T> Function(Executor executor) transaction,
  );
  Future<List<Map<String, dynamic>>> execute(String query);
  Future<List<Map<String, dynamic>>> executePrepared(
    String query,
    List<dynamic> params,
  );
}
