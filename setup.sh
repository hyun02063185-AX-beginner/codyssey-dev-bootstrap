#!/bin/zsh

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/scripts/common.sh"
source "$SCRIPT_DIR/scripts/apps-common.sh"

rule() { print -- "========================================"; }
step() { print -- "\n"; rule; print -- " STEP $1"; rule; }

rule
print -- " Codyssey Mac Environment Setup"
rule
print -- "Uses only your home directory. Never uses sudo or Homebrew."

typeset -A step_status
results_file="$(mktemp "${TMPDIR:-/tmp}/codyssey-setup.XXXXXX")" || { error "Cannot create a temporary file"; exit 1; }
trap 'rm -f "$results_file"' EXIT

step "1 — System"
if [[ "$(uname -s)" != "Darwin" ]]; then
  error "This setup supports macOS only (detected: $(uname -s)). Nothing was changed."
  exit 1
fi
system_ok=1
"$SCRIPT_DIR/scripts/system-check.sh" || system_ok=0
for tool in hdiutil ditto codesign spctl lipo plutil; do
  command -v "$tool" >/dev/null 2>&1 || { error "macOS tool not found: $tool"; system_ok=0; }
done
if mkdir -p "$USER_APPS_DIR" 2>/dev/null && [[ -w "$USER_APPS_DIR" ]]; then
  ok "Writable app folder: $USER_APPS_DIR"
else
  error "$USER_APPS_DIR is not writable; desktop apps cannot be installed."
  system_ok=0
fi
if curl -fsS -o /dev/null --connect-timeout 10 --max-time 20 https://github.com; then
  ok "Network: github.com reachable"
else
  warn "Network check failed; downloads below may fail. Already-installed items are still checked."
fi
(( system_ok )) && step_status[system]=OK || step_status[system]=FAIL

step "2 — Development environment (bootstrap.sh)"
CODYSSEY_FROM_SETUP=1 "$SCRIPT_DIR/bootstrap.sh" && step_status[bootstrap]=OK || step_status[bootstrap]=FAIL

step "3 — Desktop apps (setup-apps.sh)"
CODYSSEY_RESULTS_FILE="$results_file" "$SCRIPT_DIR/setup-apps.sh" && step_status[apps]=OK || step_status[apps]=FAIL

step "4 — Verification (verify.sh)"
CODYSSEY_REQUIRED_APPS="Claude Discord" "$SCRIPT_DIR/verify.sh" && step_status[verify]=OK || step_status[verify]=FAIL

print -- "\n"
rule
print -- " Summary"
rule
line() { printf '  %-30s [%s]\n' "$1" "$2"; }
print -- "Steps"
line "System check" "$step_status[system]"
line "Development environment" "$step_status[bootstrap]"
line "Desktop apps" "$step_status[apps]"
line "Verification" "$step_status[verify]"
print -- ""
print -- "Desktop Applications"
manual=()
while IFS='|' read -r name app_status detail; do
  line "$name" "$app_status"
  print -r -- "    $detail"
  [[ "$app_status" == MANUAL* ]] && manual+=("$name: $detail")
  [[ "$app_status" == "OPTIONAL / MANUAL" ]] && manual+=("ChatGPT (optional): install it yourself from ${APP_DOWNLOAD_PAGE[ChatGPT]} (see README)")
done < "$results_file"

print -- ""
print -- "Next steps (manual)"
for item in $manual; do
  print -r -- "  - $item"
done
if command -v gh >/dev/null 2>&1 && ! gh auth status --hostname github.com >/dev/null 2>&1; then
  print -- "  - GitHub: gh auth login --web   (then gh auth setup-git if it was not run)"
fi
print -- "  - Sign in yourself to GitHub, Codex, Claude Code, Claude, Discord (and ChatGPT)."
print -- "  - Approve macOS permission prompts (notifications, accessibility, ...) when apps ask."
print -- "  - Open a new terminal so ~/.zshrc changes take effect."
print -- "  - Before leaving a shared Mac: ./cleanup.sh (includes gh auth logout)."

print -- ""
rule
if [[ "${(j::)${(v)step_status}}" == "OKOKOKOK" ]]; then
  print -- " Setup completed"
  rule
  exit 0
fi
print -- " Setup PARTIAL — fix the [FAIL]/[MANUAL REQUIRED] items above and run ./setup.sh again"
rule
exit 1
