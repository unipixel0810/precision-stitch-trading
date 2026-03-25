import 'symbol_code.dart';

/// 차트 하단·범례용 직전(또는 당일) OHLC 스냅샷.
final class OhlcSnapshot {
  OhlcSnapshot({
    required this.symbol,
    required this.openKrw,
    required this.highKrw,
    required this.lowKrw,
    required this.closeKrw,
    required this.volumeDescription,
    required this.tickSizeKrw,
  });

  final SymbolCode symbol;
  final int openKrw;
  final int highKrw;
  final int lowKrw;
  final int closeKrw;
  /// "1.2조" 등 사람이 읽기 좋은 문자열 (infra에서 포맷해도 됨).
  final String volumeDescription;
  final int tickSizeKrw;
}
