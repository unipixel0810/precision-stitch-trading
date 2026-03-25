import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stitch_trader/presentation/theme/stitch_colors.dart';

/// Supabase + `run_trade_ai_report.py` 결과를 붙일 때까지 쓰는 데모 스냅샷.
/// KPI 중 2·3월 손익비는 프롬프트 시나리오(1.31 vs 0.97)와 맞춤.
class AnalyticsDemoData {
  const AnalyticsDemoData({
    required this.winRate,
    required this.profitFactor,
    required this.expectancy,
    required this.febProfitFactor,
    required this.marProfitFactor,
    required this.febTradeCount,
    required this.marTradeCount,
    required this.volumeCliffWinRate,
    required this.latencyMs,
    required this.coachingReport,
  });

  final double winRate;
  final double profitFactor;
  final double expectancy;
  final double febProfitFactor;
  final double marProfitFactor;
  final int febTradeCount;
  final int marTradeCount;
  final double volumeCliffWinRate;
  final double latencyMs;
  final String coachingReport;

  static AnalyticsDemoData stitchedSample() {
    return AnalyticsDemoData(
      winRate: 0.72,
      profitFactor: 0.95,
      expectancy: -2.15,
      febProfitFactor: 1.31,
      marProfitFactor: 0.97,
      febTradeCount: 10,
      marTradeCount: 12,
      volumeCliffWinRate: 0.62,
      latencyMs: 14,
      coachingReport: _demoCoachingMarkdown,
    );
  }
}

const String _demoCoachingMarkdown = '''
**사용자 DNA 요약 (데모 카피)**

- 사용자의 수익 DNA인 **거래량 절벽 후 지지 확인** 매매는 승률 **70% 이상**을 기록 중인 패턴으로 모델링되었습니다.
- 다만 **아모레퍼시픽(-15%)** 같은 대형 손절이 전체 수익을 갉아먹고 있으므로, **Stitch 3차 매수 후 시가 이탈 시 즉시 손절**하도록 **Kiwoom 0624** 쪽 설정을 규칙으로 강제할 필요가 있습니다.
- **지연시간 14ms**로 인한 슬리피지(**약 0.1~0.2%** 가정)를 반영해 **매수 타점을 1틱 더 낮게** 잡을 것을 권합니다.

---
*운영 데이터는 `analytics/stitch_final_launch.py` 로 동기화·리포트 생성 후 이 영역에 주입할 수 있습니다.*
''';

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
    final body = GoogleFonts.inter(fontSize: 13, height: 1.45, color: StitchColors.onSurface);
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
                  children: [
                    Icon(Icons.analytics_outlined, color: StitchColors.primaryContainer, size: 28),
                    const SizedBox(width: 12),
                    Text('성과분석 · AI 코칭', style: headline),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '엑셀 → Supabase trade_history → 지표/월별 비교 → LLM 리포트 파이프라인과 연결할 Analytics 뷰입니다.',
                  style: label,
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _kpiTile('승률', '${(d.winRate * 100).toStringAsFixed(1)}%', subtitle: '전체 표본'),
                    _kpiTile('손익비(PF)', d.profitFactor.toStringAsFixed(2), subtitle: '총익/|총손|'),
                    _kpiTile('기댓값', '${d.expectancy >= 0 ? '+' : ''}${d.expectancy.toStringAsFixed(2)}%', subtitle: '트레이드당 %'),
                    _kpiTile('절벽 패턴 후 승률(데모)', '${(d.volumeCliffWinRate * 100).round()}%', subtitle: 'is_volume_cliff 가정'),
                    _kpiTile('관측 지연', '${d.latencyMs.toStringAsFixed(0)} ms', subtitle: '슬리피지 평가 입력'),
                  ],
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
                  '2월 n=${d.febTradeCount} · PF=${d.febProfitFactor}  |  3월 n=${d.marTradeCount} · PF=${d.marProfitFactor}',
                  style: label,
                ),
                const SizedBox(height: 28),
                Text('AI 코칭 리포트', style: headline.copyWith(fontSize: 15)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: StitchColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: StitchColors.primaryContainer.fade(0.15)),
                  ),
                  child: SelectableText(d.coachingReport, style: body),
                ),
              ],
            ),
          ),
        );
      },
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
