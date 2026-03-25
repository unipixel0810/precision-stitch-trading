"""
키움 OpenAPI+ 로그인 스모크 테스트 (PyQt5 + QAxWidget).

- Windows 전용. KHOpenAPI 모듈이 등록된 PC에서 실행.
- 키움 증권 FAQ: 보통 **32비트** Python + 해당 버전 OpenAPI 설치 필요.

  pip install -r requirements-kiwoom.txt
  python kiwoom_pyqt_login.py

자동 실행은 주석 해제하거나:  python -c "from kiwoom_pyqt_login import main; main()"
"""

from __future__ import annotations

import sys


def main() -> None:
    try:
        from PyQt5.QAxContainer import QAxWidget
        from PyQt5.QtWidgets import QApplication
    except ImportError as e:
        raise SystemExit(
            "PyQt5 가 필요합니다. Windows에서: pip install -r requirements-kiwoom.txt\n" f"원인: {e}"
        ) from e

    class KiwoomConnect:
        def __init__(self) -> None:
            self.app = QApplication(sys.argv)
            self.kiwoom = QAxWidget("KHOPENAPI.KHOpenAPICtrl.1")
            self.kiwoom.OnEventConnect.connect(self._handler_login)
            self._login()

        def _login(self) -> None:
            self.kiwoom.dynamicCall("CommConnect()")
            self.app.exec_()

        def _handler_login(self, err_code: int) -> None:
            if err_code == 0:
                print("키움 API 연결 성공")
                account_list = self.kiwoom.dynamicCall("GetLoginInfo(QString)", "ACCNO")
                accounts = str(account_list).rstrip(";").replace(";", ", ")
                print(f"계좌번호: {accounts}")
                self.app.quit()
            else:
                print(f"연결 실패 (에러코드: {err_code})")
                self.app.quit()

    KiwoomConnect()


if __name__ == "__main__":
    main()
