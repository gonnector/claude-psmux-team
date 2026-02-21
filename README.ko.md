[🇺🇸 English](README.md) | 🇰🇷 한국어

---

# Windows에서 Claude Code 에이전트 팀 — psmux 분할 화면

> **세계 최초 네이티브 Windows 솔루션** — WSL, Cygwin, 리눅스 서브시스템 없이
> 분할 터미널 창에서 Claude Code 에이전트 팀을 실행합니다.

![Windows](https://img.shields.io/badge/Windows-11-blue?logo=windows)
![psmux](https://img.shields.io/badge/psmux-v0.3.9-orange)
![Claude Code](https://img.shields.io/badge/Claude_Code-v2.1.50-blueviolet)
![License](https://img.shields.io/badge/license-MIT-green)

## 개요

Claude Code의 [에이전트 팀 기능](https://code.claude.com/docs/en/agent-teams)을 사용하면
여러 AI 팀원이 병렬로 협업할 수 있습니다. 분할 창 모드에서는 각 팀원이 자신의 터미널 창을
가지며, 동시에 작업하는 모습을 모두 볼 수 있습니다.

이 기능은 macOS에서 **tmux** 또는 **iTerm2**를 통해 공식 지원됩니다.
**Windows**에서는 기존에 WSL(Ubuntu) 내부에서만 가능했으며,
Windows와 리눅스 서브시스템 간 파일 동기화가 필요했습니다.

**이 프로젝트는 WSL 없이 네이티브 Windows에서 동작하게 합니다.** Rust 기반 tmux 호환 클론인
[psmux](https://github.com/marlocarlo/psmux)를 활용합니다.

```
psmux 세션 (현재 동작)
┌──────────────────────────┬───────────────────────────────┐
│ Pane 1  리드             │ Pane 2  팀원 (순환 실행)      │
│ Claude Code v2.1.50      │ @alpha → 완료                 │
│ Opus 4.6 · 조율 중       │ @beta  → 완료                 │
│                          │ @gamma → 완료                 │
└──────────────────────────┴───────────────────────────────┘
 shift-tab으로 활성 팀원 간 전환
```

> **참고**: 현재 Claude Code는 모든 팀원에게 하나의 공유 창만 생성합니다
> (팀원들이 순차 실행). 팀원별 독립 창(macOS tmux 방식)은 Claude Code 업데이트가
> 필요합니다. [docs/issues-and-improvements.md](docs/issues-and-improvements.md) 참고.

## 기존 접근법

기존에 알려진 유일한 Windows 방법은 WSL 기반이었습니다:
[treylom/claude-agent-teams-setup](https://github.com/treylom/claude-agent-teams-setup)
— WSL의 Ubuntu에서 tmux를 실행하고, 작업 디렉토리를 Windows와 동기화하는 방식입니다.
이 프로젝트는 그런 오버헤드를 완전히 제거합니다.

## 요구 사항

- Windows 10/11
- [Rust / Cargo](https://rustup.rs/) (psmux 설치용)
- [Claude Code](https://code.claude.com/) v2.1.40 이상
- Git Bash 또는 MSYS2 (bash shim용)
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 활성화

## 빠른 설치

```powershell
# 1. psmux 설치
cargo install psmux

# 2. 저장소 클론
git clone https://github.com/gonnector/claude-psmux-team
cd claude-psmux-team

# 3. 설치 스크립트 실행
.\scripts\install.ps1
```

## 수동 설치

```powershell
# 1. psmux 설치
cargo install psmux

# 2. psmux의 tmux 별칭 백업
Rename-Item "$env:USERPROFILE\.cargo\bin\tmux.exe" "tmux-psmux.exe"

# 3. shim 스크립트 복사
Copy-Item scripts\tmux     "$env:USERPROFILE\.cargo\bin\tmux"      # Git Bash용
Copy-Item scripts\tmux.cmd "$env:USERPROFILE\.cargo\bin\tmux.cmd"  # PowerShell용
```

## 에이전트 팀 활성화

`~/.claude/settings.json`에 추가:
```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

## 사용법

```powershell
# psmux 세션 시작 (반드시 'default'로 명명)
psmux new-session -s default

# 세션 내에서 Claude Code 실행
claude --teammate-mode tmux

# Claude에게 팀원 스폰 요청:
# "3명의 팀원을 병렬로 구성해서 X, Y, Z를 각각 조사해줘"
```

또는 실행 스크립트 사용:
```powershell
.\scripts\launch.ps1
```

## 기본 동작이 안 되는 이유

Claude Code와 psmux 사이에 여러 비호환성이 존재합니다. 전체 기술 설명은
[docs/issues-and-improvements.md](docs/issues-and-improvements.md)를 참고하세요.
요약하면:

| 문제 | 증상 | 수정 |
|------|------|------|
| `tmux -V`가 psmux TUI 실행 | Claude Code 시작 시 행 | Shim이 `"tmux 3.4"` 반환 |
| pane 내에서 포맷 변수가 빈 값 반환 | 팀원 스폰 실패 ("Could not determine pane count") | Shim이 올바른 값 반환 |
| `send-keys -t %N`에 세션명 누락 | `no server running on session ''` 오류 | Shim이 `-t default:%N`으로 재작성 |
| CMD batch의 `%*` 재확장 버그 | psmux가 `-t split-window` (잘못된 타겟)을 받아 TUI 충돌 | 위치 인자 `%~3` + `default:` 접두어 사용 |
| 세션명이 반드시 `default`여야 함 | pane 내부에서 `psmux list-panes` 실패 | 항상 세션명을 `default`로 지정 |

## 기여

이슈와 PR을 환영합니다! psmux, Claude Code, 이 shim에 대한
알려진 이슈 및 개선 제안의 전체 목록은
[docs/issues-and-improvements.md](docs/issues-and-improvements.md)를 참고하세요.

## 관련 이슈

- [anthropics/claude-code#24384](https://github.com/anthropics/claude-code/issues/24384) — Windows Terminal을 분할 창 백엔드로 추가
- [marlocarlo/psmux](https://github.com/marlocarlo/psmux) — psmux 프로젝트

## 라이선스

MIT
