import 'package:stitch_trader/domain/dashboard_contracts.dart';

import '_fake_chart_urls.dart';

final class FakeChartContextRepository implements ChartContextRepository {
  const FakeChartContextRepository();

  @override
  Future<OhlcSnapshot> getOhlc(SymbolCode symbol) async {
    return OhlcSnapshot(
      symbol: symbol,
      openKrw: 210500,
      highKrw: 214000,
      lowKrw: 209000,
      closeKrw: 212000,
      volumeDescription: '1.2조',
      tickSizeKrw: 100,
    );
  }

  @override
  Future<List<ChartPriceLine>> listPriceLines(SymbolCode symbol) async {
    return const [
      ChartPriceLine(kind: ChartPriceLineKind.primaryBuy, priceKrw: 210500),
      ChartPriceLine(kind: ChartPriceLineKind.autoTier2, priceKrw: 208400, subtitle: '(-1.0%)'),
      ChartPriceLine(kind: ChartPriceLineKind.autoTier3, priceKrw: 206300, subtitle: '(-2.0%)'),
      ChartPriceLine(kind: ChartPriceLineKind.sellTarget, priceKrw: 218000),
    ];
  }

  @override
  Future<Uri?> backgroundImage(SymbolCode symbol) async {
    return Uri.parse(FakeChartUrls.chartMain);
  }
}
