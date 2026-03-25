// 진입점: composition root에서 환경별 저장소 → DashboardModule → 화면 주입.
// staging/production REST: --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://...
// 계약: stitch_trader/docs/PHASE4_HTTP_CONTRACT.md
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stitch_trader/app/app_environment.dart';
import 'package:stitch_trader/app/dashboard_module.dart';
import 'package:stitch_trader/app/dashboard_repository_factory.dart';
import 'package:stitch_trader/domain/dashboard_contracts.dart';
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final environment = _appEnvironmentFromDefine();
  final repos = DashboardRepositoryFactory.create(environment);
  final module = DashboardModule.fromRepositories(
    repos,
    defaultSymbol: SymbolCode('005380'),
  );
  runApp(StitchTraderApp(dashboardModule: module, environment: environment));
}

class StitchTraderApp extends StatelessWidget {
  const StitchTraderApp({super.key, required this.dashboardModule, this.environment = AppEnvironment.development});

  final DashboardModule dashboardModule;
  final AppEnvironment environment;

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
      home: PrecisionDashboardPage(module: dashboardModule, environment: environment),
    );
  }
}
