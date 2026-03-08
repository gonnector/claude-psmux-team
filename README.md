🇺🇸 English | [🇰🇷 한국어](README.ko.md)

---

# Claude Code Agent Teams on Windows — psmux Split Panes

> **World's first native Windows solution** for running Claude Code agent teams
> in split terminal panes — without WSL, without Cygwin, without any Linux subsystem.

![Windows](https://img.shields.io/badge/Windows-11-blue?logo=windows)
![psmux](https://img.shields.io/badge/psmux-v0.4.10-orange)
![Claude Code](https://img.shields.io/badge/Claude_Code-v2.1.71-blueviolet)
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
psmux session (current behavior)
┌──────────────────────────┬───────────────────────────────┐
│ Pane 1  Lead             │ Pane 2  Teammates (cycling)   │
│ Claude Code v2.1.50      │ @alpha → completes            │
│ Opus 4.6 · orchestrating │ @beta  → completes            │
│                          │ @gamma → completes            │
└──────────────────────────┴───────────────────────────────┘
 shift-tab to cycle between active teammates
```

> **Note**: Claude Code currently creates one shared pane for all teammates
> (they run sequentially). Per-teammate panes (as on macOS) require a Claude
> Code update. See [docs/issues-and-improvements.md](docs/issues-and-improvements.md).

## Prior Art

The only previously known Windows approach was WSL-based:
[treylom/claude-agent-teams-setup](https://github.com/treylom/claude-agent-teams-setup)
— runs tmux inside Ubuntu on WSL, then syncs the working directory back to Windows.
This project eliminates that overhead entirely.

## Requirements

- Windows 10/11
- [Rust / Cargo](https://rustup.rs/) (to install psmux)
- [Claude Code](https://code.claude.com/) v2.1.40+
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` enabled

## Install

### 1. Install psmux

```powershell
cargo install psmux   # v0.4.10+ required
```

### 2. Install the version-spoof shim

psmux v0.4.10 handles all tmux commands natively, but `tmux -V` returns
`"tmux 0.4.10"` — Claude Code requires version 2+ and silently falls back
to in-process mode. Additionally, Node.js `spawn` only finds `.exe` files
on Windows, so a compiled shim is required.

```powershell
git clone https://github.com/gonnector/claude-psmux-team
cd claude-psmux-team

# Rename psmux's tmux binary (name must start with "tmux" for tmux mode)
Rename-Item "$env:USERPROFILE\.cargo\bin\tmux.exe" "tmux-real.exe"

# Option A: Compile the shim (requires gcc / MSYS2)
gcc -O2 -o "$env:USERPROFILE\.cargo\bin\tmux.exe" scripts/tmux-shim.c

# Option B: Use pre-built shim (if gcc is not available)
Copy-Item scripts/tmux.exe "$env:USERPROFILE\.cargo\bin\tmux.exe"
```

The shim intercepts `tmux -V` → returns `"tmux 3.4"`, passes everything
else to `tmux-real.exe` (psmux in tmux-compatible mode).

<details>
<summary><strong>Using psmux v0.3.x?</strong> (legacy full shim required)</summary>

psmux v0.3.x does not handle `tmux -V`, `display-message` format variables,
or bare pane IDs in `send-keys`. You need the full compatibility shim
(not just version spoof). See [docs/shim-v0.3.x.md](docs/shim-v0.3.x.md).

</details>

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

## Compatibility Matrix

| Feature | psmux v0.3.9 | psmux v0.4.10+ |
|---------|:---:|:---:|
| `tmux -V` version output | Shim required | Native |
| `display-message` format vars | Shim required | Native |
| `send-keys -t %N` (bare pane ID) | Shim required | Native |
| `split-window -P -F #{pane_id}` | Shim required | Native |
| `kill-pane -t %N` | Shim required | Native |
| Per-teammate panes | Not supported | Not supported* |

*\*Claude Code creates 1 split for all teammates. This is a Claude Code behavior, not a psmux limitation.*

## Contributing

Issues and PRs welcome! See [docs/issues-and-improvements.md](docs/issues-and-improvements.md)
for the full list of known issues and suggested improvements for psmux, Claude Code, and this project.

## Related Issues

- [anthropics/claude-code#24384](https://github.com/anthropics/claude-code/issues/24384) — Add Windows Terminal as split-pane backend
- [marlocarlo/psmux#42](https://github.com/marlocarlo/psmux/issues/42) — tmux compatibility issues (resolved in v0.4.10)

## License

MIT
