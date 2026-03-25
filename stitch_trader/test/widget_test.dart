import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_trader/app/app_environment.dart';
import 'package:stitch_trader/app/dashboard_module.dart';
import 'package:stitch_trader/app/dashboard_repository_factory.dart';
import 'package:stitch_trader/domain/dashboard_contracts.dart';
import 'package:stitch_trader/main.dart';

void main() {
  testWidgets('Dashboard shows AutoTrader title', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repos = DashboardRepositoryFactory.create(AppEnvironment.development);
    final module = DashboardModule.fromRepositories(
      repos,
      defaultSymbol: SymbolCode('005380'),
    );

    await tester.pumpWidget(StitchTraderApp(dashboardModule: module));
    await tester.pump();
    expect(find.text('AutoTrader'), findsOneWidget);
  });
}
