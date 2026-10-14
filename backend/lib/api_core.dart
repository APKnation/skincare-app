import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'pg.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth.dart';

class Ctx {
  final Connection db;

  Ctx(this.db);
}

Response json(Object? body, {int status = 200}) => Response(
      status,
      body: jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );

Response fail(String message, {int status = 400}) =>
    json({'error': message}, status: status);

Future<Map<String, Object?>> readBody(Request request) async =>
    jsonDecode(await request.readAsString()) as Map<String, Object?>;

Map<String, Object?> rowToUser(ResultRow row) {
  final m = row.toColumnMap();
  return {
    'id': m['id'],
    'name': m['name'],
    'email': m['email'],
    'phone': m['phone'],
    'role': m['role'],
    'sellerStatus': m['seller_status'],
    'shopName': m['shop_name'],
    'shopLocation': m['shop_location'],
    'shopDescription': m['shop_description'],
    'contactInfo': m['contact_info'],
    'deactivated': m['deactivated'],
    'createdAt': (m['created_at'] as DateTime).toIso8601String(),
  };
}

Map<String, Object?> rowToProduct(ResultRow row) {
  final m = row.toColumnMap();
  return {
    'id': m['id'],
    'name': m['name'],
    'brand': m['brand'],
    'category': m['category'],
    'description': m['description'],
    'priceTZS': m['price_tzs'],
    'imageUrl': m['image_url'],
    'ingredients': m['ingredients'],
    'suitableSkinTypes': m['suitable_skin_types'],
    'targetsConcerns': m['targets_concerns'],
    'containsFlagged': m['contains_flagged'],
    'isComedogenic': m['is_comedogenic'],
    'usageInstructions': m['usage_instructions'],
    'sideEffects': m['side_effects'],
    'warnings': m['warnings'],
    'stock': m['stock'],
    'sellerId': m['seller_id'],
    'shopName': m['shop_name'],
    'shopLocation': m['shop_location'],
    'approval': m['approval'],
    'createdAt': (m['created_at'] as DateTime).toIso8601String(),
  };
}

const userColumns =
    'id,name,email,phone,role,seller_status,shop_name,shop_location,'
    'shop_description,contact_info,deactivated,created_at';
const productColumns =
    'id,name,brand,category,description,price_tzs,image_url,ingredients,'
    'suitable_skin_types,targets_concerns,contains_flagged,is_comedogenic,'
    'usage_instructions,side_effects,warnings,stock,seller_id,shop_name,'
    'shop_location,approval,created_at';

Future<Map<String, Object?>?> findUser(Ctx ctx, String id) async =>
    (await ctx.db.q(
      'SELECT $userColumns FROM users WHERE id = @id',
      parameters: {'id': id},
    )).firstOrNull?.toColumnMap();

/// Returns the authenticated user map or null (response must be 401).
Future<Map<String, Object?>?> requireAuth(
    Ctx ctx, Request request, Request? _) async {
  final header = request.headers['authorization'] ?? '';
  final token = header.startsWith('Bearer ') ? header.substring(7) : '';
  if (token.isEmpty) return null;
  final rows = await ctx.db.q(
    'SELECT $userColumns FROM users '
    'WHERE id = (SELECT user_id FROM sessions WHERE token = @token)',
    parameters: {'token': token},
  );
  final user = rows.firstOrNull?.toColumnMap();
  if (user == null || user['deactivated'] == true) return null;
  return user;
}

Future<Response> _createSession(Ctx ctx, String userId) async {
  final token = randomId(24);
  await ctx.db.q(
    'INSERT INTO sessions (token, user_id) VALUES (@t,@u)',
    parameters: {'t': token, 'u': userId},
  );
  return tokenResponse(token);
}

Response tokenResponse(String token) => json({'token': token});

void registerCoreRoutes(Router router, Ctx ctx) {
  router.post('/api/auth/register', (Request request) async {
    final body = await readBody(request);
    final email = (body['email'] as String).trim().toLowerCase();
    final exists = await ctx.db.q(
      'SELECT 1 FROM users WHERE lower(email) = @e',
      parameters: {'e': email},
    );
    if (exists.firstOrNull != null) {
      return fail('An account with this email already exists.', status: 409);
    }
    final salt = makeSalt();
    final rows = await ctx.db.q(
      '''INSERT INTO users (name, email, phone, password_hash, password_salt)
         VALUES (@n,@e,@p,@h,@s) RETURNING id''',
      parameters: {
        'n': (body['name'] as String).trim(),
        'e': email,
        'p': (body['phone'] as String).trim(),
        'h': hashPassword(body['password'] as String, salt),
        's': salt,
      },
    );
    return await _createSession(ctx, rows.first[0] as String);
  });

  router.post('/api/auth/login', (Request request) async {
    final body = await readBody(request);
    final rows = await ctx.db.q(
      'SELECT id, password_hash, password_salt, deactivated FROM users '
      'WHERE lower(email) = @e',
      parameters: {'e': (body['email'] as String).trim().toLowerCase()},
    );
    final row = rows.firstOrNull;
    if (row == null ||
        !verifyPassword(
            body['password'] as String, row[2] as String, row[1] as String)) {
      return fail('Wrong email or password.', status: 401);
    }
    if (row[3] == true) {
      return fail('This account has been deactivated. Contact support.',
          status: 403);
    }
    return await _createSession(ctx, row[0] as String);
  });

  router.post('/api/auth/logout', (Request request) async {
    final header = request.headers['authorization'] ?? '';
    if (header.startsWith('Bearer ')) {
      await ctx.db.q('DELETE FROM sessions WHERE token = @t',
          parameters: {'t': header.substring(7)});
    }
    return json({'ok': true});
  });

  router.get('/api/me', (Request request) async {
    final user = await requireAuth(ctx, request, null);
    if (user == null) return fail('Not logged in.', status: 401);
    return json(rowMapToUser(user));
  });

  router.put('/api/me', (Request request) async {
    final user = await requireAuth(ctx, request, null);
    if (user == null) return fail('Not logged in.', status: 401);
    final body = await readBody(request);
    final email = (body['email'] as String).trim().toLowerCase();
    final clash = (await ctx.db.q(
      'SELECT 1 FROM users WHERE lower(email) = @e AND id <> @id',
      parameters: {'e': email, 'id': user['id']},
    )).firstOrNull;
    if (clash != null) {
      return fail('That email belongs to another account.', status: 409);
    }
    await ctx.db.q(
      'UPDATE users SET name = @n, email = @e, phone = @p WHERE id = @id',
      parameters: {
        'n': (body['name'] as String).trim(),
        'e': email,
        'p': (body['phone'] as String).trim(),
        'id': user['id'],
      },
    );
    return json({'ok': true});
  });

  router.delete('/api/me', (Request request) async {
    final user = await requireAuth(ctx, request, null);
    if (user == null) return fail('Not logged in.', status: 401);
    if (user['role'] == 'admin') {
      return fail(
          'Administrators cannot delete their own account. '
          'Another admin must remove it.',
          status: 403);
    }
    final id = user['id'] as String;
    await ctx.db.q('DELETE FROM products WHERE seller_id = @id',
        parameters: {'id': id});
    await ctx.db.q('DELETE FROM orders WHERE user_id = @id',
        parameters: {'id': id});
    await ctx.db.q('DELETE FROM users WHERE id = @id',
        parameters: {'id': id});
    return json({'ok': true});
  });

  router.put('/api/me/password', (Request request) async {
    final user = await requireAuth(ctx, request, null);
    if (user == null) return fail('Not logged in.', status: 401);
    final body = await readBody(request);
    final rows = await ctx.db.q(
      'SELECT password_hash, password_salt FROM users WHERE id = @id',
      parameters: {'id': user['id']},
    );
    final row = rows.first;
    if (!verifyPassword(body['current'] as String, row[1] as String,
        row[0] as String)) {
      return fail('Current password is wrong.', status: 400);
    }
    final next = body['next'] as String;
    if (next.length < 6) {
      return fail('New password must be at least 6 characters.');
    }
    final salt = makeSalt();
    await ctx.db.q(
      'UPDATE users SET password_hash = @h, password_salt = @s WHERE id = @id',
      parameters: {
        'h': hashPassword(next, salt),
        's': salt,
        'id': user['id'],
      },
    );
    return json({'ok': true});
  });

  router.post('/api/me/seller-application', (Request request) async {
    final user = await requireAuth(ctx, request, null);
    if (user == null) return fail('Not logged in.', status: 401);
    if (user['seller_status'] == 'approved') return json({'ok': true});
    if (user['seller_status'] == 'pending') {
      return fail('Your seller application is already under review.');
    }
    final body = await readBody(request);
    await ctx.db.q(
      '''UPDATE users SET seller_status = 'pending', shop_name = @sn,
         shop_location = @sl, shop_description = @sd, contact_info = @ci
         WHERE id = @id''',
      parameters: {
        'sn': (body['shopName'] as String).trim(),
        'sl': (body['shopLocation'] as String).trim(),
        'sd': (body['shopDescription'] as String).trim(),
        'ci': (body['contactInfo'] as String).trim(),
        'id': user['id'],
      },
    );
    return json({'ok': true});
  });

  router.get('/api/products', (Request request) async {
    final rows = await ctx.db.q(
      "SELECT $productColumns FROM products WHERE approval = 'approved' "
      'ORDER BY created_at DESC',
    );
    return json([for (final r in rows) rowToProduct(r)]);
  });

  router.get('/api/products/mine', (Request request) async {
    final user = await requireAuth(ctx, request, null);
    if (user == null) return fail('Not logged in.', status: 401);
    final rows = await ctx.db.q(
      'SELECT $productColumns FROM products WHERE seller_id = @id '
      'ORDER BY created_at DESC',
      parameters: {'id': user['id']},
    );
    return json([for (final r in rows) rowToProduct(r)]);
  });

  router.get('/api/me/skin-profile', (Request request) async {
    final user = await requireAuth(ctx, request, null);
    if (user == null) return fail('Not logged in.', status: 401);
    final rows = await ctx.db.q(
      'SELECT skin_type, concerns, sensitivities, goals, notes, updated_at '
      'FROM skin_profiles WHERE user_id = @id',
      parameters: {'id': user['id']},
    );
    final row = rows.firstOrNull;
    if (row == null) return json(null);
    final m = row.toColumnMap();
    return json({
      'skinType': m['skin_type'],
      'concerns': m['concerns'],
      'sensitivities': m['sensitivities'],
      'goals': m['goals'],
      'notes': m['notes'],
      'updatedAt': (m['updated_at'] as DateTime).toIso8601String(),
    });
  });

  router.put('/api/me/skin-profile', (Request request) async {
    final user = await requireAuth(ctx, request, null);
    if (user == null) return fail('Not logged in.', status: 401);
    final body = await readBody(request);
    await ctx.db.q(
      '''INSERT INTO skin_profiles (user_id, skin_type, concerns,
           sensitivities, goals, notes, updated_at)
         VALUES (@id,@st,@c,@s,@g,@n,now())
         ON CONFLICT (user_id) DO UPDATE SET skin_type = @st,
           concerns = @c, sensitivities = @s, goals = @g, notes = @n,
           updated_at = now()''',
      parameters: {
        'id': user['id'],
        'st': body['skinType'],
        'c': body['concerns'],
        's': body['sensitivities'],
        'g': body['goals'],
        'n': body['notes'] ?? '',
      },
    );
    return json({'ok': true});
  });
}

Map<String, Object?> rowMapToUser(Map<String, Object?> m) => {
      'id': m['id'],
      'name': m['name'],
      'email': m['email'],
      'phone': m['phone'],
      'role': m['role'],
      'sellerStatus': m['seller_status'],
      'shopName': m['shop_name'],
      'shopLocation': m['shop_location'],
      'shopDescription': m['shop_description'],
      'contactInfo': m['contact_info'],
      'deactivated': m['deactivated'],
      'createdAt': (m['created_at'] as DateTime).toIso8601String(),
    };
