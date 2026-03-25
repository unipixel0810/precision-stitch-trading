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
    final results = await Future.wait<Object?>(<Future<Object?>>[
      _scanner.listHits(),
      _chart.getOhlc(_symbol),
      _chart.listPriceLines(_symbol),
      _chart.backgroundImage(_symbol),
      _auto.getStatus(),
      _auto.getRiskSettings(),
      _telemetry.getTelemetry(),
    ]);

    final hits = results[0]! as List<ScannerHit>;
    final ohlc = results[1]! as OhlcSnapshot;
    final lines = results[2]! as List<ChartPriceLine>;
    final bg = results[3] as Uri?;
    final status = results[4]! as AutoWatchStatus;
    final risk = results[5]! as RiskSettings;
    final tel = results[6]! as SessionTelemetry;

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
