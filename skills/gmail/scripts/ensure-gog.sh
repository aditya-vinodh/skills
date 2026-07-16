#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${GOG_INSTALL_DIR:-${XDG_BIN_HOME:-$HOME/.local/bin}}"

if command -v gog >/dev/null 2>&1; then
  exit 0
fi
if [[ -x "$INSTALL_DIR/gog" ]]; then
  exit 0
fi

printf 'gog is not installed; fetching a checksum-verified release from https://github.com/openclaw/gogcli/.\n' >&2
"$SCRIPT_DIR/install-gog.sh"
