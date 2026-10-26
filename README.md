# Codyssey Dev Bootstrap

코디세이 교육장 공용 Mac이 초기화된 뒤에도 **sudo 없이**, 개인 사용자 홈 디렉터리 범위에서 개발 환경을 빠르게 복구하는 스크립트 모음입니다. Homebrew나 시스템 설치 영역(`/Applications`, `/usr/local`)을 변경하지 않습니다.

## 최초 사용

```bash
git clone https://github.com/hyun02063185-AX-beginner/codyssey-dev-bootstrap.git
cd codyssey-dev-bootstrap
./setup.sh
```

`./setup.sh` 하나로 아래 4단계를 순서대로 실행하고, 마지막에 전체 결과 요약을 보여 줍니다. `bootstrap.sh`, `setup-apps.sh`, `verify.sh`를 따로 실행할 필요가 없습니다.

1. **시스템 확인**: macOS, CPU(Intel/Apple Silicon), zsh/HOME, Git·curl·VS Code CLI, `hdiutil`·`codesign` 등 macOS 기본 도구, `~/Applications` 쓰기 권한, 네트워크
2. **개발환경** (`bootstrap.sh`)
3. **데스크톱 앱** (`setup-apps.sh`): Claude Desktop, Discord Desktop
4. **최종 검증** (`verify.sh`): 개발환경 + Claude·Discord는 필수, ChatGPT는 선택 항목

한 단계가 실패해도 독립적인 나머지 단계는 계속 진행하고, 요약에 실패 항목을 모두 표시합니다. 모든 필수 항목이 정상일 때만 `Setup completed`, 하나라도 문제가 있으면 `Setup PARTIAL`로 끝납니다.

실행 권한은 Git에 포함되어 있습니다. 필요할 때만 다음처럼 복구할 수 있습니다.

```bash
chmod +x setup.sh setup-apps.sh bootstrap.sh verify.sh update.sh cleanup.sh scripts/*.sh
```

### 개발환경 (`bootstrap.sh`)

- Volta (`~/.volta`) 및 Node.js 24
- Codex CLI (`npm install -g @openai/codex`)
- Claude Code (`~/.local/bin`)
- GitHub CLI `gh` (`~/.local/share/gh`, `~/.local/bin/gh`): 공식 릴리스(github.com/cli/cli)의 macOS zip을 받아 SHA-256 체크섬과 GitHub 서명(Team ID `VEKTX9H2N7`)을 확인한 뒤 설치
- `~/.zshrc`의 Codyssey PATH 관리 블록
- zsh inline autosuggestions (`~/.zsh/zsh-autosuggestions`) 및 기본 Tab completion
- VS Code 확장 `anthropic.claude-code`, `openai.chatgpt`

`bootstrap.sh`는 단독으로 실행해도 됩니다. 필수 시스템 도구가 없다면 원인을 표시하고, 설치 가능한 나머지 단계는 계속 시도합니다. 새 터미널을 열면 `.zshrc` 설정이 자동으로 적용됩니다.

### 데스크톱 앱 (`setup-apps.sh`)

| 앱 | 처리 | 설치 위치 |
| --- | --- | --- |
| Claude Desktop | 자동 설치 (공식 DMG) | `~/Applications/Claude.app` |
| Discord Desktop | 자동 설치 (공식 DMG) | `~/Applications/Discord.app` |
| ChatGPT Desktop | 설치 여부만 확인 (직접 설치) | `~/Applications/ChatGPT.app` 권장 |

- 앱은 `~/Applications`에만 설치합니다. sudo, Homebrew를 쓰지 않고 관리자 소유인 `/Applications`는 절대 변경하지 않습니다.
- **기존 설치 SKIP**: `~/Applications` 또는 `/Applications`에 정상 앱이 있으면 그대로 두고 건너뜁니다. 이미 설치된 앱을 업데이트하지 않으며, 앱 설정·로그인 상태(`~/Library` 아래)는 건드리지 않습니다.
- **서명 검증**: 설치 전과 설치 후 모두 번들 ID, `codesign` 서명, 개발사 Team ID(Anthropic `Q6L2SF6YDW`, Discord `53Q6R32WPB`, OpenAI `2DC432GLL2`), Gatekeeper(`spctl`) 승인, CPU 아키텍처를 확인합니다. 하나라도 맞지 않으면 설치하지 않습니다. 격리 속성(`xattr`)을 제거하거나 Gatekeeper를 우회하지 않습니다.
- 다운로드는 각 공식 다운로드 진입점만 사용하고, 임시 파일은 `~/Library/Caches/codyssey-dev-bootstrap`에 두었다가 끝나면 삭제합니다.
- `~/Applications`의 앱이 손상(서명 불일치)된 경우에만 새 앱을 먼저 검증한 뒤 교체하고, 기존 번들은 `~/Applications/.<앱>.app.codyssey-backup-<시각>`으로 보존합니다. 앱이 실행 중이면 강제 종료하지 않고 교체를 중단합니다. `/Applications`의 앱은 문제가 있어도 보고만 합니다.

#### 자동 다운로드가 막히는 경우 (Claude)

Claude 공식 다운로드 주소는 스크립트(curl) 접근을 봇 차단 페이지로 막을 수 있습니다. 이 경우 `setup.sh`는 우회하지 않고 다음처럼 진행합니다.

1. `~/Downloads`에 이미 받아 둔 `Claude*.dmg`가 있으면 서명을 검증한 뒤 그것으로 설치합니다.
2. 없으면 `[MANUAL REQUIRED]`를 표시하고 브라우저로 https://claude.com/download 를 엽니다.
3. 브라우저에서 Mac용 DMG를 `~/Downloads`에 받은 뒤(열지 않아도 됨) 터미널에서 Enter를 누르면 같은 실행 안에서 검증·설치를 이어 갑니다. `s`를 입력하면 건너뜁니다.

터미널이 아닌 환경에서 실행했거나 건너뛰었다면 DMG를 받아 둔 뒤 `./setup.sh`를 다시 실행하세요. `~/Downloads`의 DMG는 사용자의 파일이므로 스크립트가 삭제하지 않습니다. Discord도 자동 다운로드가 실패하면 같은 방식으로 처리합니다.

#### ChatGPT Desktop 직접 설치

ChatGPT는 자체 설치 프로그램(`ChatGPTInstaller.dmg` 안의 `Install ChatGPT`)을 쓰므로 이 저장소는 자동 설치하지 않고 설치 여부만 확인합니다. 없으면 `[OPTIONAL / MANUAL]`로 표시되며 전체 성공 여부에는 영향을 주지 않습니다. 이미 설치된 ChatGPT.app은 변경하거나 삭제하지 않습니다.

1. https://chatgpt.com/download/ 에서 macOS용 설치 파일을 받습니다.
2. DMG를 열고 설치 프로그램 안내를 따릅니다. 설치 위치를 고를 수 있으면 관리자 권한이 필요 없는 `~/Applications`(홈 폴더의 응용 프로그램)를 선택합니다.
3. 관리자 암호를 요구하면 설치를 취소하고 교육장 담당자에게 문의합니다.
4. `./verify.sh`로 `ChatGPT [OK]`인지 확인합니다.

### GitHub CLI 로그인

`gh`가 로그인되어 있지 않으면 `setup.sh`가 브라우저 로그인을 할지 묻습니다(`y`일 때만 실행).

```bash
gh auth login --hostname github.com --web --git-protocol https   # 직접 실행할 때
gh auth setup-git                                                # git HTTPS push에 gh 인증 사용
```

- 로그인 후 `gh auth setup-git`으로 `https://github.com`에 대해서만 git이 gh 인증을 쓰도록 설정합니다. 이미 github.com용 다른 credential helper가 있으면 바꾸지 않고, 전역 `credential.helper`도 건드리지 않습니다.
- 토큰은 gh가 macOS 키체인에 저장합니다. 이 저장소, 로그, `.zshrc`에는 토큰·비밀번호·개인키를 저장하지 않습니다.
- 로그인을 건너뛰거나 실패해도 개발환경 설치 실패로 처리하지 않습니다. `verify.sh`는 `gh` 설치(필수)와 로그인 상태(선택)를 따로 보고합니다.
- `gh`로 이슈·PR 생성 등 GitHub API 쓰기 작업을 할 때 HTTP 403이 나오면 설치 문제가 아니라, 계정이나 토큰이 해당 저장소·조직에 쓰기 권한이 없거나 조직이 앱 접근을 승인하지 않은 경우일 수 있습니다. 저장소/조직 권한을 확인하세요. 이 저장소는 권한을 변경하지 않습니다.

### 로그인과 권한

다음은 자동화하지 않습니다. 설치 후 직접 로그인하세요.

- GitHub, Codex, Claude Code
- ChatGPT, Claude, Discord 데스크톱 앱

알림·접근성·화면 기록 같은 macOS 권한은 앱이 요청할 때 운영체제의 정상 승인 절차로 허용합니다. 검증 단계는 앱 번들과 서명까지만 확인하며, GUI 실행과 로그인은 자동으로 확인하지 않습니다.

### 설치 실패 시 복구

- 요약의 `[FAIL]` / `[MANUAL REQUIRED]` 항목 설명을 확인하고 원인(네트워크, 다운로드 등)을 해결한 뒤 `./setup.sh`를 다시 실행합니다. 정상 항목은 SKIP되므로 반복 실행해도 안전합니다.
- 다운로드나 검증이 실패해도 기존에 설치된 앱은 삭제되지 않습니다.
- 교체 설치 후 문제가 있으면 `~/Applications/.<앱>.app.codyssey-backup-<시각>`을 원래 이름으로 되돌릴 수 있습니다. 새 앱이 정상이면 백업은 직접 삭제해도 됩니다.

## 환경 확인

```bash
./verify.sh
```

OS/CPU, 핵심 도구와 버전, 실행 파일 경로, PATH, 필수 VS Code 확장, 데스크톱 앱을 한눈에 보여 줍니다. 단독 실행 시 ChatGPT/Claude/Discord 데스크톱 앱은 선택 항목입니다. 없으면 `[OPTIONAL / MANUAL]`, 서명 검증에 실패하면 `[WARN]`으로 표시할 뿐 검증 실패로 처리하지 않습니다. `setup.sh`에서 실행할 때는 Claude·Discord가 필수 항목이 됩니다.

## 반복 사용

```bash
git pull
./setup.sh
```

스크립트는 재실행해도 이미 맞는 도구와 앱을 건너뛰고, `.zshrc` 관리 블록을 중복 추가하지 않습니다. Node의 목표 major 버전은 [`versions.env`](versions.env)에서 관리합니다.

### zsh 입력 보조

새 zsh 터미널에서는 입력 중 이전 명령이나 completion 기반 제안이 회색 글씨로 보입니다.

- `→` 키로 제안을 수락합니다.
- `Tab`은 기존 zsh completion을 그대로 사용합니다.
- 플러그인은 `~/.zsh/zsh-autosuggestions`에 GitHub clone으로만 설치하며, Homebrew·sudo는 사용하지 않습니다.

`bootstrap.sh`는 설치와 복구만 담당하며 이미 설치된 Codex/Claude Code를 **업데이트하지 않습니다**. 복구 중 예상치 못한 breaking change를 피하기 위한 의도적인 정책입니다.

## 업데이트

`setup.sh`/`bootstrap.sh`는 이미 설치된 도구와 앱을 업데이트하지 않습니다. 새 버전이 필요할 때만 실행하세요. 데스크톱 앱은 각 앱의 자체 업데이트 기능을 사용합니다.

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

정비하거나 공용 Mac 사용을 마치기 전에 실행합니다.

```bash
./cleanup.sh
```

공용 Mac 사용을 마칠 때는 GitHub CLI에서도 로그아웃합니다. 키체인에 저장된 gh 토큰이 삭제됩니다.

```bash
gh auth logout --hostname github.com
```

v0.1의 cleanup은 의도적으로 파일을 삭제하지 않습니다. 공용 Mac에서 Git·GitHub CLI, Codex, Claude, 브라우저, VS Code의 로그인 세션을 직접 확인하도록 안내합니다. API 키·토큰·비밀번호·쿠키·인증 파일은 저장소에 커밋하지 마세요.

## 범위와 향후 계획

ChatGPT 데스크톱 앱 자동 설치, 데스크톱 앱 자동 업데이트, 로그인·API 인증 자동화는 범위 밖입니다. Codex CLI 버전 고정(`CODEX_VERSION`)도 현재는 두지 않고 Node major 정책만 유지합니다.
