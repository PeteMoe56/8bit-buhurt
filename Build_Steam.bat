@echo off
REM Build_Steam.bat - the Steam build for 8-Bit Buhurt: Combat Club (Windows + Linux), uploaded with SteamPipe.
REM steamcmd asks for your Steam password and Steam Guard code itself; nothing here stores them.
REM Nothing goes live: set the uploaded build live in Steamworks > SteamPipe > Builds.
REM   Build_Steam.bat              export both, write the SteamPipe scripts, upload
REM   Build_Steam.bat noupload     export and script only (try the builds first)
cd /d "%~dp0"
title Combat Club - Steam build
if /i "%~1"=="noupload" (
  powershell -NoProfile -ExecutionPolicy Bypass -File tools\steam_build.ps1 -NoUpload
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File tools\steam_build.ps1
)
pause
