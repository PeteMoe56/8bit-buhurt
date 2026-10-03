@echo off
setlocal
REM push_github.bat - pushes main to GitHub (PeteMoe56/8bit-buhurt) so Codemagic can build it.
cd /d "%~dp0"
git status -sb
echo.
git push origin main
if errorlevel 1 ( echo  [X] Push failed - see above. & pause & exit /b 1 )
echo.
echo  [OK] Pushed. In Codemagic: 8bit-buhurt - Start new build - workflow "iOS - TestFlight".
pause
endlocal
