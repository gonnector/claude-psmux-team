# Legacy Shim for psmux v0.3.x

> **Note**: This shim is **no longer needed** with psmux v0.4.10+.
> It is preserved here for historical reference only.

## What the Shim Fixed

psmux v0.3.9 had 5 incompatibilities with Claude Code's tmux expectations.
Two shim scripts (`scripts/tmux` for bash, `scripts/tmux.cmd` for CMD/PowerShell)
intercepted tmux calls and patched them before forwarding to psmux.

### 1. `tmux -V` → returned `"tmux 3.4"` instead of launching TUI
### 2. `display-message` → returned hardcoded format variable values
### 3. `send-keys -t %N` → rewrote to `-t default:%N` (session prefix)
### 4. `kill-pane -t %N` → rewrote to `-t default:%N` (session prefix)
### 5. `split-window` → used positional args to avoid CMD `%*` re-expansion bug

## CMD Batch `%*` Re-expansion Bug

The most subtle fix was in `tmux.cmd`'s split-window handler.
When Claude Code calls:

```
tmux split-window -t %1 -h -l 70% -P -F #{pane_id}
```

The `%1` here is a literal pane ID string (not a batch variable).
But CMD's `%*` expansion re-interprets `%1` as the first batch argument,
turning `-t %1` into `-t split-window` — causing psmux to crash.

**Fix**: Extract `%~3` (positional arg, no re-expansion) and prepend `default:`.

## Files

- `scripts/tmux` — Bash shim (Git Bash / MSYS2)
- `scripts/tmux.cmd` — CMD/PowerShell shim

Both are still in the repo but should not be installed for psmux v0.4.10+.
