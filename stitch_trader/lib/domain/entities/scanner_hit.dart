import 'instrument.dart';

/// 스캐너 배지 톤 (UI 색 분기용, presentation에서 매핑).
enum ScannerBadgeTone { primary, tertiary }

/// 스캐너 카드 보조 태그 (테마주, KOSPI 등).
final class ScannerChip {
  const ScannerChip({required this.label, required this.emphasis});

  final String label;
  /// true면 경고·강조(High Vol 등) 계열로 그릴 수 있음.
  final bool emphasis;
}

/// 스캐너 한 줄(카드) 도메인 표현.
final class ScannerHit {
  ScannerHit({
    required this.instrument,
    required this.badgeLabel,
    required this.badgeTone,
    required this.changePercent,
    required this.lastPriceKrw,
    required this.chips,
    required this.thumbnailUri,
    this.viHighlighted = false,
  });

  final Instrument instrument;
  final String badgeLabel;
  final ScannerBadgeTone badgeTone;
  /// 퍼센트 포인트 (예: +12.4 → 12.4).
  final double changePercent;
  final int lastPriceKrw;
  final List<ScannerChip> chips;
  /// 썸네일 위치 (http(s) URL 문자열). 표현 계층에서만 네트워크 로드.
  final String thumbnailUri;
  final bool viHighlighted;
}
