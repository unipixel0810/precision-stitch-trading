import 'package:stitch_trader/domain/dashboard_contracts.dart';

final class RemoteChartContextRepository implements ChartContextRepository {
  const RemoteChartContextRepository();

  @override
  Future<OhlcSnapshot> getOhlc(SymbolCode symbol) async {
    throw UnimplementedError('RemoteChartContextRepository.getOhlc');
  }

  @override
  Future<List<ChartPriceLine>> listPriceLines(SymbolCode symbol) async {
    throw UnimplementedError('RemoteChartContextRepository.listPriceLines');
  }

  @override
  Future<Uri?> backgroundImage(SymbolCode symbol) async {
    throw UnimplementedError('RemoteChartContextRepository.backgroundImage');
  }
}
