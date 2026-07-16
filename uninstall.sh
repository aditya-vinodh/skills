#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$REPO_ROOT/skills"
DEST_ROOT="${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}"
ALL=0
FORCE=0
DRY_RUN=0
SELECTED=()

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [options] [skill ...]

Options:
  --all       Uninstall all skills owned by this repository
  --force     Remove a named skill even when no ownership marker is present
  --dry-run   Show what would happen
  -h, --help  Show this help
EOF
}
fail() { printf 'error: %s\n' "$*" >&2; exit 1; }

while (($#)); do
  case "$1" in
    --all) ALL=1 ;;
    --force) FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    -*) fail "unknown option: $1" ;;
    *) SELECTED+=("$1") ;;
  esac
  shift
done

if ((ALL)) && ((${#SELECTED[@]})); then fail "use either --all or named skills"; fi
if ((ALL)); then
  SELECTED=()
  if [[ -d "$DEST_ROOT" ]]; then
    for path in "$DEST_ROOT"/*; do
      [[ -e "$path" || -L "$path" ]] || continue
      [[ -f "$path/.aditya-vinodh-skills-install" || ( -L "$path" && "$(readlink "$path")" == "$SOURCE_ROOT"/* ) ]] || continue
      SELECTED+=("$(basename "$path")")
    done
  fi
fi
((${#SELECTED[@]})) || fail "name at least one skill or use --all"

for skill in "${SELECTED[@]}"; do
  [[ "$skill" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || fail "invalid skill name: $skill"
  dest="$DEST_ROOT/$skill"
  [[ -e "$dest" || -L "$dest" ]] || { printf 'Not installed: %s\n' "$skill" >&2; continue; }

  owned=0
  [[ -f "$dest/.aditya-vinodh-skills-install" ]] && owned=1
  [[ -L "$dest" && "$(readlink "$dest")" == "$SOURCE_ROOT/$skill" ]] && owned=1
  ((owned || FORCE)) || fail "$dest is not managed by this repository (use --force to remove it)"

  if ((DRY_RUN)); then
    printf 'Would remove: %s\n' "$dest" >&2
  else
    rm -rf -- "$dest"
    printf 'Removed: %s\n' "$dest" >&2
  fi
done
