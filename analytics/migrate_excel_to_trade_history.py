"""
엑셀/CSV 매매 기록을 Supabase `trade_history`에 Bulk Insert.

사용법:
  export SUPABASE_URL=... SUPABASE_SERVICE_ROLE_KEY=...
  python migrate_excel_to_trade_history.py --file ./fixtures/sample_trade_history.csv
  python migrate_excel_to_trade_history.py --file ./매매.xlsx --sheet 0

엑셀 헤더(예시, 자동 매핑): 종목명, 수익률, 익절/손절, 체결일, 거래량, 기준거래량
image_6.png 는 엑셀로 다시 저장한 뒤 --file 로 지정하세요.
"""

from __future__ import annotations

import argparse
import os
import re
from typing import Any

import pandas as pd

try:
    from supabase import create_client
except ImportError:
    create_client = None  # type: ignore[misc, assignment]


def _client():
    if create_client is None:
        raise SystemExit("pip install supabase")
    url = os.environ.get("SUPABASE_URL", "").strip()
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip() or os.environ.get("SUPABASE_ANON_KEY", "").strip()
    if not url or not key:
        raise SystemExit("SUPABASE_URL 와 SUPABASE_SERVICE_ROLE_KEY(권장) 필요")
    return create_client(url, key)


def get_supabase_client():
    """다른 스크립트에서 재사용."""
    return _client()


_COL_ALIASES: dict[str, str] = {
    "종목명": "stock_name",
    "종목": "stock_name",
    "name": "stock_name",
    "stock_name": "stock_name",
    "수익률": "return_pct",
    "수익율": "return_pct",
    "손익률": "return_pct",
    "return_pct": "return_pct",
    "return": "return_pct",
    "결과": "status",
    "구분": "status",
    "status": "status",
    "익절/손절": "status",
    "체결일": "trade_date",
    "매매일": "trade_date",
    "trade_date": "trade_date",
    "date": "trade_date",
    "날짜": "trade_date",
    "거래량": "volume",
    "volume": "volume",
    "기준거래량": "volume_ref",
    "진입거래량": "volume_ref",
    "volume_ref": "volume_ref",
    "비고": "notes",
    "notes": "notes",
}


def _norm_header(h: str) -> str:
    s = str(h).strip()
    s = re.sub(r"\s+", "", s)
    return s


def normalize_columns(raw: pd.DataFrame) -> pd.DataFrame:
    colmap: dict[str, str] = {}
    for c in raw.columns:
        key = _norm_header(c)
        if key in _COL_ALIASES:
            colmap[c] = _COL_ALIASES[key]
        else:
            low = str(c).strip().lower()
            if low in ("stock_name", "return_pct", "status", "trade_date", "volume", "volume_ref", "notes"):
                colmap[c] = low
    out = raw.rename(columns=colmap)
    for req in ("stock_name", "return_pct", "status"):
        if req not in out.columns:
            raise ValueError(f"필수 컬럼 누락: {req} (현재: {list(out.columns)})")
    return out


def _coerce_return_pct(series: pd.Series) -> pd.Series:
    v = pd.to_numeric(series, errors="coerce")
    return v


def _coerce_status(series: pd.Series) -> pd.Series:
    out: list[str] = []
    for x in series.astype(str):
        t = x.strip()
        if "익" in t and "손" not in t:
            out.append("익절")
        elif "손" in t or "loss" in t.lower():
            out.append("손절")
        elif t in ("익절", "손절"):
            out.append(t)
        else:
            try:
                fv = float(t)
                out.append("손절" if fv < 0 else "익절")
            except ValueError:
                out.append("손절")
    return pd.Series(out, index=series.index)


def compute_volume_cliff(df: pd.DataFrame, *, min_return_pct: float = 3.0) -> pd.Series:
    """
    수익률이 min_return_pct 이상인 종목만 후보로 두고, 거래량 급감(절벽) 패턴이면 True.
    - volume_ref & volume: volume <= 0.35 * volume_ref
    - volume 만: 종목별 중앙 거래량 대비 volume < 0.30 * median_volume_symbol
    """
    high_return = pd.to_numeric(df["return_pct"], errors="coerce") >= float(min_return_pct)
    cliff = pd.Series(False, index=df.index)

    if "volume" in df.columns and "volume_ref" in df.columns:
        vol = pd.to_numeric(df["volume"], errors="coerce")
        ref = pd.to_numeric(df["volume_ref"], errors="coerce")
        mask = high_return & ref.notna() & vol.notna() & (ref > 0) & (vol <= ref * 0.35)
        cliff = cliff | mask
    elif "volume" in df.columns:
        vol = pd.to_numeric(df["volume"], errors="coerce")
        med = df.groupby("stock_name")["volume"].transform(lambda s: pd.to_numeric(s, errors="coerce").median())
        mask = high_return & med.notna() & vol.notna() & (med > 0) & (vol <= med * 0.30)
        cliff = cliff | mask.fillna(False)
    return cliff


def read_trades(path: str, sheet: int | str = 0, *, cliff_min_return_pct: float = 3.0) -> pd.DataFrame:
    path_lower = path.lower()
    if path_lower.endswith(".csv"):
        raw = pd.read_csv(path)
    elif path_lower.endswith((".xlsx", ".xls")):
        raw = pd.read_excel(path, sheet_name=sheet, engine="openpyxl" if path_lower.endswith("xlsx") else None)
    else:
        raise ValueError("지원: .csv, .xlsx, .xls")
    df = normalize_columns(raw)
    df["return_pct"] = _coerce_return_pct(df["return_pct"])
    df["status"] = _coerce_status(df["status"].astype("string"))
    if "trade_date" in df.columns:
        df["trade_date"] = pd.to_datetime(df["trade_date"], errors="coerce").dt.date.astype(str)
    else:
        df["trade_date"] = None
    for col in ("volume", "volume_ref"):
        if col in df.columns:
            df[col] = pd.to_numeric(df[col], errors="coerce")
    df["is_volume_cliff"] = compute_volume_cliff(df, min_return_pct=cliff_min_return_pct)
    if "notes" not in df.columns:
        df["notes"] = None
    return df


def to_records(df: pd.DataFrame) -> list[dict[str, Any]]:
    out = []
    for _, row in df.iterrows():
        rec: dict[str, Any] = {
            "stock_name": row["stock_name"],
            "return_pct": float(row["return_pct"]),
            "status": row["status"],
            "is_volume_cliff": bool(row["is_volume_cliff"]),
        }
        td = row.get("trade_date")
        rec["trade_date"] = td if pd.notna(td) and td is not None else None
        for k in ("volume", "volume_ref"):
            v = row.get(k)
            rec[k] = float(v) if v is not None and pd.notna(v) else None
        nv = row.get("notes")
        rec["notes"] = (
            None if nv is None or (isinstance(nv, float) and pd.isna(nv)) else str(nv)
        )
        out.append(rec)
    return out


def chunked(xs: list[Any], n: int) -> list[list[Any]]:
    return [xs[i : i + n] for i in range(0, len(xs), n)]


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--file", required=True, help=".xlsx 또는 .csv")
    ap.add_argument("--sheet", default="0", help="엑셀 시트 인덱스(숫자) 또는 시트 이름")
    ap.add_argument("--batch", type=int, default=300)
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument(
        "--cliff-min-pct",
        type=float,
        default=3.0,
        help="is_volume_cliff 후보 최소 수익률(%%). 기본 3%%",
    )
    args = ap.parse_args()

    raw_sheet = args.sheet
    sheet: int | str = int(raw_sheet) if str(raw_sheet).isdigit() else raw_sheet
    df = read_trades(args.file, sheet=sheet, cliff_min_return_pct=args.cliff_min_pct)
    rows = to_records(df)
    print(f"rows={len(rows)} dry_run={args.dry_run}")
    if args.dry_run:
        print(df.head())
        return

    db = _client()
    for batch in chunked(rows, args.batch):
        db.table("trade_history").insert(batch).execute()
    print("Bulk insert 완료")


if __name__ == "__main__":
    main()
