@echo off
REM Build_Store.bat - the signed Google Play bundle (AAB) for 8-Bit Buhurt: Combat Club.
REM Built here with the upload key at C:\Dev\keys, like ACTM. Asks for the key password.
REM Output: build\combat-club-<name>-<code>.aab  -> upload it in Play Console by hand.
REM   Build_Store.bat            next version code (last + 1), name 1.0.0
REM   Build_Store.bat 1.0.1      next code, that version name
cd /d "%~dp0"
title Combat Club - Play bundle
REM android_check only looks and prints; a FAIL line there names what the export will trip on.
powershell -NoProfile -ExecutionPolicy Bypass -File tools\android_check.ps1
if "%~1"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -File tools\aab_store.ps1
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File tools\aab_store.ps1 -Name "%~1"
)
pause
