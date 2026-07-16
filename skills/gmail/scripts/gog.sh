#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${GOG_INSTALL_DIR:-${XDG_BIN_HOME:-$HOME/.local/bin}}"

if command -v gog >/dev/null 2>&1; then
  GOG_BIN="$(command -v gog)"
elif [[ -x "$INSTALL_DIR/gog" ]]; then
  GOG_BIN="$INSTALL_DIR/gog"
else
  "$SCRIPT_DIR/ensure-gog.sh"
  [[ -x "$INSTALL_DIR/gog" ]] || { printf 'error: gog installation did not produce %s/gog\n' "$INSTALL_DIR" >&2; exit 1; }
  GOG_BIN="$INSTALL_DIR/gog"
fi

exec "$GOG_BIN" "$@"
