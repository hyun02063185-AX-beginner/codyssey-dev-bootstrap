#!/bin/zsh

SCRIPT_DIR="${0:A:h}"
source "$SCRIPT_DIR/common.sh"

# Release zips from github.com/cli/cli are signed and notarized by GitHub.
GH_TEAM_ID="VEKTX9H2N7"
install_root="$HOME/.local/share/gh"
link="$HOME/.local/bin/gh"

if version="$(command_version gh)"; then
  skip "GitHub CLI already available: $version"
  exit 0
fi

if [[ -e "$link" || -L "$link" ]]; then
  error "$link exists but does not run; inspect it. It was not replaced."
  exit 1
fi

case "$(uname -m)" in
  x86_64) arch=amd64 ;;
  arm64)  arch=arm64 ;;
  *) error "No official GitHub CLI macOS build for $(uname -m)."; exit 1 ;;
esac

# The latest release tag comes from the redirect of the official releases page.
latest_url="$(curl -fsSIL --proto '=https' --max-time 30 -o /dev/null -w '%{url_effective}' https://github.com/cli/cli/releases/latest)" || latest_url=""
tag="${latest_url##*/tag/}"
if [[ "$latest_url" != https://github.com/cli/cli/releases/tag/v* || "$tag" == *[^v0-9.]* ]]; then
  error "Could not determine the latest GitHub CLI release (network?)."
  exit 1
fi
ver="${tag#v}"
base="https://github.com/cli/cli/releases/download/$tag"
zip_name="gh_${ver}_macOS_${arch}.zip"

cache="$HOME/Library/Caches/codyssey-dev-bootstrap"
mkdir -p "$cache" || exit 1
work="$(mktemp -d "$cache/gh.XXXXXX")" || exit 1
trap 'rm -rf "$work"' EXIT

install "GitHub CLI $ver ($arch) from github.com/cli/cli releases into $install_root (no sudo)"
if ! curl -fsSL --proto '=https' --retry 2 --max-time 600 -o "$work/$zip_name" "$base/$zip_name" ||
   ! curl -fsSL --proto '=https' --retry 2 --max-time 60 -o "$work/checksums.txt" "$base/gh_${ver}_checksums.txt"; then
  error "GitHub CLI download failed; nothing was installed."
  exit 1
fi

expected="$(awk -v f="$zip_name" '$2 == f { print $1 }' "$work/checksums.txt")"
actual="$(shasum -a 256 "$work/$zip_name" | awk '{ print $1 }')"
if [[ -z "$expected" || "$expected" != "$actual" ]]; then
  error "GitHub CLI checksum mismatch; nothing was installed."
  exit 1
fi

ditto -x -k "$work/$zip_name" "$work/x" || { error "Could not extract $zip_name."; exit 1; }
binary="$work/x/gh_${ver}_macOS_${arch}/bin/gh"
team="$(codesign -dv "$binary" 2>&1 | sed -n 's/^TeamIdentifier=//p')"
if ! codesign --verify --strict "$binary" >/dev/null 2>&1 || [[ "$team" != "$GH_TEAM_ID" ]]; then
  error "GitHub CLI signature check failed (Team ID ${team:-none}, expected $GH_TEAM_ID); nothing was installed."
  exit 1
fi

mkdir -p "$install_root" "${link:h}" || exit 1
rm -rf "$install_root/$ver"
mv "$work/x/gh_${ver}_macOS_${arch}" "$install_root/$ver" || { error "Could not install into $install_root."; exit 1; }
ln -s "$install_root/$ver/bin/gh" "$link" || { error "Could not create $link."; exit 1; }

if version="$(command_version gh)"; then
  ok "GitHub CLI installed: $version"
  exit 0
fi
error "GitHub CLI was installed but gh does not run."
exit 1
