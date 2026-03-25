"""
키움 로그인 후 계좌번호(ACCNO)를 Supabase `kiwoom_accounts`에 upsert.

Windows + PyQt5 + OpenAPI+ 필수.
  pip install -r requirements.txt -r requirements-kiwoom.txt
  .env 에 SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY (또는 ANON_KEY)

실행: python kiwoom_account_sync.py

주의: 원본 스니펫의 active_strategies + SYSTEM_ACC 는 스키마 불일치·덮어쓰기 문제가 있어
별도 테이블로 분리함. 마이그레이션: supabase/migrations/20250331100000_kiwoom_accounts.sql
"""

from __future__ import annotations

import os
import sys
from datetime import datetime, timezone


def _utc_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _supabase():
    try:
        from supabase import create_client
    except ImportError as e:
        raise SystemExit(f"pip install supabase\n{e}") from e

    try:
        from dotenv import load_dotenv

        load_dotenv()
    except ImportError:
        pass

    url = os.environ.get("SUPABASE_URL", "").strip()
    key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY", "").strip() or os.environ.get("SUPABASE_ANON_KEY", "").strip()
    if not url or not key:
        raise SystemExit("SUPABASE_URL 및 SUPABASE_SERVICE_ROLE_KEY(권장) 또는 SUPABASE_ANON_KEY 를 설정하세요.")
    return create_client(url, key)


def main() -> None:
    try:
        from PyQt5.QAxContainer import QAxWidget
        from PyQt5.QtWidgets import QApplication
    except ImportError as e:
        raise SystemExit(f"Windows에서 PyQt5 필요: pip install PyQt5\n{e}") from e

    supabase = _supabase()

    class KiwoomAccountSync:
        def __init__(self) -> None:
            self.app = QApplication(sys.argv)
            self.kiwoom = QAxWidget("KHOPENAPI.KHOpenAPICtrl.1")
            self.kiwoom.OnEventConnect.connect(self._on_login)
            self._login()

        def _login(self) -> None:
            print("키움 API 로그인(CommConnect)...")
            self.kiwoom.dynamicCall("CommConnect()")
            self.app.exec_()

        def _on_login(self, err_code: int) -> None:
            if err_code == 0:
                print("로그인 성공. 계좌 동기화 중...")
                self._sync_accounts()
            else:
                print(f"로그인 실패 (에러코드: {err_code})")
            self.app.quit()

        def _sync_accounts(self) -> None:
            account_str = self.kiwoom.dynamicCall("GetLoginInfo(QString)", "ACCNO")
            raw = str(account_str).strip()
            account_list = [a.strip() for a in raw.rstrip(";").split(";") if a.strip()]

            print(f"발견된 계좌: {account_list}")

            for acc_no in account_list:
                try:
                    supabase.table("kiwoom_accounts").upsert(
                        {
                            "account_no": acc_no,
                            "display_label": f"키움_{acc_no}",
                            "is_active": True,
                            "synced_at": _utc_iso(),
                        },
                        on_conflict="account_no",
                    ).execute()
                    print(f"Supabase 반영: {acc_no}")
                except Exception as e:
                    print(f"Supabase 오류 ({acc_no}): {e!r}")

    KiwoomAccountSync()


if __name__ == "__main__":
    main()
