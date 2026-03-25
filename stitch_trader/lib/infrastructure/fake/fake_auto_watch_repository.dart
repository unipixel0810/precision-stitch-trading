import 'package:stitch_trader/domain/dashboard_contracts.dart';

final class FakeAutoWatchRepository implements AutoWatchRepository {
  RiskSettings _risk = RiskSettings(
    takeProfitPercent: 3.5,
    stopLossPercentMagnitude: 1.2,
    trailingStopPercent: 0.85,
    botSplit: BotSplitPreset.three,
    orderKind: OrderKind.market,
  );

  @override
  Future<AutoWatchStatus> getStatus() async {
    return AutoWatchStatus(
      lineSyncActive: true,
      phases: const [
        AutoWatchPhaseState(kind: AutoWatchPhaseKind.monitoring, isActive: true),
        AutoWatchPhaseState(kind: AutoWatchPhaseKind.conditionMet, isActive: false),
        AutoWatchPhaseState(kind: AutoWatchPhaseKind.orderFilled, isActive: false),
      ],
    );
  }

  @override
  Future<RiskSettings> getRiskSettings() async => _risk;

  @override
  Future<void> saveRiskSettings(RiskSettings settings) async {
    _risk = settings;
  }
}
