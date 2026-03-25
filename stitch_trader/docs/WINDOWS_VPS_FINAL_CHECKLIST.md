# Windows VPS — Stitch Trader 24시간 가동 체크리스트

키움 OpenAPI+는 **Windows 필수**이므로 AWS/IDC **Windows Server 2022** 등에서 아래를 점검합니다.

## ① 서버 환경 (Infrastructure)

- **절전·절전 매드**: 제어판 → 전원 옵션 → 절전 **해제**, 디스크 끄기 최소화.
- **재시작 후 자동 기동**: 작업 스케줄러에 `StitchTraderEngine.exe` 또는 `python windows_engine_main.py` 등록(로그온 시 / 시작 시 트리거).
- **원격 데스크톱**: 세션 끊김 시 HTS/API 동작 정책 확인(키움은 로그인 세션·화면 이슈가 있을 수 있음).

## ② API 및 보안 (Connectivity)

- **키움 자동 로그인**: 매 영업일 **08:30** 전후 OpenAPI+ 로그인·모듈 업데이트 자동화 스크립트(별도) 가동 여부.
- **Supabase**: 서버에 `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` 설정. `.env` 사용 시 프로세스 시작 전 로드.
- **Telegram(선택)**: `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` — 체결 알림(`stitch_telegram_notifier.py`).
- **방화벽**: 출발 Supabase/키움 서버 포트 허용.

## ③ 매매 로직 (The Engine)

- **틱 스냅**: `analytics/krx_price_grid.py` — 현재가·DB 기준선을 호가 단위로 보정. 실제 체결과 비교해 검증.
- **14ms 보정**: `STITCH_LATENCY_MS`, `STITCH_BUY_LATENCY_TICKS`(기본 1틱 하향) — `stitch_server_engine.py` 참고.
- **0624 자동감시**: `execute_kiwoom_order` 직후 키움 서버에 익절/손절 **감시 주문** 등록 여부를 **소액 테스트 매매**로 확인.
- **Final Line(기준봉 시가) 이탈**: 정책대로 **시장가 청산**·감시 연동 여부를 시나리오 테스트.

## 빌드

`analytics/build_windows_engine.bat` → `dist/StitchTraderEngine.exe`

배포 시 동일 폴더에 Python 런타임이 없어도 exe 단독 실행 가능(PyInstaller). `supabase` 등 종속은 빌드에 포함됨.
