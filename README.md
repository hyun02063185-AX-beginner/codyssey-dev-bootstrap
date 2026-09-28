# Codyssey Dev Bootstrap

코디세이 교육장 공용 Mac이 초기화된 뒤에도 **sudo 없이**, 개인 사용자 홈 디렉터리 범위에서 개발 환경을 빠르게 복구하는 스크립트 모음입니다. Homebrew나 시스템 설치 영역(`/Applications`, `/usr/local`)을 변경하지 않습니다.

## 최초 사용

```bash
git clone https://github.com/hyun02063185-AX-beginner/codyssey-dev-bootstrap.git
cd codyssey-dev-bootstrap
./bootstrap.sh
```

실행 권한은 Git에 포함되어 있습니다. 필요할 때만 다음처럼 복구할 수 있습니다.

```bash
chmod +x bootstrap.sh verify.sh update.sh cleanup.sh scripts/*.sh
```

`bootstrap.sh`는 macOS, CPU, zsh/HOME, Git·curl·VS Code CLI를 확인한 뒤 다음을 처리합니다.

- Volta (`~/.volta`) 및 Node.js 24
- Codex CLI (`npm install -g @openai/codex`)
- Claude Code (`~/.local/bin`)
- `~/.zshrc`의 Codyssey PATH 관리 블록
- VS Code 확장 `anthropic.claude-code`, `openai.chatgpt`

필수 시스템 도구가 없다면 원인을 표시하고, 설치 가능한 나머지 단계는 계속 시도합니다. 새 터미널을 열면 `.zshrc` 설정이 자동으로 적용됩니다.

## 환경 확인

```bash
./verify.sh
```

OS/CPU, 핵심 도구와 버전, 실행 파일 경로, PATH, 필수 VS Code 확장을 한눈에 보여 줍니다. ChatGPT/Claude/Discord 데스크톱 앱은 `~/Applications`와 `/Applications`에서 존재만 확인하며, 없어도 `[OPTIONAL]`로 표시할 뿐 검증 실패로 처리하지 않습니다.

## 반복 사용

```bash
git pull
./bootstrap.sh
```

스크립트는 재실행해도 이미 맞는 도구를 건너뛰고, `.zshrc` 관리 블록을 중복 추가하지 않습니다. Node의 목표 major 버전은 [`versions.env`](versions.env)에서 관리합니다.

`bootstrap.sh`는 설치와 복구만 담당하며 이미 설치된 Codex/Claude Code를 **업데이트하지 않습니다**. 복구 중 예상치 못한 breaking change를 피하기 위한 의도적인 정책입니다.

## 업데이트

```bash
./update.sh --check   # 버전만 확인, 변경 없음
./update.sh           # Codex CLI와 Claude Code 업데이트
./update.sh codex     # 하나만 업데이트
```

업데이트가 실패하면 기존 버전을 그대로 두고 실패만 보고합니다. Claude Code는 최신 버전을 스스로 조회하므로 `--check`에서는 현재 버전만 표시합니다.

> 참고: Claude Code 네이티브 설치본은 기본적으로 자체 자동 업데이트를 수행할 수 있습니다. 이 저장소는 자동 업데이트를 제어하지 않으며, 필요하면 향후 설정 방법을 검토할 수 있습니다.

## 정리 안내

```bash
./cleanup.sh
```

v0.1의 cleanup은 의도적으로 파일을 삭제하지 않습니다. 공용 Mac에서 Git, Codex, Claude, 브라우저, VS Code의 로그인 세션을 직접 확인하도록 안내합니다. API 키·토큰·비밀번호·쿠키·인증 파일은 저장소에 커밋하지 마세요.

## 범위와 향후 계획

데스크톱 앱(ChatGPT, Claude, Discord) 자동 설치와 API 인증 자동화는 v0.1 범위 밖입니다. 이후 `setup-apps.sh` 같은 별도 스크립트로 추가할 수 있습니다. Codex CLI 버전 고정(`CODEX_VERSION`)도 현재는 두지 않고 Node major 정책만 유지합니다.
