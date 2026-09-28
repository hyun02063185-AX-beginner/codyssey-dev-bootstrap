#!/bin/zsh

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/scripts/common.sh"

status_failures=0
report() {
  local label="$1"
  local value="$2"
  local result="$3"
  printf '  %-18s %-28s [%s]\n' "$label" "$value" "$result"
  [[ "$result" == "OK" ]] || ((status_failures++))
}

version_or_missing() {
  command_version "$1" "${2:---version}" || print -- "not found"
}

print -- "=== Codyssey Dev Environment ==="
print -- ""
print -- "System"
macos_version="$(sw_vers -productVersion 2>/dev/null || print 'not macOS')"
[[ "$(uname -s)" == "Darwin" ]] && system_status="OK" || system_status="MISSING"
report "macOS" "$macos_version" "$system_status"
report "Architecture" "$(uname -m)" "OK"

print -- ""
print -- "Core"
for entry in 'Git:git:--version' 'curl:curl:--version' 'VS Code:code:--version'; do
  parts=(${(s/:/)entry})
  value="$(version_or_missing "$parts[2]" "$parts[3]")"
  [[ "$value" == "not found" ]] && result="MISSING" || result="OK"
  report "$parts[1]" "$value" "$result"
done

print -- ""
print -- "Runtime"
for entry in 'Volta:volta:--version' 'Node:node:--version' 'npm:npm:--version'; do
  parts=(${(s/:/)entry})
  value="$(version_or_missing "$parts[2]" "$parts[3]")"
  [[ "$value" == "not found" ]] && result="MISSING" || result="OK"
  report "$parts[1]" "$value" "$result"
done

print -- ""
print -- "AI"
for entry in 'Codex:codex:--version' 'Claude:claude:--version'; do
  parts=(${(s/:/)entry})
  value="$(version_or_missing "$parts[2]" "$parts[3]")"
  [[ "$value" == "not found" ]] && result="MISSING" || result="OK"
  report "$parts[1]" "$value" "$result"
done

print -- ""
print -- "Executables"
for executable in volta node npm codex claude; do
  executable_path="$(command -v "$executable" 2>/dev/null || print -- 'not found')"
  [[ "$executable_path" == "not found" ]] && result="MISSING" || result="OK"
  report "$executable" "$executable_path" "$result"
done

print -- ""
print -- "PATH"
path_contains "$VOLTA_HOME/bin" && report "Volta bin" "$VOLTA_HOME/bin" "OK" || report "Volta bin" "$VOLTA_HOME/bin" "MISSING"
path_contains "$HOME/.local/bin" && report "Local bin" "$HOME/.local/bin" "OK" || report "Local bin" "$HOME/.local/bin" "MISSING"

print -- ""
print -- "VS Code Extensions"
if command -v code >/dev/null 2>&1; then
  extensions="$(code --list-extensions 2>/dev/null)"
  for extension in openai.chatgpt anthropic.claude-code; do
    if print -r -- "$extensions" | grep -Fxiq "$extension"; then
      report "$extension" "installed" "OK"
    else
      report "$extension" "not installed" "MISSING"
    fi
  done
else
  report "VS Code extensions" "code CLI not found" "MISSING"
fi

print -- ""
print -- "Desktop Apps (optional)"
for app in ChatGPT Claude Discord; do
  app_path=""
  for app_dir in "$HOME/Applications" /Applications; do
    if [[ -d "$app_dir/$app.app" ]]; then
      app_path="$app_dir/$app.app"
      break
    fi
  done
  # Optional: a missing app is reported but never counted as a failure.
  if [[ -n "$app_path" ]]; then
    printf '  %-18s %-28s [%s]\n' "$app" "$app_path" "OK"
  else
    printf '  %-18s %-28s [%s]\n' "$app" "not installed" "OPTIONAL"
  fi
done

print -- ""
if (( status_failures == 0 )); then
  ok "Environment verification passed."
  exit 0
fi
error "Environment verification found $status_failures issue(s)."
exit 1
