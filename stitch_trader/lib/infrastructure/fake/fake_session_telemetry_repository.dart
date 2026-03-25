import 'package:stitch_trader/domain/dashboard_contracts.dart';

final class FakeSessionTelemetryRepository implements SessionTelemetryRepository {
  const FakeSessionTelemetryRepository();

  @override
  Future<SessionTelemetry> getTelemetry() async {
    return SessionTelemetry(
      roundTripLatencyMs: 14,
      apiLabel: 'OPEN-0624-V4',
      tickSnapApplied: true,
    );
  }
}
