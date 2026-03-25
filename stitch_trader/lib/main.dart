// 진입점: composition root에서 환경별 저장소 → DashboardModule → 화면 주입.
// 샘플(가짜) 데이터: 기본 실행 — API_BASE_URL 없음.
// 실데이터: --dart-define=API_BASE_URL=http://호스트:포트 (APP_ENV=development 여도 원격 저장소 사용)
// staging/production: --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://...
// 계약: stitch_trader/docs/PHASE4_HTTP_CONTRACT.md
// 캐시 TTL: --dart-define=CACHE_TTL_HOURS=48
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_trader/app/app_environment.dart';
import 'package:stitch_trader/app/dashboard_module.dart';
import 'package:stitch_trader/app/dashboard_repository_factory.dart';
import 'package:stitch_trader/domain/dashboard_contracts.dart';
import 'package:stitch_trader/infrastructure/api/api_config.dart';
import 'package:stitch_trader/infrastructure/api/dashboard_http_client.dart';
import 'package:stitch_trader/infrastructure/persistence/dashboard_cache_ttl.dart';
import 'package:stitch_trader/infrastructure/persistence/shared_preferences_dashboard_bundle_cache.dart';
import 'package:stitch_trader/presentation/pages/precision_dashboard_page.dart';
import 'package:stitch_trader/presentation/theme/stitch_colors.dart';

AppEnvironment _appEnvironmentFromDefine() {
  const raw = String.fromEnvironment('APP_ENV', defaultValue: 'development');
  return switch (raw.toLowerCase()) {
    'staging' || 'stage' => AppEnvironment.staging,
    'production' || 'prod' => AppEnvironment.production,
    _ => AppEnvironment.development,
  };
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final environment = _appEnvironmentFromDefine();
  final prefs = await SharedPreferences.getInstance();
  final bundleCache = SharedPreferencesDashboardBundleCache(
    prefs,
    maxAge: dashboardCacheMaxAgeFromEnvironment(),
  );

  final api = ApiConfig.fromEnvironment();

  /// `API_BASE_URL` 이 있으면 APP_ENV 가 development 여도 원격 번들(실데이터) 사용.
  /// Parallels Windows 브리지 등: `--dart-define=API_BASE_URL=http://게스트IP:포트`
  DashboardHttpClient? sharedRemote;
  Future<String?> Function()? healthCheck;
  if (api.baseUri != null) {
    final remote = DashboardHttpClient(config: api);
    sharedRemote = remote;
    healthCheck = () async {
      try {
        await remote.pingHealth();
        return null;
      } catch (e) {
        return e.toString();
      }
    };
  }

  final repos = DashboardRepositoryFactory.create(environment, remoteHttpClient: sharedRemote);
  final module = DashboardModule.fromRepositories(
    repos,
    defaultSymbol: SymbolCode('005380'),
    bundleCache: bundleCache,
    checkBackendHealth: healthCheck,
  );
  final usesSampleDashboardData = sharedRemote == null;
  runApp(
    StitchTraderApp(
      dashboardModule: module,
      environment: environment,
      usesSampleDashboardData: usesSampleDashboardData,
    ),
  );
}

class StitchTraderApp extends StatelessWidget {
  const StitchTraderApp({
    super.key,
    required this.dashboardModule,
    this.environment = AppEnvironment.development,
    this.usesSampleDashboardData = true,
  });

  final DashboardModule dashboardModule;
  final AppEnvironment environment;
  final bool usesSampleDashboardData;

  @override
  Widget build(BuildContext context) {
    final baseText = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);
    final display = GoogleFonts.manropeTextTheme(baseText);

    return MaterialApp(
      title: 'StitchTrader | Kiwoom 0624',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: StitchColors.surface,
        colorScheme: ColorScheme.dark(
          primary: StitchColors.primaryContainer,
          onPrimary: StitchColors.onPrimary,
          surface: StitchColors.surface,
          onSurface: StitchColors.onSurface,
          error: StitchColors.error,
        ),
        textTheme: display,
        iconTheme: const IconThemeData(color: StitchColors.onSurfaceVariant),
      ),
      home: PrecisionDashboardPage(
        module: dashboardModule,
        environment: environment,
        usesSampleDashboardData: usesSampleDashboardData,
      ),
    );
  }
}
