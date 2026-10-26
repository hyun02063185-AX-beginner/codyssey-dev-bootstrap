#!/bin/zsh
# GitHub sign-in is the user's choice: this step never fails the setup and never
# stores or prints tokens. gh keeps its token in the macOS keychain.

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/common.sh"

if ! command -v gh >/dev/null 2>&1; then
  warn "GitHub CLI is not available; skipping GitHub sign-in."
  exit 0
fi

gh_account() {
  gh auth status --hostname github.com 2>/dev/null | sed -n 's/.*Logged in to github.com account \([^ ]*\).*/\1/p' | head -n 1
}

if gh auth status --hostname github.com >/dev/null 2>&1; then
  skip "GitHub CLI already signed in as $(gh_account)"
elif [[ -t 0 && -t 1 ]]; then
  print -- "GitHub CLI is not signed in. Sign-in uses your browser and a one-time code;"
  print -- "the token is stored in your macOS keychain, never in this repository or a log."
  read -r "answer?Sign in to GitHub now? [y/N] " || answer=""
  if [[ "$answer" == [yY]* ]]; then
    if gh auth login --hostname github.com --web --git-protocol https && gh auth status --hostname github.com >/dev/null 2>&1; then
      ok "GitHub CLI signed in as $(gh_account)"
    else
      warn "GitHub sign-in did not complete. Run later: gh auth login --web"
      exit 0
    fi
  else
    print -- "[MANUAL] GitHub sign-in skipped. Run later: gh auth login --web"
    exit 0
  fi
else
  print -- "[MANUAL] GitHub CLI is not signed in. Run in a terminal: gh auth login --web"
  exit 0
fi

# Let git use gh for https://github.com, unless another github.com helper is set.
# A global credential.helper (e.g. osxkeychain) is left as is.
helpers="$(git config --global --get-all credential.https://github.com.helper 2>/dev/null)"
if [[ "$helpers" == *"gh auth git-credential"* ]]; then
  skip "git already uses GitHub CLI for https://github.com"
elif [[ -n "${helpers//[[:space:]]/}" ]]; then
  warn "git already has another credential helper for https://github.com; left unchanged."
elif gh auth setup-git --hostname github.com; then
  ok "git now uses GitHub CLI for https://github.com (gh auth setup-git)"
else
  warn "gh auth setup-git failed; git push over HTTPS may ask for credentials."
fi
exit 0
