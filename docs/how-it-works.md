# How It Works

## Background

Claude Code's agent team feature supports "split-pane mode" where each AI teammate
gets its own visible terminal pane. On macOS this works with **tmux** or **iTerm2**.
On Windows, nothing was officially supported — until now.

## The Problem

Claude Code detects tmux by checking the `$TMUX` environment variable.
[psmux](https://github.com/marlocarlo/psmux) is a native Windows tmux clone written
in Rust, and it **does** set `$TMUX` inside its panes. So in theory it should work.

In practice, three issues prevent it:

### Issue 1: `tmux -V` hangs

Claude Code calls `tmux -V` to check the version on startup.
psmux does not recognize the `-V` flag and launches its interactive TUI instead,
causing Claude Code to hang indefinitely waiting for output that never comes.

```
# Real tmux:
$ tmux -V
tmux 3.4          ← instant output ✅

# psmux (without shim):
$ psmux -V
[launches full TUI]  ← hangs forever ❌
```

### Issue 2: Format variables return empty

Claude Code calls `tmux list-panes -t <session> -F "#{pane_id}"` to enumerate
panes before spawning teammates. Inside a detached psmux pane,
`display-message -p '#{window_panes}'` and similar format queries return empty strings.

### Issue 3: Session name must be `default`

psmux's IPC socket path embeds the string `default` regardless of the actual
session name. When a child process inside a psmux pane calls `psmux` without
specifying `-t <session>`, it looks for session `default`. If the session has
a different name, the query fails with *"no server running on session 'default'"*.

## The Solution: tmux Compatibility Shim

We install two thin wrapper scripts that intercept specific tmux calls and
return correct responses, forwarding everything else to psmux:

```
tmux -V                        → echo "tmux 3.4"          (fixes Issue 1)
tmux display-message -p '#{window_panes}'  → query psmux  (fixes Issue 2)
tmux display-message -p '#{pane_id}'       → $TMUX_PANE   (fixes Issue 2)
tmux <anything else>           → exec psmux "$@"           (pass-through)
```

Two files are needed:
- **`tmux`** (bash script) — used by Git Bash / MSYS2
- **`tmux.cmd`** (batch file) — used by PowerShell / CMD (native Windows)

Both are placed in `~/.cargo/bin/` which is in PATH, **ahead** of psmux's
original `tmux.exe` (which we rename to `tmux-psmux.exe`).

## What Claude Code Actually Calls

Extracted from the Claude Code binary via string analysis:

```javascript
// Version check on startup
["tmux", "-V"]

// Detect pane layout before spawning teammate
["tmux", "list-panes", "-t", sessionName, "-F", "#{pane_id}"]

// Spawn a new teammate pane
["tmux", "split-window", "-h", "-t", session, "--", "claude", ...]

// Send keystrokes to teammate
["tmux", "send-keys", "-t", paneId, text, "Enter"]

// Clean up
["tmux", "kill-pane", "-t", paneId]
["tmux", "kill-session", "-t", sessionName]
```

All of these work correctly through psmux once the shim handles `tmux -V`
and the session is named `default`.

## Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│  psmux session (name: "default")                    │
│                                                     │
│  ┌──────────────────┐  ┌──────────────────────────┐ │
│  │ Pane 1           │  │ Pane 2                   │ │
│  │ Claude Code      │  │ Claude Code (teammate)   │ │
│  │ @alpha (Lead)    │  │ @bravo                   │ │
│  │                  │  │                          │ │
│  │ calls:           │  └──────────────────────────┘ │
│  │  tmux split-window → shim → psmux split-window   │
│  │  tmux send-keys    → shim → psmux send-keys      │
│  └──────────────────┘                               │
│                                                     │
│  ┌─────────────────────────────────────────────┐   │
│  │ tmux shim intercepts:                       │   │
│  │   -V              → "tmux 3.4"              │   │
│  │   display-message → psmux queries / env     │   │
│  │   everything else → psmux passthrough       │   │
│  └─────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────┘
```

## Context on Prior Art

The only previously known method for Claude Code agent teams with split panes
on Windows was via WSL (Ubuntu), using tmux inside the Linux subsystem and
syncing the working directory back to Windows — a significant overhead.

This project achieves the same result natively on Windows without WSL,
using psmux as the multiplexer backend.

## Tested Environment

- Windows 11
- psmux v0.3.9 (Rust)
- Claude Code v2.1.50
- Git Bash / MSYS2 (bash shim) + PowerShell (cmd shim)
- Session name must be `default` (psmux v0.3.9 limitation)
