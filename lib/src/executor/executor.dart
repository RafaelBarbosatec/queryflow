abstract class Executor {
  Future<void> connect();
  Future<void> close();
  Future<List<Map<String, dynamic>>> executeTransation(
    Future<List<Map<String, dynamic>>> Function(Executor executor) transaction,
  );
  Future<List<Map<String, dynamic>>> execute(String query);
  Future<List<Map<String, dynamic>>> executePrepared(
    String query,
    List<dynamic> params,
  );
}
