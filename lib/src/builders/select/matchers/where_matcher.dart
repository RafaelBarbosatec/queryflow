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

  @override
  String compose(String current);
  bool containsWhereSentence(String current) {
    return current.contains(key);
  }

  String addCote(dynamic value) {
    if (value is String) {
      bool isFunction = value.contains('()');
      if (isFunction) {
        return value;
      }
      return "'$value'";
    }
    if (value is num) {
      return value.toString();
    }
    return value;
  }
}

class Equals extends WhereMatcher {
  final dynamic value;
  Equals(this.value);

  @override
  String compose(String current) {
    if (containsWhereSentence(current)) {
      return '$current ${type.value} $not$field = ${addCote(value)}';
    } else {
      return '$current $key $not$field = ${addCote(value)}';
    }
  }
}

class WhereRaw extends WhereMatcher {
  final String value;
  WhereRaw(this.value);

  @override
  String compose(String current) {
    if (containsWhereSentence(current)) {
      return '$current ${type.value} $not $value';
    } else {
      return '$current $key $not$value';
    }
  }
}

class Between extends WhereMatcher {
  final String start;
  final String end;
  Between(this.start, this.end);

  @override
  String compose(String current) {
    if (containsWhereSentence(current)) {
      return '$current ${type.value} $not$field BETWEEN $start AND $end';
    } else {
      return '$current $key $not$field BETWEEN $start AND $end';
    }
  }
}

class BetweenDate extends WhereMatcher {
  final DateTime start;
  final DateTime end;
  BetweenDate(this.start, this.end);

  @override
  String compose(String current) {
    final dateStart = start.toIso8601String().split('T').first;
    final dateEnd = end.toIso8601String().split('T').first;

    if (containsWhereSentence(current)) {
      return "$current ${type.value} $not$field BETWEEN  ${addCote(dateStart)} AND  ${addCote(dateEnd)}";
    } else {
      return "$current $key $not$field BETWEEN ${addCote(dateStart)} AND ${addCote(dateEnd)}";
    }
  }
}

class EqualsDate extends WhereMatcher {
  final DateTime value;
  EqualsDate(this.value);

  @override
  String compose(String current) {
    final date = value.toIso8601String().split('T').first;
    if (containsWhereSentence(current)) {
      return "$current ${type.value} ${not}DATE($field) = ${addCote(date)}";
    } else {
      return "$current $key ${not}DATE($field) = ${addCote(date)}";
    }
  }
}

class Like extends WhereMatcher {
  final String value;
  Like(this.value);

  @override
  String compose(String current) {
    if (containsWhereSentence(current)) {
      return '$current ${type.value} $not$field like ${addCote(value)}';
    } else {
      return '$current $key $not$field like ${addCote(value)}';
    }
  }
}

class GreaterThan extends WhereMatcher {
  final dynamic value;
  GreaterThan(this.value);

  @override
  String compose(String current) {
    if (containsWhereSentence(current)) {
      return '$current ${type.value} $not$field > ${addCote(value)}';
    } else {
      return '$current $key $not$field > ${addCote(value)}';
    }
  }
}

class LessThan extends WhereMatcher {
  final dynamic value;
  LessThan(this.value);

  @override
  String compose(String current) {
    if (containsWhereSentence(current)) {
      return '$current ${type.value} $not$field < ${addCote(value)}';
    } else {
      return '$current $key $not$field < ${addCote(value)}';
    }
  }
}
