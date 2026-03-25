import 'package:stitch_trader/infrastructure/fake/fake_auto_watch_repository.dart';
import 'package:stitch_trader/infrastructure/fake/fake_chart_context_repository.dart';
import 'package:stitch_trader/infrastructure/fake/fake_scanner_repository.dart';
import 'package:stitch_trader/infrastructure/fake/fake_session_telemetry_repository.dart';
import 'package:stitch_trader/infrastructure/remote/remote_auto_watch_repository.dart';
import 'package:stitch_trader/infrastructure/remote/remote_chart_context_repository.dart';
import 'package:stitch_trader/infrastructure/remote/remote_scanner_repository.dart';
import 'package:stitch_trader/infrastructure/remote/remote_session_telemetry_repository.dart';

import 'app_environment.dart';
import 'dashboard_repositories.dart';

abstract final class DashboardRepositoryFactory {
  static DashboardRepositories create(AppEnvironment env) {
    switch (env) {
      case AppEnvironment.development:
        return DashboardRepositories(
          scanner: const FakeScannerRepository(),
          chart: const FakeChartContextRepository(),
          autoWatch: FakeAutoWatchRepository(),
          telemetry: const FakeSessionTelemetryRepository(),
        );
      case AppEnvironment.staging:
      case AppEnvironment.production:
        return DashboardRepositories(
          scanner: const RemoteScannerRepository(),
          chart: const RemoteChartContextRepository(),
          autoWatch: const RemoteAutoWatchRepository(),
          telemetry: const RemoteSessionTelemetryRepository(),
        );
    }
  }
}
