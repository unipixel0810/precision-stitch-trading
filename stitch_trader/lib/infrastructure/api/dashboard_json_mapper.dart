import 'package:stitch_trader/domain/dashboard_contracts.dart';

import 'api_exceptions.dart';

/// `docs/PHASE4_HTTP_CONTRACT.md` 에 맞춘 JSON → Domain 매핑.
abstract final class DashboardJsonMapper {
  static List<ScannerHit> parseScannerHits(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw DashboardJsonException('scanner: root must be object');
    }
    final list = raw['hits'];
    if (list is! List) {
      throw DashboardJsonException('scanner: hits must be array');
    }
    return list.map((e) => _scannerHit(e)).toList();
  }

  static ScannerHit _scannerHit(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw DashboardJsonException('scanner hit must be object');
    }
    final symbol = raw['symbol'] as String?;
    final displayName = raw['displayName'] as String?;
    if (symbol == null || displayName == null) {
      throw DashboardJsonException('scanner hit missing symbol/displayName');
    }
    final chipsRaw = raw['chips'];
    final chips = <ScannerChip>[];
    if (chipsRaw is List) {
      for (final c in chipsRaw) {
        if (c is Map<String, dynamic>) {
          final label = c['label'] as String?;
          final tone = _chipTone(c['tone'] as String?);
          if (label != null) chips.add(ScannerChip(label: label, tone: tone));
        }
      }
    }
    return ScannerHit(
      instrument: Instrument(code: SymbolCode(symbol), displayName: displayName),
      badgeLabel: raw['badgeLabel'] as String? ?? '',
      badgeTone: _badgeTone(raw['badgeTone'] as String?),
      changePercent: (raw['changePercent'] as num?)?.toDouble() ?? 0,
      lastPriceKrw: (raw['lastPriceKrw'] as num?)?.toInt() ?? 0,
      chips: chips,
      thumbnailUri: raw['thumbnailUri'] as String? ?? '',
      viHighlighted: raw['viHighlighted'] as bool? ?? false,
    );
  }

  static ScannerBadgeTone _badgeTone(String? s) => switch (s?.toLowerCase()) {
        'tertiary' => ScannerBadgeTone.tertiary,
        _ => ScannerBadgeTone.primary,
      };

  static ScannerChipTone _chipTone(String? s) => switch (s?.toLowerCase()) {
        'tertiary' => ScannerChipTone.tertiary,
        'muted' => ScannerChipTone.muted,
        'error' => ScannerChipTone.error,
        _ => ScannerChipTone.primary,
      };

  static OhlcSnapshot parseOhlc(SymbolCode symbol, Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw DashboardJsonException('ohlc: root must be object');
    }
    return OhlcSnapshot(
      symbol: symbol,
      openKrw: (raw['openKrw'] as num?)?.toInt() ?? 0,
      highKrw: (raw['highKrw'] as num?)?.toInt() ?? 0,
      lowKrw: (raw['lowKrw'] as num?)?.toInt() ?? 0,
      closeKrw: (raw['closeKrw'] as num?)?.toInt() ?? 0,
      volumeDescription: raw['volumeDescription'] as String? ?? '',
      tickSizeKrw: (raw['tickSizeKrw'] as num?)?.toInt() ?? 1,
    );
  }

  static List<ChartPriceLine> parsePriceLines(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw DashboardJsonException('priceLines: root must be object');
    }
    final list = raw['lines'];
    if (list is! List) {
      throw DashboardJsonException('priceLines: lines must be array');
    }
    return list.map((e) => _priceLine(e)).toList();
  }

  static ChartPriceLine _priceLine(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw DashboardJsonException('price line must be object');
    }
    return ChartPriceLine(
      kind: _lineKind(raw['kind'] as String?),
      priceKrw: (raw['priceKrw'] as num?)?.toInt() ?? 0,
      subtitle: raw['subtitle'] as String?,
    );
  }

  static ChartPriceLineKind _lineKind(String? s) => switch (s) {
        'autoTier2' => ChartPriceLineKind.autoTier2,
        'autoTier3' => ChartPriceLineKind.autoTier3,
        'sellTarget' => ChartPriceLineKind.sellTarget,
        _ => ChartPriceLineKind.primaryBuy,
      };

  static Uri? parseChartBackground(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map<String, dynamic>) {
      throw DashboardJsonException('chartBackground must be object');
    }
    final u = raw['url'] as String?;
    if (u == null || u.isEmpty) return null;
    return Uri.tryParse(u);
  }

  static AutoWatchStatus parseAutoWatchStatus(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw DashboardJsonException('autoWatch status must be object');
    }
    final phasesRaw = raw['phases'];
    final phases = <AutoWatchPhaseState>[];
    if (phasesRaw is List) {
      for (final p in phasesRaw) {
        if (p is Map<String, dynamic>) {
          phases.add(
            AutoWatchPhaseState(
              kind: _phaseKind(p['kind'] as String?),
              isActive: p['isActive'] as bool? ?? false,
            ),
          );
        }
      }
    }
    return AutoWatchStatus(
      lineSyncActive: raw['lineSyncActive'] as bool? ?? false,
      phases: phases,
    );
  }

  static AutoWatchPhaseKind _phaseKind(String? s) => switch (s) {
        'conditionMet' => AutoWatchPhaseKind.conditionMet,
        'orderFilled' => AutoWatchPhaseKind.orderFilled,
        _ => AutoWatchPhaseKind.monitoring,
      };

  static RiskSettings parseRiskSettings(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw DashboardJsonException('risk must be object');
    }
    return RiskSettings(
      takeProfitPercent: (raw['takeProfitPercent'] as num?)?.toDouble() ?? 0,
      stopLossPercentMagnitude: (raw['stopLossPercentMagnitude'] as num?)?.toDouble() ?? 0,
      trailingStopPercent: (raw['trailingStopPercent'] as num?)?.toDouble() ?? 0,
      botSplit: _botSplit(raw['botSplit'] as String?),
      orderKind: _orderKind(raw['orderKind'] as String?),
    );
  }

  static Map<String, Object?> riskToJson(RiskSettings r) => {
        'takeProfitPercent': r.takeProfitPercent,
        'stopLossPercentMagnitude': r.stopLossPercentMagnitude,
        'trailingStopPercent': r.trailingStopPercent,
        'botSplit': switch (r.botSplit) {
          BotSplitPreset.five => 'five',
          BotSplitPreset.three => 'three',
        },
        'orderKind': switch (r.orderKind) {
          OrderKind.ioc => 'ioc',
          OrderKind.market => 'market',
        },
      };

  static BotSplitPreset _botSplit(String? s) => switch (s?.toLowerCase()) {
        'five' => BotSplitPreset.five,
        _ => BotSplitPreset.three,
      };

  static OrderKind _orderKind(String? s) => switch (s?.toLowerCase()) {
        'ioc' => OrderKind.ioc,
        _ => OrderKind.market,
      };

  static SessionTelemetry parseTelemetry(Object? raw) {
    if (raw is! Map<String, dynamic>) {
      throw DashboardJsonException('telemetry must be object');
    }
    return SessionTelemetry(
      roundTripLatencyMs: (raw['roundTripLatencyMs'] as num?)?.toInt() ?? 0,
      apiLabel: raw['apiLabel'] as String? ?? '',
      tickSnapApplied: raw['tickSnapApplied'] as bool? ?? false,
    );
  }
}
