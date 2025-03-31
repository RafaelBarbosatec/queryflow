abstract class Executor {
  Future<List<Map<String, dynamic>>> execute(String query);
  Future<void> connect();
  Future<void> close();
}