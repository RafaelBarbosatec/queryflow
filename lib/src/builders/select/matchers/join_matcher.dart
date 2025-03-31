import 'package:queryflow/src/builders/matcher.dart';

enum JoinMatcherType {
  inner('INNER'),
  left('LEFT'),
  right('RIGHT'),
  fullOuter('FULL OUTER');

  final String value;
  const JoinMatcherType(this.value);
}

abstract class JoinMatcher implements BaseMatcher {
  String table = '';
  String selectTable = '';
  final String firstField;
  final String secondField;
  final JoinMatcherType type;
  JoinMatcher({
    required this.firstField,
    required this.secondField,
    required this.type,
  });

  @override
  MatchResult compose(String current) {
    String prefix = '${type.value} JOIN';
    return MatchResult(
      '$current $prefix $table ON $selectTable.$firstField = $table.$secondField',
    );
  }
}

class InnerJoin extends JoinMatcher {
  InnerJoin(String firstField, String secondField)
      : super(
          firstField: firstField,
          secondField: secondField,
          type: JoinMatcherType.inner,
        );
}

class LeftJoin extends JoinMatcher {
  LeftJoin(String firstField, String secondField)
      : super(
          firstField: firstField,
          secondField: secondField,
          type: JoinMatcherType.left,
        );
}

class RightJoin extends JoinMatcher {
  RightJoin(String firstField, String secondField)
      : super(
          firstField: firstField,
          secondField: secondField,
          type: JoinMatcherType.right,
        );
}

class FullOuterJoin extends JoinMatcher {
  FullOuterJoin(String firstField, String secondField)
      : super(
          firstField: firstField,
          secondField: secondField,
          type: JoinMatcherType.fullOuter,
        );
}

class JoinRaw extends JoinMatcher {
  final String value;
  JoinRaw(this.value)
      : super(
          firstField: '',
          secondField: '',
          type: JoinMatcherType.inner,
        );

  @override
  MatchResult compose(String current) {
    return MatchResult('$current $value');
  }
}
