# Stitch Trader — AI 에이전트 최종 가동 명령 (복사용)

아래 **한 문단**을 Cursor / Claude Code 등에 그대로 전달할 수 있습니다.

---

**Stitch Trader 시스템 최종 가동 명령:** Supabase `trade_history`에 엑셀(매매 일지) 데이터를 마이그레이션하고, `stitch_final_launch.py`로 AI 성과 리포트를 생성한 뒬 그 요지를 Flutter 대시보드 **Analytics** 탭에 실시간 표시할 수 있도록 API 또는 번들 데이터로 연동해 줘. Windows VPS에서 24시간 구동할 **Python 매매 엔진**은 `analytics/windows_engine_main.py`를 **PyInstaller**로 빌드한 `StitchTraderEngine.exe`로 배포한다. 모든 주문·청산 정책은 **키움 0624 자동감시**를 기준으로 설계하고, **`STITCH_LATENCY_MS`(기본 14ms)** 및 **`krx_price_grid` 틱 스냅 + 매수선 N틱 하향 보정**을 엔진에 포함한다. `active_strategies`의 TP/SL은 `--apply-risk`로 제안값을 반영할 수 있다.

---

구현 위치 요약:

| 항목 | 경로 |
|------|------|
| 마이그레이션 + 리포트 + TP/SL | `analytics/stitch_final_launch.py` |
| Windows exe 빌드 | `analytics/build_windows_engine.bat` |
| 엔진 본체 | `analytics/stitch_server_engine.py` |
| 틱/지연 보정 | `analytics/krx_price_grid.py` |
| 대시보드 Analytics | `stitch_trader/lib/presentation/pages/analytics_performance_tab.dart` |
| VPS 체크리스트 | `stitch_trader/docs/WINDOWS_VPS_FINAL_CHECKLIST.md` |
