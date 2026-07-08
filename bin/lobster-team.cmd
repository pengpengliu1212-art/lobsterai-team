@echo off
REM ========================================
REM lobsterai-team CLI entry point (Windows cmd)
REM ========================================

setlocal

set "SCRIPT_DIR=%~dp0"
set "TEAM_ROOT=%SCRIPT_DIR%.."
set "PYTHON_CORE=%TEAM_ROOT%\bin\lobster_team\__main__.py"

REM Pick Python
set "PYTHON="
where python3 >nul 2>&1 && set "PYTHON=python3" && goto :run
where python >nul 2>&1 && set "PYTHON=python" && goto :run
where py >nul 2>&1 && set "PYTHON=py -3" && goto :run

echo [ERR] python3 not found in PATH 1>&2
echo       install Python 3.8+ first 1>&2
exit /b 1

:run
if not exist "%PYTHON_CORE%" (
    echo [ERR] lobster-team core not found at %PYTHON_CORE% 1>&2
    exit /b 1
)

%PYTHON% "%PYTHON_CORE%" %*
exit /b %ERRORLEVEL%
