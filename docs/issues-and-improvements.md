# Known Issues & Suggested Improvements

This document tracks remaining issues found during testing and suggests
improvements for psmux, Claude Code, and the shim itself.

---

## For the psmux Project

**Repo**: https://github.com/marlocarlo/psmux

### 1. `tmux -V` should print version, not launch TUI

**Severity**: Critical (blocks Claude Code)

Real tmux outputs `tmux X.Y` to stdout and exits when called with `-V`.
psmux launches its interactive TUI instead.

**Suggested fix** (Rust pseudocode):
```rust
if args.contains("-V") || args.contains("--version") {
    println!("psmux {}", env!("CARGO_PKG_VERSION"));
    std::process::exit(0);
}
```

### 2. `display-message` format variables return empty inside panes

**Severity**: High (blocks teammate spawning)

`tmux display-message -p '#{window_panes}'`, `'#{pane_id}'`, `'#{session_name}'`
all return empty strings when called from a child process inside a psmux pane
without an explicit `-t` target. Real tmux resolves these from the `$TMUX`
environment variable.

**Suggested fix**: When `$TMUX` is set, parse the socket path to determine
the current session/window/pane context and use it as the default target.

### 3. Session name hardcoded as `default` in socket path

**Severity**: Medium

The IPC socket path always contains `default` regardless of the actual session name.
This causes `psmux list-panes` (without `-t`) from inside a pane to always look
for the `default` session, failing if the session has any other name.

**Suggested fix**: Embed the actual session name in `$TMUX_PANE` or use a
separate env var (e.g., `PSMUX_SESSION`) that reflects the real session name.

### 4. Pane ID not prefixed with session name in IPC commands

**Severity**: High (blocks send-keys and kill-pane)

When Claude Code calls `send-keys -t %2` or `kill-pane -t %2` from outside
the psmux TUI process (i.e., from a child process inside the session), psmux
cannot resolve the bare pane ID `%2` to its session. The command fails with
`no server running on session ''`.

Real tmux resolves pane IDs from the `$TMUX` environment variable context.

**Suggested fix**: When looking up pane IDs, search all sessions if the session
cannot be determined from the environment.

**Workaround in shim**: Rewrite `-t %N` to `-t default:%N` (explicit session prefix).

### 5. `send-keys` may contaminate typed text with terminal escape sequences

**Severity**: Medium (intermittent agent spawn failures)

When psmux types a long command string into a pane via `send-keys`, terminal
escape sequences from the terminal state (e.g., OSC title-set sequences `ESC]`)
can get mixed into the typed text. This results in corrupted arguments such as
`--model claude-opus-4-6]` (with a stray `]` from `ESC]`).

Observed during: second or third teammate spawn into the same reused pane.

**Suggested fix**: Strip or escape non-printable characters from the text
argument before typing it into the pane.

---

## For Claude Code

**Repo**: https://github.com/anthropics/claude-code
**Related issue**: https://github.com/anthropics/claude-code/issues/24384

### 1. Add psmux as a supported split-pane backend

Claude Code currently supports only `tmux` and `iTerm2` for split-pane mode.
Since psmux provides a tmux-compatible interface on native Windows,
it should be detected and supported directly.

**Detection logic suggestion**:
```javascript
// Current
if (process.env.TMUX) return 'tmux';

// Suggested addition
if (process.env.PSMUX_SESSION) return 'psmux'; // psmux-specific env var
if (process.env.TMUX && process.env.TMUX.includes('psmux')) return 'psmux';
```

### 2. `tmux -V` should not block if version check fails

If `tmux -V` times out or returns unexpected output, Claude Code should fall
back gracefully to in-process mode rather than hanging.

**Suggested fix**: Add a timeout (e.g. 2s) to the `tmux -V` call, and on
failure/timeout, log a warning and continue with in-process mode.

### 3. Windows Terminal / PowerShell as split-pane backend

**Issue**: https://github.com/anthropics/claude-code/issues/24384

Windows Terminal exposes `wt.exe split-pane` CLI for programmatic pane splitting.
Adding this as a backend would enable split-pane mode without any third-party tools.

```powershell
# Windows Terminal split-pane API
wt.exe split-pane --horizontal -- pwsh -NoExit -Command "claude --agent-name ..."
```

### 4. Team mode creates only 1 split pane for all teammates

**Severity**: Medium (visible behavior difference from macOS/tmux)

With `--teammate-mode tmux`, Claude Code calls `split-window` only **once**
regardless of the number of teammates. All teammates share a single right-side
pane and run sequentially (one completes, then the next starts).

Observed behavior (3 teammates):
```
┌──────────────────────────┬──────────────────────────┐
│  Pane 1: Lead            │  Pane 2: teammates (×3)  │
│  (orchestrating)         │  @alpha → @beta → @gamma │
│                          │  (sequential, same pane) │
└──────────────────────────┴──────────────────────────┘
```

Expected behavior (matching macOS tmux):
```
┌──────────┬──────────┬──────────┬──────────┐
│  Lead    │  @alpha  │  @beta   │  @gamma  │
│  Pane 1  │  Pane 2  │  Pane 3  │  Pane 4  │
└──────────┴──────────┴──────────┴──────────┘
```

**Suggested fix**: Call `split-window` once per teammate to give each teammate
its own visible pane, enabling true parallel monitoring.

---

## For This Shim

### Fixed Issues (v1.0)

1. **`tmux -V` hang** — Shim intercepts `-V` and returns `"tmux 3.4"` immediately.

2. **`display-message` format variables returning empty** — Shim intercepts
   `window_panes`, `pane_id`, `session_name`, `window_id`, `window_index` and
   returns correct values.

3. **`send-keys`/`kill-pane` failing with "no server running on session ''"** —
   Shim rewrites `-t %N` to `-t default:%N` (explicit session prefix).

4. **`split-window` TUI crash (`%*` re-expansion bug in CMD)** — `psmux %*` caused
   CMD to re-expand `%1` (the pane ID literal) as the first batch argument
   (`split-window`), giving psmux an invalid target `-t split-window`. Fixed by
   extracting args positionally (`%~3`) and adding the `default:` prefix.

5. **`split-window` stdout redirect bug** — Original handler redirected all output
   (`>> log 2>&1`), preventing Claude Code from reading the new pane ID on stdout.
   Fixed to redirect only stderr (`2>> log`).

### Known Limitations

1. **Session name must be `default`** — due to psmux Issue 3 above, the psmux
   session must be named `default` for the shim to work correctly. A future
   version should auto-detect the session name from `$TMUX`.

2. **Only 2 panes total** — due to Claude Code Issue 4 above, all teammates share
   a single split pane. Claude Code does not create one pane per teammate.

3. **Intermittent model name corruption** — due to psmux Issue 5 above, the model
   name argument may occasionally include a stray `]` character when a teammate
   is spawned into a reused pane. Retry typically succeeds.

4. **`tmux.cmd` format variable parsing** — the CMD batch file uses `findstr`
   to detect format variables. Very unusual format strings might not be matched.
   The bash shim has more robust parsing.

5. **Tested on psmux v0.3.9** — compatibility with future psmux versions
   is not guaranteed. Check the psmux changelog after upgrades.

### Future Improvements

- [ ] Auto-detect psmux session name from `$TMUX` socket path
- [ ] Add `PSMUX_SESSION_NAME` env var support in launch script
- [ ] Test with WezTerm on Windows as alternative backend
- [ ] Create a proper Windows `.exe` shim using a small Rust or Go binary
      to eliminate the bash/cmd dual-file requirement
- [ ] Intercept `send-keys` to create a new split when the target pane is
      occupied, enabling per-teammate panes until Claude Code Issue 4 is fixed
