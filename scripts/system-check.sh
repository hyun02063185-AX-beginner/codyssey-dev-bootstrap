#!/bin/zsh

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/common.sh"

failures=0

if [[ "$(uname -s)" == "Darwin" ]]; then
  ok "macOS $(sw_vers -productVersion 2>/dev/null || print 'unknown')"
else
  error "This bootstrap supports macOS only (detected: $(uname -s))."
  ((failures++))
fi

architecture="$(uname -m)"
if [[ "$architecture" == "x86_64" || "$architecture" == "arm64" ]]; then
  ok "Architecture: $architecture"
else
  warn "Unverified CPU architecture: $architecture"
fi

if [[ "${SHELL:-}" == */zsh || -n "${ZSH_VERSION:-}" ]]; then
  ok "zsh shell detected"
else
  warn "Current shell is ${SHELL:-unknown}; .zshrc will still be configured for new zsh terminals."
fi

if [[ -n "${HOME:-}" && -d "$HOME" ]]; then
  ok "Home directory: $HOME"
else
  error "A valid HOME directory is required."
  ((failures++))
fi

for tool in git curl code; do
  if version="$(command_version "$tool")"; then
    ok "$tool: $version"
  else
    error "Required system tool not found: $tool"
    ((failures++))
  fi
done

exit $failures
