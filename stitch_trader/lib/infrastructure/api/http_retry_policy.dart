import 'dart:async';

import 'package:http/http.dart' as http;

import 'api_exceptions.dart';

/// GET/PUT 공통 재시도(일시적 네트워크·5xx).
/// [SocketException] 은 웹에서 `dart:io` 미지원이라 제외 — VM에서는 [ClientException]으로 대부분 감싸짐.
final class HttpRetryPolicy {
  const HttpRetryPolicy({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(milliseconds: 250),
  });

  /// 총 시도 획수(첫 요청 포함). 예: 3이면 최대 2회 재시도.
  final int maxAttempts;
  final Duration initialDelay;

  static bool _retriable(Object error) {
    if (error is TimeoutException) return true;
    if (error is http.ClientException) return true;
    if (error is HttpResponseException) return error.isTransient;
    return false;
  }

  Duration delayAfterFailureIndex(int failureIndex) =>
      initialDelay * (1 << failureIndex.clamp(0, 8));

  Future<T> run<T>(Future<T> Function() action) async {
    var failures = 0;
    while (true) {
      try {
        return await action();
      } catch (e) {
        failures++;
        if (failures >= maxAttempts || !_retriable(e)) rethrow;
        await Future<void>.delayed(delayAfterFailureIndex(failures - 1));
      }
    }
  }
}
