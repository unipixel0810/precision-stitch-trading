import 'package:stitch_trader/domain/dashboard_contracts.dart';

/// 대시보드 한 번에 그릴 때 필요한 읽기 전용 스냅샷 (application 조합).
final class DashboardBundle {
  DashboardBundle({
    required this.scannerHits,
    required this.selectedSymbol,
    required this.ohlc,
    required this.priceLines,
    required this.autoWatch,
    required this.riskSettings,
    required this.telemetry,
    required this.chartBackgroundUri,
    this.servedFromCache = false,
  });

  final List<ScannerHit> scannerHits;
  final SymbolCode selectedSymbol;
  final OhlcSnapshot ohlc;
  final List<ChartPriceLine> priceLines;
  final AutoWatchStatus autoWatch;
  final RiskSettings riskSettings;
  final SessionTelemetry telemetry;
  final String chartBackgroundUri;
  /// 로컬에 저장된 마지막 스냅샷으로만 화면을 채웠을 때 true.
  final bool servedFromCache;

  DashboardBundle copyWith({bool? servedFromCache}) {
    return DashboardBundle(
      scannerHits: scannerHits,
      selectedSymbol: selectedSymbol,
      ohlc: ohlc,
      priceLines: priceLines,
      autoWatch: autoWatch,
      riskSettings: riskSettings,
      telemetry: telemetry,
      chartBackgroundUri: chartBackgroundUri,
      servedFromCache: servedFromCache ?? this.servedFromCache,
    );
  }
}
