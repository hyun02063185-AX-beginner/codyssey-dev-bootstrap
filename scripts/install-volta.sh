#!/bin/zsh

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/common.sh"

if version="$(command_version volta)"; then
  skip "Volta already available: $version"
  exit 0
fi

if ! command -v curl >/dev/null 2>&1; then
  error "curl is required to install Volta."
  exit 1
fi

install "Volta in $HOME/.volta (official installer; no sudo)"
if curl https://get.volta.sh | bash; then
  export PATH="$VOLTA_HOME/bin:$PATH"
  if version="$(command_version volta)"; then
    ok "Volta installed: $version"
    exit 0
  fi
fi

error "Volta installation failed or volta is not available at $VOLTA_HOME/bin/volta."
exit 1
