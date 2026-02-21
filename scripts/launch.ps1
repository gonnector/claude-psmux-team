# =============================================================================
# launch.ps1 — One-click launcher for Claude Code agent team in psmux
# Usage: .\scripts\launch.ps1 [-SessionName default] [-SkipPermissions]
# =============================================================================

param(
    [string]$SessionName = "default",
    [switch]$SkipPermissions
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "  Launching Claude Code agent team in psmux..." -ForegroundColor Cyan
Write-Host "  Session: $SessionName" -ForegroundColor DarkCyan
Write-Host ""

# Kill any stale psmux session with this name
psmux kill-session -t $SessionName 2>$null

# Create fresh detached session (MUST be named 'default' for psmux self-query to work)
psmux new-session -d -s $SessionName
Start-Sleep -Milliseconds 500

# Build claude command
$claudeCmd = "claude --teammate-mode tmux"
if ($SkipPermissions) {
    $claudeCmd += " --dangerously-skip-permissions"
}

# Launch Claude Code inside psmux pane
# Unset CLAUDECODE to allow running inside another Claude session (for testing)
$fullCmd = "`$env:CLAUDECODE=`$null; $claudeCmd"
psmux send-keys -t $SessionName $fullCmd Enter

Write-Host "  Claude Code launched inside psmux session '$SessionName'" -ForegroundColor Green
Write-Host ""
Write-Host "  To attach and see the split panes:" -ForegroundColor Yellow
Write-Host "    psmux attach -t $SessionName" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  Tip: Ask Claude to create a team:" -ForegroundColor Yellow
Write-Host "    'Spawn 2 teammates and have them work on X in parallel'" -ForegroundColor DarkGray
