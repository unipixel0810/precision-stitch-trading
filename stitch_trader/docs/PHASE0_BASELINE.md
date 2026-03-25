# Phase 0 Baseline — StitchTrader (`stitch_trader`)

**완료 기준:** 설계·프론트·백엔드·QA 순 산출물이 아래에 채워짐.  
**규칙:** 상위 `rule.md` — Clean Architecture + Phase 작업 순서(설계→프론트→백엔드→QA).

---

## 1. 설계 (Design)

### 1.1 리팩터 범위

- **포함:** Flutter 앱 디렉터리 `stitch_trader/` (Clean Architecture 재편, Precision Dashboard 유지).
- **제외(현 단계):** 루트 정적 `index.html` / `css/` (별 트랙). 연동 필요 시 별도 Phase에서 명시.

### 1.2 목표 `lib/` 트리 (P1~ 이행)

```
lib/
  main.dart                 # 진입점·환경(`APP_ENV`)·저장소 팩토리·DashboardModule 주입
  app/                      # AppEnvironment, DashboardModule, RepositoryFactory (composition)
  domain/                   # 순수 Dart, 외부 package import 금지
  application/              # 유스케이스, domain만 의존
  infrastructure/           # Port 구현(Fake / Remote 스텁)
  presentation/             # pages, widgets, theme (`pages/precision_dashboard_page.dart` 등)
```

### 1.3 DI(의존성 주입) 합의

- **Phase 0~2:** 새 DI 패키지 추가 없음. 유스케이스는 추후 `main` 또는 전용 `composition_root`에서 수동 주입 가능.
- **Phase 3 권장:** `flutter_riverpod` 또는 `provider` 도입해 `presentation → application` 경계를 한곳에서 조립. (최종 선택은 Phase 3 설계 단계에서 확정.)
- **원칙:** `presentation`이 `infrastructure` 구현체를 직접 `new` 하지 않음.

### 1.4 브랜치

- 권장 브랜치명: `refactor/phase0-baseline` (또는 동일 내용의 커밋 시퀀스).

---

## 2. 프론트 (Frontend) — 문서만

| 항목 | 위치 (이행 완료) |
|------|------------------|
| 홈 화면 | `lib/presentation/pages/precision_dashboard_page.dart` |
| 색·타이포 토큰 | `lib/presentation/theme/stitch_colors.dart` (`Color.fade` 확장 포함) |
| 앱 셸 | `lib/main.dart` → `StitchTraderApp`, 환경별 `DashboardRepositoryFactory` |

---

## 3. 백엔드 (Backend) — backlog만

다음은 **인프라**에서 다룰 예정 연동(우선순위 미정, 계약은 Phase 4 설계):

- 키움 OpenAPI / 브리지(0624 등) — 주문·잔고·시세
- 사내 또는 서드파티 REST/WebSocket — 감시·스캐너 소스
- 로컬 설정/캐시 — `shared_preferences` 등 (도메인 노출 금지, 매퍼만)

---

## 4. QA (품질 기준선)

| 항목 | 결과 (기록 시점) |
|------|------------------|
| `flutter analyze` | **No issues found** (대시보드·테마 `withOpacity` → `Color.fade`/`withValues` 정리). |
| `flutter test` | 스모크 1건 + `test/application/use_cases_test.dart` (Load/Update 유스케이스). |
| Clean import | P1 완료 후 `domain/` 에 `package:` 금지 자동 검증 도입 권장. |

---

## 5. Phase 1 착수 전 체크리스트

- [x] `lib/domain`, `application`, `infrastructure`, `presentation` 폴더 및 README 존재
- [x] 본 문서와 `rule.md` Phase 0 정렬
- [x] Phase 1: 엔티티·Port·디자인 감사표·확장 슬롯 (`docs/PHASE1_*.md`, `lib/domain/`)
