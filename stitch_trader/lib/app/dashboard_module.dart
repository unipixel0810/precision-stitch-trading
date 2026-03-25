import 'package:stitch_trader/application/ports/dashboard_bundle_cache_port.dart';
import 'package:stitch_trader/application/use_cases/load_dashboard_bundle.dart';
import 'package:stitch_trader/application/use_cases/update_risk_settings.dart';
import 'package:stitch_trader/domain/dashboard_contracts.dart';

import 'dashboard_repositories.dart';

final class DashboardModule {
  DashboardModule({
    required this.loadDashboard,
    required this.updateRiskSettings,
    this.checkBackendHealth,
  });

  final LoadDashboardBundle loadDashboard;
  final UpdateRiskSettings updateRiskSettings;

  /// Remote 모드에서만 설정. `null` 이면 OK, 아니면 오류 메시지.
  final Future<String?> Function()? checkBackendHealth;

  factory DashboardModule.fromRepositories(
    DashboardRepositories repos, {
    required SymbolCode defaultSymbol,
    DashboardBundleCachePort? bundleCache,
    Future<String?> Function()? checkBackendHealth,
  }) {
    return DashboardModule(
      loadDashboard: LoadDashboardBundle(
        scannerRepository: repos.scanner,
        chartRepository: repos.chart,
        autoWatchRepository: repos.autoWatch,
        telemetryRepository: repos.telemetry,
        defaultSymbol: defaultSymbol,
        bundleCache: bundleCache,
      ),
      updateRiskSettings: UpdateRiskSettings(repos.autoWatch),
      checkBackendHealth: checkBackendHealth,
    );
  }
}
