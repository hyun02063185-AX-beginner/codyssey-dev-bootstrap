#!/bin/zsh

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/common.sh"

if version="$(command_version codex)"; then
  skip "Codex CLI already available: $version"
  exit 0
fi

if ! command -v npm >/dev/null 2>&1; then
  error "npm is unavailable; install Node.js first."
  exit 1
fi

install "latest Codex CLI with npm (user-managed Volta tools directory)"
if npm install -g @openai/codex; then
  if version="$(command_version codex)"; then
    ok "Codex CLI installed: $version"
    exit 0
  fi
fi

error "Codex CLI installation failed."
exit 1
