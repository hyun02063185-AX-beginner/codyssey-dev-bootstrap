#!/bin/zsh

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/common.sh"

if ! command -v volta >/dev/null 2>&1; then
  error "Volta is unavailable; cannot install Node.js."
  exit 1
fi

node_version="$(node --version 2>/dev/null || true)"
if [[ "${node_version#v}" == ${NODE_VERSION}.* ]]; then
  skip "Node.js $node_version already satisfies major version $NODE_VERSION"
  exit 0
fi

install "Node.js $NODE_VERSION with Volta"
if volta install "node@$NODE_VERSION"; then
  node_version="$(node --version 2>/dev/null || true)"
  if [[ "${node_version#v}" == ${NODE_VERSION}.* ]]; then
    ok "Node.js installed: $node_version"
    exit 0
  fi
fi

error "Node.js $NODE_VERSION installation failed."
exit 1
