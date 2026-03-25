import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stitch_trader/infrastructure/api/api_config.dart';
import 'package:stitch_trader/infrastructure/api/api_exceptions.dart';
import 'package:stitch_trader/infrastructure/api/dashboard_http_client.dart';
import 'package:stitch_trader/infrastructure/api/http_retry_policy.dart';

void main() {
  test('HttpRetryPolicy retries transient 503 then succeeds', () async {
    var n = 0;
    final inner = MockClient((req) async {
      n++;
      if (n < 3) {
        return http.Response('gateway', 503);
      }
      expect(req.url.host, 'example.com');
      return http.Response('{"hits":[]}', 200);
    });
    final client = DashboardHttpClient(
      config: ApiConfig(baseUri: Uri.parse('https://example.com')),
      httpClient: inner,
      retryPolicy: const HttpRetryPolicy(
        maxAttempts: 3,
        initialDelay: Duration.zero,
      ),
    );
    final json = await client.getJson('/v1/scanner/hits');
    expect(n, 3);
    expect(json, isA<Map>());
  });

  test('does not retry non-transient 404', () async {
    var n = 0;
    final inner = MockClient((req) async {
      n++;
      return http.Response('nf', 404);
    });
    final client = DashboardHttpClient(
      config: ApiConfig(baseUri: Uri.parse('https://example.com')),
      httpClient: inner,
      retryPolicy: const HttpRetryPolicy(maxAttempts: 3, initialDelay: Duration.zero),
    );
    await expectLater(
      client.getJson('/v1/scanner/hits'),
      throwsA(isA<HttpResponseException>().having((e) => e.statusCode, 'code', 404)),
    );
    expect(n, 1);
  });
}
