/// `API_BASE_URL` 미설정 또는 잘못된 설정.
final class ApiConfigurationException implements Exception {
  ApiConfigurationException(this.message);
  final String message;

  @override
  String toString() => 'ApiConfigurationException: $message';
}

/// Remote 모드에서 베이스 URL이 비어 있음.
final class ApiNotConfiguredException implements Exception {
  const ApiNotConfiguredException();

  @override
  String toString() =>
      'ApiNotConfiguredException: staging/production 에서 --dart-define=API_BASE_URL=https://... 를 설정하세요.';
}

/// HTTP 4xx/5xx.
final class HttpResponseException implements Exception {
  HttpResponseException(this.statusCode, this.body);
  final int statusCode;
  final String body;

  @override
  String toString() => 'HttpResponseException: $statusCode ${body.length > 200 ? "${body.substring(0, 200)}…" : body}';
}

/// 응답 JSON 형식이 계약과 다름(Domain 매핑 전 단계).
final class DashboardJsonException implements Exception {
  DashboardJsonException(this.message);
  final String message;

  @override
  String toString() => 'DashboardJsonException: $message';
}
