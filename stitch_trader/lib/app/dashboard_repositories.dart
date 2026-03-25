import 'package:stitch_trader/domain/dashboard_contracts.dart';

final class DashboardRepositories {
  DashboardRepositories({
    required this.scanner,
    required this.chart,
    required this.autoWatch,
    required this.telemetry,
  });

  final ScannerRepository scanner;
  final ChartContextRepository chart;
  final AutoWatchRepository autoWatch;
  final SessionTelemetryRepository telemetry;
}
