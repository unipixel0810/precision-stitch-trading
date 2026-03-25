import 'package:stitch_trader/domain/dashboard_contracts.dart';

final class RemoteSessionTelemetryRepository implements SessionTelemetryRepository {
  const RemoteSessionTelemetryRepository();

  @override
  Future<SessionTelemetry> getTelemetry() async {
    throw UnimplementedError('RemoteSessionTelemetryRepository.getTelemetry');
  }
}
