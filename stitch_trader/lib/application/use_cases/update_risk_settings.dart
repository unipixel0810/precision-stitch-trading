import 'package:stitch_trader/domain/dashboard_contracts.dart';

final class UpdateRiskSettings {
  UpdateRiskSettings(this._repository);

  final AutoWatchRepository _repository;

  Future<void> call(RiskSettings settings) => _repository.saveRiskSettings(settings);
}
