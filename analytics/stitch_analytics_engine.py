"""
거래 내역(DataFrame) → 핵심 지표 + (선택) GPT 코칭.
엑셀/CSV에서 읽은 `status`, `return_pct` 컬럼을 가정합니다.
"""

from __future__ import annotations

import json
import os
from typing import Any

import numpy as np
import pandas as pd

try:
    from openai import OpenAI
except ImportError:  # pragma: no cover
    OpenAI = None  # type: ignore[misc, assignment]


class StitchAnalyticsEngine:
    def __init__(self, api_key: str | None = None):
        """
        api_key: OpenAI 키. None이면 환경변수 OPENAI_API_KEY 사용.
        """
        self._api_key = api_key or os.environ.get("OPENAI_API_KEY", "")
        self._client: Any = None
        if self._api_key and OpenAI is not None:
            self._client = OpenAI(api_key=self._api_key)

    def calculate_metrics(self, trade_data_df: pd.DataFrame) -> dict[str, float]:
        """
        status: '익절' | '손절' (그 외 행은 승률 분모에서 제외 가능 — 아래는 전체 행 기준).
        return_pct: 퍼센트 수익률 (예: 3.2 또는 -8.3).
        """
        if trade_data_df is None or trade_data_df.empty:
            return {
                "win_rate": 0.0,
                "profit_factor": 0.0,
                "expectancy": 0.0,
                "avg_profit": 0.0,
                "avg_loss": 0.0,
            }

        df = trade_data_df.copy()
        if "status" not in df.columns or "return_pct" not in df.columns:
            raise ValueError("trade_data_df 에 'status', 'return_pct' 컬럼이 필요합니다.")

        wins = df[df["status"] == "익절"]
        losses = df[df["status"] == "손절"]
        n = len(df)
        if n == 0:
            return self.calculate_metrics(pd.DataFrame())

        win_rate = len(wins) / n

        avg_profit = float(wins["return_pct"].mean()) if len(wins) else 0.0
        avg_loss = float(losses["return_pct"].mean()) if len(losses) else 0.0

        gross_profit = float(wins["return_pct"].sum()) if len(wins) else 0.0
        gross_loss = float(losses["return_pct"].sum()) if len(losses) else 0.0
        # 손실 합이 0에 가깝거나 익절만 있으면 PF 정의 불가 → 0 또는 대형값 대신 명시
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
        }

    def get_ai_coaching(
        self,
        metrics: dict[str, float],
        recent_trades: pd.DataFrame | None = None,
        *,
        model: str = "gpt-4o-mini",
    ) -> str:
        """계산된 지표와 최근 체결 요약을 바탕으로 코칭 문구 생성."""
        if self._client is None:
            raise RuntimeError(
                "OpenAI 클라이언트를 쓸 수 없습니다. pip install openai 와 유효한 API 키를 설정하세요."
            )

        recent_blob = ""
        if recent_trades is not None and not recent_trades.empty:
            tail = recent_trades.tail(10)
            recent_blob = tail.to_string(index=False)

        win_pct = metrics["win_rate"] * 100
        prompt = f"""
당신은 퀀트·디지털 트레이딩 코치입니다. 아래 매매 지표를 보고 한국어로 간결하고 실행 가능한 조언을 주세요.

[매매 지표]
- 승률: {win_pct:.2f}%
- 손익비(대략 총익/총손 절대비): {metrics["profit_factor"]}
- 기댓값(트레이드당 %): {metrics["expectancy"]}
- 평균 익절률: {metrics["avg_profit"]}%
- 평균 손절률: {metrics["avg_loss"]}%

[최근 체결 샘플]
{recent_blob if recent_blob else "(없음)"}

분석 가이드:
1. 이 구조가 장기적으로 기대값을 플러스로 만들 수 있는지.
2. 손익비가 나쁘다면 익절이 짧은지 손절이 긴지 역추적.
3. Stitch Controller의 SL 슬라이더·TP를 어떤 방향으로 조정할지 수치감 있게.
""".strip()

        response = self._client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": "Professional trading coach. Be direct and practical."},
                {"role": "user", "content": prompt},
            ],
            temperature=0.6,
        )
        return (response.choices[0].message.content or "").strip()

    def generate_execution_coaching_report(
        self,
        metrics: dict[str, float],
        feb_march: dict[str, Any],
        *,
        march_large_stop_summary: str,
        march_averaging_summary: str = "",
        latency_ms: float = 14.0,
        model: str = "gpt-4o-mini",
    ) -> str:
        """
        Final Execution 리포트: 세력봉 전략 유효성, 3월 대형 손절·SL 제안, 지연→슬리피지.
        """
        if self._client is None:
            raise RuntimeError(
                "OpenAI 클라이언트를 쓸 수 없습니다. pip install openai 와 유효한 API 키를 설정하세요."
            )

        feb = feb_march.get("february")
        mar = feb_march.get("march")
        delta = feb_march.get("delta_profit_factor")
        win_pct = metrics["win_rate"] * 100
        averaging_blob = march_averaging_summary.strip() or "(생략)"

        prompt = f"""
당신은 Stitch 트레이딩 시스템의 AI 애널리스트입니다. 한국어로 **구조화된 리포트**를 작성하세요.
반드시 아래 **세 가지 소제목**을 순서대로 포함하고, 각 소제목 아래 2~5문단으로 분석하세요.

**반드시 다음 취지를 본문에 녹여낼 것:**
- 사용자 수익 DNA인 **'거래량 절벽 후 지지 확인'** 매매: 데이터상 승률이 높다면(예: 70% 이상) 그 유효성을 명시.
- **아모레퍼시픽(-15%)급 대형 손절**이 전체 수익을 갉아먹는 구조라면, **Stitch 3차 매수 후 시가 이탈 시 즉시 손절**·**Kiwoom 0624** 환경에서 **규칙 강제** 필요성을 설명.
- 지연 **{latency_ms:.0f}ms**로 인한 슬리피지를 **약 0.1~0.2%** 수준으로 가정해 언급하고, **매수 타점을 1틱 더 낮게** 잡을 것을 권고.

## 1) 사용자의 현재 수익 DNA인 '세력봉 중심선 지지' 전략의 유효성 검증
- 전체 지표(승률·손익비·기댓값)와 2월 대비 3월 성과 저하가 전략 실패인지 시장·실행 문제인지 구분하세요.

## 2) 3월 손익비 하락(2월 대비 PF가 약 0.97로 내려간 경우 등) — **평단가 조절 실패** 관점
- 아래 [평단가·꼬리 손실 휴리스틱]을 근거로 3월에 무엇이 달랐는지 설명하세요.
- 대형 손절 사례와 연결해 Stitch Controller **SL** 조정·**시가 이탈 기계 손절**을 구체적으로 제안하세요.

## 3) 지연시간 {latency_ms:.0f}ms를 고려했을 때, 실제 체결 오차(Slippage)가 수익률에 미친 영향 평가
- 초단타/세력봉 터치 전략에서 {latency_ms:.0f}ms가 체결가를 얼마나 밀 수 있는지 정성+간단 정량 가정으로 평가하세요.

[전체 집계 지표]
- 승률: {win_pct:.2f}%
- 손익비(PF): {metrics["profit_factor"]}
- 기댓값(트레이드당 %): {metrics["expectancy"]}
- 평균 익절: {metrics["avg_profit"]}%
- 평균 손절: {metrics["avg_loss"]}%

[2월 vs 3월 손익비 비교]
- 2월: {feb}
- 3월: {mar}
- PF 차이(2월-3월): {delta}

[평단가·꼬리 손실 휴리스틱(데이터 기반 요약)]
{averaging_blob}

[3월 대형 손절 요약]
{march_large_stop_summary}
""".strip()

        response = self._client.chat.completions.create(
            model=model,
            messages=[
                {
                    "role": "system",
                    "content": "You write concise, professional Korean trading analytics. Use markdown headings as requested.",
                },
                {"role": "user", "content": prompt},
            ],
            temperature=0.5,
        )
        return (response.choices[0].message.content or "").strip()

    def suggest_tp_sl_percentages(
        self,
        metrics: dict[str, float],
        feb_march: dict[str, Any],
        *,
        march_averaging_summary: str,
        coaching_excerpt: str = "",
        default_tp: float = 3.5,
        default_sl: float = 1.2,
        model: str = "gpt-4o-mini",
    ) -> dict[str, Any]:
        """
        JSON: { "tp_percent": float, "sl_percent": float, "rationale_ko": string }
        active_strategies.tp_percent / sl_percent 반영용.
        """
        if self._client is None:
            return {
                "tp_percent": default_tp,
                "sl_percent": max(0.9, default_sl - 0.15),
                "rationale_ko": "OpenAI 미설정: 보수적으로 SL 소폭 타이트.",
            }

        schema_hint = '{"tp_percent": 3.2, "sl_percent": 1.0, "rationale_ko": "..."}'
        user = f"""
Stitch Trader 위험 설정 제안. 출력은 **JSON 한 개만**(다른 텍스트 금지).
tp_percent: 목표 익절 % (보통 2.8~4.0), sl_percent: 손절 % 양수 (보통 0.85~1.35).
3월 PF가 2월보다 나쁘면 SL을 약간 타이트하게.

현재 기본값 TP={default_tp}%, SL={default_sl}%.
지표: {metrics}
2·3월: {feb_march}
평단가 휴리스틱: {march_averaging_summary}
리포트 요지(참고): {coaching_excerpt[:1200] if coaching_excerpt else "(없음)"}

스키마 예시: {schema_hint}
""".strip()

        response = self._client.chat.completions.create(
            model=model,
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": "Output only valid JSON. Numbers for tp_percent and sl_percent."},
                {"role": "user", "content": user},
            ],
            temperature=0.2,
        )
        raw = (response.choices[0].message.content or "").strip()
        try:
            data = json.loads(raw)
            tp = float(data["tp_percent"])
            sl = float(data["sl_percent"])
            rationale = str(data.get("rationale_ko", ""))
            return {"tp_percent": tp, "sl_percent": sl, "rationale_ko": rationale}
        except (json.JSONDecodeError, KeyError, TypeError, ValueError):
            return {
                "tp_percent": default_tp,
                "sl_percent": max(0.9, default_sl - 0.15),
                "rationale_ko": "JSON 파싱 실패 — 기본값 유지·SL만 소폭 타이트.",
            }


if __name__ == "__main__":
    data = {
        "종목명": ["한라캐스트", "나노팀", "아모레퍼시픽", "가온전선"],
        "return_pct": [0.33, -8.30, -15.37, -12.1],
        "status": ["익절", "손절", "손절", "손절"],
    }
    frame = pd.DataFrame(data)
    engine = StitchAnalyticsEngine()
    m = engine.calculate_metrics(frame)
    print("metrics:", m)
    # 코칭은 키가 있을 때만:
    # print(engine.get_ai_coaching(m, frame))
