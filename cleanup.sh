#!/bin/zsh

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/scripts/common.sh"

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  print -- "Usage: ./cleanup.sh"
  print -- "v0.1 is advisory only: it does not delete files, tokens, or login sessions."
  exit 0
fi

print -- "=== Codyssey Cleanup Guidance (no files deleted) ==="
print -- ""
print -- "User-managed installation locations:"
print -- "  Volta / Node / npm tools: $HOME/.volta"
print -- "  Claude Code:             $HOME/.local/bin/claude"
print -- "  zsh PATH block:          $HOME/.zshrc"
print -- ""
print -- "Before leaving a shared Mac:"
print -- "  - Review Git authentication with: git config --global --list"
print -- "  - Sign out of Codex and Claude Code if you no longer need the session."
print -- "  - Review browser and VS Code account sessions, then sign out where appropriate."
print -- "  - Do not share API keys, tokens, passwords, cookies, or credential files."
print -- ""
warn "v0.1 intentionally performs no automatic deletion. Remove personal data manually only after confirming the target."
