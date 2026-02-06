@echo off
setlocal EnableExtensions EnableDelayedExpansion

title Domin.cmd - Remote PowerShell Runner
color 0A
mode con: cols=90 lines=35

:: ================================
:: Admin check + auto-elevate
:: ================================
net session >nul 2>&1
if %errorlevel% neq 0 (
  cls
  echo ===========================================
  echo   Administrator privileges required!
  echo   Relaunching with admin rights...
  echo ===========================================
  powershell -NoProfile -Command "Start-Process '%~f0' -Verb RunAs"
  exit /b
)

set "TMPPS=%TEMP%\domin_remote.ps1"

:menu
cls
echo =============================================================
echo  Domin.cmd - Remote PowerShell Runner

echo =============================================================
echo.
echo  [1] Safe Run (download ^> preview ^> confirm ^> run)
echo  [2] Safe Download Only (save to TEMP and open in Notepad)
echo  [3] Direct Run (irm ^| iex)  ^(DANGEROUS^)
echo  [4] Run Local .ps1 file

echo  [0] Exit

echo -------------------------------------------------------------
echo Choose a menu option using your keyboard [1,2,3,4,0] :
echo -------------------------------------------------------------
set /p opt=^>^> 

if "%opt%"=="1" goto saferun
if "%opt%"=="2" goto download
if "%opt%"=="3" goto direct
if "%opt%"=="4" goto local
if "%opt%"=="0" exit /b

echo Invalid choice!
pause
goto menu

:geturl
set "URL="
echo.
set /p URL=Enter script URL (https://.../something.ps1) : 
if not defined URL (
  echo URL is empty.
  pause
  goto menu
)
exit /b 0

:download
call :geturl
cls
echo Downloading script...

powershell -NoProfile -ExecutionPolicy Bypass -Command "^$u='%URL%'; if(-not ^$u.StartsWith('http')){throw 'URL must start with http/https'}; ^$c=(Invoke-WebRequest -UseBasicParsing -Uri ^$u).Content; ^$p='%TMPPS%'; ^$c ^| Set-Content -LiteralPath ^$p -Encoding UTF8; Write-Host 'Saved to:' ^$p"
if errorlevel 1 (
  echo.
  echo Download failed.
  pause
  goto menu
)

echo.
echo Opening in Notepad so you can inspect it...
notepad "%TMPPS%"

echo.
echo Done.
pause
goto menu

:saferun
call :geturl
cls
echo Downloading script...

powershell -NoProfile -ExecutionPolicy Bypass -Command "^$u='%URL%'; if(-not ^$u.StartsWith('http')){throw 'URL must start with http/https'}; ^$c=(Invoke-WebRequest -UseBasicParsing -Uri ^$u).Content; ^$p='%TMPPS%'; ^$c ^| Set-Content -LiteralPath ^$p -Encoding UTF8; Write-Host 'Saved to:' ^$p"
if errorlevel 1 (
  echo.
  echo Download failed.
  pause
  goto menu
)

echo.
echo ===================== PREVIEW (first 60 lines) =====================
powershell -NoProfile -Command "Get-Content -LiteralPath '%TMPPS%' -TotalCount 60"
echo ====================================================================
echo.
set /p ok=Run this script now? (Y/N) : 
if /I not "%ok%"=="Y" (
  echo Cancelled.
  pause
  goto menu
)

cls
echo Running downloaded script...

powershell -NoProfile -ExecutionPolicy Bypass -File "%TMPPS%"

echo.
echo Finished.
pause
goto menu

:direct
call :geturl
cls
echo WARNING: This runs remote code immediately (irm ^| iex).
echo Only continue if you 100%% trust the source.
echo.
set /p ok=Continue? (Y/N) : 
if /I not "%ok%"=="Y" goto menu

powershell -NoProfile -ExecutionPolicy Bypass -Command "irm '%URL%' | iex"

echo.
echo Finished.
pause
goto menu

:local
cls
echo Enter full path to a local PowerShell script (.ps1)
echo Example: C:\Scripts\my.ps1
set /p LPS=Path : 
if not defined LPS goto menu
if not exist "%LPS%" (
  echo File not found.
  pause
  goto menu
)

cls
echo Running: %LPS%
powershell -NoProfile -ExecutionPolicy Bypass -File "%LPS%"

echo.
echo Finished.
pause
goto menu
