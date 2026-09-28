#!/bin/zsh
# Shared helpers. This file is sourced by the executable scripts.

if [[ -n "${CODEYSSEY_COMMON_LOADED:-}" ]]; then
  return 0
fi
CODEYSSEY_COMMON_LOADED=1

COMMON_DIR="${0:A:h}"
PROJECT_ROOT="${COMMON_DIR:h}"

if [[ -f "$PROJECT_ROOT/versions.env" ]]; then
  source "$PROJECT_ROOT/versions.env"
fi
: "${NODE_VERSION:=24}"

export VOLTA_HOME="${VOLTA_HOME:-$HOME/.volta}"
case ":$PATH:" in
  *":$VOLTA_HOME/bin:"*) ;;
  *) export PATH="$VOLTA_HOME/bin:$PATH" ;;
esac
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH" ;;
esac

ok()      { print -r -- "[OK] $*"; }
skip()    { print -r -- "[SKIP] $*"; }
install() { print -r -- "[INSTALL] $*"; }
warn()    { print -r -- "[WARN] $*"; }
error()   { print -r -- "[ERROR] $*" >&2; }

command_version() {
  local executable="$1"
  local version_args="${2:---version}"
  command -v "$executable" >/dev/null 2>&1 || return 1
  "$executable" ${(z)version_args} 2>/dev/null | head -n 1
}

path_contains() {
  case ":$PATH:" in
    *":$1:"*) return 0 ;;
    *) return 1 ;;
  esac
}
