/// 차트 위 오버레이 라인 종류.
enum ChartPriceLineKind {
  primaryBuy,
  autoTier2,
  autoTier3,
  sellTarget,
}

final class ChartPriceLine {
  const ChartPriceLine({
    required this.kind,
    required this.priceKrw,
    this.subtitle,
  });

  final ChartPriceLineKind kind;
  final int priceKrw;
  /// 예: "(-1.0%)"
  final String? subtitle;
}
