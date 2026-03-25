/// 실행 환경 (기본은 개발·Fake 저장소).
enum AppEnvironment {
  development,
  staging,
  production,
}

extension AppEnvironmentUi on AppEnvironment {
  /// 상단·디버그 표시용 짧은 라벨.
  String get shortLabel => switch (this) {
        AppEnvironment.development => 'DEV',
        AppEnvironment.staging => 'STG',
        AppEnvironment.production => 'PRD',
      };
}
