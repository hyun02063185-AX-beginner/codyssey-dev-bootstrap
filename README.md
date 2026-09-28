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
chmod +x bootstrap.sh verify.sh cleanup.sh scripts/*.sh
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

OS/CPU, 핵심 도구와 버전, 실행 파일 경로, PATH, 필수 VS Code 확장을 한눈에 보여 줍니다.

## 반복 사용

```bash
git pull
./bootstrap.sh
```

스크립트는 재실행해도 이미 맞는 도구를 건너뛰고, `.zshrc` 관리 블록을 중복 추가하지 않습니다. Node의 목표 major 버전은 [`versions.env`](versions.env)에서 관리합니다.

## 정리 안내

```bash
./cleanup.sh
```

v0.1의 cleanup은 의도적으로 파일을 삭제하지 않습니다. 공용 Mac에서 Git, Codex, Claude, 브라우저, VS Code의 로그인 세션을 직접 확인하도록 안내합니다. API 키·토큰·비밀번호·쿠키·인증 파일은 저장소에 커밋하지 마세요.

## 범위와 향후 계획

ChatGPT Desktop/Claude Desktop 자동 설치와 API 인증 자동화는 v0.1 범위 밖입니다. 이후 `setup-apps.sh` 같은 별도 스크립트로 추가할 수 있습니다.
