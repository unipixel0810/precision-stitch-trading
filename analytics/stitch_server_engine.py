"""
Supabase 활성 전략 + 매수선(BUY)을 폴링하고, 현재가가 선 이하일 때 키움 주문 훅을 호출하는 루프.
키움/실계좌 연동 전까지 가격·주문은 스텁으로 두었습니다.

환경 변수:
  SUPABASE_URL
  SUPABASE_SERVICE_ROLE_KEY (권장) 또는 SUPABASE_ANON_KEY
"""

from __future__ import annotations

import os
import signal
import time
from dataclasses import dataclass, field
from datetime import datetime, timezone
from typing import Any

try:
    from supabase import Client, create_client
except ImportError:  # pragma: no cover
    Client = Any  # type: ignore[misc, assignment]
    create_client = None  # type: ignore[misc, assignment]


def _utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _env_required(name: str) -> str:
    v = os.environ.get(name, "").strip()
    if not v:
        raise OSError(f"환경 변수 {name} 가 필요합니다.")
    return v


def _make_supabase() -> Client:
    if create_client is None:
        raise ImportError("pip install supabase")
    url = _env_required("SUPABASE_URL")
    key = (
        os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip()
        or _env_required("SUPABASE_ANON_KEY")
    )
    return create_client(url, key)


@dataclass
class LineArmState:
    """가격이 선 위로 다시 올라올 때까지 같은 신호로 반복 주문하지 않도록 함."""

    armed: bool = True


@dataclass
class StitchServerEngine:
    """
    DB에서 활성 전략·라인을 읽고 BUY 선 터치 시 주문 훅을 호출합니다.
    """

    poll_interval_sec: float = 1.0
    rearm_ratio: float = 0.001
    """선 가격 대비 이 비율만큼 위로 올라오면 재무장(다음 터치 허용)."""

    db: Client | None = None
    _stop: bool = field(default=False, repr=False)
    _line_arm: dict[str, LineArmState] = field(default_factory=dict, repr=False)

    def __post_init__(self) -> None:
        if self.db is None:
            self.db = _make_supabase()

    def request_stop(self) -> None:
        self._stop = True

    def get_kiwoom_price(self, code: str) -> float | None:
        """실시간 시세. 키움 OpenAPI+ 연동 시 여기서 조회."""
        _ = code
        return None

    def execute_kiwoom_order(self, code: str, side: str, order_type: str) -> None:
        """SendOrder 등 실주문. 미연동 시 로그만."""
        print(f"[주문훅] {code} {side} ({order_type})")

    def update_db_after_trade(self, strategy_id: str, fill_price: float, line: dict[str, Any]) -> None:
        """
        체결 후 DB 정리. 스키마에 맞게 확장하세요 (체결 로그 테이블 insert 등).
        기본: active_strategies.updated_at 갱신.
        """
        _ = line
        self.db.table("active_strategies").update({"updated_at": _utc_now_iso()}).eq("id", strategy_id).execute()

    def _line_key(self, strategy_id: str, line: dict[str, Any]) -> str:
        lid = line.get("id")
        if lid is not None:
            return f"{strategy_id}:{lid}"
        return f"{strategy_id}:{line.get('line_type')}:{line.get('price')}"

    def _maybe_fire_buy(
        self,
        strategy_id: str,
        code: str,
        line: dict[str, Any],
        current: float,
    ) -> None:
        if line.get("line_type") != "BUY":
            return
        try:
            threshold = float(line["price"])
        except (TypeError, ValueError):
            return

        key = self._line_key(strategy_id, line)
        st = self._line_arm.setdefault(key, LineArmState())

        if current > threshold * (1.0 + self.rearm_ratio):
            st.armed = True
            return

        if not st.armed:
            return

        if current <= threshold:
            self.execute_kiwoom_order(code, "BUY", "시장가")
            self.update_db_after_trade(strategy_id, current, line)
            st.armed = False

    def fetch_active_strategies(self) -> list[dict[str, Any]]:
        res = (
            self.db.table("active_strategies")
            .select("*, trading_lines(*)")
            .eq("is_active", True)
            .execute()
        )
        return list(res.data or [])

    def run_once(self) -> None:
        strategies = self.fetch_active_strategies()
        for s in strategies:
            code = s.get("stock_code")
            sid = s.get("id")
            if not code or not sid:
                continue

            current = self.get_kiwoom_price(code)
            if current is None:
                continue

            lines = s.get("trading_lines") or []
            if isinstance(lines, dict):
                lines = [lines]
            for line in lines:
                if not isinstance(line, dict):
                    continue
                self._maybe_fire_buy(str(sid), str(code), line, float(current))

    def run_engine(self) -> None:
        print("Stitch 서버 엔진 시작 (Ctrl+C 종료)")
        def _sig(_signum: int, _frame: Any) -> None:  # pragma: no cover
            self.request_stop()
        signal.signal(signal.SIGINT, _sig)
        try:
            signal.signal(signal.SIGTERM, _sig)
        except (AttributeError, ValueError):
            pass

        while not self._stop:
            try:
                self.run_once()
            except Exception as e:  # pragma: no cover
                print(f"[루프 오류] {e!r}")
            time.sleep(self.poll_interval_sec)


if __name__ == "__main__":  # pragma: no cover
    eng = StitchServerEngine(poll_interval_sec=1.0)
    eng.run_engine()
