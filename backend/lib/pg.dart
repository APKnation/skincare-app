import 'package:postgres/postgres.dart';

/// Runs [sql] as a named-parameter statement (`@foo` placeholders).
///
/// The postgres 3.5 driver executes a bare `String` query as a direct literal
/// and never binds `@name` parameters, so every parameterized query must be
/// wrapped in `Sql.named` to be tokenized.
extension NamedSql on Session {
  Future<Result> q(
    String sql, {
    Object? parameters,
    bool ignoreRows = false,
    Duration? timeout,
  }) =>
      execute(
        Sql.named(sql),
        parameters: parameters,
        ignoreRows: ignoreRows,
        timeout: timeout,
      );
}
