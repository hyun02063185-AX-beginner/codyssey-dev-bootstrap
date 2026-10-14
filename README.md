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
- zsh inline autosuggestions (`~/.zsh/zsh-autosuggestions`) 및 기본 Tab completion
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

### zsh 입력 보조

새 zsh 터미널에서는 입력 중 이전 명령이나 completion 기반 제안이 회색 글씨로 보입니다.

- `→` 키로 제안을 수락합니다.
- `Tab`은 기존 zsh completion을 그대로 사용합니다.
- 플러그인은 `~/.zsh/zsh-autosuggestions`에 GitHub clone으로만 설치하며, Homebrew·sudo는 사용하지 않습니다.

`bootstrap.sh`는 설치와 복구만 담당하며 이미 설치된 Codex/Claude Code를 **업데이트하지 않습니다**. 복구 중 예상치 못한 breaking change를 피하기 위한 의도적인 정책입니다.

## 업데이트

```bash
./update.sh --check   # 버전만 확인, 변경 없음
./update.sh           # Codex CLI와 Claude Code 업데이트
./update.sh codex     # 하나만 업데이트
```

업데이트가 실패하면 기존 버전을 그대로 두고 실패만 보고합니다. Claude Code는 최신 버전을 스스로 조회하므로 `--check`에서는 현재 버전만 표시합니다.

> 참고: Claude Code 네이티브 설치본은 기본적으로 자체 자동 업데이트를 수행할 수 있습니다. 이 저장소는 자동 업데이트를 제어하지 않으며, 필요하면 향후 설정 방법을 검토할 수 있습니다.

## AWS EC2 SSH 개인키 복구 및 사용

코디세이 교육장 공용 Mac에서 EC2에 SSH로 접속할 때는 개인키를 이 Git 저장소가 아닌 별도 개인 저장소에서 복구해 사용합니다. 현재 사용자는 개인 Google Drive에 SSH 키를 별도로 보관하고 있습니다.

- EC2 개인키(`.pem`, `id_rsa`, `id_ed25519` 등)는 Git 저장소에 절대 커밋하지 않습니다.
- private Git 저장소라도 개인키 보관용으로 사용하지 않습니다.
- 실제 개인키는 개인 Google Drive 등 별도 개인 저장소에 보관합니다.
- API key, SSH private key, credential 등 민감정보는 README나 Git에 기록하지 않습니다.

개인 Google Drive에서 키 파일을 내려받은 뒤, 교육장 Mac의 `~/.ssh` 아래로 옮깁니다. Google Drive나 다운로드를 거치면 Unix permission이 유지되지 않을 수 있으므로, 사용 전에 권한을 다시 설정합니다.

```bash
mkdir -p ~/.ssh
chmod 700 ~/.ssh

mv ~/Downloads/b3-1-ec2-key.pem ~/.ssh/
chmod 400 ~/.ssh/b3-1-ec2-key.pem
```

SSH 접속 예시는 다음과 같습니다. 실제 EC2 IP 주소, AWS 계정 정보, 개인키 내용은 문서에 넣지 않습니다.

```bash
ssh -i ~/.ssh/b3-1-ec2-key.pem ec2-user@<EC2_PUBLIC_IP>
```

공용 PC 사용을 마치기 전에는 개인키가 `~/.ssh`에 남아 있는지 확인합니다.

```bash
ls -la ~/.ssh
```

필요하면 로컬에 복사한 키를 삭제합니다.

```bash
rm ~/.ssh/b3-1-ec2-key.pem
```

## 정리 안내

```bash
./cleanup.sh
```

v0.1의 cleanup은 의도적으로 파일을 삭제하지 않습니다. 공용 Mac에서 Git, Codex, Claude, 브라우저, VS Code의 로그인 세션을 직접 확인하도록 안내합니다. API 키·토큰·비밀번호·쿠키·인증 파일은 저장소에 커밋하지 마세요.

## 범위와 향후 계획

데스크톱 앱(ChatGPT, Claude, Discord) 자동 설치와 API 인증 자동화는 v0.1 범위 밖입니다. 이후 `setup-apps.sh` 같은 별도 스크립트로 추가할 수 있습니다. Codex CLI 버전 고정(`CODEX_VERSION`)도 현재는 두지 않고 Node major 정책만 유지합니다.
