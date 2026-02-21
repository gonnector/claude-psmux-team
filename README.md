# Claude Code Agent Teams on Windows — psmux Split Panes

> **World's first native Windows solution** for running Claude Code agent teams
> in split terminal panes — without WSL, without Cygwin, without any Linux subsystem.

![Windows](https://img.shields.io/badge/Windows-11-blue?logo=windows)
![psmux](https://img.shields.io/badge/psmux-v0.3.9-orange)
![Claude Code](https://img.shields.io/badge/Claude_Code-v2.1.50-blueviolet)
![License](https://img.shields.io/badge/license-MIT-green)

## What This Does

Claude Code's [agent team feature](https://code.claude.com/docs/en/agent-teams)
lets you spawn multiple AI teammates that collaborate on tasks in parallel.
In split-pane mode, each teammate gets its own visible terminal pane — you can
watch all of them working simultaneously.

This is officially supported on macOS via **tmux** or **iTerm2**.
On **Windows**, it was previously only possible inside WSL (Ubuntu) —
requiring syncing files between Windows and the Linux subsystem.

**This project makes it work natively on Windows** using
[psmux](https://github.com/marlocarlo/psmux), a Rust-based tmux clone
that runs without WSL.

```
psmux session
┌─────────────────────────┬──────────────────────────────┐
│ Pane 1  @alpha (Lead)   │ Pane 2  @bravo (Teammate 1) │
│ Claude Code v2.1.50     │ Claude Code v2.1.50          │
│ Opus 4.6                │ Opus 4.6                     │
├─────────────────────────┴──────────────────────────────┤
│ Pane 3  @bravo (Teammate 2)                            │
│ Claude Code v2.1.50                                    │
└────────────────────────────────────────────────────────┘
```

## Prior Art

The only previously known Windows approach was WSL-based:
[treylom/claude-agent-teams-setup](https://github.com/treylom/claude-agent-teams-setup)
— runs tmux inside Ubuntu on WSL, then syncs the working directory back to Windows.
This project eliminates that overhead entirely.

## Requirements

- Windows 10/11
- [Rust / Cargo](https://rustup.rs/) (to install psmux)
- [Claude Code](https://code.claude.com/) v2.1.40+
- Git Bash or MSYS2 (for the bash shim)
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` enabled

## Quick Install

```powershell
# 1. Install psmux
cargo install psmux

# 2. Clone this repo
git clone https://github.com/YOUR_USERNAME/claude-psmux-team
cd claude-psmux-team

# 3. Run the installer
.\scripts\install.ps1
```

## Manual Install

```powershell
# 1. Install psmux
cargo install psmux

# 2. Backup psmux's tmux alias
Rename-Item "$env:USERPROFILE\.cargo\bin\tmux.exe" "tmux-psmux.exe"

# 3. Copy shim scripts
Copy-Item scripts\tmux     "$env:USERPROFILE\.cargo\bin\tmux"      # Git Bash
Copy-Item scripts\tmux.cmd "$env:USERPROFILE\.cargo\bin\tmux.cmd"  # PowerShell
```

## Enable Agent Teams

Add to `~/.claude/settings.json`:
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## Usage

```powershell
# Start a psmux session (must be named 'default')
psmux new-session -s default

# Inside the psmux session, launch Claude Code
claude --teammate-mode tmux

# Then ask Claude to spawn teammates:
# "Spawn 2 teammates to research X and Y in parallel"
```

Or use the launch script:
```powershell
.\scripts\launch.ps1
```

## Why It Doesn't Work Out of the Box

Claude Code and psmux have 3 incompatibilities. See [docs/how-it-works.md](docs/how-it-works.md)
for the full technical explanation. In short:

| Issue | Symptom | Fix |
|-------|---------|-----|
| `tmux -V` launches psmux TUI | Claude Code hangs on startup | Shim returns `"tmux 3.4"` |
| Format vars return empty in panes | Teammate spawn fails with "Could not determine pane count" | Shim intercepts and returns correct values |
| Session name must be `default` | `psmux list-panes` fails inside pane | Always name your session `default` |

## Contributing

Issues and PRs welcome! See [docs/issues-and-improvements.md](docs/issues-and-improvements.md)
for the full list of known issues and suggested improvements for:
- psmux
- Claude Code
- This shim

## Related Issues

- [anthropics/claude-code#24384](https://github.com/anthropics/claude-code/issues/24384) — Add Windows Terminal as split-pane backend
- [marlocarlo/psmux](https://github.com/marlocarlo/psmux) — psmux project

## License

MIT
