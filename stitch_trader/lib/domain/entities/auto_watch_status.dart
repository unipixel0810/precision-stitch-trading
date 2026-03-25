/// 0624 자동감시 타일 단계.
enum AutoWatchPhaseKind { monitoring, conditionMet, orderFilled }

final class AutoWatchPhaseState {
  const AutoWatchPhaseState({
    required this.kind,
    required this.isActive,
  });

  final AutoWatchPhaseKind kind;
  final bool isActive;
}

/// 우측 패널 상단 "Active Line Sync" 등과 연동되는 집합 상태.
final class AutoWatchStatus {
  const AutoWatchStatus({
    required this.lineSyncActive,
    required this.phases,
  });

  final bool lineSyncActive;
  final List<AutoWatchPhaseState> phases;
}
