import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_trader/application/dashboard_bundle_codec.dart';
import 'package:stitch_trader/application/models/dashboard_bundle.dart';
import 'package:stitch_trader/domain/dashboard_contracts.dart';
import 'package:stitch_trader/infrastructure/persistence/shared_preferences_dashboard_bundle_cache.dart';

DashboardBundle _minimal() {
  return DashboardBundle(
    scannerHits: [
      ScannerHit(
        instrument: Instrument(code: SymbolCode('005380'), displayName: '현대차'),
        badgeLabel: '',
        badgeTone: ScannerBadgeTone.primary,
        changePercent: 0,
        lastPriceKrw: 0,
        chips: const [],
        thumbnailUri: '',
      ),
    ],
    selectedSymbol: SymbolCode('005380'),
    ohlc: OhlcSnapshot(
      symbol: SymbolCode('005380'),
      openKrw: 0,
      highKrw: 0,
      lowKrw: 0,
      closeKrw: 0,
      volumeDescription: '',
      tickSizeKrw: 1,
    ),
    priceLines: const [],
    autoWatch: const AutoWatchStatus(lineSyncActive: false, phases: []),
    riskSettings: RiskSettings(
      takeProfitPercent: 1,
      stopLossPercentMagnitude: 1,
      trailingStopPercent: 1,
      botSplit: BotSplitPreset.three,
      orderKind: OrderKind.market,
    ),
    telemetry: SessionTelemetry(roundTripLatencyMs: 0, apiLabel: '', tickSnapApplied: false),
    chartBackgroundUri: '',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TTL expired cache is removed and returns null', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final bundle = _minimal();
    final map = Map<String, dynamic>.from(
      jsonDecode(DashboardBundleCodec.encodeForPersist(bundle)) as Map,
    );
    map['cachedAtEpochMs'] = DateTime.now().millisecondsSinceEpoch - const Duration(hours: 48).inMilliseconds;
    await prefs.setString('dashboard_bundle_cache_v1', jsonEncode(map));

    final cache = SharedPreferencesDashboardBundleCache(prefs, maxAge: const Duration(hours: 24));
    expect(await cache.read(), isNull);
    expect(prefs.getString('dashboard_bundle_cache_v1'), isNull);
  });

  test('Fresh cache within TTL is returned', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final cache = SharedPreferencesDashboardBundleCache(prefs, maxAge: const Duration(hours: 24));
    await cache.write(_minimal());
    final got = await cache.read();
    expect(got, isNotNull);
    expect(got!.servedFromCache, isTrue);
  });
}
