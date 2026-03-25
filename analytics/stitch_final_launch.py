#!/usr/bin/env python3
"""
Stitch Trader 최종 가동: (옵션) 엑셀/CSV → trade_history 업로드 + 지표 + 평단가 분석 + AI 리포트 + (옵션) active_strategies TP/SL 반영.

  cd analytics
  export SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... OPENAI_API_KEY=...

  # 업로드만
  python stitch_final_launch.py --migrate ../journal.xlsx

  # 업로드 + 분석 + 리포트 + DB TP/SL 업데이트
  python stitch_final_launch.py --migrate ../journal.xlsx --analyze-remote --apply-risk

  # 이미 업로드된 DB만 분석
  python stitch_final_launch.py --analyze-remote --apply-risk --no-llm
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone

import pandas as pd

import migrate_excel_to_trade_history as mig
from stitch_analytics_engine import StitchAnalyticsEngine
from trade_history_analytics import (
    calculate_performance_metrics,
    compare_feb_march_performance,
    march_pf_drop_averaging_failure_analysis,
    summarize_march_large_stops,
)


def _load_remote_df() -> pd.DataFrame:
    db = mig.get_supabase_client()
    res = db.table("trade_history").select("*").order("trade_date", desc=False).limit(10_000).execute()
    rows = res.data or []
    if not rows:
        raise SystemExit("trade_history 가 비어 있습니다. --migrate 로 먼저 업로드하세요.")
    return pd.DataFrame(rows)


def _resolve_analysis_df(args: argparse.Namespace, df_after_migrate: pd.DataFrame | None) -> pd.DataFrame:
    if args.analyze_remote:
        return _load_remote_df()
    if df_after_migrate is not None:
        return df_after_migrate
    if args.file:
        raw_sheet = args.sheet
        sheet: int | str = int(raw_sheet) if str(raw_sheet).isdigit() else raw_sheet
        return mig.read_trades(args.file, sheet=sheet, cliff_min_return_pct=args.cliff_min_pct)
    raise SystemExit("분석 대상을 지정하세요: --migrate PATH, --file PATH, 또는 --analyze-remote")


def _apply_risk(db, tp: float, sl: float) -> None:
    now = datetime.now(timezone.utc).isoformat()
    db.table("active_strategies").update(
        {"tp_percent": tp, "sl_percent": sl, "updated_at": now},
    ).eq("is_active", True).execute()


def main() -> None:
    ap = argparse.ArgumentParser(description="Stitch Final Launch: migration + AI + TP/SL sync")
    ap.add_argument("--migrate", metavar="PATH", help="엑셀/CSV → trade_history bulk insert")
    ap.add_argument("--sheet", default="0")
    ap.add_argument("--cliff-min-pct", type=float, default=3.0)
    ap.add_argument("--batch", type=int, default=300)
    ap.add_argument("--analyze-remote", action="store_true", help="Supabase trade_history 에서 읽어 분석")
    ap.add_argument("--file", help="로컬 파일만 분석(업로드 없이)")
    ap.add_argument("--year", type=int, default=None)
    ap.add_argument("--no-llm", action="store_true")
    ap.add_argument("--apply-risk", action="store_true", help="AI(또는 규칙) TP/SL → active_strategies")
    ap.add_argument("--default-tp", type=float, default=3.5)
    ap.add_argument("--default-sl", type=float, default=1.2)
    ap.add_argument("--latency-ms", type=float, default=14.0)
    args = ap.parse_args()

    df_after_migrate: pd.DataFrame | None = None
    if args.migrate:
        raw_sheet = args.sheet
        sheet: int | str = int(raw_sheet) if str(raw_sheet).isdigit() else raw_sheet
        df_up = mig.read_trades(args.migrate, sheet=sheet, cliff_min_return_pct=args.cliff_min_pct)
        rows = mig.to_records(df_up)
        db = mig.get_supabase_client()
        for batch in mig.chunked(rows, args.batch):
            db.table("trade_history").insert(batch).execute()
        print(f"[migrate] trade_history rows inserted: {len(rows)}")
        df_after_migrate = df_up

    df = _resolve_analysis_df(args, df_after_migrate)
    df["return_pct"] = pd.to_numeric(df["return_pct"], errors="coerce")
    if "trade_date" in df.columns:
        df["trade_date"] = pd.to_datetime(df["trade_date"], errors="coerce")

    metrics_trade = calculate_performance_metrics(df)
    feb_mar = compare_feb_march_performance(df, year=args.year)
    averaging = march_pf_drop_averaging_failure_analysis(df, year=args.year)
    stops = summarize_march_large_stops(df, threshold_pct=-12.0)

    win_rate = metrics_trade["win_rate"]
    print("[승률 WinRate]", f"{win_rate * 100:.2f}% (익절 건수 / 전체)")
    print("[손익비 Profit Factor]", metrics_trade["profit_factor"], "(총 수익 합 / |총 손실 합|)")
    print("[2·3월]", feb_mar)
    print("[3월 평단가 조절 관점]", averaging["summary_ko"])
    print("[대형 손절 요약]\n", stops)

    coaching_text = ""
    suggestion: dict = {
        "tp_percent": args.default_tp,
        "sl_percent": args.default_sl,
        "rationale_ko": "no-llm",
    }

    if not args.no_llm:
        engine = StitchAnalyticsEngine()
        coaching_text = engine.generate_execution_coaching_report(
            metrics_trade,
            feb_mar,
            march_large_stop_summary=stops,
            march_averaging_summary=averaging["summary_ko"],
            latency_ms=args.latency_ms,
        )
        print("\n=== AI 코칭 리포트 ===\n")
        print(coaching_text)
        suggestion = engine.suggest_tp_sl_percentages(
            metrics_trade,
            feb_mar,
            march_averaging_summary=averaging["summary_ko"],
            coaching_excerpt=coaching_text,
            default_tp=args.default_tp,
            default_sl=args.default_sl,
        )
    else:
        feb = feb_mar.get("february") or {}
        mar = feb_mar.get("march") or {}
        if feb.get("profit_factor") and mar.get("profit_factor"):
            if float(mar["profit_factor"]) < float(feb["profit_factor"]):
                suggestion = {
                    "tp_percent": round(args.default_tp - 0.2, 2),
                    "sl_percent": round(max(0.9, args.default_sl - 0.15), 2),
                    "rationale_ko": "no-llm: 3월 PF < 2월 → SL 타이트·TP 소폭 하향",
                }

    print("\n[TP/SL 제안]", suggestion)

    if args.apply_risk:
        db = mig.get_supabase_client()
        _apply_risk(db, float(suggestion["tp_percent"]), float(suggestion["sl_percent"]))
        print("[apply-risk] active_strategies (is_active=true) tp_percent/sl_percent 업데이트 완료")


if __name__ == "__main__":
    main()
