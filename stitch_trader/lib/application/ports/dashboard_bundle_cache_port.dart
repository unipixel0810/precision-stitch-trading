import 'package:stitch_trader/application/models/dashboard_bundle.dart';

/// 마지막 성공 번들 로컬 보관 (오프라인 폴백).
abstract class DashboardBundleCachePort {
  Future<void> write(DashboardBundle bundle);

  Future<DashboardBundle?> read();
}
