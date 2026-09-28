#!/bin/zsh

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/scripts/common.sh"

print -- "=== Codyssey Dev Bootstrap ==="
print -- "This script only uses your home directory. It never uses sudo or Homebrew."

failures=0
run_step() {
  local label="$1"
  local script="$2"
  print -- "\n--- $label ---"
  if "$script"; then
    return 0
  fi
  error "$label did not complete. See the message above."
  ((failures++))
}

run_step "System checks" "$SCRIPT_DIR/scripts/system-check.sh"
run_step "Volta" "$SCRIPT_DIR/scripts/install-volta.sh"
run_step "Node.js" "$SCRIPT_DIR/scripts/install-node.sh"
run_step "Codex CLI" "$SCRIPT_DIR/scripts/install-codex.sh"
run_step "Claude Code" "$SCRIPT_DIR/scripts/install-claude.sh"

print -- "\n--- zsh configuration ---"
zshrc="$HOME/.zshrc"
start_marker="# >>> codyssey-dev-bootstrap >>>"
end_marker="# <<< codyssey-dev-bootstrap <<<"
if [[ -f "$zshrc" ]] && grep -Fqx "$start_marker" "$zshrc" && grep -Fqx "$end_marker" "$zshrc"; then
  skip "Existing Codyssey PATH block kept in $zshrc"
else
  {
    print -- ""
    print -- "$start_marker"
    print -- 'export VOLTA_HOME="$HOME/.volta"'
    print -- 'export PATH="$VOLTA_HOME/bin:$PATH"'
    print -- 'export PATH="$HOME/.local/bin:$PATH"'
    print -- "$end_marker"
  } >> "$zshrc"
  ok "Added Codyssey PATH block to $zshrc"
fi

run_step "VS Code extensions" "$SCRIPT_DIR/scripts/setup-vscode.sh"

print -- "\n--- Verification ---"
if "$SCRIPT_DIR/verify.sh"; then
  :
else
  ((failures++))
fi

if (( failures == 0 )); then
  ok "Bootstrap complete. Open a new terminal to load .zshrc automatically."
  exit 0
fi

error "Bootstrap completed with $failures failed step(s). Fix the reported issue and run ./bootstrap.sh again."
exit 1
