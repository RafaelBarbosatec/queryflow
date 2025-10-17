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
