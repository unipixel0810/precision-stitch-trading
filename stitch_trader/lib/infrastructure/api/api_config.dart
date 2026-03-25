import 'api_exceptions.dart';

/// `--dart-define=API_BASE_URL=...` 로 주입. staging/production Remote 저장소에서 필수.
final class ApiConfig {
  ApiConfig({required this.baseUri, this.apiKey});

  /// 예: `https://api.example.com` 또는 `https://example.com/stitch` (prefix path 허용).
  final Uri? baseUri;
  final String? apiKey;

  static ApiConfig fromEnvironment() {
    const raw = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (raw.trim().isEmpty) {
      return ApiConfig(baseUri: null);
    }
    final uri = Uri.parse(raw.trim());
    if (!uri.hasScheme || uri.host.isEmpty) {
      throw ApiConfigurationException('API_BASE_URL must be an absolute URL with scheme and host: $raw');
    }
    const key = String.fromEnvironment('API_KEY', defaultValue: '');
    return ApiConfig(
      baseUri: uri,
      apiKey: key.isEmpty ? null : key,
    );
  }

  /// [absolutePath]는 `/v1/...` 형태.
  Uri buildUri(String absolutePath) {
    final b = baseUri;
    if (b == null) {
      throw const ApiNotConfiguredException();
    }
    final ap = absolutePath.startsWith('/') ? absolutePath : '/$absolutePath';
    final rawPath = b.path;
    final prefix = rawPath.isEmpty || rawPath == '/' ? '' : (rawPath.endsWith('/') ? rawPath.substring(0, rawPath.length - 1) : rawPath);
    final fullPath = '$prefix$ap';
    return Uri(scheme: b.scheme, host: b.host, port: b.hasPort ? b.port : null, path: fullPath, query: b.query);
  }
}
