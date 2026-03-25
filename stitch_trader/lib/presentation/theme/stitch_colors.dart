import 'package:flutter/material.dart';

/// 기존 opacity 곱과 동일한 알파 처리(`withValues`), Flutter 3.27+ 권장.
extension StitchColorFade on Color {
  Color fade(double factor) => withValues(alpha: (a * factor).clamp(0.0, 1.0));
}

/// Kiwoom 0624 / Precision Stitch palette (Tailwind HTML parity + design.md)
abstract final class StitchColors {
  static const Color background = Color(0xFF131313);
  static const Color surface = Color(0xFF131313);
  static const Color surfaceDim = Color(0xFF131313);
  static const Color surfaceContainerLowest = Color(0xFF0E0E0E);
  static const Color surfaceContainerLow = Color(0xFF1C1B1B);
  static const Color surfaceContainer = Color(0xFF201F1F);
  static const Color surfaceContainerHigh = Color(0xFF2A2A2A);
  static const Color surfaceContainerHighest = Color(0xFF353534);
  static const Color surfaceBright = Color(0xFF393939);
  static const Color surfaceVariant = Color(0xFF353534);

  static const Color primary = Color(0xFFC3F5FF);
  static const Color primaryContainer = Color(0xFF00E5FF);
  static const Color onPrimary = Color(0xFF00363D);
  static const Color onPrimaryContainer = Color(0xFF00626E);
  static const Color onPrimaryFixed = Color(0xFF001F24);

  static const Color tertiary = Color(0xFFFFEAC0);
  static const Color tertiaryContainer = Color(0xFFFEC931);
  static const Color onTertiary = Color(0xFF3E2E00);

  static const Color error = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFF93000A);

  static const Color onBackground = Color(0xFFE5E2E1);
  static const Color onSurface = Color(0xFFE5E2E1);
  static const Color onSurfaceVariant = Color(0xFFBAC9CC);

  static const Color outline = Color(0xFF849396);
  static const Color outlineVariant = Color(0xFF3B494C);

  static const Color chartBackdrop = Color(0xFF0D0D0D);

  static const Color glassPanel = Color(0xB31C1B1B);

  static const LinearGradient primaryCtaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF00E5FF), onPrimaryContainer],
  );

  static const LinearGradient stitchSheenGradient = LinearGradient(
    begin: Alignment(-0.2, -0.2),
    end: Alignment(0.2, 0.2),
    colors: [primary, primaryContainer],
  );
}
