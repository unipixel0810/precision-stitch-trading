import 'dart:convert';

import 'package:stitch_trader/application/models/dashboard_bundle.dart';
import 'package:stitch_trader/domain/dashboard_contracts.dart';

/// [DashboardBundle] ↔ JSON (캐시 전용, 계약 버전 1).
abstract final class DashboardBundleCodec {
  static const _v = 1;

  static String encode(DashboardBundle b) => jsonEncode(toMap(b));

  /// 디스크/Preferences 저장용 — 저장 시각 포함.
  static String encodeForPersist(DashboardBundle b) {
    final m = Map<String, dynamic>.from(toMap(b));
    m['cachedAtEpochMs'] = DateTime.now().millisecondsSinceEpoch;
    return jsonEncode(m);
  }

  /// 테스트·마이그레이션용 디코드. `cachedAtEpochMs` 가 있으면 제거 후 파싱.
  static DashboardBundle decode(String raw, {required bool servedFromCache}) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('bundle cache: root must be object');
    }
    final m = Map<String, dynamic>.from(decoded)..remove('cachedAtEpochMs');
    return fromMap(m, servedFromCache: servedFromCache);
  }

  /// TTL 판단용 — `(번들, 저장 시각 ms)`. 타임스탬프 없으면(레거시) `null`.
  static (DashboardBundle bundle, int? cachedAtMs) decodePersisted(
    String raw, {
    required bool servedFromCache,
  }) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException('bundle cache: root must be object');
    }
    final m = Map<String, dynamic>.from(decoded);
    final at = (m['cachedAtEpochMs'] as num?)?.toInt();
    m.remove('cachedAtEpochMs');
    return (fromMap(m, servedFromCache: servedFromCache), at);
  }

  static Map<String, Object?> toMap(DashboardBundle b) => {
        '_v': _v,
        'servedFromCache': false,
        'selectedSymbol': b.selectedSymbol.value,
        'chartBackgroundUri': b.chartBackgroundUri,
        'scannerHits': b.scannerHits.map(_hitToMap).toList(),
        'ohlc': _ohlcToMap(b.ohlc),
        'priceLines': b.priceLines.map(_lineToMap).toList(),
        'autoWatch': _autoToMap(b.autoWatch),
        'riskSettings': _riskToMap(b.riskSettings),
        'telemetry': _telToMap(b.telemetry),
      };

  static DashboardBundle fromMap(Map<String, dynamic> m, {required bool servedFromCache}) {
    final ver = m['_v'];
    if (ver is! int) {
      throw FormatException('bundle cache: _v must be int');
    }
    return switch (ver) {
      1 => _fromMapV1(m, servedFromCache: servedFromCache),
      _ => throw FormatException('bundle cache: unsupported _v $ver (마이그레이션: dashboard_bundle_codec)'),
    };
  }

  /// 스키마 v1. 향후 v2 추가 시 [ver] 분기에서 `_fromMapV2` 호출.
  static DashboardBundle _fromMapV1(Map<String, dynamic> m, {required bool servedFromCache}) {
    final sym = SymbolCode(m['selectedSymbol'] as String);
    final hitsRaw = m['scannerHits'] as List<dynamic>?;
    final linesRaw = m['priceLines'] as List<dynamic>?;
    return DashboardBundle(
      scannerHits: (hitsRaw ?? []).map((e) => _hitFromMap(e as Map<String, dynamic>)).toList(),
      selectedSymbol: sym,
      ohlc: _ohlcFromMap(sym, m['ohlc'] as Map<String, dynamic>),
      priceLines: (linesRaw ?? []).map((e) => _lineFromMap(e as Map<String, dynamic>)).toList(),
      autoWatch: _autoFromMap(m['autoWatch'] as Map<String, dynamic>),
      riskSettings: _riskFromMap(m['riskSettings'] as Map<String, dynamic>),
      telemetry: _telFromMap(m['telemetry'] as Map<String, dynamic>),
      chartBackgroundUri: m['chartBackgroundUri'] as String? ?? '',
      servedFromCache: servedFromCache,
    );
  }

  static Map<String, Object?> _hitToMap(ScannerHit h) => {
        'symbol': h.instrument.code.value,
        'displayName': h.instrument.displayName,
        'badgeLabel': h.badgeLabel,
        'badgeTone': _badgeToneStr(h.badgeTone),
        'changePercent': h.changePercent,
        'lastPriceKrw': h.lastPriceKrw,
        'chips': h.chips
            .map((c) => {'label': c.label, 'tone': _chipToneStr(c.tone)})
            .toList(),
        'thumbnailUri': h.thumbnailUri,
        'viHighlighted': h.viHighlighted,
      };

  static ScannerHit _hitFromMap(Map<String, dynamic> m) {
    return ScannerHit(
      instrument: Instrument(
        code: SymbolCode(m['symbol'] as String),
        displayName: m['displayName'] as String,
      ),
      badgeLabel: m['badgeLabel'] as String? ?? '',
      badgeTone: _parseBadgeTone(m['badgeTone'] as String?),
      changePercent: (m['changePercent'] as num?)?.toDouble() ?? 0,
      lastPriceKrw: (m['lastPriceKrw'] as num?)?.toInt() ?? 0,
      chips: ((m['chips'] as List<dynamic>?) ?? [])
          .map((c) => ScannerChip(
                label: (c as Map<String, dynamic>)['label'] as String,
                tone: _parseChipTone(c['tone'] as String?),
              ))
          .toList(),
      thumbnailUri: m['thumbnailUri'] as String? ?? '',
      viHighlighted: m['viHighlighted'] as bool? ?? false,
    );
  }

  static String _badgeToneStr(ScannerBadgeTone t) => switch (t) {
        ScannerBadgeTone.tertiary => 'tertiary',
        ScannerBadgeTone.primary => 'primary',
      };

  static ScannerBadgeTone _parseBadgeTone(String? s) => switch (s) {
        'tertiary' => ScannerBadgeTone.tertiary,
        _ => ScannerBadgeTone.primary,
      };

  static String _chipToneStr(ScannerChipTone t) => switch (t) {
        ScannerChipTone.tertiary => 'tertiary',
        ScannerChipTone.muted => 'muted',
        ScannerChipTone.error => 'error',
        ScannerChipTone.primary => 'primary',
      };

  static ScannerChipTone _parseChipTone(String? s) => switch (s) {
        'tertiary' => ScannerChipTone.tertiary,
        'muted' => ScannerChipTone.muted,
        'error' => ScannerChipTone.error,
        _ => ScannerChipTone.primary,
      };

  static Map<String, Object?> _ohlcToMap(OhlcSnapshot o) => {
        'openKrw': o.openKrw,
        'highKrw': o.highKrw,
        'lowKrw': o.lowKrw,
        'closeKrw': o.closeKrw,
        'volumeDescription': o.volumeDescription,
        'tickSizeKrw': o.tickSizeKrw,
      };

  static OhlcSnapshot _ohlcFromMap(SymbolCode symbol, Map<String, dynamic> m) {
    return OhlcSnapshot(
      symbol: symbol,
      openKrw: (m['openKrw'] as num?)?.toInt() ?? 0,
      highKrw: (m['highKrw'] as num?)?.toInt() ?? 0,
      lowKrw: (m['lowKrw'] as num?)?.toInt() ?? 0,
      closeKrw: (m['closeKrw'] as num?)?.toInt() ?? 0,
      volumeDescription: m['volumeDescription'] as String? ?? '',
      tickSizeKrw: (m['tickSizeKrw'] as num?)?.toInt() ?? 1,
    );
  }

  static Map<String, Object?> _lineToMap(ChartPriceLine l) => {
        'kind': _lineKindStr(l.kind),
        'priceKrw': l.priceKrw,
        'subtitle': l.subtitle,
      };

  static ChartPriceLine _lineFromMap(Map<String, dynamic> m) {
    return ChartPriceLine(
      kind: _parseLineKind(m['kind'] as String?),
      priceKrw: (m['priceKrw'] as num?)?.toInt() ?? 0,
      subtitle: m['subtitle'] as String?,
    );
  }

  static String _lineKindStr(ChartPriceLineKind k) => switch (k) {
        ChartPriceLineKind.autoTier2 => 'autoTier2',
        ChartPriceLineKind.autoTier3 => 'autoTier3',
        ChartPriceLineKind.sellTarget => 'sellTarget',
        ChartPriceLineKind.primaryBuy => 'primaryBuy',
      };

  static ChartPriceLineKind _parseLineKind(String? s) => switch (s) {
        'autoTier2' => ChartPriceLineKind.autoTier2,
        'autoTier3' => ChartPriceLineKind.autoTier3,
        'sellTarget' => ChartPriceLineKind.sellTarget,
        _ => ChartPriceLineKind.primaryBuy,
      };

  static Map<String, Object?> _autoToMap(AutoWatchStatus a) => {
        'lineSyncActive': a.lineSyncActive,
        'phases': a.phases
            .map((p) => {'kind': _phaseKindStr(p.kind), 'isActive': p.isActive})
            .toList(),
      };

  static AutoWatchStatus _autoFromMap(Map<String, dynamic> m) {
    final phasesRaw = m['phases'] as List<dynamic>?;
    return AutoWatchStatus(
      lineSyncActive: m['lineSyncActive'] as bool? ?? false,
      phases: (phasesRaw ?? [])
          .map((p) {
            final pm = p as Map<String, dynamic>;
            return AutoWatchPhaseState(
              kind: _parsePhaseKind(pm['kind'] as String?),
              isActive: pm['isActive'] as bool? ?? false,
            );
          })
          .toList(),
    );
  }

  static String _phaseKindStr(AutoWatchPhaseKind k) => switch (k) {
        AutoWatchPhaseKind.conditionMet => 'conditionMet',
        AutoWatchPhaseKind.orderFilled => 'orderFilled',
        AutoWatchPhaseKind.monitoring => 'monitoring',
      };

  static AutoWatchPhaseKind _parsePhaseKind(String? s) => switch (s) {
        'conditionMet' => AutoWatchPhaseKind.conditionMet,
        'orderFilled' => AutoWatchPhaseKind.orderFilled,
        _ => AutoWatchPhaseKind.monitoring,
      };

  static Map<String, Object?> _riskToMap(RiskSettings r) => {
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

  static RiskSettings _riskFromMap(Map<String, dynamic> m) {
    return RiskSettings(
      takeProfitPercent: (m['takeProfitPercent'] as num?)?.toDouble() ?? 0,
      stopLossPercentMagnitude: (m['stopLossPercentMagnitude'] as num?)?.toDouble() ?? 0,
      trailingStopPercent: (m['trailingStopPercent'] as num?)?.toDouble() ?? 0,
      botSplit: (m['botSplit'] as String?) == 'five' ? BotSplitPreset.five : BotSplitPreset.three,
      orderKind: (m['orderKind'] as String?) == 'ioc' ? OrderKind.ioc : OrderKind.market,
    );
  }

  static Map<String, Object?> _telToMap(SessionTelemetry t) => {
        'roundTripLatencyMs': t.roundTripLatencyMs,
        'apiLabel': t.apiLabel,
        'tickSnapApplied': t.tickSnapApplied,
      };

  static SessionTelemetry _telFromMap(Map<String, dynamic> m) {
    return SessionTelemetry(
      roundTripLatencyMs: (m['roundTripLatencyMs'] as num?)?.toInt() ?? 0,
      apiLabel: m['apiLabel'] as String? ?? '',
      tickSnapApplied: m['tickSnapApplied'] as bool? ?? false,
    );
  }
}
