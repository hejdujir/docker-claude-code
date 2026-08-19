#!/usr/bin/env bash
# Install dcc without Homebrew:
#   curl -fsSL https://raw.githubusercontent.com/hejdujir/docker-claude-code/main/install.sh | bash
set -euo pipefail

REPO="${DCC_REPO:-hejdujir/docker-claude-code}"
REF="${DCC_REF:-main}"
PREFIX="${DCC_PREFIX:-$HOME/.local}"
SHARE="$PREFIX/share/dcc"

command -v curl >/dev/null || { echo "curl is missing" >&2; exit 1; }
command -v tar  >/dev/null || { echo "tar is missing" >&2; exit 1; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
echo "Downloading $REPO@$REF…"
curl -fsSL "https://github.com/$REPO/archive/$REF.tar.gz" | tar -xz -C "$tmp" --strip-components=1

mkdir -p "$PREFIX/bin" "$SHARE"
install -m 0755 "$tmp/bin/dcc" "$PREFIX/bin/dcc"
rm -rf "$SHARE/image"; cp -R "$tmp/image" "$SHARE/image"

echo "✓ installed: $PREFIX/bin/dcc"
case ":$PATH:" in
  *":$PREFIX/bin:"*) ;;
  *) echo "  Add to PATH:  export PATH=\"$PREFIX/bin:\$PATH\"" ;;
esac
echo "  Get started:  mkdir -p ~/dev/claude && cd ~/dev/claude && dcc create"
