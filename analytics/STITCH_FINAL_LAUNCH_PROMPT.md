# Stitch Trader — 최종 가동 & AI 분석 통합 프롬프트

아래 블록을 Cursor / Claude Code 등에 붙여 넣거나, **이미 구현된 CLI**로 동일 작업을 실행하세요.

## 시스템에서 실제 실행 (권장)

```bash
cd analytics
export SUPABASE_URL=...
export SUPABASE_SERVICE_ROLE_KEY=...
export OPENAI_API_KEY=...   # 리포트·TP/SL 제안 시

# image_6.png → 엑셀로 저장한 파일 경로를 지정
python stitch_final_launch.py --migrate /path/to/매매일지.xlsx --apply-risk

# DB에 이미 올려둔 경우
python stitch_final_launch.py --analyze-remote --apply-risk
```

- `is_volume_cliff`: **수익률 ≥ 3%** 이면서 거래량 급감 패턴일 때 `true` (`--cliff-min-pct` 로 조정).
- 분석 출력: **승률**, **손익비(PF)**, **3월 평단가 조절 실패** 휴리스틱, **AI 코칭 리포트**, **`active_strategies.tp_percent` / `sl_percent`** 자동 반영(`--apply-risk`).

---

## AI 도구용 원문 프롬프트 (복사용)

**[Final Integration: Data Sync & AI Strategy Report]**

1. **데이터 마이그레이션 (Excel → Supabase)**  
   매매 일지(이미지는 엑셀 내보내기)에서 `종목명`, `return_pct`, `상태(익절/손절)`를 `trade_history`에 bulk insert.  
   **수익률 3% 이상**인 종목 중 거래량이 급감한 사례는 `is_volume_cliff = true`.

2. **성과 분석**  
   승률(익절/전체), 손익비(총 수익 합 / |총 손실 합|).  
   3월 PF가 2월 대비 **0.97 수준으로 하락**한 원인을 **평단가 조절 실패** 관점에서 분석.

3. **AI 코칭**  
   - 거래량 절벽 후 지지 확인 DNA · 승률 70%+ 유효성  
   - 아모레 -15% 류 대형 손절 → **3차 매수 후 시가 이탈 즉시 손절**, **0624** 설정 강제  
   - **14ms** 지연·슬리피지 **0.1~0.2%** → 매수 **1틱 낮게**

4. **자동화**  
   분석 결과로 `active_strategies`의 **`tp_percent`**, **`sl_percent`** 를 AI 제안값으로 업데이트.

---

구현 파일: `migrate_excel_to_trade_history.py`, `trade_history_analytics.py`, `stitch_analytics_engine.py`, `stitch_final_launch.py`, 마이그레이션 `supabase/migrations/20250329000000_active_strategies_tp_sl.sql`.

---

**AI 에이전트용 한 줄 명령 전체 본문:** [`STITCH_FINAL_AGENT_COMMAND.md`](./STITCH_FINAL_AGENT_COMMAND.md)
