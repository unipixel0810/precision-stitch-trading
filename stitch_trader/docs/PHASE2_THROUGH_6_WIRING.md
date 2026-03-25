# Phase 2–6 — Application · Presentation · Infra 스텁 · DI · QA

이 문서는 `rule.md`의 P2~P6에 대응하는 **현재 코드 스냅샷**을 한 곳에 묶는다.

## Phase 2 — Application

- `lib/application/models/dashboard_bundle.dart` — 대시보드 읽기 스냅샷.
- `lib/application/use_cases/load_dashboard_bundle.dart` — 포트 조합으로 번들 로드(독립 호출 **병렬** `Future.wait`).
- `lib/application/use_cases/update_risk_settings.dart` — 리스크 설정 저장.

## Phase 3 — Presentation + Fake backend

- `lib/presentation/pages/precision_dashboard_page.dart` — Precision Dashboard (스캐너 / 차트 / 0624 패널 / 텔레메트리 토스트).
- `lib/infrastructure/fake/*` — 개발용 Fake 구현체.
- 진입 조립: `lib/main.dart` → `DashboardRepositoryFactory.create(development)` → `DashboardModule.fromRepositories`.

## Phase 4 — Infrastructure (HTTP 계약)

- `lib/infrastructure/api/*` — `ApiConfig`(`API_BASE_URL`, `API_KEY`), `DashboardHttpClient` + `HttpRetryPolicy`, JSON 매퍼·예외.
- `lib/infrastructure/remote/*` — 위 클라이언트로 REST 호출. 계약: `docs/PHASE4_HTTP_CONTRACT.md`.
- 스테이징/프로덕션: **`--dart-define=API_BASE_URL=https://...`** 필수(미설정 시 `ApiNotConfiguredException`).

## Phase 5 — DI · 환경

- `lib/app/app_environment.dart` — dev / staging / production (`shortLabel`: DEV/STG/PRD).
- `lib/app/dashboard_repository_factory.dart` — 환경별 저장소 세트.
- `lib/app/dashboard_module.dart` — 유스케이스 묶음.
- `lib/app/dashboard_repositories.dart` — Port 홀더.

### 실행 환경 전환 (`APP_ENV`)

`main.dart`에서 `--dart-define=APP_ENV=staging` 또는 `production` 으로 주입한다. 미지정 시 `development`(Fake 저장소).

- **staging / production:** 백엔드가 `PHASE4_HTTP_CONTRACT.md` 미준수·네트워크 실패 시 **전면 오류 + 다시 시도**; 부분 새로고침·저장 실패는 **SnackBar**.

## Phase 6 — QA

- 스모크: `test/widget_test.dart` — `StitchTraderApp` + `AutoTrader` 헤더.
- Application: `test/application/use_cases_test.dart` — `LoadDashboardBundle`, `UpdateRiskSettings` (Fake Port).
- Infra: `test/infrastructure/dashboard_json_mapper_test.dart` — REST JSON 매핑.
- Infra: `test/infrastructure/http_retry_policy_test.dart` — 503 재시도·404 비재시도.
- 릴리즈 전: `flutter analyze`, `flutter test`, 수동 3패널 회귀.

## Legacy 제거

- 이전 화면: ~~`lib/screens/precision_dashboard_screen.dart`~~ → `presentation/pages/precision_dashboard_page.dart`.
- 이전 테마: ~~`lib/theme/stitch_colors.dart`~~ → `presentation/theme/stitch_colors.dart`.
