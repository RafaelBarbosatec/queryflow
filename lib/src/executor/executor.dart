abstract class Executor implements ExecutorOnly {
  Future<void> connect();
  Future<void> close();
  Future<List<Map<String, dynamic>>> executeTransation(
    Future<List<Map<String, dynamic>>> Function(ExecutorOnly executor)
        transaction,
  );
}

abstract class ExecutorOnly {
  Future<List<Map<String, dynamic>>> execute(String query);
  Future<List<Map<String, dynamic>>> executePrepared(
    String query,
    List<dynamic> params,
  );
}
