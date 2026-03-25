"""
KRX 주식 호가단위(틱) 스냅 및 14ms 지연을 고려한 1틱 보정(매수선 하향 등).
실제 키움 체결가와 비교 검증 후 단위 규칙을 조정하세요.
"""

from __future__ import annotations

import math


def krx_tick_size_krw(price: float) -> int:
    """원 단위 현재가 구간에 따른 최소 호가 단위(원)."""
    p = abs(price)
    if p < 1_000:
        return 1
    if p < 5_000:
        return 5
    if p < 10_000:
        return 10
    if p < 50_000:
        return 50
    if p < 100_000:
        return 100
    if p < 500_000:
        return 500
    return 1_000


def snap_price_to_tick(price: float, *, downward: bool = False) -> float:
    """가장 가까운 호가(동일 틱 배수)로 맞춤. downward=True면 내림."""
    if price == 0:
        return 0.0
    tick = krx_tick_size_krw(price)
    q = price / tick
    if downward:
        snapped = math.floor(q) * tick
    else:
        snapped = round(q) * tick
    return float(int(snapped))


def adjust_line_for_latency_buy(line_price: float, ticks_lower: int = 1) -> float:
    """
    지연·슬리피지 보정: 매수 기준선을 N틱 낮춤(더 보수적 체결 구간).
    """
    if ticks_lower <= 0:
        return snap_price_to_tick(line_price)
    p = line_price
    for _ in range(ticks_lower):
        t = krx_tick_size_krw(p)
        p -= t
    return snap_price_to_tick(p, downward=True)


def adjust_line_for_latency_sell(line_price: float, ticks_higher: int = 1) -> float:
    """매도(익절) 기준을 N틱 높임."""
    if ticks_higher <= 0:
        return snap_price_to_tick(line_price)
    p = line_price
    for _ in range(ticks_higher):
        t = krx_tick_size_krw(p)
        p += t
    return float(int(snap_price_to_tick(p)))

