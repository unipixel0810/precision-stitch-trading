import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stitch_trader/app/app_environment.dart';
import 'package:stitch_trader/app/dashboard_module.dart';
import 'package:stitch_trader/application/models/dashboard_bundle.dart';
import 'package:stitch_trader/domain/dashboard_contracts.dart';

import '../constants/remote_chart_assets.dart';
import '../theme/stitch_colors.dart';
import 'analytics_performance_tab.dart';

class PrecisionDashboardPage extends StatefulWidget {
  const PrecisionDashboardPage({super.key, required this.module, this.environment = AppEnvironment.development});

  final DashboardModule module;
  final AppEnvironment environment;

  @override
  State<PrecisionDashboardPage> createState() => _PrecisionDashboardPageState();
}

class _PrecisionDashboardPageState extends State<PrecisionDashboardPage> {
  static const double _sideWidth = 320;

  DashboardBundle? _bundle;
  bool _loading = true;
  bool _refreshBusy = false;
  Object? _loadError;

  double _tpPercent = 3.5;
  double _slPercent = 1.2;
  final TextEditingController _trailingCtrl = TextEditingController();
  int _botPreset = 0;
  int _drawTool = 1;
  /// 0 포트폴리오, 1 주문현황, 2 성과분석, 3 로그
  int _mainNavIndex = 0;

  TextStyle get _headline => GoogleFonts.manrope(color: StitchColors.onSurface);
  TextStyle get _label => GoogleFonts.inter(color: StitchColors.onSurfaceVariant);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _runHealthCheck() async {
    final fn = widget.module.checkBackendHealth;
    if (fn == null) return;
    final msg = await fn();
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(msg == null ? '연결 정상' : '연결 실패'),
        content: SingleChildScrollView(
          child: SelectableText(msg ?? 'GET /v1/health 응답 OK'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('닫기')),
        ],
      ),
    );
  }

  Future<void> _load({bool showFullScreenLoader = true}) async {
    final needsFullScreen = showFullScreenLoader || _bundle == null;
    if (!needsFullScreen && _refreshBusy) return;
    if (!needsFullScreen) {
      _refreshBusy = true;
      if (mounted) setState(() => _loadError = null);
    } else {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final b = await widget.module.loadDashboard.call();
      if (!mounted) return;
      setState(() {
        _bundle = b;
        _loading = false;
        _refreshBusy = false;
        _loadError = null;
        _tpPercent = b.riskSettings.takeProfitPercent;
        _slPercent = b.riskSettings.stopLossPercentMagnitude;
        _trailingCtrl.text = b.riskSettings.trailingStopPercent.toString();
        _botPreset = b.riskSettings.botSplit == BotSplitPreset.three ? 0 : 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshBusy = false;
        if (_bundle == null) {
          _loadError = e;
        }
      });
      if (_bundle != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('데이터 새로고침 실패: $e'),
            backgroundColor: StitchColors.errorContainer,
          ),
        );
      }
    }
  }

  RiskSettings _riskFromForm() {
    final b = _bundle!;
    final trailing = double.tryParse(_trailingCtrl.text) ?? b.riskSettings.trailingStopPercent;
    return b.riskSettings.copyWith(
      takeProfitPercent: _tpPercent,
      stopLossPercentMagnitude: _slPercent,
      trailingStopPercent: trailing,
      botSplit: _botPreset == 0 ? BotSplitPreset.three : BotSplitPreset.five,
    );
  }

  Future<void> _persistRisk() async {
    try {
      await widget.module.updateRiskSettings.call(_riskFromForm());
      await _load(showFullScreenLoader: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('설정 저장 실패: $e'), backgroundColor: StitchColors.errorContainer),
      );
    }
  }

  static String _formatKrw(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }

  ChartPriceLine? _priceLine(ChartPriceLineKind k) {
    for (final e in _bundle!.priceLines) {
      if (e.kind == k) return e;
    }
    return null;
  }

  String _pctUi(double p) => '${p >= 0 ? '+' : ''}${p.toStringAsFixed(1)}%';

  /// 실제 매매는 키움 OpenAPI+(Windows)·백엔드·Python 엔진 연동 후에만 가능합니다.
  static const String _stubTradingExplain =
      '현재 빌드는 UI·샘플 데이터입니다. 주문/체결은 미연동 상태입니다. '
      '실거래는 Windows VPS의 키움 API + analytics/stitch_server_engine.py 등을 연결해야 합니다.';

  void _showStubActionNotice(String headline) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 7),
        backgroundColor: StitchColors.surfaceContainerHigh,
        content: Text(
          '$headline\n\n$_stubTradingExplain',
          style: GoogleFonts.inter(
            fontSize: 12,
            height: 1.35,
            color: StitchColors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _scannerCardFromHit(ScannerHit hit) {
    return _scannerCard(
      badge: hit.badgeLabel,
      badgeAccent: hit.badgeTone == ScannerBadgeTone.primary ? _BadgeAccent.primary : _BadgeAccent.tertiary,
      title: hit.instrument.displayName,
      pct: _pctUi(hit.changePercent),
      price: '${_formatKrw(hit.lastPriceKrw)} 원',
      chipRows: hit.chips.map((c) => _ChipData(c.label, _mapChipTone(c.tone))).toList(),
      thumb: hit.thumbnailUri,
      viLeftRail: hit.viHighlighted,
      onTap: () => _showStubActionNotice(
        '「${hit.instrument.displayName}」종목 카드 — 차트 심볼·실시간 호가 전환은 아직 없습니다.',
      ),
    );
  }

  _ChipTone _mapChipTone(ScannerChipTone t) => switch (t) {
        ScannerChipTone.primary => _ChipTone.primary,
        ScannerChipTone.tertiary => _ChipTone.tertiary,
        ScannerChipTone.muted => _ChipTone.muted,
        ScannerChipTone.error => _ChipTone.error,
      };

  String _selectedInstrumentLabel() {
    final sym = _bundle!.selectedSymbol;
    for (final h in _bundle!.scannerHits) {
      if (h.instrument.code.value == sym.value) {
        return '${h.instrument.displayName} (${sym.value})';
      }
    }
    return sym.value;
  }

  String _buyLinePrimaryLabel() {
    final p = _priceLine(ChartPriceLineKind.primaryBuy);
    return p != null ? '매수 @ KRW ${_formatKrw(p.priceKrw)}' : '매수';
  }

  String _buyLineAuto2Label() {
    final p = _priceLine(ChartPriceLineKind.autoTier2);
    if (p == null) return '오토-2';
    final s = p.subtitle != null ? ' ${p.subtitle}' : '';
    return '오토-2 @ KRW ${_formatKrw(p.priceKrw)}$s';
  }

  String _buyLineAuto3Label() {
    final p = _priceLine(ChartPriceLineKind.autoTier3);
    if (p == null) return '오토-3';
    final s = p.subtitle != null ? ' ${p.subtitle}' : '';
    return '오토-3 @ KRW ${_formatKrw(p.priceKrw)}$s';
  }

  @override
  void dispose() {
    _trailingCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadError != null && _bundle == null) {
      return Scaffold(
        backgroundColor: StitchColors.surface,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_outlined, size: 48, color: StitchColors.error.fade(0.9)),
                  const SizedBox(height: 16),
                  Text(
                    '대시보드를 불러오지 못했습니다',
                    textAlign: TextAlign.center,
                    style: _headline.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_loadError',
                    textAlign: TextAlign.center,
                    style: _label.copyWith(fontSize: 12, color: StitchColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _load,
                    child: const Text('다시 시도'),
                  ),
                  if (widget.module.checkBackendHealth != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _runHealthCheck,
                      child: const Text('연결 진단 (/v1/health)'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (_loading || _bundle == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: StitchColors.surface,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          RefreshIndicator(
            color: StitchColors.primaryContainer,
            edgeOffset: 64,
            onRefresh: () => _load(showFullScreenLoader: false),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _topNav()),
                if (_mainNavIndex == 0 && _bundle!.servedFromCache)
                  SliverToBoxAdapter(child: _offlineSnapshotBanner()),
                if (_mainNavIndex == 0)
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final vw = c.maxWidth.isFinite ? c.maxWidth : _dashboardMinContentWidth;
                        final contentW = vw < _dashboardMinContentWidth ? _dashboardMinContentWidth : vw;
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            Positioned.fill(child: CustomPaint(painter: _GridDotsPainter())),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                primary: false,
                                child: SizedBox(
                                  width: contentW,
                                  height: c.maxHeight,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(width: _sideWidth, child: _scannerPanel()),
                                      Expanded(child: _chartPanel()),
                                      SizedBox(width: _sideWidth, child: _controllerPanel()),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  )
                else if (_mainNavIndex == 2)
                  const SliverFillRemaining(
                    hasScrollBody: true,
                    child: AnalyticsPerformanceTab(),
                  )
                else
                  SliverFillRemaining(
                    hasScrollBody: true,
                    child: Center(
                      child: Text(
                        '준비 중입니다',
                        style: GoogleFonts.inter(color: StitchColors.onSurfaceVariant, fontSize: 15),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_mainNavIndex == 0) _LatencyToast(telemetry: _bundle!.telemetry),
        ],
      ),
    );
  }

  Widget _offlineSnapshotBanner() {
    return Material(
      color: StitchColors.tertiaryContainer.fade(0.12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: StitchColors.tertiaryContainer.fade(0.35))),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off_outlined, size: 20, color: StitchColors.tertiaryContainer),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '오프라인 · 마지막으로 저장된 스냅샷입니다. 상단 새로고침 또는 화면을 아래로 당겨 다시 시도하세요.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: StitchColors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 좁은 뷰포트(웹 창 축소 등)에서 가로 오버플로 방지.
  static const double _topNavMinContentWidth = 1080;

  /// 좌·우 패널 [_sideWidth] + 차트 최소 가독 폭.
  static const double _dashboardMinContentWidth = _sideWidth + 440 + _sideWidth;

  Widget _topNav() {
    return Material(
      color: StitchColors.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final vw = constraints.maxWidth.isFinite ? constraints.maxWidth : _topNavMinContentWidth;
          final contentW = vw < _topNavMinContentWidth ? _topNavMinContentWidth : vw;
          return SizedBox(
            height: 64,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: StitchColors.primaryContainer.fade(0.2))),
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  primary: false,
                  child: SizedBox(
                    width: contentW,
                    height: 64,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
            Text(
              'AutoTrader',
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: StitchColors.primaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: switch (widget.environment) {
                      AppEnvironment.production => StitchColors.surfaceContainerHigh.fade(0.8),
                      AppEnvironment.staging => StitchColors.tertiaryContainer.fade(0.2),
                      AppEnvironment.development => StitchColors.primaryContainer.fade(0.12),
                    },
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: switch (widget.environment) {
                        AppEnvironment.production => StitchColors.outlineVariant.fade(0.5),
                        AppEnvironment.staging => StitchColors.tertiaryContainer.fade(0.5),
                        AppEnvironment.development => StitchColors.primaryContainer.fade(0.35),
                      },
                ),
              ),
              child: Text(
                widget.environment.shortLabel,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                  color: switch (widget.environment) {
                        AppEnvironment.production => StitchColors.onSurfaceVariant,
                        AppEnvironment.staging => StitchColors.tertiaryContainer,
                        AppEnvironment.development => StitchColors.primaryContainer,
                      },
                ),
              ),
            ),
            const SizedBox(width: 28),
            Expanded(
              child: Wrap(
                spacing: 32,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _navLink('포트폴리오', index: 0),
                  _navLink('주문현황', index: 1),
                  _navLink('성과분석', index: 2),
                  _navLink('로그', index: 3),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: StitchColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: StitchColors.primaryContainer.fade(0.1)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.account_balance_wallet_outlined, size: 18, color: StitchColors.primaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    '24,500,000 KRW',
                    style: GoogleFonts.manrope(fontSize: 12, fontWeight: FontWeight.w700, color: StitchColors.onSurface),
                  ),
                  const SizedBox(width: 16),
                  Container(width: 1, height: 12, color: StitchColors.outlineVariant.fade(0.3)),
                  const SizedBox(width: 16),
                  Icon(Icons.cloud_done_outlined, size: 18, color: StitchColors.tertiaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    'SYNC ACTIVE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                      color: StitchColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: '새로고침',
              onPressed: (_loading || _refreshBusy)
                  ? null
                  : () => _load(showFullScreenLoader: false),
              icon: Icon(
                Icons.refresh,
                color: (_loading || _refreshBusy)
                    ? StitchColors.onSurfaceVariant.fade(0.4)
                    : StitchColors.primaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: StitchColors.primaryContainer,
                foregroundColor: StitchColors.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                elevation: 0,
              ),
              onPressed: () => _showStubActionNotice('LIVE TRADING'),
              child: Text(
                'LIVE TRADING',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              tooltip: '설정',
              onPressed: () => _showStubActionNotice('설정 — 화면 미구현'),
              icon: Icon(Icons.settings_outlined, color: StitchColors.onSurfaceVariant),
            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _navLink(String label, {required int index}) {
    final active = _mainNavIndex == index;
    return TextButton(
      onPressed: () => setState(() => _mainNavIndex = index),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: active ? StitchColors.primaryContainer : StitchColors.onSurfaceVariant,
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _scannerPanel() {
    return ColoredBox(
      color: StitchColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: StitchColors.surfaceContainer.fade(0.3),
              border: Border(
                bottom: BorderSide(color: StitchColors.primary.fade(0.3)),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('종목 스캐너', style: _headline.copyWith(fontSize: 14, color: StitchColors.primaryContainer)),
                      const SizedBox(height: 2),
                      Text('20시 종목 추출 로직', style: _label.copyWith(fontSize: 10, letterSpacing: 1.5)),
                    ],
                  ),
                ),
                Icon(Icons.radar, color: StitchColors.primaryContainer, size: 22),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (var i = 0; i < _bundle!.scannerHits.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  _scannerCardFromHit(_bundle!.scannerHits[i]),
                ],
              ],
            ),
          ),
          ColoredBox(
            color: StitchColors.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () => _showStubActionNotice('신규 스캐너 추가'),
                icon: Icon(Icons.add_circle_outline, size: 18, color: StitchColors.primaryContainer),
                label: Text(
                  '신규 스캐너 추가',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: StitchColors.primaryContainer,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: StitchColors.primaryContainer,
                  side: BorderSide(color: StitchColors.primaryContainer.fade(0.3)),
                  backgroundColor: StitchColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scannerCard({
    required String badge,
    required _BadgeAccent badgeAccent,
    required String title,
    required String pct,
    required String price,
    required List<_ChipData> chipRows,
    required String thumb,
    bool viLeftRail = false,
    required VoidCallback onTap,
  }) {
    final cyanEdge = StitchColors.primaryContainer.fade(0.3);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: StitchColors.surfaceContainerHigh.fade(0.4),
                    border: Border.all(
                      color: viLeftRail ? cyanEdge : StitchColors.outlineVariant.fade(0.05),
                    ),
                  ),
                ),
              ),
              if (viLeftRail)
                const Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 4,
                  child: ColoredBox(color: StitchColors.primaryContainer),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(viLeftRail ? 14 : 12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _scannerBadge(badge, badgeAccent),
                        const SizedBox(height: 4),
                        Text(title, style: GoogleFonts.manrope(fontSize: 18, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        pct,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: StitchColors.primaryContainer,
                        ),
                      ),
                      Text(price, style: _label.copyWith(fontSize: 10)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: chipRows.map((c) => _chip(c)).toList(),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: Opacity(
                    opacity: 0.6,
                    child: Image.network(thumb, fit: BoxFit.cover, errorBuilder: (_, _, _) => ColoredBox(color: StitchColors.surfaceContainerLowest)),
                  ),
                ),
              ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
 }

  Widget _scannerBadge(String text, _BadgeAccent accent) {
    final (bg, fg) = switch (accent) {
      _BadgeAccent.primary => (
          StitchColors.primaryContainer.fade(0.1),
          StitchColors.primaryContainer,
        ),
      _BadgeAccent.tertiary => (
          StitchColors.tertiaryContainer.fade(0.1),
          StitchColors.tertiaryContainer,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }

  Widget _chip(_ChipData data) {
    final style = switch (data.tone) {
      _ChipTone.primary => (
          StitchColors.primaryContainer.fade(0.1),
          StitchColors.primaryContainer,
          StitchColors.primaryContainer.fade(0.2),
        ),
      _ChipTone.tertiary => (
          StitchColors.tertiaryContainer.fade(0.1),
          StitchColors.tertiaryContainer,
          StitchColors.tertiaryContainer.fade(0.2),
        ),
      _ChipTone.muted => (
          StitchColors.outlineVariant.fade(0.2),
          StitchColors.onSurfaceVariant,
          StitchColors.outlineVariant.fade(0.2),
        ),
      _ChipTone.error => (
          StitchColors.errorContainer.fade(0.2),
          StitchColors.error,
          StitchColors.error.fade(0.2),
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: style.$1,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: style.$3),
      ),
      child: Text(
        data.label,
        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, color: style.$2),
      ),
    );
  }

  Widget _chartPanel() {
    return ColoredBox(
      color: StitchColors.chartBackdrop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _chartToolbar(),
          Expanded(child: _chartStage()),
          _ohlcLegend(),
        ],
      ),
    );
  }

  Widget _chartToolbar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: StitchColors.surfaceContainerLowest.fade(0.5),
        border: Border(bottom: BorderSide(color: StitchColors.primaryContainer.fade(0.1))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: StitchColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                _toolBtn(0, Icons.show_chart_outlined),
                _toolBtn(1, Icons.edit_outlined),
                _toolBtn(2, Icons.square_foot_outlined),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 16, color: StitchColors.outlineVariant.fade(0.3)),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _modeChip('AUTO LINE (S)'),
                  const SizedBox(width: 8),
                  _modeChip('QUADRANT (Q)'),
                  const SizedBox(width: 8),
                  _modeChip('FIBONACCI (F)'),
                  const SizedBox(width: 8),
                  _modeChip('MAGNET', icon: Icons.bolt, active: true),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: StitchColors.primaryContainer.fade(0.1),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: StitchColors.primaryContainer.fade(0.2)),
            ),
            child: Text(
              'ALT + 드래그하여 매수 라인 생성',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: StitchColors.primaryContainer,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 16, color: StitchColors.outlineVariant.fade(0.3)),
          const SizedBox(width: 12),
          Text(
            '5M 정밀 뷰',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: StitchColors.onSurfaceVariant,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toolBtn(int index, IconData icon) {
    final on = _drawTool == index;
    return Material(
      color: on ? StitchColors.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: () => setState(() => _drawTool = index),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 18,
            color: on ? StitchColors.onPrimary : StitchColors.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _modeChip(String label, {IconData? icon, bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: active ? StitchColors.surfaceContainerHigh : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: active ? StitchColors.primaryContainer.fade(0.4) : StitchColors.outlineVariant.fade(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: StitchColors.primaryContainer),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: StitchColors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _chartStage() {
    return LayoutBuilder(
      builder: (context, c) {
        final h = c.maxHeight;
        final w = c.maxWidth;
        return MouseRegion(
          cursor: SystemMouseCursors.precise,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Opacity(
                opacity: 0.5,
                child: Image.network(
                  _bundle!.chartBackgroundUri.isNotEmpty ? _bundle!.chartBackgroundUri : RemoteChartAssets.chartMain,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ColoredBox(color: StitchColors.chartBackdrop),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _DashedHLinesPainter(
                    fractions: const [0.65, 0.72, 0.78],
                    opacities: const [1.0, 0.6, 0.3],
                  ),
                ),
              ),
              _buyLineLabel(h: h, yFrac: 0.65, label: _buyLinePrimaryLabel(), emphasized: true),
              _buyLineLabel(h: h, yFrac: 0.72, label: _buyLineAuto2Label(), opacity: 0.85),
              _buyLineLabel(h: h, yFrac: 0.78, label: _buyLineAuto3Label(), opacity: 0.65),
              _sellTargetBanner(h: h, yFrac: 0.25),
              _viMarkerColumn(w: w, h: h, rightFrac: 0.3, yFrac: 0.4),
              Positioned(
                top: 40,
                left: 40,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      width: 220,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: StitchColors.glassPanel,
                        border: Border.all(color: StitchColors.primaryContainer.fade(0.3)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedInstrumentLabel(),
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: StitchColors.primaryContainer.fade(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: StitchColors.primaryContainer.fade(0.2)),
                                ),
                                child: Text(
                                  '실시간 동기화',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: StitchColors.primaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              style: GoogleFonts.manrope(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: StitchColors.primaryContainer,
                              ),
                              children: [
                                TextSpan(text: '${_formatKrw(_bundle!.ohlc.closeKrw)} '),
                                TextSpan(
                                  text: 'KRW',
                                  style: GoogleFonts.manrope(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: StitchColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Divider(color: StitchColors.outlineVariant.fade(0.1), height: 1),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '감시 가격:',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: StitchColors.onSurfaceVariant,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatKrw(
                                  _priceLine(ChartPriceLineKind.primaryBuy)?.priceKrw ?? _bundle!.ohlc.openKrw,
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: StitchColors.primaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// [yFrac] is position from top of chart (0–1), matching HTML `top-[65%]` style lines.
  Widget _buyLineLabel({
    required double h,
    required double yFrac,
    required String label,
    bool emphasized = false,
    double opacity = 1,
  }) {
    return Positioned(
      left: 0,
      right: 0,
      top: h * yFrac - 12,
      child: Opacity(
        opacity: opacity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (emphasized) ...[
                Container(width: 96, height: 1, color: StitchColors.primaryContainer.fade(0.5)),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: emphasized ? StitchColors.primaryContainer : StitchColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: StitchColors.primaryContainer.fade(emphasized ? 0 : 0.4)),
                  boxShadow: emphasized
                      ? [BoxShadow(color: StitchColors.primaryContainer.fade(0.25), blurRadius: 12)]
                      : null,
                ),
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: emphasized ? 10 : 9,
                    fontWeight: FontWeight.w900,
                    color: emphasized ? StitchColors.onPrimary : StitchColors.primaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sellTargetBanner({required double h, required double yFrac}) {
    final p = _priceLine(ChartPriceLineKind.sellTarget);
    final bannerText = p != null ? '목표 매도 @ KRW ${_formatKrw(p.priceKrw)}' : '목표 매도';
    return Positioned(
      left: 0,
      right: 0,
      top: h * yFrac - 12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: StitchColors.errorContainer,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: StitchColors.error.fade(0.3)),
                boxShadow: [BoxShadow(color: StitchColors.error.fade(0.15), blurRadius: 12)],
              ),
              child: Text(
                bannerText,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: StitchColors.error,
                  letterSpacing: -0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _viMarkerColumn({
    required double w,
    required double h,
    required double rightFrac,
    required double yFrac,
  }) {
    return Positioned(
      right: w * rightFrac,
      top: h * yFrac,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: StitchColors.tertiaryContainer,
              borderRadius: BorderRadius.circular(4),
              boxShadow: [BoxShadow(color: StitchColors.tertiaryContainer.fade(0.3), blurRadius: 10)],
            ),
            child: Text(
              'VI 발동 구간',
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w900,
                color: StitchColors.onTertiary,
              ),
            ),
          ),
          CustomPaint(
            size: const Size(2, 128),
            painter: _VerticalDashedPainter(color: StitchColors.tertiaryContainer.fade(0.5)),
          ),
        ],
      ),
    );
  }

  Widget _ohlcLegend() {
    final o = _bundle!.ohlc;
    Widget ohlcKV(String k, String val, {Color? highlight}) {
      return Text.rich(
        TextSpan(
          style: GoogleFonts.inter(fontSize: 10, color: StitchColors.onSurfaceVariant),
          children: [
            TextSpan(
              text: '$k: ',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: StitchColors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text: val,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: highlight ?? StitchColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: StitchColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: StitchColors.primaryContainer.fade(0.1))),
      ),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ohlcKV('O', _formatKrw(o.openKrw)),
            const SizedBox(width: 16),
            ohlcKV('H', _formatKrw(o.highKrw)),
            const SizedBox(width: 16),
            ohlcKV('L', _formatKrw(o.lowKrw)),
            const SizedBox(width: 16),
            ohlcKV('C', _formatKrw(o.closeKrw)),
            const SizedBox(width: 24),
            Container(width: 1, height: 12, color: StitchColors.outlineVariant.fade(0.3)),
            const SizedBox(width: 16),
            ohlcKV('Vol', o.volumeDescription, highlight: StitchColors.primaryContainer),
            const SizedBox(width: 16),
            Text.rich(
              TextSpan(
                style: GoogleFonts.inter(fontSize: 10, color: StitchColors.onSurfaceVariant),
                children: [
                  TextSpan(text: '틱 스냅: ', style: TextStyle(letterSpacing: 0.5)),
                  TextSpan(
                    text: '${_formatKrw(o.tickSizeKrw)} KRW',
                    style: TextStyle(color: StitchColors.onSurface, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controllerPanel() {
    return ColoredBox(
      color: StitchColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: StitchColors.surfaceContainer.fade(0.3),
              border: Border(bottom: BorderSide(color: StitchColors.primaryContainer.fade(0.1))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '0624 자동감시',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _headline.copyWith(fontSize: 14, color: StitchColors.primaryContainer),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: StitchColors.primaryContainer.fade(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: StitchColors.primaryContainer.fade(0.2)),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _bundle!.autoWatch.lineSyncActive ? 'ACTIVE LINE SYNC' : 'LINE SYNC OFF',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: StitchColors.primaryContainer,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    for (var i = 0; i < _bundle!.autoWatch.phases.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: _statusTileForPhase(_bundle!.autoWatch.phases[i])),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('오토봇 분할매수', style: _label.copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
                    Text(
                      'MULTI-ENTRY DRAW',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: StitchColors.primaryContainer.fade(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _botPresetBtn('3-Bot', 0),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _botPresetBtn('5-Bot', 1),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('이익실현(TP)', style: _label.copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
                    Text(
                      '${_tpPercent.toStringAsFixed(2)}%',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: StitchColors.primaryContainer),
                    ),
                  ],
                ),
                Slider(
                  value: _tpPercent,
                  min: 0.5,
                  max: 10,
                  divisions: 95,
                  activeColor: StitchColors.primaryContainer,
                  inactiveColor: StitchColors.surfaceContainerHighest,
                  onChanged: (v) => setState(() => _tpPercent = v),
                  onChangeEnd: (_) => _persistRisk(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('손실제한(SL)', style: _label.copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
                    Text(
                      '-${_slPercent.toStringAsFixed(2)}%',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: StitchColors.error),
                    ),
                  ],
                ),
                Slider(
                  value: _slPercent,
                  min: 0.1,
                  max: 5,
                  divisions: 49,
                  activeColor: StitchColors.error,
                  inactiveColor: StitchColors.surfaceContainerHighest,
                  onChanged: (v) => setState(() => _slPercent = v),
                  onChangeEnd: (_) => _persistRisk(),
                ),
                const SizedBox(height: 8),
                Text('트레일링 스톱 (%)', style: _label.copyWith(fontSize: 10, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    TextField(
                      controller: _trailingCtrl,
                      onEditingComplete: _persistRisk,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        color: StitchColors.primaryContainer,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: StitchColors.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: StitchColors.outlineVariant.fade(0.2)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(color: StitchColors.outlineVariant.fade(0.2)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: const BorderSide(color: StitchColors.primaryContainer, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text('%', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: StitchColors.onSurfaceVariant)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Divider(color: StitchColors.outlineVariant.fade(0.1), height: 1),
                const SizedBox(height: 16),
                Text('안전장치', style: _label.copyWith(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: StitchColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: StitchColors.primaryContainer.fade(0.05)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('주문 유형', style: GoogleFonts.inter(fontSize: 12, color: StitchColors.onSurface)),
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: StitchColors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: StitchColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [BoxShadow(color: Colors.black.fade(0.2), blurRadius: 4)],
                              ),
                              child: Text(
                                'MARKET',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              child: Text(
                                'IOC',
                                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: StitchColors.onSurfaceVariant),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: StitchColors.primaryContainer.fade(0.15))),
            ),
            child: Column(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: StitchColors.primaryCtaGradient,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [BoxShadow(color: StitchColors.primaryContainer.fade(0.2), blurRadius: 16)],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showStubActionNotice('오토봇 실행 — 키움 SendOrder·감시주문 미연동'),
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            '오토봇 실행 🚀',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.3,
                              color: StitchColors.onPrimaryFixed,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: StitchColors.primaryContainer,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: StitchColors.primaryContainer.fade(0.4), blurRadius: 6)],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '키움 엔진 대기 중',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: StitchColors.onSurfaceVariant,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusTileForPhase(AutoWatchPhaseState phase) {
    final (icon, label) = switch (phase.kind) {
      AutoWatchPhaseKind.monitoring => (Icons.visibility_outlined, '감시 중'),
      AutoWatchPhaseKind.conditionMet => (Icons.check_circle_outline, '조건 도달'),
      AutoWatchPhaseKind.orderFilled => (Icons.flash_on_outlined, '체결됨'),
    };
    return _statusTile(
      icon: icon,
      label: label,
      active: phase.isActive,
      dim: !phase.isActive,
    );
  }

  Widget _statusTile({required IconData icon, required String label, bool active = false, bool dim = false}) {
    final o = dim ? 0.35 : 1.0;
    return Opacity(
      opacity: o,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: StitchColors.surfaceContainerHigh.fade(active ? 0.6 : 0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active ? StitchColors.primaryContainer : Colors.transparent,
            width: 2,
          ),
          boxShadow: active
              ? [BoxShadow(color: StitchColors.primaryContainer.fade(0.15), blurRadius: 15)]
              : null,
        ),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: active ? StitchColors.primaryContainer : StitchColors.onSurfaceVariant),
                if (active)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: StitchColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: active ? StitchColors.primaryContainer : StitchColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botPresetBtn(String label, int index) {
    final on = _botPreset == index;
    return OutlinedButton(
      onPressed: () async {
        setState(() => _botPreset = index);
        await _persistRisk();
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 8),
        backgroundColor: on ? StitchColors.surface : StitchColors.surfaceContainerLowest,
        side: BorderSide(
          color: on ? StitchColors.primaryContainer : StitchColors.outlineVariant.fade(0.3),
          width: on ? 2 : 1,
        ),
        foregroundColor: on ? StitchColors.primaryContainer : StitchColors.onSurfaceVariant,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: on ? FontWeight.w900 : FontWeight.w700)),
    );
  }
}

enum _BadgeAccent { primary, tertiary }

class _ChipData {
  const _ChipData(this.label, this.tone);
  final String label;
  final _ChipTone tone;
}

enum _ChipTone { primary, tertiary, muted, error }

class _GridDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = StitchColors.primaryContainer.fade(0.03);
    for (double x = 0; x < size.width; x += 32) {
      for (double y = 0; y < size.height; y += 32) {
        canvas.drawCircle(Offset(x, y), 1, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedHLinesPainter extends CustomPainter {
  _DashedHLinesPainter({required this.fractions, required this.opacities});

  final List<double> fractions;
  final List<double> opacities;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < fractions.length; i++) {
      final frac = fractions[i];
      final op = i < opacities.length ? opacities[i] : 1.0;
      final y = size.height * frac;
      final paint = Paint()
        ..color = StitchColors.primaryContainer.fade(op)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      const dash = 6.0;
      const gap = 4.0;
      var x = 0.0;
      while (x < size.width) {
        final end = (x + dash).clamp(0.0, size.width);
        canvas.drawLine(Offset(x, y), Offset(end, y), paint);
        x += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedHLinesPainter oldDelegate) {
    return oldDelegate.fractions != fractions || oldDelegate.opacities != opacities;
  }
}

class _VerticalDashedPainter extends CustomPainter {
  _VerticalDashedPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 6.0;
    const gap = 4.0;
    var y = 0.0;
    final x = size.width / 2;
    while (y < size.height) {
      final end = (y + dash).clamp(0.0, size.height);
      canvas.drawLine(Offset(x, y), Offset(x, end), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _VerticalDashedPainter oldDelegate) => oldDelegate.color != color;
}

class _LatencyToast extends StatelessWidget {
  const _LatencyToast({required this.telemetry});

  final SessionTelemetry telemetry;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 24,
      child: IgnorePointer(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 24),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: StitchColors.surfaceContainerHigh.fade(0.9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: StitchColors.primaryContainer.fade(0.3)),
                    boxShadow: [BoxShadow(color: Colors.black.fade(0.5), blurRadius: 24)],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.settings_input_antenna_outlined, size: 18, color: StitchColors.primaryContainer),
                        const SizedBox(width: 12),
                        Text(
                          '지연시간: ${telemetry.roundTripLatencyMs}ms',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: StitchColors.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(width: 1, height: 12, color: StitchColors.outlineVariant.fade(0.3)),
                        const SizedBox(width: 12),
                        Text(
                          'API: ${telemetry.apiLabel}',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: StitchColors.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(width: 1, height: 12, color: StitchColors.outlineVariant.fade(0.3)),
                        const SizedBox(width: 12),
                        Text(
                          telemetry.tickSnapApplied ? '틱 단위 스냅 적용' : '틱 스냅 미적용',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: StitchColors.primaryContainer,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
