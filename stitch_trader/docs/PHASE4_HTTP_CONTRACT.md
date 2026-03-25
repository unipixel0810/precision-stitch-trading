# Phase 4 — HTTP 계약 (Dashboard Remote)

백엔드가 이 문서의 **경로·JSON 형태**를 맞추면 `AppEnvironment.staging|production` + `--dart-define=API_BASE_URL=...` 로 앱이 실데이터를 탑재할 수 있다.

## 공통

- **Base URL:** `--dart-define=API_BASE_URL=https://your-host` (필수). path prefix 포함 가능 (예: `https://host/api`).
- **인증(선택):** `--dart-define=API_KEY=...` → `Authorization: Bearer …` 헤더.
- **Content-Type:** 요청 본문 JSON은 `application/json; charset=utf-8`.
- **응답:** 성공 시 `2xx` + JSON 본문. 오류 시 UI에 상태코드·본문 일부가 표시될 수 있음.

### 클라이언트 동작 (앱 측)

- **병렬 로드:** `LoadDashboardBundle` 유스케이스가 스캐너·차트·자동감시·텔레메트리 Port 호출을 `Future.wait`로 묶어 **왕복 지연을 줄임**(단, 한 Port라도 실패하면 전체 실패).
- **재시도:** `DashboardHttpClient`는 `HttpRetryPolicy`로 **최대 3회**(첫 시도 포함)까지 재시도한다.
  - 재시도 대상: `TimeoutException`, `SocketException`, `ClientException`, HTTP **408 / 429 / 5xx**.
  - **4xx**(위에 해당하지 않는 경우)는 재시도하지 않는다.
  - backoff: 250ms 시작 지수 증가(×2).
- **오프라인 캐시:** 마지막으로 **성공한** 번들을 `shared_preferences`에 JSON 저장한다. 이후 전체 로드가 실패하면 캐시를 읽어 화면에 표시(`servedFromCache`)하고 상단에 오프라인 배너를 띄운다.
- **연결 진단:** 앱 구성이 허용하면 오류 화면에서 `GET /v1/health` 를 호출해 결과를 대화상자로 보여 준다.

### `GET /v1/health`

`2xx` + JSON 본문(빈 객체도 가능). 예:

```json
{ "status": "ok" }
```

본문 형식은 자유. 클라이언트는 상태 코드만으로 성공을 판단한다.

## 엔드포인트

### `GET /v1/scanner/hits`

```json
{
  "hits": [
    {
      "symbol": "005380",
      "displayName": "현대차",
      "badgeLabel": "VI 포착",
      "badgeTone": "primary",
      "changePercent": 15.1,
      "lastPriceKrw": 212000,
      "chips": [{ "label": "HIGH VOL", "tone": "error" }],
      "thumbnailUri": "https://…",
      "viHighlighted": true
    }
  ]
}
```

- `badgeTone`: `primary` | `tertiary`
- `chips[].tone`: `primary` | `tertiary` | `muted` | `error`

### `GET /v1/symbols/{symbol}/ohlc`

`{symbol}` 는 URL 인코딩된 종목코드 (예: `005380`).

```json
{
  "openKrw": 210500,
  "highKrw": 214000,
  "lowKrw": 209000,
  "closeKrw": 212000,
  "volumeDescription": "1.2조",
  "tickSizeKrw": 100
}
```

### `GET /v1/symbols/{symbol}/price-lines`

```json
{
  "lines": [
    { "kind": "primaryBuy", "priceKrw": 210500 },
    { "kind": "autoTier2", "priceKrw": 208400, "subtitle": "(-1.0%)" },
    { "kind": "autoTier3", "priceKrw": 206300, "subtitle": "(-2.0%)" },
    { "kind": "sellTarget", "priceKrw": 218000 }
  ]
}
```

- `kind`: `primaryBuy` | `autoTier2` | `autoTier3` | `sellTarget`

### `GET /v1/symbols/{symbol}/chart-background`

```json
{ "url": "https://…/chart.png" }
```

`url` 이 없거나 빈 문자열이면 앱은 로컬/플레이스홀더 폴백을 쓸 수 있음.

### `GET /v1/autowatch/status`

```json
{
  "lineSyncActive": true,
  "phases": [
    { "kind": "monitoring", "isActive": true },
    { "kind": "conditionMet", "isActive": false },
    { "kind": "orderFilled", "isActive": false }
  ]
}
```

### `GET /v1/autowatch/risk` / `PUT /v1/autowatch/risk`

**GET 응답** 및 **PUT 요청 본문** 동일 형태:

```json
{
  "takeProfitPercent": 3.5,
  "stopLossPercentMagnitude": 1.2,
  "trailingStopPercent": 0.85,
  "botSplit": "three",
  "orderKind": "market"
}
```

- `botSplit`: `three` | `five`
- `orderKind`: `market` | `ioc`

### `GET /v1/session/telemetry`

```json
{
  "roundTripLatencyMs": 14,
  "apiLabel": "OPEN-0624-V4",
  "tickSnapApplied": true
}
```

## 구현 참조

- HTTP: `lib/infrastructure/api/dashboard_http_client.dart`
- 재시도: `lib/infrastructure/api/http_retry_policy.dart`
- 매핑: `lib/infrastructure/api/dashboard_json_mapper.dart`
- 예외: `lib/infrastructure/api/api_exceptions.dart`
- 번들 조립: `lib/application/use_cases/load_dashboard_bundle.dart` (병렬 `Future.wait`, 캐시 폴백).
- 캐시: `lib/infrastructure/persistence/shared_preferences_dashboard_bundle_cache.dart`, 코덱 `lib/application/dashboard_bundle_codec.dart`.
