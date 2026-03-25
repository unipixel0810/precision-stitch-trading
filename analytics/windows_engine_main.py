"""
Windows VPS용 Stitch 매매 엔진 진입점.

  PyInstaller: analytics 폴더에서 build_windows_engine.bat 실행 → dist\\StitchTraderEngine.exe

환경 변수(.env는 수동 로드 또는 python-dotenv — 여기서는 OS 환경 기준):
  SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
  STITCH_LATENCY_MS=14
  STITCH_BUY_LATENCY_TICKS=1

키움 OpenAPI+ 연동·0624 자동감시는 get_kiwoom_price / execute_kiwoom_order 에서 구현합니다.
"""

from __future__ import annotations

import os
import sys


def main() -> None:
    os.environ.setdefault("STITCH_LATENCY_MS", "14")
    os.environ.setdefault("STITCH_BUY_LATENCY_TICKS", "1")

    # PyInstaller 번들에서도 analytics 패키지 경로 인식
    root = os.path.dirname(os.path.abspath(__file__))
    if root not in sys.path:
        sys.path.insert(0, root)

    from stitch_server_engine import StitchServerEngine

    print(
        f"[StitchTraderEngine] latency_ms={os.environ.get('STITCH_LATENCY_MS', '14')} "
        f"buy_ticks={os.environ.get('STITCH_BUY_LATENCY_TICKS', '1')}",
        flush=True,
    )
    eng = StitchServerEngine()
    eng.run_engine()


if __name__ == "__main__":
    main()
