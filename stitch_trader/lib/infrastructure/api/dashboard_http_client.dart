import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exceptions.dart';

/// Dashboard REST 호출용 얇은 클라이언트 (인프라 전용).
final class DashboardHttpClient {
  DashboardHttpClient({
    required ApiConfig config,
    http.Client? httpClient,
    Duration? timeout,
  })  : _config = config,
        _http = httpClient ?? http.Client(),
        _timeout = timeout ?? const Duration(seconds: 20);

  final ApiConfig _config;
  final http.Client _http;
  final Duration _timeout;

  Map<String, String> get _headers {
    final h = <String, String>{'Accept': 'application/json'};
    final k = _config.apiKey;
    if (k != null && k.isNotEmpty) {
      h['Authorization'] = 'Bearer $k';
    }
    return h;
  }

  Future<Object?> getJson(String absolutePath) async {
    final uri = _config.buildUri(absolutePath);
    final resp = await _http.get(uri, headers: _headers).timeout(_timeout);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpResponseException(resp.statusCode, resp.body);
    }
    if (resp.body.isEmpty) return null;
    try {
      return jsonDecode(resp.body);
    } on FormatException catch (e) {
      throw DashboardJsonException('JSON decode: $e');
    }
  }

  Future<void> putJson(String absolutePath, Map<String, Object?> body) async {
    final uri = _config.buildUri(absolutePath);
    final headers = {..._headers, 'Content-Type': 'application/json; charset=utf-8'};
    final resp = await _http.put(uri, headers: headers, body: jsonEncode(body)).timeout(_timeout);
    if (resp.statusCode < 200 || resp.statusCode >= 300) {
      throw HttpResponseException(resp.statusCode, resp.body);
    }
  }

  void close() => _http.close();
}
