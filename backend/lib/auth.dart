import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

final _rng = Random.secure();

String randomId([int bytes = 12]) => base64Url
    .encode(List<int>.generate(bytes, (_) => _rng.nextInt(256)))
    .replaceAll('=', '');

String makeSalt() => randomId(16);

/// PBKDF2-HMAC-SHA256. Real deployments should move to argon2id server-side.
String hashPassword(String password, String salt) {
  final hmac = Hmac(sha256, utf8.encode(salt));
  var block = hmac.convert(utf8.encode('${password}_1')).bytes;
  var out = Uint8List.fromList(block);
  for (var i = 2; i <= 20000; i++) {
    block = hmac.convert(block).bytes;
    for (var j = 0; j < out.length; j++) {
      out[j] ^= block[j];
    }
  }
  return base64.encode(out);
}

bool verifyPassword(String password, String salt, String expectedHash) {
  final actual = hashPassword(password, salt);
  if (actual.length != expectedHash.length) return false;
  var diff = 0;
  for (var i = 0; i < actual.length; i++) {
    diff |= actual.codeUnitAt(i) ^ expectedHash.codeUnitAt(i);
  }
  return diff == 0;
}
