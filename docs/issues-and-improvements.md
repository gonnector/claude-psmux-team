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

---

## For This Shim

### Known Limitations

1. **Session name must be `default`** — due to psmux Issue 3 above, the psmux
   session must be named `default` for the shim to work correctly. A future
   version should auto-detect the session name from `$TMUX`.

2. **`tmux.cmd` format variable parsing** — the CMD batch file uses `findstr`
   to detect format variables. Very unusual format strings might not be matched.
   The bash shim has more robust parsing.

3. **Tested on psmux v0.3.9** — compatibility with future psmux versions
   is not guaranteed. Check the psmux changelog after upgrades.

### Future Improvements

- [ ] Auto-detect psmux session name from `$TMUX` socket path
- [ ] Add `PSMUX_SESSION_NAME` env var support in launch script
- [ ] Test with WezTerm on Windows as alternative backend
- [ ] Create a proper Windows `.exe` shim using a small Rust or Go binary
      to eliminate the bash/cmd dual-file requirement
