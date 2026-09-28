#!/bin/zsh

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/common.sh"

plugin_dir="$HOME/.zsh/zsh-autosuggestions"
plugin_file="$plugin_dir/zsh-autosuggestions.zsh"
zshrc="$HOME/.zshrc"
start_marker="# >>> codyssey-dev-bootstrap zsh-autosuggestions >>>"
end_marker="# <<< codyssey-dev-bootstrap zsh-autosuggestions <<<"
legacy_comment="# zsh autosuggestions"
legacy_source='source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"'
legacy_strategy='ZSH_AUTOSUGGEST_STRATEGY=(history completion)'

if [[ -d "$plugin_dir" ]]; then
  if [[ -r "$plugin_file" ]]; then
    skip "zsh-autosuggestions already installed at $plugin_dir"
  else
    error "zsh-autosuggestions directory exists but $plugin_file is missing. Refusing to replace it; inspect $plugin_dir."
    exit 1
  fi
else
  command -v git >/dev/null 2>&1 || {
    error "Git is required to install zsh-autosuggestions from GitHub."
    exit 1
  }
  install "zsh-autosuggestions from GitHub into $plugin_dir"
  mkdir -p "$HOME/.zsh" || exit 1
  if ! git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$plugin_dir"; then
    error "zsh-autosuggestions clone failed; no shell configuration was changed."
    exit 1
  fi
  [[ -r "$plugin_file" ]] || {
    error "Clone completed but $plugin_file was not found."
    exit 1
  }
  ok "zsh-autosuggestions installed at $plugin_dir"
fi

# Only this bootstrap's own block and the exact legacy lines it previously used
# are changed. Everything else in .zshrc stays in its original order.
[[ -e "$zshrc" ]] || : > "$zshrc"
temporary="$(mktemp "${TMPDIR:-/tmp}/codyssey-zshrc.XXXXXX")" || {
  error "Could not prepare a safe temporary .zshrc update."
  exit 1
}

inside_block=0
legacy_migrated=0
while IFS= read -r line || [[ -n "$line" ]]; do
  if [[ "$line" == "$start_marker" ]]; then
    inside_block=1
    continue
  fi
  if (( inside_block )); then
    if [[ "$line" == "$end_marker" ]]; then
      inside_block=0
    fi
    continue
  fi
  # Migrate only the old, exact standalone setup lines so they cannot be sourced
  # twice after the managed block is added.
  if [[ "$line" == "$legacy_comment" || "$line" == "$legacy_source" || "$line" == "$legacy_strategy" ]]; then
    legacy_migrated=1
    continue
  fi
  print -r -- "$line" >> "$temporary"
done < "$zshrc"

if (( inside_block )); then
  rm -f "$temporary"
  error "Found an unterminated Codyssey zsh-autosuggestions block in $zshrc; no changes were made."
  exit 1
fi

{
  print -- ""
  print -- "$start_marker"
  print -- 'autoload -Uz compaudit'
  print -- 'insecure_completion_paths=("${(@f)$(compaudit 2>/dev/null)}")'
  print -- 'for completion_path in "${insecure_completion_paths[@]}"; do'
  print -- '  fpath=("${(@)fpath:#$completion_path}")'
  print -- 'done'
  print -- 'unset completion_path insecure_completion_paths'
  print -- 'autoload -Uz compinit'
  print -- 'compinit'
  print -- 'source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"'
  print -- 'ZSH_AUTOSUGGEST_STRATEGY=(history completion)'
  print -- "$end_marker"
} >> "$temporary"

mv "$temporary" "$zshrc" || {
  rm -f "$temporary"
  error "Could not update $zshrc."
  exit 1
}

if (( legacy_migrated )); then
  ok "Migrated existing zsh-autosuggestions lines into the Codyssey-managed block"
else
  ok "Configured zsh-autosuggestions and zsh completion in $zshrc"
fi
