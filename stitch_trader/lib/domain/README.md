# domain

순수 Dart만 사용합니다. **`package:` 외부 의존성 금지.**

- `entities/` — 엔티티·enum (`SymbolCode`, `ScannerHit`, `OhlcSnapshot`, `RiskSettings` 등)
- `repositories/` — 추상 Port: `ScannerRepository`, `ChartContextRepository`, `AutoWatchRepository`, `SessionTelemetryRepository`
- `dashboard_contracts.dart` — export 허브 (경량 import용)

문서: `docs/PHASE1_DESIGN_AUDIT.md`, `docs/PHASE1_EXPANSION_SLOTS.md`
