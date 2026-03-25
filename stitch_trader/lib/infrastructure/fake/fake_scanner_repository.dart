import 'package:stitch_trader/domain/dashboard_contracts.dart';

import '_fake_chart_urls.dart';

final class FakeScannerRepository implements ScannerRepository {
  const FakeScannerRepository();

  @override
  Future<List<ScannerHit>> listHits() async {
    return [
      ScannerHit(
        instrument: Instrument(
          code: SymbolCode('005930'),
          displayName: '삼성전자',
        ),
        badgeLabel: '1000억/10%상승',
        badgeTone: ScannerBadgeTone.primary,
        changePercent: 12.4,
        lastPriceKrw: 78400,
        chips: const [
          ScannerChip(label: '테마주', tone: ScannerChipTone.tertiary),
          ScannerChip(label: 'KOSPI', tone: ScannerChipTone.muted),
        ],
        thumbnailUri: FakeChartUrls.scanner1,
        viHighlighted: false,
      ),
      ScannerHit(
        instrument: Instrument(
          code: SymbolCode('247540'),
          displayName: '에코프로비엠',
        ),
        badgeLabel: '5000억 양봉',
        badgeTone: ScannerBadgeTone.tertiary,
        changePercent: 8.2,
        lastPriceKrw: 245500,
        chips: const [
          ScannerChip(label: '주도주', tone: ScannerChipTone.primary),
          ScannerChip(label: 'KOSDAQ', tone: ScannerChipTone.muted),
        ],
        thumbnailUri: FakeChartUrls.scanner2,
        viHighlighted: false,
      ),
      ScannerHit(
        instrument: Instrument(
          code: SymbolCode('005380'),
          displayName: '현대차',
        ),
        badgeLabel: 'VI 포착',
        badgeTone: ScannerBadgeTone.primary,
        changePercent: 15.1,
        lastPriceKrw: 212000,
        chips: const [
          ScannerChip(label: 'HIGH VOL', tone: ScannerChipTone.error),
        ],
        thumbnailUri: FakeChartUrls.scanner3,
        viHighlighted: true,
      ),
    ];
  }
}
