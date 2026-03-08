# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/).

## [Unreleased]

### Added
- Compiled C shim (`scripts/tmux-shim.c`) for version spoofing on psmux v0.4.10+
- Pre-built `scripts/tmux.exe` shim binary (122KB, MinGW64 gcc 15.1)
- Legacy shim documentation (`docs/shim-v0.3.x.md`)
- Korean README (`README.ko.md`)
- Detailed issues & improvements tracker (`docs/issues-and-improvements.md`)

### Changed
- Updated install instructions for psmux v0.4.10+ (version-spoof shim instead of full shim)
- Simplified bash/CMD shim scripts to version-spoof only (7 lines each)
- Updated shim binary reference from `psmux-tmux` to `tmux-real` (psmux argv[0] detection)
- Updated Claude Code badge to v2.1.71

### Fixed
- Node.js `spawn` on Windows only finds `.exe` files — replaced script shims with compiled exe
- psmux binary naming: must start with `tmux` for tmux-compatible mode (not `psmux-tmux`)

## [0.1.0] - 2026-02-21

### Added
- Initial release with full compatibility shim for psmux v0.3.9
- Bash shim (`scripts/tmux`) and CMD shim (`scripts/tmux.cmd`) — 5-fix shim
- Install script (`scripts/install.ps1`) and launch script (`scripts/launch.ps1`)
- README with compatibility matrix
