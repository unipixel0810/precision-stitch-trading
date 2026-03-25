import 'package:stitch_trader/domain/dashboard_contracts.dart';
import 'package:stitch_trader/infrastructure/api/dashboard_http_client.dart';
import 'package:stitch_trader/infrastructure/api/dashboard_json_mapper.dart';

final class RemoteScannerRepository implements ScannerRepository {
  RemoteScannerRepository(this._client);

  final DashboardHttpClient _client;

  @override
  Future<List<ScannerHit>> listHits() async {
    final json = await _client.getJson('/v1/scanner/hits');
    return DashboardJsonMapper.parseScannerHits(json);
  }
}
