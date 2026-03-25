# Phase 2–6 — Application · Presentation · Infra 스텁 · DI · QA

이 문서는 `rule.md`의 P2~P6에 대응하는 **현재 코드 스냅샷**을 한 곳에 묶는다.

## Phase 2 — Application

- `lib/application/models/dashboard_bundle.dart` — 대시보드 읽기 스냅샷.
- `lib/application/use_cases/load_dashboard_bundle.dart` — 포트 조합으로 번들 로드.
- `lib/application/use_cases/update_risk_settings.dart` — 리스크 설정 저장.

## Phase 3 — Presentation + Fake backend

- `lib/presentation/pages/precision_dashboard_page.dart` — Precision Dashboard (스캐너 / 차트 / 0624 패널 / 텔레메트리 토스트).
- `lib/infrastructure/fake/*` — 개발용 Fake 구현체.
- 진입 조립: `lib/main.dart` → `DashboardRepositoryFactory.create(development)` → `DashboardModule.fromRepositories`.

## Phase 4 — Infrastructure (실연동 자리)

- `lib/infrastructure/remote/*` — `UnimplementedError` 스텁. `AppEnvironment.staging|production`에서 주입.

## Phase 5 — DI · 환경

- `lib/app/app_environment.dart` — dev / staging / production.
- `lib/app/dashboard_repository_factory.dart` — 환경별 저장소 세트.
- `lib/app/dashboard_module.dart` — 유스케이스 묶음.
- `lib/app/dashboard_repositories.dart` — Port 홀더.

## Phase 6 — QA

- 스모크: `test/widget_test.dart` — `StitchTraderApp` + `AutoTrader` 헤더.
- 릴리즈 전: `flutter analyze`, `flutter test`, 수동 3패널 회귀.

## Legacy 제거

- 이전 화면: ~~`lib/screens/precision_dashboard_screen.dart`~~ → `presentation/pages/precision_dashboard_page.dart`.
- 이전 테마: ~~`lib/theme/stitch_colors.dart`~~ → `presentation/theme/stitch_colors.dart`.
