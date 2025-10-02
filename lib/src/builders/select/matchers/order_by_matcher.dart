import 'package:queryflow/src/builders/matcher.dart';
import 'package:queryflow/src/builders/select/matchers/where_matchers.dart';
import 'package:queryflow/src/builders/select/select_contracts.dart';
import 'package:queryflow/src/dialect/sql_dialect.dart';

class OrderByMatcher extends EndMatcher {
  final List<String> fields;
  final OrderByType type;
  @override
  SqlDialect? dialect;

  OrderByMatcher({
    required this.fields,
    required this.type,
  }) : super(raw: '');

  @override
  void setDialect(SqlDialect? dialect) {
    this.dialect = dialect;
  }

  @override
  MatchResult compose(String current) {
    final quotedFields = fields.map((f) => dialect?.quoteIdentifier(f) ?? f);
    final orderType = type.value;
    return MatchResult(
      'ORDER BY ${quotedFields.join(', ')} $orderType',
    );
  }
}
