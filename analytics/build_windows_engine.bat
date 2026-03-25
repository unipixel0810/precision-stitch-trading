@echo off
REM Windows Server / VPS — analytics 폴더에서 더블클릭 또는 cmd로 실행
cd /d "%~dp0"

python -m pip install -q -r requirements.txt
python -m pip install -q pyinstaller

pyinstaller --noconfirm --onefile --console --name StitchTraderEngine ^
  --paths "%CD%" ^
  windows_engine_main.py

echo.
echo Build complete: dist\StitchTraderEngine.exe
echo Supabase 키는 서버 환경 변수 또는 .env 로더를 함께 배포하세요.
pause
