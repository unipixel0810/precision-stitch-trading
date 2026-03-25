// 진입점: Clean Architecture 이행은 docs/PHASE0_BASELINE.md 참고.
// P3 이전까지 화면은 lib/screens/, 테마는 lib/theme/ (이후 lib/presentation/).
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/precision_dashboard_screen.dart';
import 'theme/stitch_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StitchTraderApp());
}

class StitchTraderApp extends StatelessWidget {
  const StitchTraderApp({super.key});

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
      home: const PrecisionDashboardScreen(),
    );
  }
}
