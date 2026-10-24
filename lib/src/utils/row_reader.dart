/// Reads a string column from a database result row using a case-insensitive
/// lookup.
///
/// MySQL reports `INFORMATION_SCHEMA` column labels in upper case (for example
/// `COLUMN_NAME`), while PostgreSQL folds unquoted identifiers to lower case
/// (`column_name`). A direct `row['COLUMN_NAME']` lookup is therefore not
/// portable between both databases.
String? readStringColumn(Map<String, dynamic> row, String columnName) {
  if (row.containsKey(columnName)) {
    return row[columnName]?.toString();
  }

  final normalized = columnName.toLowerCase();
  for (final entry in row.entries) {
    if (entry.key.toLowerCase() == normalized) {
      return entry.value?.toString();
    }
  }
  return null;
}
