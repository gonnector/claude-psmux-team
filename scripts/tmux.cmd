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

:: Fallback: pass all arguments to psmux
psmux %*
