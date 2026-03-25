"""
Supabase trade_history → 지표 + 2·3월 비교 + LLM Final Execution 리포트 출력.

  export SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=... OPENAI_API_KEY=...
  python run_trade_ai_report.py

또는 로컬 CSV만 분석(LLM 없이 지표만):
  python run_trade_ai_report.py --file fixtures/sample_trade_history.csv --no-llm
"""

from __future__ import annotations

import argparse
import os
import sys

import pandas as pd

from migrate_excel_to_trade_history import read_trades
from stitch_analytics_engine import StitchAnalyticsEngine
from trade_history_analytics import (
    calculate_performance_metrics,
    compare_feb_march_performance,
    march_pf_drop_averaging_failure_analysis,
    summarize_march_large_stops,
)

try:
    from supabase import create_client
except ImportError:
    create_client = None  # type: ignore[misc, assignment]


def _supabase():
    if create_client is None:
        raise SystemExit("pip install supabase")
    url = os.environ["SUPABASE_URL"].strip()
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip() or os.environ["SUPABASE_ANON_KEY"].strip()
    return create_client(url, key)


def load_from_supabase(limit: int = 10_000) -> pd.DataFrame:
    db = _supabase()
    q = db.table("trade_history").select("*").order("trade_date", desc=False)
    res = q.limit(limit).execute()
    rows = res.data or []
    if not rows:
        return pd.DataFrame()
    return pd.DataFrame(rows)


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", help="Supabase 대신 로컬 CSV/엑셀")
    ap.add_argument("--year", type=int, default=None, help="월별 비교 시 연도 필터")
    ap.add_argument("--no-llm", action="store_true")
    ap.add_argument("--latency-ms", type=float, default=14.0)
    args = ap.parse_args()

    if args.file:
        df = read_trades(args.file)
    else:
        df = load_from_supabase()
    if df.empty:
        print("거래 데이터가 없습니다.")
        sys.exit(1)

    for col in ("return_pct",):
        df[col] = pd.to_numeric(df[col], errors="coerce")
    if "trade_date" in df.columns:
        df["trade_date"] = pd.to_datetime(df["trade_date"], errors="coerce")

    metrics = calculate_performance_metrics(df)
    feb_mar = compare_feb_march_performance(df, year=args.year)
    averaging = march_pf_drop_averaging_failure_analysis(df, year=args.year)
    stop_blob = summarize_march_large_stops(df, threshold_pct=-12.0)

    print("[지표]", metrics)
    print("[2·3월 비교]", feb_mar)
    print("[3월 평단가 조절 관점]", averaging["summary_ko"])

    if args.no_llm:
        return

    engine = StitchAnalyticsEngine()
    report = engine.generate_execution_coaching_report(
        metrics,
        feb_mar,
        march_large_stop_summary=stop_blob,
        march_averaging_summary=averaging["summary_ko"],
        latency_ms=args.latency_ms,
    )
    print("\n--- AI Coaching Report ---\n")
    print(report)


if __name__ == "__main__":
    main()
