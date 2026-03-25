import 'package:stitch_trader/infrastructure/api/api_config.dart';
import 'package:stitch_trader/infrastructure/api/dashboard_http_client.dart';
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
        final api = ApiConfig.fromEnvironment();
        final httpClient = DashboardHttpClient(config: api);
        return DashboardRepositories(
          scanner: RemoteScannerRepository(httpClient),
          chart: RemoteChartContextRepository(httpClient),
          autoWatch: RemoteAutoWatchRepository(httpClient),
          telemetry: RemoteSessionTelemetryRepository(httpClient),
        );
    }
  }
}
