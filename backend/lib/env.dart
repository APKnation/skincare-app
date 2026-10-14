import 'dart:io';

/// Minimal .env loader: process environment wins over file values.
Map<String, String> loadEnv(String path) {
  final values = <String, String>{};
  final file = File(path);
  if (file.existsSync()) {
    for (final line in file.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final eq = trimmed.indexOf('=');
      if (eq == -1) continue;
      values[trimmed.substring(0, eq).trim()] =
          trimmed.substring(eq + 1).trim();
    }
  }
  for (final key in [
    'PGHOST',
    'PGPORT',
    'PGDATABASE',
    'PGUSER',
    'PGPASSWORD',
    'PORT',
  ]) {
    final fromEnv = Platform.environment[key];
    if (fromEnv != null && fromEnv.isNotEmpty) values[key] = fromEnv;
  }
  return values;
}

String envOr(Map<String, String> env, String key, String fallback) =>
    env[key] ?? fallback;
