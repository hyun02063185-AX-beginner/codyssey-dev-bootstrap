#!/bin/zsh
# Desktop app helpers shared by setup-apps.sh and verify.sh. This file is sourced.

if [[ -n "${CODYSSEY_APPS_LOADED:-}" ]]; then
  return 0
fi
CODYSSEY_APPS_LOADED=1

# Overridable only so the install path can be tested in a scratch directory.
USER_APPS_DIR="${CODYSSEY_USER_APPS_DIR:-$HOME/Applications}"
SYSTEM_APPS_DIR="${CODYSSEY_SYSTEM_APPS_DIR:-/Applications}"
DOWNLOADS_DIR="${CODYSSEY_DOWNLOADS_DIR:-$HOME/Downloads}"
APP_CACHE_DIR="${CODYSSEY_CACHE_DIR:-$HOME/Library/Caches/codyssey-dev-bootstrap}"

# Expected signing identity per app. Team IDs were read from apps signed by each
# developer (codesign -dv); an app that does not match is never installed.
typeset -gA APP_BUNDLE_IDS APP_TEAM_ID APP_DOWNLOAD_URL APP_DOWNLOAD_PAGE APP_DOWNLOAD_HOSTS
APP_BUNDLE_IDS=(
  ChatGPT "com.openai.codex com.openai.chat"
  Claude  "com.anthropic.claudefordesktop"
  Discord "com.hnc.Discord"
)
APP_TEAM_ID=(
  ChatGPT 2DC432GLL2   # OpenAI OpCo, LLC
  Claude  Q6L2SF6YDW   # Anthropic PBC
  Discord 53Q6R32WPB   # Discord, Inc.
)
# Official entry points from each download page. Both serve a universal DMG.
APP_DOWNLOAD_URL=(
  Claude  "https://claude.ai/api/desktop/darwin/universal/dmg/latest/redirect"
  Discord "https://discord.com/api/download/stable?platform=osx"
)
APP_DOWNLOAD_PAGE=(
  ChatGPT "https://chatgpt.com/download/"
  Claude  "https://claude.com/download"
  Discord "https://discord.com/download"
)
# Hosts a scripted download may finally land on after redirects.
APP_DOWNLOAD_HOSTS=(
  Claude  "claude.ai *.claude.ai claude.com *.claude.com *.anthropic.com"
  Discord "discord.com *.discord.com *.discordapp.net *.discordapp.com"
)

# Print the first existing bundle: ~/Applications first, then /Applications.
find_app() {
  local dir
  for dir in "$USER_APPS_DIR" "$SYSTEM_APPS_DIR"; do
    if [[ -d "$dir/$1.app" ]]; then
      print -r -- "$dir/$1.app"
      return 0
    fi
  done
  return 1
}

# Check bundle id, code signature, developer Team ID, Gatekeeper and CPU
# architecture. On success REPLY is the app version; on failure, the reason.
app_check() {
  local app_path="$1" name="$2"
  local plist="$app_path/Contents/Info.plist"
  local bundle_id version executable team archs
  REPLY=""
  if [[ ! -f "$plist" ]]; then
    REPLY="not a valid app bundle (Info.plist missing)"
    return 1
  fi
  bundle_id="$(plutil -extract CFBundleIdentifier raw "$plist" 2>/dev/null)"
  version="$(plutil -extract CFBundleShortVersionString raw "$plist" 2>/dev/null)"
  executable="$(plutil -extract CFBundleExecutable raw "$plist" 2>/dev/null)"
  if [[ -z "$bundle_id" || " ${APP_BUNDLE_IDS[$name]} " != *" $bundle_id "* ]]; then
    REPLY="unexpected bundle id: ${bundle_id:-none}"
    return 1
  fi
  if ! codesign --verify --deep --strict "$app_path" >/dev/null 2>&1; then
    REPLY="code signature is invalid or modified"
    return 1
  fi
  team="$(codesign -dv "$app_path" 2>&1 | sed -n 's/^TeamIdentifier=//p')"
  if [[ "$team" != "${APP_TEAM_ID[$name]}" ]]; then
    REPLY="signed by Team ID ${team:-none}, expected ${APP_TEAM_ID[$name]}"
    return 1
  fi
  if ! spctl --assess --type execute "$app_path" >/dev/null 2>&1; then
    REPLY="rejected by Gatekeeper (spctl)"
    return 1
  fi
  archs="$(lipo -archs "$app_path/Contents/MacOS/$executable" 2>/dev/null)"
  if [[ " $archs " != *" $(uname -m) "* ]]; then
    REPLY="built for ${archs:-unknown}, not $(uname -m)"
    return 1
  fi
  REPLY="${version:-unknown version}"
  return 0
}

app_running() {
  pgrep -f -- "$1/Contents/MacOS/" >/dev/null 2>&1
}

# Download the official DMG into $2. Fails unless the final URL is an expected
# host and the file is a disk image. The app signature is checked separately.
download_app_dmg() {
  local name="$1" destination="$2" final_url host pattern
  final_url="$(curl -fL --proto '=https' --retry 2 --connect-timeout 15 --max-time 1800 \
    -o "$destination" -w '%{url_effective}' "${APP_DOWNLOAD_URL[$name]}" 2>/dev/null)" || {
    rm -f "$destination"
    REPLY="official download did not succeed (network error or the site blocks scripted downloads)"
    return 1
  }
  host="${${final_url#https://}%%/*}"
  for pattern in ${=APP_DOWNLOAD_HOSTS[$name]}; do
    if [[ "$host" == ${~pattern} ]]; then
      if hdiutil imageinfo "$destination" >/dev/null 2>&1; then
        return 0
      fi
      rm -f "$destination"
      REPLY="downloaded file is not a disk image"
      return 1
    fi
  done
  rm -f "$destination"
  REPLY="download ended on an unexpected host: $host"
  return 1
}

# Install $name.app from a DMG into ~/Applications. The new copy is verified
# before it replaces anything; a replaced bundle is kept as a backup.
install_app_from_dmg() {
  local name="$1" dmg="$2" work="$3"
  local mount_point="$work/mount" source_app
  local staged="$USER_APPS_DIR/.$name.app.codyssey-new"
  local target="$USER_APPS_DIR/$name.app" backup=""
  mkdir -p "$mount_point" "$USER_APPS_DIR" || { REPLY="cannot create $USER_APPS_DIR"; return 1; }
  if ! hdiutil attach -nobrowse -readonly -noautoopen -mountpoint "$mount_point" "$dmg" >/dev/null 2>&1; then
    REPLY="could not mount $dmg"
    return 1
  fi
  {
    source_app="$mount_point/$name.app"
    if [[ ! -d "$source_app" ]]; then
      REPLY="$name.app not found inside the disk image"
      return 1
    fi
    if ! app_check "$source_app" "$name"; then
      REPLY="refused to install: $REPLY"
      return 1
    fi
    rm -rf "$staged"
    if ! ditto "$source_app" "$staged"; then
      rm -rf "$staged"
      REPLY="copy to $USER_APPS_DIR failed"
      return 1
    fi
  } always {
    hdiutil detach "$mount_point" -quiet >/dev/null 2>&1 || hdiutil detach "$mount_point" -force -quiet >/dev/null 2>&1
  }
  if ! app_check "$staged" "$name"; then
    rm -rf "$staged"
    REPLY="copied app failed verification: $REPLY"
    return 1
  fi
  if [[ -e "$target" ]]; then
    backup="$USER_APPS_DIR/.$name.app.codyssey-backup-$(date +%Y%m%d%H%M%S)"
    if ! mv "$target" "$backup"; then
      rm -rf "$staged"
      REPLY="could not move the existing $target aside; nothing changed"
      return 1
    fi
  fi
  if ! mv "$staged" "$target"; then
    [[ -n "$backup" ]] && mv "$backup" "$target"
    rm -rf "$staged"
    REPLY="could not move the new app into place; previous state restored"
    return 1
  fi
  app_check "$target" "$name"
  [[ -n "$backup" ]] && REPLY="$REPLY (previous bundle kept at $backup)"
  return 0
}
