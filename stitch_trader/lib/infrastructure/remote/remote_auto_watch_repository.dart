import 'package:stitch_trader/domain/dashboard_contracts.dart';

final class RemoteAutoWatchRepository implements AutoWatchRepository {
  const RemoteAutoWatchRepository();

  @override
  Future<AutoWatchStatus> getStatus() async {
    throw UnimplementedError('RemoteAutoWatchRepository.getStatus');
  }

  @override
  Future<RiskSettings> getRiskSettings() async {
    throw UnimplementedError('RemoteAutoWatchRepository.getRiskSettings');
  }

  @override
  Future<void> saveRiskSettings(RiskSettings settings) async {
    throw UnimplementedError('RemoteAutoWatchRepository.saveRiskSettings');
  }
}
