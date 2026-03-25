import 'package:stitch_trader/domain/dashboard_contracts.dart';
import 'package:stitch_trader/infrastructure/api/dashboard_http_client.dart';
import 'package:stitch_trader/infrastructure/api/dashboard_json_mapper.dart';

final class RemoteSessionTelemetryRepository implements SessionTelemetryRepository {
  RemoteSessionTelemetryRepository(this._client);

  final DashboardHttpClient _client;

  @override
  Future<SessionTelemetry> getTelemetry() async {
    final json = await _client.getJson('/v1/session/telemetry');
    return DashboardJsonMapper.parseTelemetry(json);
  }
}
