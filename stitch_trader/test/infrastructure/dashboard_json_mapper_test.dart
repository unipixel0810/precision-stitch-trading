import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_trader/domain/dashboard_contracts.dart';
import 'package:stitch_trader/infrastructure/api/dashboard_json_mapper.dart';

void main() {
  test('parseScannerHits maps hits list', () {
    final raw = jsonDecode('''{
      "hits": [
        {
          "symbol": "005380",
          "displayName": "현대차",
          "badgeLabel": "VI",
          "badgeTone": "primary",
          "changePercent": 1.5,
          "lastPriceKrw": 1000,
          "chips": [{"label": "A", "tone": "muted"}],
          "thumbnailUri": "https://x/y.png",
          "viHighlighted": true
        }
      ]
    }''');

    final hits = DashboardJsonMapper.parseScannerHits(raw);
    expect(hits.length, 1);
    expect(hits.single.instrument.code.value, '005380');
    expect(hits.single.chips.single.tone, ScannerChipTone.muted);
  });

  test('parseOhlc uses symbol argument', () {
    final sym = SymbolCode('005380');
    final raw = jsonDecode('''{
      "openKrw": 1, "highKrw": 2, "lowKrw": 3, "closeKrw": 4,
      "volumeDescription": "v", "tickSizeKrw": 100
    }''');
    final o = DashboardJsonMapper.parseOhlc(sym, raw);
    expect(o.symbol, sym);
    expect(o.closeKrw, 4);
  });

  test('parsePriceLines reads kinds', () {
    final raw = jsonDecode('''{
      "lines": [
        {"kind": "sellTarget", "priceKrw": 218000}
      ]
    }''');
    final lines = DashboardJsonMapper.parsePriceLines(raw);
    expect(lines.single.kind, ChartPriceLineKind.sellTarget);
  });

  test('risk round-trip json keys', () {
    final r = RiskSettings(
      takeProfitPercent: 1,
      stopLossPercentMagnitude: 2,
      trailingStopPercent: 3,
      botSplit: BotSplitPreset.five,
      orderKind: OrderKind.ioc,
    );
    final m = DashboardJsonMapper.riskToJson(r);
    expect(m['botSplit'], 'five');
    expect(m['orderKind'], 'ioc');
    final back = DashboardJsonMapper.parseRiskSettings(jsonDecode(jsonEncode(m)));
    expect(back.botSplit, BotSplitPreset.five);
    expect(back.orderKind, OrderKind.ioc);
  });
}
