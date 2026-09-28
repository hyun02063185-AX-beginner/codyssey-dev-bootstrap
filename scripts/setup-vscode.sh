#!/bin/zsh

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/common.sh"

if ! command -v code >/dev/null 2>&1; then
  error "VS Code 'code' CLI is not available; cannot manage extensions."
  exit 1
fi

installed_extensions="$(code --list-extensions 2>/dev/null)"
failures=0
for extension in anthropic.claude-code openai.chatgpt; do
  if print -r -- "$installed_extensions" | grep -Fxiq "$extension"; then
    skip "VS Code extension already installed: $extension"
  else
    install "VS Code extension: $extension"
    if code --install-extension "$extension"; then
      ok "VS Code extension installed: $extension"
    else
      error "Failed to install VS Code extension: $extension"
      ((failures++))
    fi
  fi
done

exit $failures
