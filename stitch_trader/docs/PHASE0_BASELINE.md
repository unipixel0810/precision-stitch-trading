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
  main.dart                 # 진입점·MaterialApp·테마(최소) — Phase 3 이후 조립만 증가
  domain/                   # 순수 Dart, 외부 package import 금지
  application/              # 유스케이스, domain만 의존
  infrastructure/           # Port 구현, API/DB/키움 등
  presentation/             # pages, widgets, theme (목표 위치)
  screens/                  # 레거시 — Phase 3에서 presentation으로 이전 후 제거
  theme/                    # 레거시 — Phase 3에서 presentation/theme 으로 이전
```

### 1.3 DI(의존성 주입) 합의

- **Phase 0~2:** 새 DI 패키지 추가 없음. 유스케이스는 추후 `main` 또는 전용 `composition_root`에서 수동 주입 가능.
- **Phase 3 권장:** `flutter_riverpod` 또는 `provider` 도입해 `presentation → application` 경계를 한곳에서 조립. (최종 선택은 Phase 3 설계 단계에서 확정.)
- **원칙:** `presentation`이 `infrastructure` 구현체를 직접 `new` 하지 않음.

### 1.4 브랜치

- 권장 브랜치명: `refactor/phase0-baseline` (또는 동일 내용의 커밋 시퀀스).

---

## 2. 프론트 (Frontend) — 문서만

| 항목 | 현재 (P0) | 목표 (P3~) |
|------|-----------|------------|
| 홈 화면 | `lib/screens/precision_dashboard_screen.dart` | `lib/presentation/pages/…` |
| 색·타이포 토큰 | `lib/theme/stitch_colors.dart` | `lib/presentation/theme/…` |
| 앱 셸 | `lib/main.dart` 내 `StitchTraderApp` | 동일 파일 또는 `lib/presentation/app.dart` 분리 |

P0에서는 **파일 이동 없음**. 위 표만 계약으로 삼는다.

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
| `flutter analyze` | **0 errors / 0 warnings** — info 레벨: `withOpacity` deprecated 등 약 67건 (`precision_dashboard_screen.dart` 중심). Phase 3 이후 점진 정리. |
| `flutter test` | 스모크 1건 통과(대시보드 제목). |
| Clean import | P1 완료 후 `domain/` 에 `package:` 금지 자동 검증 도입 권장. |

---

## 5. Phase 1 착수 전 체크리스트

- [x] `lib/domain`, `application`, `infrastructure`, `presentation` 폴더 및 README 존재
- [x] 본 문서와 `rule.md` Phase 0 정렬
- [ ] Phase 1: 엔티티·Port·디자인 감사표 작성
