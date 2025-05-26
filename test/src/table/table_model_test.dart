import 'package:queryflow/queryflow.dart';
import 'package:test/test.dart';

void main() {
// Additional tests for TableModel class
  group('TableModel tests', () {
    test('primaryKeyColumn returns the name of the first primary key', () {
      final tableModel = TableModel(
        name: 'users',
        columns: {
          'id': TypeInt(isPrimaryKey: true),
          'uuid': TypeVarchar(isPrimaryKey: true), // Another primary key
          'name': TypeVarchar(),
        },
      );

      expect(tableModel.primaryKeyColumn, 'id');
    });

    test('primaryKeyColumn returns empty string when no primary key exists',
        () {
      final tableModel = TableModel(
        name: 'logs',
        columns: {
          'event': TypeVarchar(),
          'timestamp': TypeDateTime(),
        },
      );

      expect(tableModel.primaryKeyColumn, '');
    });

    test('toCreateSql generates valid SQL with single primary key', () {
      final tableModel = TableModel(
        name: 'products',
        columns: {
          'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
          'name': TypeVarchar(isNotNull: true),
          'price': TypeDouble(defaultValue: '0.0'),
          'in_stock': TypeBool(defaultValue: 'TRUE'),
        },
      );

      final sql = tableModel.toCreateSql();
      expect(sql, contains('CREATE TABLE `products`'));
      expect(sql, contains('`id` INT(11) NOT NULL AUTO_INCREMENT'));
      expect(sql, contains('`name` VARCHAR(255) NOT NULL'));
      expect(sql, contains('`price` DOUBLE DEFAULT 0.0'));
      expect(sql, contains('`in_stock` BOOLEAN DEFAULT TRUE'));
      expect(sql, contains('PRIMARY KEY (id)'));
      expect(sql, contains('ENGINE=InnoDB'));
    });

    test('toCreateSql generates valid SQL with multiple primary keys', () {
      final tableModel = TableModel(
        name: 'order_items',
        columns: {
          'order_id': TypeInt(isPrimaryKey: true),
          'product_id': TypeInt(isPrimaryKey: true),
          'quantity': TypeInt(),
        },
      );

      final sql = tableModel.toCreateSql();
      expect(sql, contains('CREATE TABLE `order_items`'));
      expect(sql, contains('PRIMARY KEY (order_id, product_id)'));
    });

    test('toCreateSql includes foreign key constraints', () {
      final tableModel = TableModel(
        name: 'comments',
        columns: {
          'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
          'content': TypeText(),
          'user_id': TypeInt(
            foreignKey: ForeingKey(
              table: 'users',
              column: 'id',
            ),
          ),
          'post_id': TypeInt(
            foreignKey: ForeingKey(
              table: 'posts',
              column: 'id',
            ),
          ),
        },
      );

      final sql = tableModel.toCreateSql();
      expect(sql, contains('CONSTRAINT `fk_user_id_users_id`'));
      expect(
          sql, contains('FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)'));
      expect(sql, contains('CONSTRAINT `fk_post_id_posts_id`'));
      expect(
          sql, contains('FOREIGN KEY (`post_id`) REFERENCES `posts` (`id`)'));
    });

    test('toCreateSql uses custom engine, charset and auto increment', () {
      final tableModel = TableModel(
        name: 'logs',
        columns: {
          'id': TypeInt(isPrimaryKey: true, isAutoIncrement: true),
          'message': TypeText(),
        },
        engine: 'MyISAM',
        outomaticIncrement: 1000,
        charset: 'latin1',
      );

      final sql = tableModel.toCreateSql();
      expect(sql, contains('ENGINE=MyISAM'));
      expect(sql, contains('AUTO_INCREMENT=1000'));
      expect(sql, contains('DEFAULT CHARSET=latin1'));
    });
  });
}
