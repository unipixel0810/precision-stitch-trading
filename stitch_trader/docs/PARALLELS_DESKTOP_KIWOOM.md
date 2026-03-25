# MacBook + Parallels Desktop — 키움 API 브리지

키움 OpenAPI+ ActiveX는 **Windows에서만** 동작하므로, 맥에서는 **Parallels 안의 Windows 게스트**에서 HTS/API를 띄우는 구성이 맞습니다.

## 역할 분리

| 실행 위치 | 역할 |
|-----------|------|
| **Windows VM** | 키움 영웅문/OpenAPI+, `kiwoom_pyqt_login.py` / 주문 래퍼, (선택) `stitch_server_engine.py`, Supabase 업로드 |
| **macOS 호스트** | Cursor, Flutter 웹/데스크톱 UI 개발, 분석 스크립트 일부 |

Flutter(UI)와 Windows(주문)는 **직접 프로세스 호출이 불가**하므로 중간 채널이 필요합니다.

## 연동 패턴 (권장 순)

### A. 로컬 HTTP 브리지 (가장 단순)

1. Windows VM에서 **아주 얇은 HTTP 서버**(FastAPI/Flask 등) 실행.
2. 엔드포인트 예: `POST /v1/order`, `GET /v1/price?code=005930` — 내부에서 PyQt 키움 `dynamicCall(SendOrder…)` 호출.
3. Parallels **공유 네트워크**에서 호스트 맥 → 게스트 Windows IP로 요청 (또는 포트 포워딩).
4. macOS에서 돌리는 Flutter는 `API_BASE_URL=http://<게스트_IP>:포트` 처럼 **원격만** 쓰면 됨 (지금 `PHASE4_HTTP_CONTRACT.md` 방향과 동일).

**주의:** API 서버에 인증·방화벽을 반드시 걸 것. 개발 중에만 VM 내부 `localhost`로 제한하는 것도 가능.

### B. Supabase / 큐만 쓰기 (이미 있는 축 활용)

1. Windows VM의 Python 루프가 **Supabase `trading_lines`·`active_strategies`** 를 읽고 키움으로 주문.
2. Flutter는 **주문을 직접 보내지 않고** 선/설정만 Supabase에 쓰기 (`syncStitchToSupabase` 류).
3. 실시간 체결 알림은 **Telegram** 또는 Supabase Realtime으로 호스트에서도 확인 가능.

이 방식은 **맥에서 Flutter만 켜도**, 주문은 전부 **Windows 엔진**이 처리합니다.

### C. Parallels “Windows 앱을 맥처럼”만 쓰는 경우

Coherence 모드로 키움 창만 맥에 띄워도, **API는 여전히 Windows 프로세스** 안입니다. Flutter와의 연결은 위 A 또는 B와 동일하게 **네트워크/DB**로 해결합니다.

## Parallels 네트워크 팁

- 게스트가 **공유 IP / 브리지** 중 어떤 모드인지에 따라 호스트→게스트 접속 주소가 달라집니다.
- Windows **방화벽**에서 브리지 서버 포트 인바운드 허용.
- `localhost` on Mac **≠** VM 안의 localhost. VM 내부 서비스는 **게스트의 IP**로 접근합니다.

## 체크리스트

- [ ] Windows VM: 32비트 Python 등 키움 요구사항 충족
- [ ] `kiwoom_account_sync.py` / 로그인 스모크 성공
- [ ] (선택) 브리지 서버 또는 `stitch_server_engine` + Supabase만으로 운영决定
- [ ] Flutter: 실주문 버튼은 **REST/Supabase 계약**이 생긴 뒤에만 연결

## 관련 파일

- Python 엔진: `analytics/stitch_server_engine.py`
- PyQt 로그인 샘플: `analytics/kiwoom_pyqt_login.py`
- 계좌 동기: `analytics/kiwoom_account_sync.py`
- VPS 일반 점검: `WINDOWS_VPS_FINAL_CHECKLIST.md`
