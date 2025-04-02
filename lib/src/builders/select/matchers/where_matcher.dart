import 'package:queryflow/src/builders/matcher.dart';

enum WhereMatcherType {
  and('AND'),
  or('OR');

  final String value;
  const WhereMatcherType(this.value);
}

abstract class WhereMatcher implements BaseMatcher {
  WhereMatcherType type = WhereMatcherType.and;
  bool isNot = false;
  String field = '';
  final _key = 'WHERE';

  String get _not => isNot ? 'NOT ' : '';

  String addsAgragator(String current) {
    String agregator = '';
    if (current.contains(_key)) {
      agregator = ' ${type.value}';
    } else {
      agregator = ' $_key$_not';
    }
    return '$current$agregator';
  }
}

class WhereRaw extends WhereMatcher {
  final String value;
  WhereRaw(this.value);

  @override
  MatchResult compose(String current) {
    return MatchResult(
      '${addsAgragator(current)} $value',
    );
  }
}

class _ComparatorWhere extends WhereMatcher {
  final String comparator;
  final dynamic value;
  _ComparatorWhere(
    this.value,
    this.comparator,
  );

  @override
  MatchResult compose(String current) {
    List params = [value];
    return MatchResult(
      '${addsAgragator(current)} $field $comparator ?',
      params,
    );
  }
}

class Equals extends _ComparatorWhere {
  Equals(dynamic value) : super(value, '=');
}

class Different extends _ComparatorWhere {
  Different(dynamic value) : super(value, '!=');
}

class GreaterThan extends _ComparatorWhere {
  GreaterThan(dynamic value) : super(value, '>');
}

class GreaterThanOrEqual extends _ComparatorWhere {
  GreaterThanOrEqual(dynamic value) : super(value, '>=');
}

class LessThan extends _ComparatorWhere {
  LessThan(dynamic value) : super(value, '<');
}

class LessThanOrEqual extends _ComparatorWhere {
  LessThanOrEqual(dynamic value) : super(value, '<=');
}

class Between extends WhereMatcher {
  final dynamic start;
  final dynamic end;
  Between(this.start, this.end);

  @override
  MatchResult compose(String current) {
    List params = [start, end];
    return MatchResult(
      '${addsAgragator(current)} $field BETWEEN ? AND ?',
      params,
    );
  }
}

class BetweenDate extends WhereMatcher {
  final DateTime start;
  final DateTime end;
  BetweenDate(this.start, this.end);

  @override
  MatchResult compose(String current) {
    final dateStart = start.toIso8601String().split('T').first;
    final dateEnd = end.toIso8601String().split('T').first;
    List params = [dateStart, dateEnd];

    return MatchResult(
      "${addsAgragator(current)} $field BETWEEN ? AND ?",
      params,
    );
  }
}

class EqualsDate extends WhereMatcher {
  final DateTime value;
  EqualsDate(this.value);

  @override
  MatchResult compose(String current) {
    final date = value.toIso8601String().split('T').first;
    List params = [date];
    return MatchResult(
      "${addsAgragator(current)} DATE($field) = ?",
      params,
    );
  }
}

class Like extends WhereMatcher {
  final String value;
  Like(this.value);

  @override
  MatchResult compose(String current) {
    final params = [value];
    return MatchResult(
      '${addsAgragator(current)} $field like ?',
      params,
    );
  }
}

class In extends WhereMatcher {
  final List<String> value;
  In(this.value);

  @override
  MatchResult compose(String current) {
    final params = value;
    return MatchResult(
      '${addsAgragator(current)} $field IN (${value.map((e) => '?').join(',')})',
      params,
    );
  }
}
