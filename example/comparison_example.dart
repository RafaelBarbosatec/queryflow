import 'package:queryflow/queryflow.dart';

class Product {
  static const table = 'products';
  final int? id;
  final String name;
  final double price;
  final bool active;
  final DateTime createdAt;

  Product({
    required this.name,
    required this.price,
    required this.active,
    required this.createdAt,
    this.id,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) 'id': id,
      'name': name,
      'price': price,
      'active': active,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int?,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      active: map['active'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  @override
  String toString() => 'Product(id: $id, name: $name, price: \$${price.toStringAsFixed(2)}, active: $active)';
}

Future<void> testDatabase(String dbName, Queryflow queryflow) async {
  print('\n🔧 Testing $dbName Database');
  print('${'=' * (20 + dbName.length)}');

  try {
    // Synchronize schema
    await queryflow.syncronize(dropTable: true);
    print('✅ Schema synchronized');

    // Insert test products
    final products = [
      Product(
        name: '$dbName Widget',
        price: 19.99,
        active: true,
        createdAt: DateTime.now(),
      ),
      Product(
        name: '$dbName Gadget',
        price: 39.99,
        active: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      ),
      Product(
        name: '$dbName Tool',
        price: 59.99,
        active: true,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    for (final product in products) {
      final id = await queryflow.insertModel(product);
      print('📝 Inserted ${product.name} with ID: $id');
    }

    // Query active products
    print('\n🔍 Active products:');
    final activeProducts = await queryflow
        .selectModel<Product>()
        .where('active', Equals(true))
        .orderBy(['price'])
        .fetch();

    for (final product in activeProducts) {
      print('  • $product');
    }

    // Aggregate query
    final totalProducts = await queryflow.select('products').count();
    print('\n📊 Total products: $totalProducts');

    // Price range query
    print('\n💰 Products under \$50:');
    final affordableProducts = await queryflow
        .selectModel<Product>()
        .where('price', LessThan(50.0))
        .fetch();

    for (final product in affordableProducts) {
      print('  • $product');
    }

    // Update product
    if (activeProducts.isNotEmpty) {
      final productToUpdate = Product(
        id: activeProducts.first.id,
        name: '${activeProducts.first.name} (Updated)',
        price: activeProducts.first.price * 1.1, // 10% price increase
        active: activeProducts.first.active,
        createdAt: activeProducts.first.createdAt,
      );

      await queryflow.updateModel(productToUpdate);
      print('\n✏️ Updated product: ${productToUpdate.name}');
    }

    // Test raw SQL
    final rawResult = await queryflow.execute('''
      SELECT
        COUNT(*) as total_count,
        AVG(price) as avg_price,
        MAX(price) as max_price,
        MIN(price) as min_price
      FROM products
    ''');

    if (rawResult.isNotEmpty) {
      final stats = rawResult.first;
      print('\n📈 Product Statistics:');
      print('  Total: ${stats['total_count']}');
      print('  Average Price: \$${(stats['avg_price'] as num).toStringAsFixed(2)}');
      print('  Max Price: \$${(stats['max_price'] as num).toStringAsFixed(2)}');
      print('  Min Price: \$${(stats['min_price'] as num).toStringAsFixed(2)}');
    }

    print('✅ $dbName test completed successfully!');

  } catch (e, stackTrace) {
    print('❌ Error in $dbName test: $e');
    print('Stack trace: $stackTrace');
  }
}

void main() async {
  print('🚀 Queryflow Database Comparison Example');
  print('========================================');
  print('This example demonstrates Queryflow working with both MySQL and PostgreSQL');

  // MySQL Configuration
  final mysqlDb = Queryflow(
    databaseType: DatabaseType.mysql,
    host: 'localhost',
    port: 3306,
    userName: 'root',
    password: 'password',
    databaseName: 'queryflow_test',
    secure: false,
    debug: false, // Set to true to see SQL queries
    typeAdapters: [
      QueryTypeAdapter<Product>(
        table: Product.table,
        primaryKeyColumn: 'id',
        toMap: (product) => product.toMap(),
        fromMap: Product.fromMap,
      ),
    ],
    tables: [
      TableModel(
        name: 'products',
        columns: {
          'id': TypeInt(
            isPrimaryKey: true,
            isAutoIncrement: true,
          ),
          'name': TypeVarchar(length: 255),
          'price': TypeDouble(),
          'active': TypeBool(),
          'created_at': TypeDateTime(),
        },
      ),
    ],
  );

  // PostgreSQL Configuration
  final postgresDb = Queryflow(
    databaseType: DatabaseType.postgresql,
    host: 'localhost',
    port: 5432,
    userName: 'postgres',
    password: 'password',
    databaseName: 'queryflow_test',
    useSSL: false,
    debug: false, // Set to true to see SQL queries
    typeAdapters: [
      QueryTypeAdapter<Product>(
        table: Product.table,
        primaryKeyColumn: 'id',
        toMap: (product) => product.toMap(),
        fromMap: Product.fromMap,
      ),
    ],
    tables: [
      TableModel(
        name: 'products',
        columns: {
          'id': TypeInt(
            isPrimaryKey: true,
            isAutoIncrement: true,
          ),
          'name': TypeVarchar(length: 255),
          'price': TypeDouble(),
          'active': TypeBool(),
          'created_at': TypeDateTime(),
        },
      ),
    ],
  );

  try {
    // Test MySQL
    await testDatabase('MySQL', mysqlDb);

    // Test PostgreSQL
    await testDatabase('PostgreSQL', postgresDb);

    print('\n🎉 All database tests completed!');
    print('Both MySQL and PostgreSQL work seamlessly with Queryflow!');

  } catch (e) {
    print('\n❌ Main error: $e');
  } finally {
    // Clean up connections
    await mysqlDb.close();
    await postgresDb.close();
    print('\n🔒 All database connections closed');
  }
}