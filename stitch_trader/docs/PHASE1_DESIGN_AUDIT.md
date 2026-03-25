# Phase 1 — UI 디자인 감사 (`design.md` vs Flutter)

**기준:** 루트 `design.md` (Precision Stitch)  
**대상:** `lib/screens/precision_dashboard_screen.dart`, `lib/theme/stitch_colors.dart`

| # | design.md 규칙 | 현재 Flutter | 갭 | 제안 (Phase 3 프론트) |
|---|----------------|--------------|-----|------------------------|
| 1 | **No-Line:** 섹션 구분에 1px 실선 금지, 배경 톤으로 구분 | 헤더·패널·툴바에 `Border` + 반투명 시안 사용 다수 | 중 | 실선 제거 또는 `surface-*` 단계만으로 구역 분리 |
| 2 | **Surface 계층** surface / -low / -high | `StitchColors`와 대체로 정합 | 소 | 일부 하드코 `#131313`, `#0D0D0D` → 토큰 통일 |
| 3 | **Glass:** `surface-variant` 60% + **20px** blur | `BackdropFilter` **sigma 12** (`glass-panel` 등) | 중 | sigma를 design에 맞게 상향(≈20px 느낌) |
| 4 | **Primary CTA:** 135° `primary`→`primary-container` 그라데이션 | 하단 오토봇 버튼은 그라데이션, **Live Trading** 등은 단색 | 중 | 동일 메인 액션에 그라데이션 정책 통일 |
| 5 | **Typography:** Manrope 디스플레이 / Inter 라벨, `label-sm` 0.6875рем | `google_fonts` 사용, 픽셀 혼재(9~13px) | 소 | `presentation/theme/typography.dart`로 스케일 상수화 |
| 6 | **입력 포커스:** 하단 2px 스티치 + primary 5% 틴트 | 커스텀 `InputDecoration` 일부만 유사 | 소 | `design.md` §5 Input과 동일 스펙 적용 |
| 7 | **Ambiente shadow:** 0,12 / blur 32 / rgba 0,0,0,0.45 | 일부 `shadow`·glow가 더 짧고 진함 | 소 | 플로팅 토스트·모달에 스펙 통일 |
| 8 | **Stitch 포커스:** 좌/상단 dashed primary 30% | VI 카드는 좌 스트립으로 반영됨, 포커스 링 전역은 미흡 | 소 | 포커스 가능 위젯에 통일 accent |
| 9 | **의도적 비대칭** 모듈 스택 | 3단 고정 폭(320·flex·320) 대칭 레이아웃 | 중 | 중앙 차트/플로팅 카드 오프셋 등 점진 적용 |
| 10 | **순백(#FFF) 금지** | 대체로 `on-surface` 계열 | — | 주기적 grep `#FFF` |

**합의:** P1에서는 표만 확정. **P3 설계 단계**에서 우선순위(① 토큰/타이포 → ② No-Line → ③ Glass·그라데이션)로 반영.
