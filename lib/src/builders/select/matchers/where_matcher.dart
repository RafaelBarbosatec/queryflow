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
  final key = 'WHERE';

  String get not => isNot ? 'NOT ' : '';
  bool containsWhereSentence(String current) {
    return current.contains(key);
  }
}

class Equals extends WhereMatcher {
  final dynamic value;
  Equals(this.value);

  @override
  MatchResult compose(String current) {
    List params = [value];
    if (containsWhereSentence(current)) {
      return MatchResult(
        '$current ${type.value} $not$field = ?',
        params,
      );
    } else {
      return MatchResult(
        '$current $key $not$field = ?',
        params,
      );
    }
  }
}

class WhereRaw extends WhereMatcher {
  final String value;
  WhereRaw(this.value);

  @override
  MatchResult compose(String current) {
    if (containsWhereSentence(current)) {
      return MatchResult(
        '$current ${type.value} $not $value',
      );
    } else {
      return MatchResult(
        '$current $key $not$value',
      );
    }
  }
}

class Between extends WhereMatcher {
  final dynamic start;
  final dynamic end;
  Between(this.start, this.end);

  @override
  MatchResult compose(String current) {
    List params = [start, end];
    if (containsWhereSentence(current)) {
      return MatchResult(
        '$current ${type.value} $not$field BETWEEN ? AND ?',
        params,
      );
    } else {
      return MatchResult(
        '$current $key $not$field BETWEEN ? AND ?',
        params,
      );
    }
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

    if (containsWhereSentence(current)) {
      return MatchResult(
        "$current ${type.value} $not$field BETWEEN  ? AND ?",
        params,
      );
    } else {
      return MatchResult(
        "$current $key $not$field BETWEEN ? AND ?",
        params,
      );
    }
  }
}

class EqualsDate extends WhereMatcher {
  final DateTime value;
  EqualsDate(this.value);

  @override
  MatchResult compose(String current) {
    final date = value.toIso8601String().split('T').first;
    List params = [date];
    if (containsWhereSentence(current)) {
      return MatchResult(
        "$current ${type.value} ${not}DATE($field) = ?",
        params,
      );
    } else {
      return MatchResult(
        "$current $key ${not}DATE($field) = ?",
        params,
      );
    }
  }
}

class Like extends WhereMatcher {
  final String value;
  Like(this.value);

  @override
  MatchResult compose(String current) {
    final params = [value];
    if (containsWhereSentence(current)) {
      return MatchResult('$current ${type.value} $not$field like ?', params);
    } else {
      return MatchResult('$current $key $not$field like ?', params);
    }
  }
}

class GreaterThan extends WhereMatcher {
  final dynamic value;
  GreaterThan(this.value);

  @override
  MatchResult compose(String current) {
    final params = [value];
    if (containsWhereSentence(current)) {
      return MatchResult('$current ${type.value} $not$field > ?', params);
    } else {
      return MatchResult('$current $key $not$field > ?', params);
    }
  }
}

class LessThan extends WhereMatcher {
  final dynamic value;
  LessThan(this.value);

  @override
  MatchResult compose(String current) {
    final params = [value];
    if (containsWhereSentence(current)) {
      return MatchResult('$current ${type.value} $not$field < ?', params);
    } else {
      return MatchResult('$current $key $not$field < ?', params);
    }
  }
}
