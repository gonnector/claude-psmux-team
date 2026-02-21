@echo off
:: =============================================================================
:: tmux compatibility shim for psmux (Windows CMD / PowerShell version)
:: Enables Claude Code agent team split-pane mode on native Windows via psmux
::
:: This .cmd file is needed because PowerShell cannot execute bash shebangs.
:: It mirrors the logic of the bash `tmux` script for Windows environments.
::
:: Install:
::   copy scripts\tmux.cmd %USERPROFILE%\.cargo\bin\tmux.cmd
:: =============================================================================
setlocal EnableDelayedExpansion

if "%~1"=="-V" (
    echo tmux 3.4
    exit /b 0
)

if "%~1"=="display-message" (
    set "FORMAT="
    set "NEXT=0"
    for %%A in (%*) do (
        if "!NEXT!"=="1" (
            set "FORMAT=%%A"
            set "NEXT=0"
        )
        if "%%A"=="-p" set "NEXT=1"
    )

    echo !FORMAT! | findstr /C:"window_panes" >nul 2>&1
    if !ERRORLEVEL!==0 (
        for /f %%C in ('psmux list-panes 2^>nul ^| find /c /v ""') do echo %%C
        exit /b 0
    )

    echo !FORMAT! | findstr /C:"pane_id" >nul 2>&1
    if !ERRORLEVEL!==0 (
        if defined TMUX_PANE (echo !TMUX_PANE!) else (echo %%1)
        exit /b 0
    )

    echo !FORMAT! | findstr /C:"session_name" >nul 2>&1
    if !ERRORLEVEL!==0 (
        echo default
        exit /b 0
    )

    echo !FORMAT! | findstr /C:"window_id" >nul 2>&1
    if !ERRORLEVEL!==0 (
        echo @1
        exit /b 0
    )

    echo !FORMAT! | findstr /C:"window_index" >nul 2>&1
    if !ERRORLEVEL!==0 (
        echo 1
        exit /b 0
    )
)

:: send-keys / kill-pane: psmux cannot resolve pane IDs (%N) to sessions.
:: Rewrite: -t %N  →  -t default:%N
if "%~1"=="send-keys" (
    set "PANEID=%~3"
    set "TARGET=default:!PANEID!"
    echo !TIME! SEND-KEYS: -t !TARGET! key=%~5 >> "%TEMP%\psmux-shim.log" 2>&1
    psmux send-keys %~2 "!TARGET!" "%~4" %~5 %~6 %~7 %~8 %~9
    exit /b %ERRORLEVEL%
)

if "%~1"=="kill-pane" (
    set "PANEID=%~3"
    set "TARGET=default:!PANEID!"
    echo !TIME! KILL-PANE rewritten: %~2 !TARGET! >> "%TEMP%\psmux-shim.log" 2>&1
    psmux kill-pane %~2 "!TARGET!"
    exit /b %ERRORLEVEL%
)

:: split-window: rewrite target + avoid %* re-expansion bug.
:: CRITICAL: Do NOT use "psmux %*" here.
::   %* contains "%1" (the pane ID). CMD re-expands %1 as the 1st batch arg
::   ("split-window"), so psmux receives -t split-window (invalid) and crashes.
:: Fix: extract args positionally (%~3 = pane ID, %~4..%~9 = rest).
::      Add session prefix same as send-keys: default:PANEID.
:: IMPORTANT: only redirect stderr to log — stdout must reach Claude Code (pane ID).
if "%~1"=="split-window" (
    set "SPLIT_PANE=%~3"
    echo !TIME! SPLIT: -t default:!SPLIT_PANE! %~4 %~5 %~6 %~7 %~8 %~9 >> "%TEMP%\psmux-shim.log" 2>&1
    ping -n 3 -w 1000 127.0.0.1 >nul 2>&1
    psmux split-window -t "default:!SPLIT_PANE!" %~4 %~5 %~6 %~7 %~8 %~9 2>>"%TEMP%\psmux-shim.log"
    set "SPLIT_EXIT=!ERRORLEVEL!"
    echo !TIME! SPLIT EXIT: !SPLIT_EXIT! >> "%TEMP%\psmux-shim.log" 2>&1
    exit /b !SPLIT_EXIT!
)

:: Fallback: pass all arguments to psmux
psmux %*
