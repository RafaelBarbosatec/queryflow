class ForeignKeyNameGenerator {
  static const int maxLength = 64;

  const ForeignKeyNameGenerator._();

  static String generate(
    String currentTable,
    String currentColumn,
    String targetTable,
    String targetColumn, {
    int maxKeyNameLength = maxLength,
  }) {
    final generatedName = [
      'fk',
      _shortIdentifier(currentTable),
      _shortIdentifier(currentColumn),
      _shortIdentifier(targetTable),
      _shortIdentifier(targetColumn),
    ].where((part) => part.isNotEmpty).join('_');

    if (generatedName.length <= maxKeyNameLength) {
      return generatedName;
    }

    final hash = _shortHash(
      '$currentTable|$currentColumn|$targetTable|$targetColumn',
    );
    final prefixLength = maxKeyNameLength - hash.length - 1;
    final prefix =
        generatedName.substring(0, prefixLength).replaceAll(RegExp(r'_+$'), '');

    return '${prefix}_$hash';
  }

  static String _shortIdentifier(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');

    if (normalized.length <= 12) {
      return normalized;
    }

    final parts = normalized.split('_');
    if (parts.length > 1) {
      final abbreviated = parts
          .map((part) => part.length <= 4 ? part : part.substring(0, 4))
          .join('_');
      if (abbreviated.length <= 12) {
        return abbreviated;
      }
      return abbreviated.substring(0, 12).replaceAll(RegExp(r'_+$'), '');
    }

    return '${normalized.substring(0, 8)}_${_shortHash(normalized)}';
  }

  static String _shortHash(String value) {
    var hash = 0x811C9DC5;
    for (final codeUnit in value.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }

    return hash.toRadixString(16).padLeft(8, '0');
  }
}
