# =============================================================================
# Install script for psmux + Claude Code agent team shim
# Run from PowerShell: .\scripts\install.ps1
# =============================================================================

$ErrorActionPreference = "Stop"
$cargoBin = "$env:USERPROFILE\.cargo\bin"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  psmux + Claude Code Agent Team Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check psmux is installed
Write-Host "[1/4] Checking psmux..." -ForegroundColor Yellow
if (-not (Get-Command psmux -ErrorAction SilentlyContinue)) {
    Write-Host "  psmux not found. Installing via cargo..." -ForegroundColor DarkYellow
    cargo install psmux
} else {
    $ver = psmux version 2>&1
    Write-Host "  psmux found: $ver" -ForegroundColor Green
}

# Step 2: Backup psmux's tmux.exe alias
Write-Host "[2/4] Backing up psmux tmux.exe alias..." -ForegroundColor Yellow
$tmuxExe    = Join-Path $cargoBin "tmux.exe"
$tmuxBackup = Join-Path $cargoBin "tmux-psmux.exe"

if (Test-Path $tmuxExe) {
    if (-not (Test-Path $tmuxBackup)) {
        Move-Item $tmuxExe $tmuxBackup
        Write-Host "  Renamed tmux.exe → tmux-psmux.exe" -ForegroundColor Green
    } else {
        Write-Host "  Backup already exists (tmux-psmux.exe), skipping" -ForegroundColor DarkGreen
    }
} else {
    Write-Host "  tmux.exe not found (already replaced or not installed)" -ForegroundColor DarkGreen
}

# Step 3: Install shim scripts
Write-Host "[3/4] Installing tmux shim scripts..." -ForegroundColor Yellow

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Bash shim (for Git Bash / MSYS2)
$bashShim = Join-Path $scriptDir "tmux"
$bashDest  = Join-Path $cargoBin "tmux"
Copy-Item $bashShim $bashDest -Force
Write-Host "  Installed: $bashDest (bash shim)" -ForegroundColor Green

# CMD shim (for PowerShell / CMD)
$cmdShim = Join-Path $scriptDir "tmux.cmd"
$cmdDest  = Join-Path $cargoBin "tmux.cmd"
Copy-Item $cmdShim $cmdDest -Force
Write-Host "  Installed: $cmdDest (CMD/PowerShell shim)" -ForegroundColor Green

# Step 4: Verify
Write-Host "[4/4] Verifying installation..." -ForegroundColor Yellow

$tmuxVer = tmux -V 2>&1
if ($tmuxVer -match "tmux") {
    Write-Host "  tmux -V → $tmuxVer" -ForegroundColor Green
} else {
    Write-Host "  WARNING: tmux -V returned: $tmuxVer" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Installation complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open a new psmux session:" -ForegroundColor White
Write-Host "       psmux new-session -s default" -ForegroundColor DarkCyan
Write-Host "  2. Inside psmux, run Claude Code:" -ForegroundColor White
Write-Host "       claude --teammate-mode tmux" -ForegroundColor DarkCyan
Write-Host "  3. Ask Claude to spawn teammates!" -ForegroundColor White
Write-Host ""
Write-Host "See README.md for full usage guide." -ForegroundColor DarkGray
