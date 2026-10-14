import 'dart:convert';
import 'dart:io';

/// Thin HTTP client for the Sura Yangu backend.
///
/// Base URL precedence: --dart-define=API_BASE_URL=... > default.
/// The default targets the phone's own localhost, which `adb reverse
/// tcp:8181 tcp:8181` tunnels to the backend on this computer (works on
/// physical devices and emulators). Other options:
///   same Wi-Fi LAN:   --dart-define=API_BASE_URL=http://192.168.1.10:8181
///   Android emulator: --dart-define=API_BASE_URL=http://10.0.2.2:8181
class ApiClient {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8181',
  );

  String? token;
  final _client = HttpClient()..connectionTimeout = const Duration(seconds: 8);

  Future<Map<String, Object?>> request(
    String method,
    String path, {
    Object? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final req = await _client.openUrl(method, uri);
    req.headers.contentType = ContentType.json;
    if (token != null) {
      req.headers.set('authorization', 'Bearer $token');
    }
    if (body != null) req.write(jsonEncode(body));
    final resp = await req.close();
    final text = await resp.transform(utf8.decoder).join();
    final data = text.isEmpty ? <String, Object?>{} : jsonDecode(text);
    if (resp.statusCode >= 400) {
      final message = data is Map && data['error'] != null
          ? data['error'] as String
          : 'Server error (${resp.statusCode}). Is the backend running?';
      throw ApiException(message);
    }
    return data is Map<String, Object?>
        ? data
        : {'result': data};
  }

  /// Returns null on success (server errors surface as the error message,
  /// mirroring the old synchronous Store contract).
  Future<String?> attempt(
    String method,
    String path, {
    Object? body,
  }) async {
    try {
      await request(method, path, body: body);
      return null;
    } on ApiException catch (e) {
      return e.message;
    } on SocketException {
      return 'Cannot reach the Sura Yangu server. Check that the backend is '
          'running and your API_BASE_URL is correct.';
    }
  }

  void close() => _client.close(force: true);
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

List<Map<String, Object?>> asMapList(Object? value) => value is List
    ? value.cast<Map<String, Object?>>()
    : const [];
