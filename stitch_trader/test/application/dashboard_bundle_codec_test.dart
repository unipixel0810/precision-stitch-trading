import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_trader/application/dashboard_bundle_codec.dart';
import 'package:stitch_trader/application/models/dashboard_bundle.dart';
import 'package:stitch_trader/domain/dashboard_contracts.dart';

DashboardBundle _sample() {
  return DashboardBundle(
    scannerHits: [
      ScannerHit(
        instrument: Instrument(code: SymbolCode('005380'), displayName: '현대차'),
        badgeLabel: 'x',
        badgeTone: ScannerBadgeTone.primary,
        changePercent: 1,
        lastPriceKrw: 1,
        chips: const [ScannerChip(label: 'c', tone: ScannerChipTone.muted)],
        thumbnailUri: '',
        viHighlighted: false,
      ),
    ],
    selectedSymbol: SymbolCode('005380'),
    ohlc: OhlcSnapshot(
      symbol: SymbolCode('005380'),
      openKrw: 1,
      highKrw: 2,
      lowKrw: 3,
      closeKrw: 4,
      volumeDescription: 'v',
      tickSizeKrw: 100,
    ),
    priceLines: const [
      ChartPriceLine(kind: ChartPriceLineKind.sellTarget, priceKrw: 9),
    ],
    autoWatch: const AutoWatchStatus(
      lineSyncActive: true,
      phases: [
        AutoWatchPhaseState(kind: AutoWatchPhaseKind.monitoring, isActive: true),
      ],
    ),
    riskSettings: RiskSettings(
      takeProfitPercent: 1,
      stopLossPercentMagnitude: 2,
      trailingStopPercent: 3,
      botSplit: BotSplitPreset.five,
      orderKind: OrderKind.ioc,
    ),
    telemetry: SessionTelemetry(roundTripLatencyMs: 1, apiLabel: 'L', tickSnapApplied: true),
    chartBackgroundUri: 'https://x',
  );
}

void main() {
  test('codec roundtrip and servedFromCache flag', () {
    final a = _sample();
    final raw = DashboardBundleCodec.encode(a);
    final b = DashboardBundleCodec.decode(raw, servedFromCache: true);
    expect(b.servedFromCache, isTrue);
    expect(b.selectedSymbol.value, '005380');
    expect(b.scannerHits.length, 1);
    expect(b.priceLines.single.kind, ChartPriceLineKind.sellTarget);
    expect(b.riskSettings.botSplit, BotSplitPreset.five);
    expect(b.chartBackgroundUri, 'https://x');
    final fresh = DashboardBundleCodec.decode(raw, servedFromCache: false);
    expect(fresh.servedFromCache, isFalse);
  });
}
