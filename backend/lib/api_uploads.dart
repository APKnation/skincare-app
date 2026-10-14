import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'api_core.dart';
import 'auth.dart';
import 'pg.dart';

const _extToMime = {
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'webp': 'image/webp',
  'gif': 'image/gif',
};

const _maxUploadBytes = 5 * 1024 * 1024;

final _fileNamePattern = RegExp(r'^[A-Za-z0-9_\-]{4,40}\.(jpg|jpeg|png|webp|gif)$');

String _uploadsDirPath() =>
    Directory('backend').existsSync() ? 'backend/uploads' : 'uploads';

void registerUploadRoutes(Router router, Ctx ctx) {
  router.post('/api/upload', (Request request) async {
    final user = await requireAuth(ctx, request, null);
    if (user == null) return fail('Not logged in.', status: 401);
    if (user['role'] != 'seller' && user['role'] != 'admin') {
      return fail('Only sellers can upload product images.', status: 403);
    }
    final ext = (request.url.queryParameters['ext'] ?? 'jpg').toLowerCase();
    if (!_extToMime.containsKey(ext)) {
      return fail('Unsupported image type. Use jpg, png, webp or gif.');
    }
    final bytes =
        await request.read().fold<List<int>>(<int>[], (a, c) => a..addAll(c));
    if (bytes.isEmpty) return fail('Empty upload.');
    if (bytes.length > _maxUploadBytes) {
      return fail('Image too large (max 5 MB).');
    }
    final dir = Directory(_uploadsDirPath());
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final name = '${randomId(12)}.$ext';
    await File('${dir.path}/$name').writeAsBytes(bytes);
    return json({'path': '/uploads/$name'});
  });

  router.get('/uploads/<name>', (Request request, String name) async {
    if (!_fileNamePattern.hasMatch(name)) {
      return fail('Not found.', status: 404);
    }
    final file = File('${_uploadsDirPath()}/$name');
    if (!file.existsSync()) return fail('Not found.', status: 404);
    final bytes = await file.readAsBytes();
    return Response(200,
        body: bytes,
        headers: {
          'content-type': _extToMime[name.split('.').last] ?? 'image/jpeg',
          'cache-control': 'public, max-age=86400',
        });
  });

  router.put('/api/me/shop', (Request request) async {
    final user = await requireAuth(ctx, request, null);
    if (user == null) return fail('Not logged in.', status: 401);
    if (user['role'] == 'admin') {
      return fail('Administrator accounts do not have a shop.', status: 403);
    }
    final body = await readBody(request);
    await ctx.db.q(
      '''UPDATE users SET shop_name = @sn, shop_location = @sl,
         shop_description = @sd, contact_info = @ci WHERE id = @id''',
      parameters: {
        'sn': (body['shopName'] as String? ?? '').trim(),
        'sl': (body['shopLocation'] as String? ?? '').trim(),
        'sd': (body['shopDescription'] as String? ?? '').trim(),
        'ci': (body['contactInfo'] as String? ?? '').trim(),
        'id': user['id'],
      },
    );
    return json({'ok': true});
  });
}
