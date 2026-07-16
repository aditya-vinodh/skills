#!/usr/bin/env bash
set -euo pipefail

DEFAULT_VERSION="v0.34.0"
VERSION="${GOG_VERSION:-$DEFAULT_VERSION}"
INSTALL_DIR="${GOG_INSTALL_DIR:-${XDG_BIN_HOME:-$HOME/.local/bin}}"
REPLACE=0

usage() {
  cat <<'EOF'
Usage: install-gog.sh [--version vX.Y.Z] [--replace]

Download a pinned gog release, verify its SHA-256 checksum, and install it in
a user-local directory. No sudo is used.

Environment:
  GOG_VERSION      Override the release version
  GOG_INSTALL_DIR  Override the binary directory (default: ~/.local/bin)
EOF
}
fail() { printf 'error: %s\n' "$*" >&2; exit 1; }

while (($#)); do
  case "$1" in
    --version)
      (($# >= 2)) || fail "--version requires a value"
      VERSION="$2"; shift
      ;;
    --replace) REPLACE=1 ;;
    -h|--help) usage; exit 0 ;;
    *) fail "unknown argument: $1" ;;
  esac
  shift
done

[[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+([.-][A-Za-z0-9.-]+)?$ ]] || fail "invalid version: $VERSION (expected vX.Y.Z)"
command -v curl >/dev/null 2>&1 || fail "curl is required"
command -v tar >/dev/null 2>&1 || fail "tar is required"

case "$(uname -s)" in
  Darwin) os=darwin ;;
  Linux) os=linux ;;
  *) fail "unsupported operating system: $(uname -s)" ;;
esac

case "$(uname -m)" in
  x86_64|amd64) arch=amd64 ;;
  arm64|aarch64) arch=arm64 ;;
  *) fail "unsupported architecture: $(uname -m)" ;;
esac

binary="$INSTALL_DIR/gog"
if [[ -e "$binary" && $REPLACE -ne 1 ]]; then
  fail "$binary already exists; use --replace to update it"
fi

release_version="${VERSION#v}"
archive="gogcli_${release_version}_${os}_${arch}.tar.gz"
base_url="https://github.com/openclaw/gogcli/releases/download/${VERSION}"
tmp="$(mktemp -d "${TMPDIR:-/tmp}/gog-install.XXXXXX")"
trap 'rm -rf -- "$tmp"' EXIT HUP INT TERM

printf 'Downloading gog %s for %s/%s from openclaw/gogcli...\n' "$VERSION" "$os" "$arch" >&2
curl --fail --location --proto '=https' --tlsv1.2 \
  --retry 3 --retry-delay 1 \
  --output "$tmp/$archive" "$base_url/$archive"
curl --fail --location --proto '=https' --tlsv1.2 \
  --retry 3 --retry-delay 1 \
  --output "$tmp/checksums.txt" "$base_url/checksums.txt"

expected="$(awk -v file="$archive" '$2 == file || $2 == "*" file { print $1; exit }' "$tmp/checksums.txt")"
[[ "$expected" =~ ^[0-9a-fA-F]{64}$ ]] || fail "no valid checksum found for $archive"

if command -v sha256sum >/dev/null 2>&1; then
  actual="$(sha256sum "$tmp/$archive" | awk '{print $1}')"
elif command -v shasum >/dev/null 2>&1; then
  actual="$(shasum -a 256 "$tmp/$archive" | awk '{print $1}')"
else
  fail "sha256sum or shasum is required for release verification"
fi
actual="$(printf '%s' "$actual" | tr '[:upper:]' '[:lower:]')"
expected="$(printf '%s' "$expected" | tr '[:upper:]' '[:lower:]')"
[[ "$actual" == "$expected" ]] || fail "checksum verification failed for $archive"
printf 'Verified SHA-256 checksum.\n' >&2

tar -xzf "$tmp/$archive" -C "$tmp"
extracted="$(find "$tmp" -type f -name gog -perm -u+x -print -quit)"
if [[ -z "$extracted" ]]; then
  extracted="$(find "$tmp" -type f -name gog -print -quit)"
fi
[[ -n "$extracted" ]] || fail "the release archive did not contain a gog binary"

mkdir -p "$INSTALL_DIR"
staged="$INSTALL_DIR/.gog.install.$$"
cp "$extracted" "$staged"
chmod 0755 "$staged"
mv -f "$staged" "$binary"

"$binary" --version >&2
printf 'Installed gog at %s\n' "$binary" >&2
