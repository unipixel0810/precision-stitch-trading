import 'package:stitch_trader/domain/dashboard_contracts.dart';

import '../models/dashboard_bundle.dart';

final class LoadDashboardBundle {
  LoadDashboardBundle({
    required ScannerRepository scannerRepository,
    required ChartContextRepository chartRepository,
    required AutoWatchRepository autoWatchRepository,
    required SessionTelemetryRepository telemetryRepository,
    required SymbolCode defaultSymbol,
  })  : _scanner = scannerRepository,
        _chart = chartRepository,
        _auto = autoWatchRepository,
        _telemetry = telemetryRepository,
        _symbol = defaultSymbol;

  final ScannerRepository _scanner;
  final ChartContextRepository _chart;
  final AutoWatchRepository _auto;
  final SessionTelemetryRepository _telemetry;
  final SymbolCode _symbol;

  Future<DashboardBundle> call() async {
    final hits = await _scanner.listHits();
    final ohlc = await _chart.getOhlc(_symbol);
    final lines = await _chart.listPriceLines(_symbol);
    final bg = await _chart.backgroundImage(_symbol);
    final status = await _auto.getStatus();
    final risk = await _auto.getRiskSettings();
    final tel = await _telemetry.getTelemetry();
    return DashboardBundle(
      scannerHits: hits,
      selectedSymbol: _symbol,
      ohlc: ohlc,
      priceLines: lines,
      autoWatch: status,
      riskSettings: risk,
      telemetry: tel,
      chartBackgroundUri: bg?.toString() ?? '',
    );
  }
}
