/// 하단 컨텍스트 바 등 시스템 메타.
final class SessionTelemetry {
  SessionTelemetry({
    required this.roundTripLatencyMs,
    required this.apiLabel,
    required this.tickSnapApplied,
  });

  final int roundTripLatencyMs;
  final String apiLabel;
  final bool tickSnapApplied;
}
