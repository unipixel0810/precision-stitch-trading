/// `--dart-define=CACHE_TTL_HOURS=48` (기본 24, 범위 1–168시간).
Duration dashboardCacheMaxAgeFromEnvironment() {
  const raw = String.fromEnvironment('CACHE_TTL_HOURS', defaultValue: '24');
  final h = int.tryParse(raw.trim()) ?? 24;
  return Duration(hours: h.clamp(1, 168));
}
