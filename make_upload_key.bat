@echo off
setlocal
REM make_upload_key.bat - creates the Google Play UPLOAD key for 8-Bit Buhurt: Combat Club.
REM Writes C:\Dev\keys\combatclub-upload.jks (OUTSIDE the repo - never commit it).
REM keytool asks you for a password (type it twice) and your name/org. Use ONE password:
REM PKCS12 uses the same one for the store and the key, which is what Godot and Codemagic expect.
set "OUT=C:\Dev\keys\combatclub-upload.jks"
if exist "%OUT%" (
  echo  [X] %OUT% already exists - not overwriting it.
  pause & exit /b 1
)
set "KT="
for %%P in ("%JAVA_HOME%\bin\keytool.exe" "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" "C:\Program Files\Android\Android Studio\jre\bin\keytool.exe") do if exist %%P set "KT=%%~P"
if not defined KT for /f "delims=" %%K in ('where keytool 2^>nul') do if not defined KT set "KT=%%K"
if not defined KT (
  echo  [X] keytool not found. Install Android Studio, or set JAVA_HOME to a JDK, then run this again.
  pause & exit /b 1
)
if not exist "C:\Dev\keys" mkdir "C:\Dev\keys"
echo  Using %KT%
echo.
"%KT%" -genkeypair -v -keystore "%OUT%" -storetype PKCS12 -alias upload -keyalg RSA -keysize 2048 -validity 10000
if errorlevel 1 ( echo  [X] keytool failed. & pause & exit /b 1 )
echo.
echo  [OK] %OUT%
echo  Next: Codemagic - Team settings - Code signing identities - Android keystores - Add.
echo        Reference name: combatclub_upload   Alias: upload   Password: the one you just typed (both fields).
echo  Back the file up with your other keys. Losing it means a key reset request to Google.
pause
endlocal
