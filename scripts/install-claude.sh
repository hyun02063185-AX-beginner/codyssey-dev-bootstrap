#!/bin/zsh

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/common.sh"

if version="$(command_version claude)"; then
  skip "Claude Code already available: $version"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  error "curl is required to install Claude Code."
  exit 1
fi

install "Claude Code in $HOME/.local/bin (official installer; no sudo)"
if curl -fsSL https://claude.ai/install.sh | bash; then
  export PATH="$HOME/.local/bin:$PATH"
  if version="$(command_version claude)"; then
    ok "Claude Code installed: $version"
    exit 0
  fi
fi

error "Claude Code installation failed or claude is not available at $HOME/.local/bin/claude."
exit 1
