import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_trader/application/use_cases/load_dashboard_bundle.dart';
import 'package:stitch_trader/application/use_cases/update_risk_settings.dart';
import 'package:stitch_trader/domain/dashboard_contracts.dart';
import 'package:stitch_trader/infrastructure/fake/fake_auto_watch_repository.dart';
import 'package:stitch_trader/infrastructure/fake/fake_chart_context_repository.dart';
import 'package:stitch_trader/infrastructure/fake/fake_scanner_repository.dart';
import 'package:stitch_trader/infrastructure/fake/fake_session_telemetry_repository.dart';

void main() {
  group('LoadDashboardBundle', () {
    test('aggregates repositories for default symbol', () async {
      final symbol = SymbolCode('005380');
      final load = LoadDashboardBundle(
        scannerRepository: const FakeScannerRepository(),
        chartRepository: const FakeChartContextRepository(),
        autoWatchRepository: FakeAutoWatchRepository(),
        telemetryRepository: const FakeSessionTelemetryRepository(),
        defaultSymbol: symbol,
      );

      final bundle = await load();

      expect(bundle.selectedSymbol, symbol);
      expect(bundle.scannerHits.length, 3);
      expect(bundle.ohlc.symbol, symbol);
      expect(bundle.telemetry.apiLabel, 'OPEN-0624-V4');
      expect(bundle.autoWatch.lineSyncActive, isTrue);
      expect(bundle.autoWatch.phases.length, 3);
    });
  });

  group('UpdateRiskSettings', () {
    test('persists via AutoWatchRepository', () async {
      final repo = FakeAutoWatchRepository();
      final uc = UpdateRiskSettings(repo);
      final next = RiskSettings(
        takeProfitPercent: 4.2,
        stopLossPercentMagnitude: 2.0,
        trailingStopPercent: 1.1,
        botSplit: BotSplitPreset.five,
        orderKind: OrderKind.market,
      );

      await uc(next);

      final stored = await repo.getRiskSettings();
      expect(stored.takeProfitPercent, 4.2);
      expect(stored.stopLossPercentMagnitude, 2.0);
      expect(stored.trailingStopPercent, 1.1);
      expect(stored.botSplit, BotSplitPreset.five);
    });
  });
}
