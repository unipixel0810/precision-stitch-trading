import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';

import 'package:stitch_trader/main.dart';

void main() {
  testWidgets('Dashboard shows AutoTrader title', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const StitchTraderApp());
    await tester.pump();
    expect(find.text('AutoTrader'), findsOneWidget);
  });
}
