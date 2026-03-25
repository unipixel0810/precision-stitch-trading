import 'package:stitch_trader/application/use_cases/load_dashboard_bundle.dart';
import 'package:stitch_trader/application/use_cases/update_risk_settings.dart';
import 'package:stitch_trader/domain/dashboard_contracts.dart';

import 'dashboard_repositories.dart';

final class DashboardModule {
  DashboardModule({
    required this.loadDashboard,
    required this.updateRiskSettings,
  });

  final LoadDashboardBundle loadDashboard;
  final UpdateRiskSettings updateRiskSettings;

  factory DashboardModule.fromRepositories(
    DashboardRepositories repos, {
    required SymbolCode defaultSymbol,
  }) {
    return DashboardModule(
      loadDashboard: LoadDashboardBundle(
        scannerRepository: repos.scanner,
        chartRepository: repos.chart,
        autoWatchRepository: repos.autoWatch,
        telemetryRepository: repos.telemetry,
        defaultSymbol: defaultSymbol,
      ),
      updateRiskSettings: UpdateRiskSettings(repos.autoWatch),
    );
  }
}
