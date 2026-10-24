/// Converts MySQL style `?` placeholders into PostgreSQL `$1, $2, ...`
/// placeholders.
///
/// The conversion skips single quoted strings, double quoted identifiers and
/// dollar quoted strings (`$$...$$` or `$tag$...$tag$`), so literal question
/// marks are preserved. Queries that already use `$n` placeholders are returned
/// unchanged (mixing `?` and `$n` in the same query is not supported).
String normalizePostgresPlaceholders(String query) {
  if (!query.contains('?')) {
    return query;
  }

  final buffer = StringBuffer();
  var index = 0;
  var paramIndex = 1;

  while (index < query.length) {
    final char = query[index];

    if (char == "'") {
      final end = _skipQuoted(query, index, "'");
      buffer.write(query.substring(index, end));
      index = end;
      continue;
    }

    if (char == '"') {
      final end = _skipQuoted(query, index, '"');
      buffer.write(query.substring(index, end));
      index = end;
      continue;
    }

    if (char == r'$') {
      final dollarQuote = _dollarQuoteTag(query, index);
      if (dollarQuote != null) {
        final end = query.indexOf(dollarQuote, index + dollarQuote.length);
        if (end != -1) {
          final endIndex = end + dollarQuote.length;
          buffer.write(query.substring(index, endIndex));
          index = endIndex;
          continue;
        }
      }
      buffer.write(char);
      index++;
      continue;
    }

    if (char == '?') {
      buffer.write('\$$paramIndex');
      paramIndex++;
      index++;
      continue;
    }

    buffer.write(char);
    index++;
  }

  return buffer.toString();
}

/// Returns the index right after the closing quote, handling escaped quotes
/// (`''` for strings and `""` for identifiers).
int _skipQuoted(String value, int start, String quote) {
  var index = start + 1;
  while (index < value.length) {
    if (value[index] == quote) {
      if (index + 1 < value.length && value[index + 1] == quote) {
        index += 2;
        continue;
      }
      return index + 1;
    }
    index++;
  }
  return value.length;
}

/// Detects a dollar quote tag at [start] and returns it (for example `$$` or
/// `$body$`), or `null` when the `$` is not a dollar quote.
String? _dollarQuoteTag(String value, int start) {
  if (value[start] != r'$') {
    return null;
  }
  var index = start + 1;
  if (index < value.length && value[index] == r'$') {
    return r'$$';
  }
  if (index >= value.length || !_isIdentifierStart(value[index])) {
    return null;
  }
  while (index < value.length && _isIdentifierPart(value[index])) {
    index++;
  }
  if (index < value.length && value[index] == r'$') {
    return value.substring(start, index + 1);
  }
  return null;
}

bool _isIdentifierStart(String char) {
  final code = char.codeUnitAt(0);
  return (code >= 65 && code <= 90) ||
      (code >= 97 && code <= 122) ||
      char == '_';
}

bool _isIdentifierPart(String char) {
  final code = char.codeUnitAt(0);
  return _isIdentifierStart(char) || (code >= 48 && code <= 57);
}
