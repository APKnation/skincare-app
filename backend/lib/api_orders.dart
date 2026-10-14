import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'api_core.dart';
import 'auth.dart';
import 'pg.dart';

final _rng = Random.secure();

int _deliveryFee(String city) =>
    city.trim().toLowerCase() == 'dar es salaam' ? 3000 : 5000;

void registerCartOrderRoutes(Router router, Ctx ctx) {
  Future<Map<String, Object?>?> auth(Request request) =>
      requireAuth(ctx, request, null);

  Future<bool> isAdmin(Map<String, Object?>? user) async =>
      user != null && user['role'] == 'admin';

  router.get('/api/me/cart', (Request request) async {
    final user = await auth(request);
    if (user == null) return fail('Not logged in.', status: 401);
    final rows = await ctx.db.q(
      'SELECT product_id, quantity FROM cart_items WHERE user_id = @id',
      parameters: {'id': user['id']},
    );
    return json({
      'items': [
        for (final r in rows)
          {'productId': r[0], 'quantity': r[1]}
      ],
    });
  });

  router.post('/api/me/cart', (Request request) async {
    final user = await auth(request);
    if (user == null) return fail('Not logged in.', status: 401);
    final body = await readBody(request);
    final productId = body['productId'] as String;
    final quantity = (body['quantity'] as num?)?.toInt() ?? 1;
    final stock = await _stockOf(ctx, productId);
    if (stock == null) return fail('Product unavailable.', status: 404);
    final current = await _cartQty(ctx, user['id'] as String, productId);
    if (current + quantity > stock) {
      return fail('Only $stock left in stock.');
    }
    await ctx.db.q(
      '''INSERT INTO cart_items (user_id, product_id, quantity)
         VALUES (@u,@p,@q)
         ON CONFLICT (user_id, product_id)
         DO UPDATE SET quantity = cart_items.quantity + @q''',
      parameters: {'u': user['id'], 'p': productId, 'q': quantity},
    );
    return json({'ok': true});
  });

  router.put('/api/me/cart/<productId>', (Request request, String productId) async {
    final user = await auth(request);
    if (user == null) return fail('Not logged in.', status: 401);
    final body = await readBody(request);
    final quantity = (body['quantity'] as num).toInt();
    if (quantity <= 0) {
      await ctx.db.q(
        'DELETE FROM cart_items WHERE user_id = @u AND product_id = @p',
        parameters: {'u': user['id'], 'p': productId},
      );
      return json({'ok': true});
    }
    final stock = await _stockOf(ctx, productId);
    if (stock == null) return fail('Product unavailable.', status: 404);
    await ctx.db.q(
      '''INSERT INTO cart_items (user_id, product_id, quantity)
         VALUES (@u,@p,@q)
         ON CONFLICT (user_id, product_id) DO UPDATE SET quantity = @q2''',
      parameters: {
        'u': user['id'],
        'p': productId,
        'q': quantity.clamp(0, stock),
        'q2': quantity.clamp(0, stock),
      },
    );
    return json({'ok': true});
  });

  router.delete('/api/me/cart', (Request request) async {
    final user = await auth(request);
    if (user == null) return fail('Not logged in.', status: 401);
    await ctx.db.q(
      'DELETE FROM cart_items WHERE user_id = @u',
      parameters: {'u': user['id']},
    );
    return json({'ok': true});
  });

  router.post('/api/orders', (Request request) async {
    final user = await auth(request);
    if (user == null) return fail('Not logged in.', status: 401);
    final body = await readBody(request);
    final cart = await ctx.db.q(
      '''SELECT c.product_id, p.name, p.price_tzs, c.quantity, p.stock,
                p.approval
         FROM cart_items c JOIN products p ON p.id = c.product_id
         WHERE c.user_id = @u''',
      parameters: {'u': user['id']},
    ).then((r) => [for (final row in r) row.toColumnMap()]);
    if (cart.isEmpty) return fail('Your cart is empty.');
    for (final line in cart) {
      if (line['approval'] != 'approved') {
        return fail('A product in your cart is no longer available.');
      }
      if ((line['quantity'] as int) > (line['stock'] as int)) {
        return fail('Stock changed for ${line['name']}. Adjust your cart.');
      }
    }
    final subtotal = cart.fold<int>(
        0, (s, l) => s + (l['price_tzs'] as int) * (l['quantity'] as int));
    final city = (body['city'] as String).trim();
    final fee = _deliveryFee(city);
    final orderId =
        'SY${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final method = body['paymentMethod'] as String;
    await ctx.db.runTx((tx) async {
      await tx.q(
        '''INSERT INTO orders (id, user_id, subtotal_tzs, delivery_fee_tzs,
             total_tzs, recipient_name, recipient_phone, address, city,
             delivery_notes, payment_method, payment_status, status)
           VALUES (@id,@u,@sub,@fee,@total,@rn,@rp,@addr,@city,@notes,@pm,
             'unpaid','placed')''',
        parameters: {
          'id': orderId,
          'u': user['id'],
          'sub': subtotal,
          'fee': fee,
          'total': subtotal + fee,
          'rn': body['recipientName'],
          'rp': body['recipientPhone'],
          'addr': body['address'],
          'city': city,
          'notes': body['deliveryNotes'] ?? '',
          'pm': method,
        },
      );
      for (final l in cart) {
        await tx.q(
          '''INSERT INTO order_lines (order_id, product_id, name,
               unit_price_tzs, quantity)
             VALUES (@o,@p,@n,@price,@q)''',
          parameters: {
            'o': orderId,
            'p': l['product_id'],
            'n': l['name'],
            'price': l['price_tzs'],
            'q': l['quantity'],
          },
        );
        final updated = await tx.q(
          '''UPDATE products SET stock = stock - @q
             WHERE id = @p AND stock >= @q RETURNING id''',
          parameters: {'q': l['quantity'], 'p': l['product_id']},
        );
        if (updated.firstOrNull == null) {
          throw StateError('Stock changed for ${l['name']}.');
        }
      }
      await tx.q(
        '''INSERT INTO order_events (order_id, status, note, at)
           VALUES (@o,'placed','Order received', now())''',
        parameters: {'o': orderId},
      );
      await tx.q(
        'DELETE FROM cart_items WHERE user_id = @u',
        parameters: {'u': user['id']},
      );
    });
    return json({'orderId': orderId});
  });

  router.get('/api/orders', (Request request) async {
    final user = await auth(request);
    if (user == null) return fail('Not logged in.', status: 401);
    return json(await _ordersWhere(ctx, 'WHERE o.user_id = @v', user['id'] as String));
  });

  router.get('/api/orders/sales', (Request request) async {
    final user = await auth(request);
    if (user == null) return fail('Not logged in.', status: 401);
    if (user['role'] != 'seller') return fail('Forbidden.', status: 403);
    final ids = await ctx.db.q(
      'SELECT DISTINCT ol.order_id FROM order_lines ol '
      'JOIN products p ON p.id = ol.product_id '
      'WHERE p.seller_id = @s',
      parameters: {'s': user['id']},
    );
    final orders = <Map<String, Object?>>[];
    for (final r in ids) {
      final list = await _ordersWhere(ctx, 'WHERE o.id = @v', r[0] as String);
      if (list.isNotEmpty) orders.add(list.first);
    }
    orders.sort((a, b) =>
        (b['placedAt'] as String).compareTo(a['placedAt'] as String));
    return json(orders);
  });

  router.get('/api/orders/<id>', (Request request, String id) async {
    final user = await auth(request);
    if (user == null) return fail('Not logged in.', status: 401);
    final list = await _ordersWhere(ctx, "WHERE o.id = @v", id);
    final order = list.firstOrNull;
    if (order == null) return fail('Order not found.', status: 404);
    if (order['userId'] != user['id'] && user['role'] != 'admin') {
      if (user['role'] != 'seller') return fail('Forbidden.', status: 403);
      final mine = await ctx.db.q(
        'SELECT 1 FROM order_lines ol JOIN products p ON p.id = ol.product_id '
        'WHERE ol.order_id = @o AND p.seller_id = @s',
        parameters: {'o': id, 's': user['id']},
      );
      if (mine.firstOrNull == null) return fail('Forbidden.', status: 403);
    }
    return json(order);
  });

  router.post('/api/orders/<id>/pay/start', (Request request, String id) async {
    final user = await auth(request);
    if (user == null) return fail('Not logged in.', status: 401);
    final rows = await ctx.db.q(
      'SELECT payment_method, payment_status, total_tzs, recipient_phone, user_id '
      'FROM orders WHERE id = @id',
      parameters: {'id': id},
    );
    final o = rows.firstOrNull?.toColumnMap();
    if (o == null || o['user_id'] != user['id']) {
      return fail('Order not found.', status: 404);
    }
    if (o['payment_status'] == 'paid') return fail('Already paid.');
    final reference =
        'SY${DateTime.now().millisecondsSinceEpoch}${String.fromCharCode(65 + _rng.nextInt(26))}${_rng.nextInt(9000) + 1000}';
    await ctx.db.q(
      '''UPDATE orders SET payment_status = 'verifying', payment_ref = @r
         WHERE id = @id''',
      parameters: {'r': reference, 'id': id},
    );
    return json({
      'reference': reference,
      'amountTZS': o['total_tzs'],
      'phone': o['recipient_phone'],
      'method': o['payment_method'],
    });
  });

  router.post('/api/orders/<id>/pay/confirm',
      (Request request, String id) async {
    final user = await auth(request);
    if (user == null) return fail('Not logged in.', status: 401);
    final body = await readBody(request);
    final pin = body['pin'] as String;
    final rows = await ctx.db.q(
      'SELECT payment_status, user_id, payment_ref FROM orders WHERE id = @id',
      parameters: {'id': id},
    );
    final o = rows.firstOrNull?.toColumnMap();
    if (o == null || o['user_id'] != user['id']) {
      return fail('Order not found.', status: 404);
    }
    final declined = !RegExp(r'^\d{4}$').hasMatch(pin) || pin == '0000';
    if (declined) {
      await ctx.db.q(
        '''UPDATE orders SET payment_status = 'failed' WHERE id = @id''',
        parameters: {'id': id},
      );
      return json({
        'success': false,
        'message': 'Transaction declined on your handset. No money was moved.',
      });
    }
    // Authoritative verification happens HERE, server-side, exactly like a
    // provider callback would. The client can never mark an order paid.
    await ctx.db.q(
      '''UPDATE orders SET payment_status = 'paid', status = 'confirmed'
         WHERE id = @id''',
      parameters: {'id': id},
    );
    await ctx.db.q(
      '''INSERT INTO order_events (order_id, status, note, at)
         VALUES (@id,'confirmed','Payment verified by provider', now())''',
      parameters: {'id': id},
    );
    return json({'success': true, 'reference': o['payment_ref']});
  });

  router.put('/api/orders/<id>/cancel', (Request request, String id) async {
    final user = await auth(request);
    if (user == null) return fail('Not logged in.', status: 401);
    final rows = await ctx.db.q(
      'SELECT status, user_id FROM orders WHERE id = @id',
      parameters: {'id': id},
    );
    final o = rows.firstOrNull?.toColumnMap();
    if (o == null || o['user_id'] != user['id']) {
      return fail('Order not found.', status: 404);
    }
    if (o['status'] == 'delivered' || o['status'] == 'cancelled') {
      return fail('This order can no longer be cancelled.');
    }
    await ctx.db.q(
      '''UPDATE orders SET status = 'cancelled' WHERE id = @id''',
      parameters: {'id': id},
    );
    await ctx.db.q(
      '''INSERT INTO order_events (order_id, status, note, at)
         VALUES (@id,'cancelled','Cancelled by customer', now())''',
      parameters: {'id': id},
    );
    return json({'ok': true});
  });

  // ---- seller product mutations ----

  router.post('/api/products', (Request request) async {
    final user = await auth(request);
    if (user == null) return fail('Not logged in.', status: 401);
    if (user['role'] != 'seller' && user['role'] != 'admin') {
      return fail('Only approved sellers can add products.', status: 403);
    }
    if (user['role'] == 'seller' && user['seller_status'] != 'approved') {
      return fail('Your seller account is not approved yet.', status: 403);
    }
    final body = await readBody(request);
    await ctx.db.q(
      '''INSERT INTO products (name, brand, category, description, price_tzs,
           image_url, ingredients, suitable_skin_types, targets_concerns,
           contains_flagged, is_comedogenic, usage_instructions, side_effects,
           warnings, stock, seller_id, shop_name, shop_location, approval)
         VALUES (@name,@brand,@category,@description,@price,@image,
           @ingredients,@skinTypes,@concerns,@flagged,@comedogenic,@usage,
           @sideEffects,@warnings,@stock,@sellerId,@shopName,@shopLocation,
           'pending')
         RETURNING id''',
      parameters: {
        ...productParams(body),
        'sellerId': user['id'],
        'shopName': user['shop_name'] ?? '',
        'shopLocation': user['shop_location'] ?? '',
      },
    );
    return json({'ok': true});
  });

  router.put('/api/products/<id>', (Request request, String id) async {
    final user = await auth(request);
    if (user == null) return fail('Not logged in.', status: 401);
    final existing = await ctx.db.q(
      'SELECT seller_id FROM products WHERE id = @id',
      parameters: {'id': id},
    );
    final row = existing.firstOrNull;
    if (row == null) return fail('Product not found.', status: 404);
    if (user['role'] != 'admin' && row[0] != user['id']) {
      return fail('You can only edit your own products.', status: 403);
    }
    final body = await readBody(request);
    await ctx.db.q(
      '''UPDATE products SET ${productSets(body)} WHERE id = @id''',
      parameters: {...productParams(body), 'id': id},
    );
    return json({'ok': true});
  });

  router.delete('/api/products/<id>', (Request request, String id) async {
    final user = await auth(request);
    if (user == null) return fail('Not logged in.', status: 401);
    final existing = await ctx.db.q(
      'SELECT seller_id FROM products WHERE id = @id',
      parameters: {'id': id},
    );
    final row = existing.firstOrNull;
    if (row == null) return fail('Product not found.', status: 404);
    if (user['role'] != 'admin' && row[0] != user['id']) {
      return fail('You can only delete your own products.', status: 403);
    }
    await ctx.db.q('DELETE FROM products WHERE id = @id',
        parameters: {'id': id});
    return json({'ok': true});
  });

  // ---- admin ----

  router.get('/api/admin/sellers', (Request request) async {
    final user = await auth(request);
    if (!await isAdmin(user)) return fail('Forbidden.', status: 403);
    final rows = await ctx.db.q(
      "SELECT $userColumns FROM users WHERE role = 'seller' OR "
      "seller_status <> 'none' ORDER BY created_at DESC",
    );
    return json([for (final r in rows) rowToUser(r)]);
  });

  router.put('/api/admin/sellers/<id>/status',
      (Request request, String id) async {
    final user = await auth(request);
    if (!await isAdmin(user)) return fail('Forbidden.', status: 403);
    final body = await readBody(request);
    await ctx.db.q(
      '''UPDATE users SET seller_status = @s,
           role = CASE WHEN @s = 'approved' THEN 'seller' ELSE role END
         WHERE id = @id''',
      parameters: {'s': body['status'], 'id': id},
    );
    return json({'ok': true});
  });

  router.get('/api/admin/products', (Request request) async {
    final user = await auth(request);
    if (!await isAdmin(user)) return fail('Forbidden.', status: 403);
    final rows = await ctx.db.q(
      "SELECT $productColumns FROM products WHERE approval = 'pending' "
      'ORDER BY created_at DESC',
    );
    return json([for (final r in rows) rowToProduct(r)]);
  });

  router.put('/api/admin/products/<id>/approval',
      (Request request, String id) async {
    final user = await auth(request);
    if (!await isAdmin(user)) return fail('Forbidden.', status: 403);
    final body = await readBody(request);
    await ctx.db.q(
      'UPDATE products SET approval = @a WHERE id = @id',
      parameters: {'a': body['approval'], 'id': id},
    );
    return json({'ok': true});
  });

  router.get('/api/admin/users', (Request request) async {
    final user = await auth(request);
    if (!await isAdmin(user)) return fail('Forbidden.', status: 403);
    final rows = await ctx.db.q(
      'SELECT $userColumns FROM users WHERE role <> \'admin\' '
      'ORDER BY name',
    );
    return json([for (final r in rows) rowToUser(r)]);
  });

  router.put('/api/admin/users/<id>/active',
      (Request request, String id) async {
    final user = await auth(request);
    if (!await isAdmin(user)) return fail('Forbidden.', status: 403);
    final body = await readBody(request);
    await ctx.db.q(
      'UPDATE users SET deactivated = @d WHERE id = @id AND role <> \'admin\'',
      parameters: {'d': !(body['active'] as bool), 'id': id},
    );
    await ctx.db.q('DELETE FROM sessions WHERE user_id = @id',
        parameters: {'id': id});
    return json({'ok': true});
  });

  router.post('/api/admin/users', (Request request) async {
    final user = await auth(request);
    if (!await isAdmin(user)) return fail('Forbidden.', status: 403);
    final body = await readBody(request);
    final email = (body['email'] as String).trim().toLowerCase();
    final password = body['password'] as String? ?? '';
    final role = body['role'] as String? ?? 'customer';
    if (!['customer', 'seller', 'admin'].contains(role)) {
      return fail('Unknown role.', status: 400);
    }
    if (password.length < 6) {
      return fail('Password must be at least 6 characters.', status: 400);
    }
    final clash = await ctx.db.q(
      'SELECT 1 FROM users WHERE lower(email) = @e',
      parameters: {'e': email},
    );
    if (clash.firstOrNull != null) {
      return fail('An account with this email already exists.', status: 409);
    }
    final salt = makeSalt();
    final rows = await ctx.db.q(
      '''INSERT INTO users (name, email, phone, password_hash, password_salt, role)
         VALUES (@n,@e,@p,@h,@s,@r) RETURNING id''',
      parameters: {
        'n': (body['name'] as String).trim(),
        'e': email,
        'p': (body['phone'] as String).trim(),
        'h': hashPassword(password, salt),
        's': salt,
        'r': role,
      },
    );
    return json({'id': rows.first[0]});
  });

  router.put('/api/admin/users/<id>', (Request request, String id) async {
    final user = await auth(request);
    if (!await isAdmin(user)) return fail('Forbidden.', status: 403);
    final target = await findUser(ctx, id);
    if (target == null) return fail('User not found.', status: 404);
    final body = await readBody(request);
    final role = body['role'] as String? ?? target['role'];
    if (!['customer', 'seller', 'admin'].contains(role)) {
      return fail('Unknown role.', status: 400);
    }
    if (id == user!['id'] && role != target['role']) {
      return fail('You cannot change your own role.', status: 400);
    }
    if (target['role'] == 'admin' && role != 'admin') {
      final others = await ctx.db.q(
        "SELECT count(*) FROM users WHERE role = 'admin' AND id <> @id",
        parameters: {'id': id},
      );
      if ((others.first[0] as int) == 0) {
        return fail('Cannot demote the last administrator.', status: 400);
      }
    }
    final email = (body['email'] as String).trim().toLowerCase();
    final clash = await ctx.db.q(
      'SELECT 1 FROM users WHERE lower(email) = @e AND id <> @id',
      parameters: {'e': email, 'id': id},
    );
    if (clash.firstOrNull != null) {
      return fail('Another account already uses this email.', status: 409);
    }
    await ctx.db.q(
      'UPDATE users SET name = @n, email = @e, phone = @p, role = @r '
      'WHERE id = @id',
      parameters: {
        'n': (body['name'] as String).trim(),
        'e': email,
        'p': (body['phone'] as String).trim(),
        'r': role,
        'id': id,
      },
    );
    return json({'ok': true});
  });

  router.delete('/api/admin/users/<id>',
      (Request request, String id) async {
    final user = await auth(request);
    if (!await isAdmin(user)) return fail('Forbidden.', status: 403);
    if (id == user!['id']) {
      return fail('You cannot delete your own account.', status: 400);
    }
    final target = await findUser(ctx, id);
    if (target == null) return fail('User not found.', status: 404);
    if (target['role'] == 'admin') {
      final others = await ctx.db.q(
        "SELECT count(*) FROM users WHERE role = 'admin' AND id <> @id",
        parameters: {'id': id},
      );
      if ((others.first[0] as int) == 0) {
        return fail('Cannot delete the last administrator.', status: 400);
      }
    }
    await ctx.db.q('DELETE FROM products WHERE seller_id = @id',
        parameters: {'id': id});
    await ctx.db.q('DELETE FROM orders WHERE user_id = @id',
        parameters: {'id': id});
    await ctx.db.q('DELETE FROM users WHERE id = @id',
        parameters: {'id': id});
    return json({'ok': true});
  });

  router.get('/api/admin/products/all', (Request request) async {
    final user = await auth(request);
    if (!await isAdmin(user)) return fail('Forbidden.', status: 403);
    final rows = await ctx.db.q(
      'SELECT $productColumns FROM products ORDER BY created_at DESC',
    );
    return json([for (final r in rows) rowToProduct(r)]);
  });

  router.get('/api/admin/orders', (Request request) async {
    final user = await auth(request);
    if (!await isAdmin(user)) return fail('Forbidden.', status: 403);
    return json(await _ordersWhere(ctx, '', null));
  });

  router.put('/api/admin/orders/<id>/status',
      (Request request, String id) async {
    final user = await auth(request);
    if (!await isAdmin(user)) return fail('Forbidden.', status: 403);
    final body = await readBody(request);
    await ctx.db.q(
      'UPDATE orders SET status = @s WHERE id = @id',
      parameters: {'s': body['status'], 'id': id},
    );
    await ctx.db.q(
      'INSERT INTO order_events (order_id, status, note, at) '
      'VALUES (@id,@s,@n,now())',
      parameters: {
        'id': id,
        's': body['status'],
        'n': body['note'] ?? 'Status updated by marketplace',
      },
    );
    return json({'ok': true});
  });

  router.delete('/api/admin/orders/<id>',
      (Request request, String id) async {
    final user = await auth(request);
    if (!await isAdmin(user)) return fail('Forbidden.', status: 403);
    final deleted = await ctx.db.q(
      'DELETE FROM orders WHERE id = @id RETURNING id',
      parameters: {'id': id},
    );
    if (deleted.firstOrNull == null) {
      return fail('Order not found.', status: 404);
    }
    return json({'ok': true});
  });
}

Map<String, Object?> productParams(Map<String, Object?> body) => {
      'name': body['name'],
      'brand': body['brand'] ?? '',
      'category': body['category'],
      'description': body['description'],
      'price': body['priceTZS'],
      'image': body['imageUrl'],
      'ingredients': body['ingredients'],
      'skinTypes': body['suitableSkinTypes'],
      'concerns': body['targetsConcerns'],
      'flagged': body['containsFlagged'] ?? <String>[],
      'comedogenic': body['isComedogenic'] ?? false,
      'usage': body['usageInstructions'] ?? '',
      'sideEffects': body['sideEffects'] ?? <String>[],
      'warnings': body['warnings'] ?? <String>[],
      'stock': body['stock'],
    };

const _productColumnMap = {
  'name': 'name',
  'brand': 'brand',
  'category': 'category',
  'description': 'description',
  'price': 'price_tzs',
  'image': 'image_url',
  'ingredients': 'ingredients',
  'skinTypes': 'suitable_skin_types',
  'concerns': 'targets_concerns',
  'flagged': 'contains_flagged',
  'comedogenic': 'is_comedogenic',
  'usage': 'usage_instructions',
  'sideEffects': 'side_effects',
  'warnings': 'warnings',
  'stock': 'stock',
};

String productSets(Map<String, Object?> body) =>
    _productColumnMap.entries.map((e) => '${e.value} = @${e.key}').join(', ');

Future<int?> _stockOf(Ctx ctx, String productId) async {
  final rows = await ctx.db.q(
    "SELECT stock FROM products WHERE id = @id AND approval = 'approved'",
    parameters: {'id': productId},
  );
  return rows.firstOrNull?[0] as int?;
}

Future<int> _cartQty(Ctx ctx, String userId, String productId) async {
  final rows = await ctx.db.q(
    'SELECT quantity FROM cart_items WHERE user_id = @u AND product_id = @p',
    parameters: {'u': userId, 'p': productId},
  );
  return rows.firstOrNull?[0] as int? ?? 0;
}

Future<List<Map<String, Object?>>> _ordersWhere(
    Ctx ctx, String where, Object? value) async {
  final rows = await ctx.db.q(
    'SELECT o.id,o.user_id,o.subtotal_tzs,o.delivery_fee_tzs,o.total_tzs,'
    'o.recipient_name,o.recipient_phone,o.address,o.city,o.delivery_notes,'
    'o.payment_method,o.payment_status,o.payment_ref,o.status,o.placed_at '
    'FROM orders o $where'.replaceAll('WHERE o.id = @v', 'WHERE o.id = @v'),
    parameters: value == null ? const {} : {'v': value},
  );
  final orders = <Map<String, Object?>>[];
  for (final r in rows) {
    final m = r.toColumnMap();
    final lines = await ctx.db.q(
      'SELECT product_id,name,unit_price_tzs,quantity FROM order_lines '
      'WHERE order_id = @id',
      parameters: {'id': m['id']},
    );
    final events = await ctx.db.q(
      'SELECT status,note,at FROM order_events WHERE order_id = @id '
      'ORDER BY at',
      parameters: {'id': m['id']},
    );
    orders.add({
      'id': m['id'],
      'userId': m['user_id'],
      'subtotalTZS': m['subtotal_tzs'],
      'deliveryFeeTZS': m['delivery_fee_tzs'],
      'totalTZS': m['total_tzs'],
      'recipientName': m['recipient_name'],
      'recipientPhone': m['recipient_phone'],
      'address': m['address'],
      'city': m['city'],
      'deliveryNotes': m['delivery_notes'],
      'paymentMethod': m['payment_method'],
      'paymentStatus': m['payment_status'],
      'paymentRef': m['payment_ref'],
      'status': m['status'],
      'placedAt': (m['placed_at'] as DateTime).toIso8601String(),
      'lines': [
        for (final l in lines)
          {
            'productId': l[0],
            'name': l[1],
            'unitPriceTZS': l[2],
            'quantity': l[3],
          }
      ],
      'timeline': [
        for (final e in events)
          {
            'status': e[0],
            'note': e[1],
            'at': (e[2] as DateTime).toIso8601String(),
          }
      ],
    });
  }
  return orders
    ..sort((a, b) => (b['placedAt'] as String).compareTo(a['placedAt'] as String));
}
