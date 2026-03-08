[🇺🇸 English](README.md) | 🇰🇷 한국어

---

# Windows에서 Claude Code 에이전트 팀 — psmux 분할 화면

> **세계 최초 네이티브 Windows 솔루션** — WSL, Cygwin, 리눅스 서브시스템 없이
> 분할 터미널 창에서 Claude Code 에이전트 팀을 실행합니다.

![Windows](https://img.shields.io/badge/Windows-11-blue?logo=windows)
![psmux](https://img.shields.io/badge/psmux-v0.4.10-orange)
![Claude Code](https://img.shields.io/badge/Claude_Code-v2.1.71-blueviolet)
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
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` 활성화

## 설치

### 1. psmux 설치

```powershell
cargo install psmux   # v0.4.10 이상 필요
```

### 2. 버전 스푸핑 shim 설치

psmux v0.4.10은 모든 tmux 명령을 네이티브로 처리하지만, `tmux -V`가
`"tmux 0.4.10"`을 반환합니다. Claude Code는 버전 2 이상을 요구하며,
미달 시 in-process 모드로 자동 전환됩니다. 또한 Node.js `spawn`은 Windows에서
`.exe` 파일만 찾으므로 컴파일된 shim이 필요합니다.

```powershell
git clone https://github.com/gonnector/claude-psmux-team
cd claude-psmux-team

# psmux의 tmux 바이너리 이름 변경 (tmux 모드 유지를 위해 "tmux"로 시작해야 함)
Rename-Item "$env:USERPROFILE\.cargo\bin\tmux.exe" "tmux-real.exe"

# 방법 A: shim 직접 컴파일 (gcc / MSYS2 필요)
gcc -O2 -o "$env:USERPROFILE\.cargo\bin\tmux.exe" scripts/tmux-shim.c

# 방법 B: 사전 빌드된 shim 사용 (gcc가 없는 경우)
Copy-Item scripts/tmux.exe "$env:USERPROFILE\.cargo\bin\tmux.exe"
```

shim은 `tmux -V` → `"tmux 3.4"` 반환, 나머지는 `tmux-real.exe`(psmux tmux 호환 모드)로 전달합니다.

<details>
<summary><strong>psmux v0.3.x를 사용 중이라면?</strong> (레거시 전체 shim 필요)</summary>

psmux v0.3.x는 `tmux -V`, `display-message` 포맷 변수, `send-keys`의 bare pane ID를
처리하지 못합니다. 버전 스푸핑만이 아닌 전체 호환성 shim이 필요합니다.
[docs/shim-v0.3.x.md](docs/shim-v0.3.x.md) 참고.

</details>

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

## 호환성 매트릭스

| 기능 | psmux v0.3.9 | psmux v0.4.10+ |
|------|:---:|:---:|
| `tmux -V` 버전 출력 | Shim 필요 | 네이티브 |
| `display-message` 포맷 변수 | Shim 필요 | 네이티브 |
| `send-keys -t %N` (bare pane ID) | Shim 필요 | 네이티브 |
| `split-window -P -F #{pane_id}` | Shim 필요 | 네이티브 |
| `kill-pane -t %N` | Shim 필요 | 네이티브 |
| 팀원별 독립 pane | 미지원 | 미지원* |

*\*Claude Code가 모든 팀원에게 1개 split만 생성합니다. psmux 한계가 아닌 Claude Code 동작 방식입니다.*

## 기여

이슈와 PR을 환영합니다! psmux, Claude Code, 이 프로젝트에 대한
알려진 이슈 및 개선 제안은
[docs/issues-and-improvements.md](docs/issues-and-improvements.md)를 참고하세요.

## 관련 이슈

- [anthropics/claude-code#24384](https://github.com/anthropics/claude-code/issues/24384) — Windows Terminal을 분할 창 백엔드로 추가
- [marlocarlo/psmux#42](https://github.com/marlocarlo/psmux/issues/42) — tmux 호환성 이슈 (v0.4.10에서 해결)

## 라이선스

MIT
