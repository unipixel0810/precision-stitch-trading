/// 주문 유형 (안전장치 토글).
enum OrderKind { market, ioc }

/// 분할매수 봇 프리셋.
enum BotSplitPreset { three, five }

/// 우측 패널 리스크·분할 설정.
final class RiskSettings {
  const RiskSettings({
    required this.takeProfitPercent,
    required this.stopLossPercentMagnitude,
    required this.trailingStopPercent,
    required this.botSplit,
    required this.orderKind,
  });

  /// 이익실현 % (양수).
  final double takeProfitPercent;
  /// 손실제한 절대값 % (양수로 저장, UI에서 음수로 표시).
  final double stopLossPercentMagnitude;
  final double trailingStopPercent;
  final BotSplitPreset botSplit;
  final OrderKind orderKind;
}
