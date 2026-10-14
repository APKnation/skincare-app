import 'dart:io';

import 'package:postgres/postgres.dart';

import 'env.dart';

Future<Connection> openDb(Map<String, String> env) => Connection.open(
      Endpoint(
        host: envOr(env, 'PGHOST', 'localhost'),
        port: int.parse(envOr(env, 'PGPORT', '5432')),
        database: envOr(env, 'PGDATABASE', 'surayangu'),
        username: envOr(env, 'PGUSER', 'surayangu'),
        password: envOr(env, 'PGPASSWORD', ''),
      ),
      settings: const ConnectionSettings(sslMode: SslMode.disable),
    );

/// Applies every migrations/*.sql file exactly once, in filename order.
Future<void> runMigrations(Connection db, String migrationsDir) async {
  await db.execute('''
    CREATE TABLE IF NOT EXISTS schema_migrations (
      name TEXT PRIMARY KEY,
      applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
    )''');
  final applied = <String>{
    for (final row in await db.execute('SELECT name FROM schema_migrations'))
      row[0] as String,
  };
  final dir = Directory(migrationsDir);
  final files = dir.listSync().whereType<File>().toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  for (final file in files) {
    final name = file.uri.pathSegments.last;
    if (applied.contains(name)) continue;
    stdout.writeln('applying migration $name');
    await db.execute(file.readAsStringSync());
    await db.execute(
      'INSERT INTO schema_migrations (name) VALUES (@name)',
      parameters: {'name': name},
    );
  }
}

extension RowExt on ResultRow {
  Map<String, Object?> toMap() => toColumnMap();
}
