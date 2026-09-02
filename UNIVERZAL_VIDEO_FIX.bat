@echo off
setlocal EnableExtensions
cd /d "%~dp0"

set "PATCHER=%~dp0video_fix.ps1"

if not exist "%PATCHER%" (
    echo CHYBA: Chyba video_fix.ps1
    pause
    exit /b 1
)

if "%~1"=="" (
    if exist "%~dp0lieu.exe" (
        set "TARGET=%~dp0lieu.exe"
    ) else (
        echo.
        echo Pouzitie:
        echo   1. Poloz tento BAT a PS1 vedla lieu.exe a spusti BAT dvojklikom.
        echo   alebo
        echo   2. Pretiahni lieu.exe na tento BAT subor.
        echo.
        pause
        exit /b 2
    )
) else (
    set "TARGET=%~f1"
)

if not exist "%TARGET%" (
    echo.
    echo CHYBA: lieu.exe neexistuje:
    echo   "%TARGET%"
    pause
    exit /b 2
)

for %%I in ("%TARGET%") do set "TARGETDIR=%%~dpI"

REM ------------------------------------------------------------
REM Test actual write access to the game directory.
REM This is more reliable than guessing from Program Files/admin state.
REM ------------------------------------------------------------
set "WRITETEST=%TARGETDIR%.__lieu_patch_write_test_%RANDOM%_%RANDOM%.tmp"
> "%WRITETEST%" echo test 2>nul

if exist "%WRITETEST%" (
    del /f /q "%WRITETEST%" >nul 2>&1
    goto :RUN_PATCHER
)

REM ------------------------------------------------------------
REM No write access: elevate by launching cmd.exe through UAC.
REM cmd.exe then re-runs THIS BAT with the original lieu.exe path.
REM Environment variables avoid fragile nested PowerShell quoting.
REM ------------------------------------------------------------
echo.
echo Patcher nema pravo zapisovat do:
echo   "%TARGETDIR%"
echo.
echo Windows teraz zobrazi UAC dialog.
echo Po potvrdeni sa patcher automaticky spusti znova ako administrator.
echo.

set "PATCH_SELF=%~f0"
set "PATCH_TARGET=%TARGET%"
set ELEVATE_ARGS=/d /c ""%PATCH_SELF%" "%PATCH_TARGET%""

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -Command ^
  "try { Start-Process -FilePath $env:ComSpec -ArgumentList $env:ELEVATE_ARGS -Verb RunAs; exit 0 } catch { Write-Host $_.Exception.Message -ForegroundColor Red; exit 1 }"

if errorlevel 1 (
    echo.
    echo CHYBA: Nepodarilo sa spustit zvyseny proces cez UAC.
    pause
    exit /b 1
)

REM Elevated copy of this BAT now owns the rest of the work.
exit /b 0

:RUN_PATCHER
echo.
echo Strateny v Europe - universal video fix
echo.
echo Pravo na zapis do adresara hry: OK
echo.
echo POZOR: tento patcher priamo nahradi:
echo   "%TARGET%"
echo.
echo Ak budes chciet povodny subor, obnov ho z instalacky hry.
echo.

REM Bypass applies only to this PowerShell process.
REM It does not permanently modify system/user Execution Policy.
powershell.exe -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass ^
    -File "%PATCHER%" "%TARGET%"

set "RC=%ERRORLEVEL%"
echo.
if "%RC%"=="0" (
    echo Hotovo.
) else (
    echo Patcher skoncil s chybou ^(kod %RC%^).
)
pause
exit /b %RC%
