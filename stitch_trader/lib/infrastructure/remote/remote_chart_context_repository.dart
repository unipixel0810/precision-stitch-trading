import 'package:stitch_trader/domain/dashboard_contracts.dart';
import 'package:stitch_trader/infrastructure/api/dashboard_http_client.dart';
import 'package:stitch_trader/infrastructure/api/dashboard_json_mapper.dart';

final class RemoteChartContextRepository implements ChartContextRepository {
  RemoteChartContextRepository(this._client);

  final DashboardHttpClient _client;

  String _sym(SymbolCode s) => Uri.encodeComponent(s.value);

  @override
  Future<OhlcSnapshot> getOhlc(SymbolCode symbol) async {
    final json = await _client.getJson('/v1/symbols/${_sym(symbol)}/ohlc');
    return DashboardJsonMapper.parseOhlc(symbol, json);
  }

  @override
  Future<List<ChartPriceLine>> listPriceLines(SymbolCode symbol) async {
    final json = await _client.getJson('/v1/symbols/${_sym(symbol)}/price-lines');
    return DashboardJsonMapper.parsePriceLines(json);
  }

  @override
  Future<Uri?> backgroundImage(SymbolCode symbol) async {
    final json = await _client.getJson('/v1/symbols/${_sym(symbol)}/chart-background');
    return DashboardJsonMapper.parseChartBackground(json);
  }
}
