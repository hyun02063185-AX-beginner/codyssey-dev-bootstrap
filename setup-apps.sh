#!/bin/zsh

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/scripts/common.sh"
source "$SCRIPT_DIR/scripts/apps-common.sh"

# Claude and Discord are installed into ~/Applications. ChatGPT is only checked;
# install it yourself from https://chatgpt.com/download/ if you want it.
REQUIRED_APPS=(Claude Discord)

print -- "=== Codyssey Desktop Apps ==="
print -- "Installs into $USER_APPS_DIR only. Never uses sudo, never modifies $SYSTEM_APPS_DIR."

results_file="${CODYSSEY_RESULTS_FILE:-}"
record() {
  [[ -n "$results_file" ]] && print -r -- "$1|$2|$3" >> "$results_file"
  case "$2" in
    SKIP)    skip "$1: $3" ;;
    INSTALL) ok "$1 installed: $3" ;;
    OK)      ok "$1: $3" ;;
    FAIL)    error "$1: $3" ;;
    *)       print -r -- "[$2] $1: $3" ;;
  esac
}

mkdir -p "$APP_CACHE_DIR" || { error "Cannot create $APP_CACHE_DIR"; exit 1; }
work_root="$(mktemp -d "$APP_CACHE_DIR/run.XXXXXX")" || { error "Cannot create a temporary directory"; exit 1; }
trap 'rm -rf "$work_root"' EXIT

# Try each locally downloaded DMG for this app, newest first. Files in
# ~/Downloads belong to the user and are never deleted.
install_from_downloads() {
  local name="$1" work="$2" dmg
  for dmg in "$DOWNLOADS_DIR"/${name}*.dmg(N.om); do
    print -r -- "  trying $dmg"
    if install_app_from_dmg "$name" "$dmg" "$work"; then
      return 0
    fi
    warn "$name: $REPLY"
  done
  return 1
}

install_app() {
  local name="$1" work="$work_root/$1" download_reason answer
  mkdir -p "$work"

  print -r -- "  downloading the official DMG (${APP_DOWNLOAD_PAGE[$name]})"
  if download_app_dmg "$name" "$work/$name.dmg"; then
    if install_app_from_dmg "$name" "$work/$name.dmg" "$work"; then
      record "$name" INSTALL "$REPLY at $USER_APPS_DIR/$name.app"
      return 0
    fi
    record "$name" FAIL "$REPLY"
    return 1
  fi
  download_reason="$REPLY"
  warn "$name: $download_reason"

  if install_from_downloads "$name" "$work"; then
    record "$name" INSTALL "$REPLY at $USER_APPS_DIR/$name.app (from $DOWNLOADS_DIR)"
    return 0
  fi

  # Fall back to the browser: the user downloads the official DMG, this script
  # verifies and installs it. Only possible when someone is at the terminal.
  if [[ -t 0 && -t 1 ]]; then
    print -- ""
    print -- "[MANUAL REQUIRED] $name: download the macOS DMG in the browser."
    print -- "  1. The official page opens: ${APP_DOWNLOAD_PAGE[$name]}"
    print -- "  2. Download the Mac version into $DOWNLOADS_DIR (do not open it)."
    print -- "  3. Come back here and press Enter. Type s and Enter to skip."
    open "${APP_DOWNLOAD_PAGE[$name]}" 2>/dev/null
    while true; do
      read -r "answer?  Press Enter when the download has finished (s = skip): " || break
      [[ "$answer" == [sS]* ]] && break
      if install_from_downloads "$name" "$work"; then
        record "$name" INSTALL "$REPLY at $USER_APPS_DIR/$name.app (browser download)"
        return 0
      fi
      print -- "  No valid ${name}*.dmg found in $DOWNLOADS_DIR yet."
    done
  fi
  record "$name" "MANUAL REQUIRED" "download the DMG from ${APP_DOWNLOAD_PAGE[$name]} into $DOWNLOADS_DIR and re-run ./setup.sh"
  return 1
}

failures=0
for name in $REQUIRED_APPS; do
  print -- "\n--- $name ---"
  if app_path="$(find_app "$name")"; then
    if app_check "$app_path" "$name"; then
      record "$name" SKIP "$REPLY already installed at $app_path"
      continue
    fi
    if [[ "$app_path" != "$USER_APPS_DIR/"* ]]; then
      record "$name" FAIL "$app_path failed verification ($REPLY); it is admin-managed and was not modified"
      ((failures++))
      continue
    fi
    if app_running "$app_path"; then
      record "$name" FAIL "$app_path failed verification ($REPLY); quit $name and re-run to replace it"
      ((failures++))
      continue
    fi
    warn "$name at $app_path failed verification ($REPLY); a verified copy will replace it"
  fi
  install_app "$name" || ((failures++))
done

print -- "\n--- ChatGPT (optional, not installed by this script) ---"
if app_path="$(find_app ChatGPT)"; then
  if app_check "$app_path" ChatGPT; then
    record ChatGPT OK "$REPLY at $app_path"
  else
    record ChatGPT WARN "$app_path: $REPLY (left unchanged)"
  fi
else
  record ChatGPT "OPTIONAL / MANUAL" "not installed; get it from ${APP_DOWNLOAD_PAGE[ChatGPT]}"
fi

print -- ""
if (( failures == 0 )); then
  ok "Desktop apps ready: ${(j:, :)REQUIRED_APPS}"
  exit 0
fi
error "$failures desktop app(s) need attention."
exit 1
