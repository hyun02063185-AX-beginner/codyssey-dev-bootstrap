#!/bin/zsh

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/scripts/common.sh"

usage() {
  print -- "Usage: ./update.sh [--check] [codex] [claude]"
  print -- "  --check   show versions only; change nothing"
  print -- "  codex / claude   limit to one tool (default: both)"
  print -- "bootstrap.sh never updates existing tools; use this script when you want newer versions."
}

check_only=0
targets=()
for arg in "$@"; do
  case "$arg" in
    -h|--help) usage; exit 0 ;;
    --check) check_only=1 ;;
    codex|claude) targets+=("$arg") ;;
    *) error "Unknown argument: $arg"; usage >&2; exit 2 ;;
  esac
done
(( ${#targets} )) || targets=(codex claude)

update_codex() {
  local before after latest
  if ! before="$(command_version codex)"; then
    error "Codex CLI is not installed; run ./bootstrap.sh first."
    return 1
  fi
  if ! command -v npm >/dev/null 2>&1; then
    error "npm is unavailable; install Node.js first."
    return 1
  fi
  latest="$(npm view @openai/codex version 2>/dev/null)" || latest=""
  if [[ -n "$latest" && "$before" == *"$latest"* ]]; then
    skip "Codex CLI is already latest: $before"
    return 0
  fi
  if (( check_only )); then
    print -- "[CHECK] Codex CLI: $before (latest: ${latest:-unknown})"
    return 0
  fi
  install "latest Codex CLI with npm"
  if npm install -g @openai/codex@latest && after="$(command_version codex)"; then
    ok "Codex CLI: $before -> $after"
    return 0
  fi
  error "Codex CLI update failed; the previous version was left in place."
  return 1
}

update_claude() {
  local before after
  if ! before="$(command_version claude)"; then
    error "Claude Code is not installed; run ./bootstrap.sh first."
    return 1
  fi
  if (( check_only )); then
    print -- "[CHECK] Claude Code: $before (latest is checked by 'claude update')"
    return 0
  fi
  install "Claude Code via 'claude update'"
  if claude update && after="$(command_version claude)"; then
    ok "Claude Code: $before -> $after"
    return 0
  fi
  error "Claude Code update failed; the previous version was left in place."
  return 1
}

failures=0
for target in $targets; do
  print -- "\n--- $target ---"
  "update_$target" || ((failures++))
done

print -- ""
if (( failures == 0 )); then
  (( check_only )) && ok "Check complete. No changes made." || ok "Update complete."
  exit 0
fi
error "$failures update step(s) failed."
exit 1
