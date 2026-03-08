@echo off
:: =============================================================================
:: Minimal tmux shim for psmux v0.4.10+ (CMD / PowerShell version)
::
:: psmux v0.4.10 handles all tmux commands natively. The ONLY remaining issue
:: is that "tmux -V" returns "tmux 0.4.10" — Claude Code requires version 2+
:: and disables split-pane mode for lower versions.
::
:: This shim intercepts -V and spoofs the version. Everything else passes
:: directly to psmux's tmux binary (psmux-tmux).
::
:: Install:
::   rename %USERPROFILE%\.cargo\bin\tmux.exe tmux-real.exe
::   copy scripts\tmux.cmd %USERPROFILE%\.cargo\bin\tmux.cmd
:: =============================================================================
if "%~1"=="-V" (
    echo tmux 3.4
    exit /b 0
)
tmux-real %*
