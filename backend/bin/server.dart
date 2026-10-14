import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'package:sura_yangu_backend/api_core.dart';
import 'package:sura_yangu_backend/api_orders.dart';
import 'package:sura_yangu_backend/db.dart';
import 'package:sura_yangu_backend/env.dart';
import 'package:sura_yangu_backend/seed.dart';

Future<void> main(List<String> args) async {
  final env = loadEnv(
      args.isNotEmpty ? args.first : 'backend/.env');
  final db = await openDb(env);

  final migrationsDir = File('backend/migrations/001_init.sql').existsSync()
      ? 'backend/migrations'
      : 'migrations';
  await runMigrations(db, migrationsDir);
  await seedIfEmpty(db);

  final ctx = Ctx(db);
  final router = Router();
  registerCoreRoutes(router, ctx);
  registerCartOrderRoutes(router, ctx);
  router.get('/api/health', (Request request) => json({'ok': true}));

  final handler = const Pipeline()
      .addMiddleware(_cors())
      .addHandler(router.call);

  final port = int.parse(env['PORT'] ?? '8181');
  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  stdout.writeln(
      'Sura Yangu API listening on http://${server.address.host}:$port '
      '(db ${envOr(env, 'PGHOST', 'localhost')}/${envOr(env, 'PGDATABASE', 'surayangu')})');
}

Middleware _cors() => (inner) => (request) async {
      if (request.method == 'OPTIONS') {
        return Response(
          204,
          headers: _corsHeaders,
        );
      }
      final response = await inner(request);
      return response.change(headers: _corsHeaders);
    };

const _corsHeaders = {
  'access-control-allow-origin': '*',
  'access-control-allow-methods': 'GET,POST,PUT,DELETE,OPTIONS',
  'access-control-allow-headers': 'content-type,authorization',
};
