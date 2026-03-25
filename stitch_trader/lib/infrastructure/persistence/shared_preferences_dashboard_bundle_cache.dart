import 'package:shared_preferences/shared_preferences.dart';
import 'package:stitch_trader/application/dashboard_bundle_codec.dart';
import 'package:stitch_trader/application/models/dashboard_bundle.dart';
import 'package:stitch_trader/application/ports/dashboard_bundle_cache_port.dart';

final class SharedPreferencesDashboardBundleCache implements DashboardBundleCachePort {
  SharedPreferencesDashboardBundleCache(
    this._prefs, {
    Duration? maxAge,
  }) : _maxAge = maxAge ?? const Duration(hours: 24);

  final SharedPreferences _prefs;
  final Duration _maxAge;

  static const _key = 'dashboard_bundle_cache_v1';

  @override
  Future<void> write(DashboardBundle bundle) async {
    final raw = DashboardBundleCodec.encodeForPersist(bundle.copyWith(servedFromCache: false));
    await _prefs.setString(_key, raw);
  }

  @override
  Future<DashboardBundle?> read() async {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final (bundle, at) = DashboardBundleCodec.decodePersisted(raw, servedFromCache: true);
      if (at == null) {
        await _prefs.remove(_key);
        return null;
      }
      final ageMs = DateTime.now().millisecondsSinceEpoch - at;
      if (ageMs > _maxAge.inMilliseconds) {
        await _prefs.remove(_key);
        return null;
      }
      return bundle;
    } on FormatException {
      await _prefs.remove(_key);
      return null;
    }
  }
}
