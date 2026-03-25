"""
Telegram Bot으로 Stitch 매매 알림 전송.

환경 변수(선택):
  TELEGRAM_BOT_TOKEN
  TELEGRAM_CHAT_ID
"""

from __future__ import annotations

import os
from typing import Any

try:
    import requests
except ImportError:  # pragma: no cover
    requests = None  # type: ignore[misc, assignment]


class StitchTelegramNotifier:
    def __init__(self, token: str, chat_id: str, *, timeout_sec: float = 15.0):
        self.token = token.strip()
        self.chat_id = str(chat_id).strip()
        self.timeout_sec = timeout_sec
        self._send_url = f"https://api.telegram.org/bot{self.token}/sendMessage"

    @classmethod
    def try_from_env(cls) -> StitchTelegramNotifier | None:
        token = os.environ.get("TELEGRAM_BOT_TOKEN", "").strip()
        chat = os.environ.get("TELEGRAM_CHAT_ID", "").strip()
        if not token or not chat:
            return None
        return cls(token, chat)

    def _post(self, payload: dict[str, Any]) -> None:
        if requests is None:
            raise ImportError("pip install requests")
        r = requests.post(self._send_url, data=payload, timeout=self.timeout_sec)
        r.raise_for_status()
        data = r.json()
        if not data.get("ok"):
            raise RuntimeError(f"Telegram API: {data!r}")

    def send_text(self, text: str, *, silent: bool = False) -> None:
        payload: dict[str, Any] = {"chat_id": self.chat_id, "text": text}
        if silent:
            payload["disable_notification"] = True
        self._post(payload)

    def send_trade_report(
        self,
        stock_name: str,
        return_pct: float,
        profit_krw: int,
        status: str,
        *,
        ai_comment: str | None = None,
    ) -> None:
        """수익/손실 청산 시 요약 알림."""
        emoji = "🚀" if status == "익절" else "📉"
        profit_s = f"{int(profit_krw):,}"
        line_ai = ai_comment or (
            "세력봉 중심선 지지 후 반등 타점으로 정리되었습니다."
            if status == "익절"
            else "손절 규칙(Final Line 등) 준수 여부를 복기해 보세요."
        )
        message = (
            f"{emoji} [Stitch Trader 매매 알림]\n\n"
            f"📌 종목명: {stock_name}\n"
            f"📊 수익률: {return_pct}%\n"
            f"💰 손익금: {profit_s}원\n"
            f"✅ 상태: {status} 완료\n\n"
            f"💡 AI 한줄평: {line_ai}"
        )
        self._post({"chat_id": self.chat_id, "text": message})

    def send_buy_fill_notice(self, stock_code: str, fill_price_krw: float) -> None:
        """매수 체결 직후 간단 알림(손익 계산 전)."""
        message = (
            f"🔔 [Stitch Trader 체결]\n\n"
            f"종목: {stock_code}\n"
            f"매수 체결가: {fill_price_krw:,.0f}원 (틱 스냅 반영)\n"
            f"— 익절/손절 알림은 청산 시 send_trade_report 로 전송하세요."
        )
        self._post({"chat_id": self.chat_id, "text": message})
