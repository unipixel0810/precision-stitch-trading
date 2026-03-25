import '../entities/auto_watch_status.dart';
import '../entities/risk_settings.dart';

/// 0624 자동감시 상태·리스크 설정.
abstract class AutoWatchRepository {
  Future<AutoWatchStatus> getStatus();

  Future<RiskSettings> getRiskSettings();

  Future<void> saveRiskSettings(RiskSettings settings);
}
