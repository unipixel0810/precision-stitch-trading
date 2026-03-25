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
  static DashboardRepositories create(
    AppEnvironment env, {
    DashboardHttpClient? remoteHttpClient,
  }) {
    switch (env) {
      case AppEnvironment.development:
        if (remoteHttpClient != null) {
          return DashboardRepositories(
            scanner: RemoteScannerRepository(remoteHttpClient),
            chart: RemoteChartContextRepository(remoteHttpClient),
            autoWatch: RemoteAutoWatchRepository(remoteHttpClient),
            telemetry: RemoteSessionTelemetryRepository(remoteHttpClient),
          );
        }
        return DashboardRepositories(
          scanner: const FakeScannerRepository(),
          chart: const FakeChartContextRepository(),
          autoWatch: FakeAutoWatchRepository(),
          telemetry: const FakeSessionTelemetryRepository(),
        );
      case AppEnvironment.staging:
      case AppEnvironment.production:
        final client = remoteHttpClient ?? DashboardHttpClient(config: ApiConfig.fromEnvironment());
        return DashboardRepositories(
          scanner: RemoteScannerRepository(client),
          chart: RemoteChartContextRepository(client),
          autoWatch: RemoteAutoWatchRepository(client),
          telemetry: RemoteSessionTelemetryRepository(client),
        );
    }
  }
}
