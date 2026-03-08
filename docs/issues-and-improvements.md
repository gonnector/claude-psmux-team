# Known Issues & Suggested Improvements

This document tracks remaining issues found during testing and suggests
improvements for psmux, Claude Code, and this project.

---

## Version History

### psmux v0.4.10 (2025-03-08)

Resolved all tmux command compatibility issues. A **minimal version-spoof shim**
is still required because `tmux -V` returns `"tmux 0.4.10"` (Claude Code
requires version 2+). The full 5-fix shim from v0.3.x is no longer needed.

| Issue | v0.3.9 | v0.4.10 |
|-------|--------|---------|
| `tmux -V` launches TUI | Shim required | Fixed natively |
| `display-message` format vars empty | Shim required | Fixed natively |
| `send-keys -t %N` bare pane ID | Shim required | Fixed natively |
| `split-window -P -F #{pane_id}` | Shim required | Fixed natively |
| `kill-pane -t %N` | Shim required | Fixed natively |

### psmux v0.3.9 (legacy)

Required the bash/CMD compatibility shim for all tmux operations.
See [shim-v0.3.x.md](shim-v0.3.x.md) for the shim's technical details.

---

## Remaining Issues

### For psmux

**Repo**: https://github.com/marlocarlo/psmux
**Related issue**: https://github.com/marlocarlo/psmux/issues/42

#### 1. `send-keys` may contaminate typed text with terminal escape sequences

**Severity**: Medium (intermittent agent spawn failures)
**Status**: Needs verification on v0.4.10

When psmux types a long command string into a pane via `send-keys`, terminal
escape sequences from the terminal state (e.g., OSC title-set sequences `ESC]`)
can get mixed into the typed text. This results in corrupted arguments such as
`--model claude-opus-4-6]` (with a stray `]` from `ESC]`).

Observed during: second or third teammate spawn into the same reused pane.

**Suggested fix**: Strip or escape non-printable characters from the text
argument before typing it into the pane.

#### 2. Session name hardcoded as `default` in socket path

**Severity**: Medium
**Status**: Needs verification on v0.4.10

The IPC socket path may still contain `default` regardless of the actual session
name, preventing multi-session workflows.

#### 3. `tmux -V` reports `"tmux 0.4.10"` — fails Claude Code version check

**Severity**: High (blocks split-pane mode entirely)
**Status**: Requires version-spoof shim

psmux v0.4.10's `tmux.exe` returns `"tmux 0.4.10"` for `-V`. Claude Code
parses the version number and requires 2.0+. When the check fails, Claude Code
silently falls back to in-process (Agent) mode instead of split-pane (Teammate).

**Workaround**: A compiled C shim (`scripts/tmux-shim.c`) intercepts `-V` and
returns `"tmux 3.4"`, passing all other commands to `tmux-real.exe`.

**Suggested fix for psmux**: Allow configuring the version string reported by
`tmux -V`, or report a version >= 3.0 (e.g., `"tmux 3.4-psmux0.4.10"`).

#### 4. `TMUX` environment variable not set inside psmux sessions

**Severity**: Low (does not block functionality with `--teammate-mode tmux`)
**Status**: Cosmetic

Real tmux sets `TMUX` and `TMUX_PANE` environment variables inside sessions.
psmux does not set these. Claude Code uses `process.env.TMUX` to detect if
it's running inside a tmux session. Without it, Claude Code operates in
"external session mode" — which still works, but the status line shows
`View teammates: tmux -L ... a` instead of inline teammate indicators.

---

### For Claude Code

**Repo**: https://github.com/anthropics/claude-code
**Related issue**: https://github.com/anthropics/claude-code/issues/24384

#### 1. Add psmux as a supported split-pane backend

Claude Code currently supports only `tmux` and `iTerm2` for split-pane mode.
Since psmux provides a tmux-compatible interface on native Windows,
it should be detected and supported directly.

#### 2. Windows Terminal as split-pane backend

**Issue**: https://github.com/anthropics/claude-code/issues/24384

Windows Terminal exposes `wt.exe split-pane` CLI for programmatic pane splitting.
Adding this as a backend would enable split-pane mode without any third-party tools.

#### 3. Node.js `spawn` only finds `.exe` on Windows — `.cmd`/bash shims ignored

**Severity**: High (blocks split-pane mode entirely)

Node.js `child_process.spawn('tmux', ...)` without `shell: true` uses
Windows `CreateProcess` which only resolves `.exe` and `.com` extensions.
Bash scripts (`tmux`) and CMD batch files (`tmux.cmd`) in PATH are invisible.

**Impact**: A version-spoof shim must be a compiled `.exe`, not a script.
The project provides `scripts/tmux-shim.c` for this purpose.

#### 4. psmux argv[0] binary name detection

psmux determines its operating mode from the executable name:
- Name starts with `tmux` → tmux-compatible mode
- Name contains `psmux` → psmux-native mode

When renaming the binary for the shim setup, the real binary must be named
`tmux-real.exe` (not `psmux-tmux.exe`), otherwise it enters the wrong mode.

#### 5. Team mode creates only 1 split pane for all teammates

**Severity**: Medium (visible behavior difference from macOS/tmux)

With `--teammate-mode tmux`, Claude Code calls `split-window` only **once**
regardless of the number of teammates. All teammates share a single right-side
pane and run sequentially (one completes, then the next starts).

```
Observed (2 panes):                  Expected (4 panes):
┌──────────┬──────────────┐          ┌──────┬──────┬──────┬──────┐
│ Lead     │ teammates×3  │          │ Lead │ @a   │ @b   │ @c   │
│          │ (sequential) │          │      │      │      │      │
└──────────┴──────────────┘          └──────┴──────┴──────┴──────┘
```

---

## Shim Documentation

### v0.4.10 — Version-spoof shim (`scripts/tmux-shim.c`)

A minimal C program (122KB compiled) that intercepts `tmux -V` to return
`"tmux 3.4"` and delegates all other commands to `tmux-real.exe` via `_spawnvp`.
Must be compiled as `.exe` because Node.js spawn only finds executables.

### v0.3.x — Full compatibility shim (legacy)

The script shims (`scripts/tmux` and `scripts/tmux.cmd`) were created for
psmux v0.3.9 compatibility and are preserved in the repo for reference.
They fixed 5 issues that are now handled natively by psmux v0.4.10.

See [shim-v0.3.x.md](shim-v0.3.x.md) for the full technical breakdown.

---

## Future Improvements

- [ ] Verify escape sequence contamination (psmux Issue 1) on v0.4.10
- [ ] Verify session name handling (psmux Issue 2) on v0.4.10
- [ ] Test with WezTerm on Windows as alternative backend
- [ ] Create install script for psmux v0.4.10+ (simplified — just `cargo install`)
