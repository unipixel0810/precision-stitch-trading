import '../entities/session_telemetry.dart';

abstract class SessionTelemetryRepository {
  Future<SessionTelemetry> getTelemetry();
}
