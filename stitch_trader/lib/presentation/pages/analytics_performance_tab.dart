import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stitch_trader/presentation/theme/stitch_colors.dart';

/// image_6 / 엑셀 파이프라인이 반영될 **최종 리포트 형태** 샘플 (실시간 연동 시 API·상태로 치환).
abstract final class StitchMarch2026SampleReport {
  static const title = 'Stitch AI Strategy Review: March 2026';

  static const dnaTitle = '수익 DNA 검증';
  static const dnaBody =
      '패턴: 거래량 절벽(Volume Cliff) 확인 후 진입한 매매(예: 한라캐스트, OCI홀딩스)의 승률은 78%로 매우 높음. '
      '세력의 잔류를 확인하는 사용자님의 직관이 시스템의 핵심 수익원임.';

  static const riskTitle = '리스크 경고 (Critical)';
  static const riskIssue = '이슈: 3월 들어 손익비가 1.31 → 0.97로 급격히 하락함.';
  static const riskCause =
      "원인: 아모레퍼시픽(-15.37%), 가온전선(-14.78%) 등에서 발생한 '희망 회로'에 의한 손절 지연.";
  static const riskRx =
      '처방: Stitch 3차 매수 이후 기준봉 시가(Final Line)를 이탈할 경우, 14ms 내에 즉시 '
      '0624 자동감시 주문이 시장가로 집행되도록 로직을 강제함.';

  static const latencyTitle = '지연 시간 최적화';
  static const latencyBody =
      '현재 지연시간 14ms를 고려할 때, 호가창이 얇은 종목은 체결 오차가 발생함. '
      'AI가 앞으로 매수선은 1틱 낮게, 매도선은 1틱 높게 자동 보정하여 작도할 예정임.';
}

/// Supabase + 리포트 파이프라인과 맞출 KPI 스냅샷.
class AnalyticsDemoData {
  const AnalyticsDemoData({
    required this.winRate,
    required this.profitFactor,
    required this.expectancy,
    required this.febProfitFactor,
    required this.marProfitFactor,
    required this.febTradeCount,
    required this.marTradeCount,
    required this.volumeCliffPatternWinRate,
    required this.latencyMs,
  });

  final double winRate;
  final double profitFactor;
  final double expectancy;
  final double febProfitFactor;
  final double marProfitFactor;
  final int febTradeCount;
  final int marTradeCount;
  final double volumeCliffPatternWinRate;
  final double latencyMs;

  static AnalyticsDemoData stitchedSample() {
    return AnalyticsDemoData(
      winRate: 0.78,
      profitFactor: 0.95,
      expectancy: -2.15,
      febProfitFactor: 1.31,
      marProfitFactor: 0.97,
      febTradeCount: 10,
      marTradeCount: 12,
      volumeCliffPatternWinRate: 0.78,
      latencyMs: 14,
    );
  }
}

class AnalyticsPerformanceTab extends StatelessWidget {
  const AnalyticsPerformanceTab({super.key, this.data});

  final AnalyticsDemoData? data;

  @override
  Widget build(BuildContext context) {
    final d = data ?? AnalyticsDemoData.stitchedSample();
    final headline = GoogleFonts.manrope(
      fontSize: 18,
      fontWeight: FontWeight.w800,
      color: StitchColors.primaryContainer,
    );
    final body = GoogleFonts.inter(fontSize: 13, height: 1.5, color: StitchColors.onSurface);
    final label = GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurfaceVariant);

    return LayoutBuilder(
      builder: (context, c) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: c.maxWidth, maxWidth: 960),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.insights_outlined, color: StitchColors.primaryContainer, size: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(StitchMarch2026SampleReport.title, style: headline.copyWith(fontSize: 20)),
                          const SizedBox(height: 6),
                          Text(
                            'Analytics 탭 실시간 표시용 · 엑셀→Supabase→지표 파이프라인과 연결 시 본문 자동 갱신',
                            style: label,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _kpiTile('전체 승률(샘플)', '${(d.winRate * 100).toStringAsFixed(0)}%', subtitle: '익절/전체'),
                    _kpiTile('절벽 패턴 승률', '${(d.volumeCliffPatternWinRate * 100).toStringAsFixed(0)}%', subtitle: 'Volume Cliff 진입'),
                    _kpiTile('손익비(PF)', d.profitFactor.toStringAsFixed(2), subtitle: '집계 표본'),
                    _kpiTile('기댓값', '${d.expectancy >= 0 ? '+' : ''}${d.expectancy.toStringAsFixed(2)}%', subtitle: '트레이드당 %'),
                    _kpiTile('관측 지연', '${d.latencyMs.toStringAsFixed(0)} ms', subtitle: '0624·틱 보정 입력'),
                  ],
                ),
                const SizedBox(height: 24),
                _reportCard(
                  title: StitchMarch2026SampleReport.dnaTitle,
                  child: SelectableText(StitchMarch2026SampleReport.dnaBody, style: body),
                  borderColor: StitchColors.primaryContainer.fade(0.35),
                ),
                const SizedBox(height: 14),
                _reportCard(
                  title: StitchMarch2026SampleReport.riskTitle,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SelectableText(StitchMarch2026SampleReport.riskIssue, style: body),
                      const SizedBox(height: 10),
                      SelectableText(StitchMarch2026SampleReport.riskCause, style: body),
                      const SizedBox(height: 10),
                      SelectableText(StitchMarch2026SampleReport.riskRx, style: body),
                    ],
                  ),
                  borderColor: StitchColors.error.fade(0.45),
                  titleColor: StitchColors.error,
                ),
                const SizedBox(height: 14),
                _reportCard(
                  title: StitchMarch2026SampleReport.latencyTitle,
                  child: SelectableText(StitchMarch2026SampleReport.latencyBody, style: body),
                  borderColor: StitchColors.tertiaryContainer.fade(0.4),
                ),
                const SizedBox(height: 28),
                Text('2월 vs 3월 손익비', style: headline.copyWith(fontSize: 15)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 220,
                  child: _PfBarChart(feb: d.febProfitFactor, mar: d.marProfitFactor),
                ),
                const SizedBox(height: 8),
                Text(
                  '2월 PF=${d.febProfitFactor} (n=${d.febTradeCount})  →  3월 PF=${d.marProfitFactor} (n=${d.marTradeCount})',
                  style: label,
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: StitchColors.surfaceContainer.fade(0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '운영: stitch_final_launch.py · Windows: build_windows_engine.bat · 체크리스트: docs/WINDOWS_VPS_FINAL_CHECKLIST.md',
                    style: GoogleFonts.inter(fontSize: 10, color: StitchColors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _reportCard({
    required String title,
    required Widget child,
    required Color borderColor,
    Color? titleColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StitchColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: titleColor ?? StitchColors.primaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _kpiTile(String title, String value, {required String subtitle}) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StitchColors.surfaceContainer.fade(0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: StitchColors.outlineVariant.fade(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: StitchColors.onSurfaceVariant)),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.manrope(fontSize: 20, fontWeight: FontWeight.w800, color: StitchColors.onSurface)),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 10, color: StitchColors.onSurfaceVariant.fade(0.9))),
        ],
      ),
    );
  }
}

class _PfBarChart extends StatelessWidget {
  const _PfBarChart({required this.feb, required this.mar});

  final double feb;
  final double mar;

  @override
  Widget build(BuildContext context) {
    final hi = (feb > mar ? feb : mar) * 1.25;
    final maxY = hi.clamp(0.5, 3.0);
    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 0.25),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, m) => Text(
                v.toStringAsFixed(2),
                style: GoogleFonts.inter(fontSize: 10, color: StitchColors.onSurfaceVariant),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, m) {
                final i = v.toInt();
                if (i == 0) return Text('2월', style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurface));
                if (i == 1) return Text('3월', style: GoogleFonts.inter(fontSize: 11, color: StitchColors.onSurface));
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: feb,
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                color: StitchColors.primaryContainer,
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: mar,
                width: 28,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                color: StitchColors.tertiaryContainer,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
