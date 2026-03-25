"""
trade_history(DataFrame 또는 Supabase) → 성과 지표 + 월별(2·3월) 손익비 비교.
"""

from __future__ import annotations

from typing import Any

import numpy as np
import pandas as pd


def ensure_trade_columns(df: pd.DataFrame) -> pd.DataFrame:
    need = {"status", "return_pct"}
    if not need.issubset(df.columns):
        raise ValueError(f"필수 컬럼: {need}")
    out = df.copy()
    if "trade_date" in out.columns:
        out["trade_date"] = pd.to_datetime(out["trade_date"], errors="coerce")
    return out


def calculate_performance_metrics(trade_df: pd.DataFrame) -> dict[str, float]:
    """승률, 손익비(총익/|총손|), 기댓값(트레이드당 %), 평균 익절·손절 %."""
    df = ensure_trade_columns(trade_df)
    if df.empty:
        return {
            "win_rate": 0.0,
            "profit_factor": 0.0,
            "expectancy": 0.0,
            "avg_profit": 0.0,
            "avg_loss": 0.0,
            "trade_count": 0.0,
        }

    wins = df[df["status"] == "익절"]
    losses = df[df["status"] == "손절"]
    n = len(df)
    win_rate = len(wins) / n if n else 0.0

    avg_profit = float(wins["return_pct"].mean()) if len(wins) else 0.0
    avg_loss = float(losses["return_pct"].mean()) if len(losses) else 0.0

    gross_profit = float(wins["return_pct"].sum()) if len(wins) else 0.0
    gross_loss = float(losses["return_pct"].sum()) if len(losses) else 0.0

    if gross_loss == 0 or np.isnan(gross_loss):
        profit_factor = float("inf") if gross_profit > 0 else 0.0
    else:
        profit_factor = abs(gross_profit / gross_loss)

    expectancy = (win_rate * avg_profit) + ((1 - win_rate) * avg_loss)

    return {
        "win_rate": round(win_rate, 4),
        "profit_factor": round(min(profit_factor, 9999.0), 4) if np.isfinite(profit_factor) else 9999.0,
        "expectancy": round(expectancy, 4),
        "avg_profit": round(avg_profit, 4),
        "avg_loss": round(avg_loss, 4),
        "trade_count": float(n),
    }


def compare_feb_march_performance(
    trade_df: pd.DataFrame,
    *,
    year: int | None = None,
) -> dict[str, Any]:
    """
    2월 vs 3월 손익비·건수·승률 비교.
    year가 None이면 trade_date 연도 무시하고 매 1~12월 중 2·3월만 월 집계(혼합 연도 주의).
    """
    df = ensure_trade_columns(trade_df)
    if df.empty or "trade_date" not in df.columns or df["trade_date"].isna().all():
        return {
            "february": None,
            "march": None,
            "delta_profit_factor": None,
            "note": "trade_date 가 없어 월별 비교를 생략했습니다.",
        }

    work = df.dropna(subset=["trade_date"]).copy()
    if year is not None:
        work = work[work["trade_date"].dt.year == year]

    def _month(m: int) -> dict[str, Any] | None:
        sub = work[work["trade_date"].dt.month == m]
        if sub.empty:
            return None
        met = calculate_performance_metrics(sub)
        return {
            "month": m,
            "profit_factor": met["profit_factor"],
            "win_rate": met["win_rate"],
            "expectancy": met["expectancy"],
            "trade_count": int(met["trade_count"]),
        }

    feb = _month(2)
    mar = _month(3)
    delta = None
    if feb and mar and feb["profit_factor"] is not None and mar["profit_factor"] is not None:
        delta = round(float(feb["profit_factor"]) - float(mar["profit_factor"]), 4)

    return {
        "february": feb,
        "march": mar,
        "delta_profit_factor": delta,
        "year_filter": year,
    }


def summarize_march_large_stops(trade_df: pd.DataFrame, threshold_pct: float = -12.0) -> str:
    """3월 대형 손절 행 요약 (LLM 컨텍스트용)."""
    df = ensure_trade_columns(trade_df)
    if "trade_date" not in df.columns:
        return "(날짜 없음)"
    m = df["trade_date"].dt.month == 3
    sub = df[m & (df["return_pct"] <= threshold_pct)]
    if sub.empty:
        sub = df[m & (df["status"] == "손절")].nsmallest(3, "return_pct")
    if sub.empty:
        return "3월 대형 손절 샘플 없음"
    lines = []
    for _, r in sub.head(6).iterrows():
        name = r.get("stock_name", "?")
        d = r.get("trade_date")
        rp = r.get("return_pct")
        cliff = r.get("is_volume_cliff", "")
        lines.append(f"- {d} {name} {rp}% (volume_cliff={cliff})")
    return "\n".join(lines)
