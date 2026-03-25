# Phase 1 — 확장 슬롯 (backlog 체크)

`rule.md` UI 원칙에 따른 **추가 가능 영역**. 적용 시 해당 Phase **설계**에서 domain Port·엔티티·유스케이스를 보강한다.

| 슬롯 | 설명 | Domain/Port 영향 (예시) | 우선순위 (팀 편집) |
|------|------|-------------------------|---------------------|
| ☐ | 설정 패널 (모달/시트) | `SettingsRepository`, 알림·테마 플래그 엔티티 | |
| ☐ | 스캐너 필터·정렬·저장 프리셋 | `ScannerRepository` 쿼리 파라미터, `ScannerFilter` VO | |
| ☐ | 알림·토스트 스트림 (체결·오류) | `NotificationStream` Port 또는 `WatchEvent` 엔티티 | |
| ☐ | 다계정·모의/실전 스위처 | `TradingSessionContext`, `EnvironmentRepository` | |
| ☐ | 주문 확인 다이얼로그·2FA | `OrderDraft`, `ConfirmOrder` 유스케이스 (P2) | |
| ☐ | 차트 도구 프로필 저장 | `ChartToolProfile` 엔티티, `ChartContextRepository` 확장 | |
| ☐ | 키움 장애·지연 Degraded UI 상태 | `SessionTelemetry` 확장, `HealthRepository` | |

**체크된 항목**은 다음 Phase 계획에 반드시 기입할 것.
