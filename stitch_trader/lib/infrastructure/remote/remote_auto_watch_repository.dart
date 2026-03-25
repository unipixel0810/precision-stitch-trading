import 'package:stitch_trader/domain/dashboard_contracts.dart';
import 'package:stitch_trader/infrastructure/api/dashboard_http_client.dart';
import 'package:stitch_trader/infrastructure/api/dashboard_json_mapper.dart';

final class RemoteAutoWatchRepository implements AutoWatchRepository {
  RemoteAutoWatchRepository(this._client);

  final DashboardHttpClient _client;

  @override
  Future<AutoWatchStatus> getStatus() async {
    final json = await _client.getJson('/v1/autowatch/status');
    return DashboardJsonMapper.parseAutoWatchStatus(json);
  }

  @override
  Future<RiskSettings> getRiskSettings() async {
    final json = await _client.getJson('/v1/autowatch/risk');
    return DashboardJsonMapper.parseRiskSettings(json);
  }

  @override
  Future<void> saveRiskSettings(RiskSettings settings) async {
    await _client.putJson('/v1/autowatch/risk', DashboardJsonMapper.riskToJson(settings));
  }
}
