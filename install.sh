#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_ROOT="$REPO_ROOT/skills"
DEST_ROOT="${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}"
MODE=copy
FORCE=0
DRY_RUN=0
LIST_ONLY=0
ALL=0
SELECTED=()

usage() {
  cat <<'EOF'
Usage: ./install.sh [options] [skill ...]

Install personal skills into ~/.agents/skills.

Options:
  --all       Install every skill (the default when none are named)
  --list      List available skills and exit
  --link      Symlink skills instead of copying them
  --force     Replace an existing unowned destination
  --dry-run   Show what would happen without changing files
  -h, --help  Show this help

Environment:
  AGENTS_SKILLS_DIR  Override the destination directory
EOF
}

fail() { printf 'error: %s\n' "$*" >&2; exit 1; }
log() { printf '%s\n' "$*" >&2; }

available_skills() {
  local path
  for path in "$SOURCE_ROOT"/*; do
    [[ -d "$path" && -f "$path/SKILL.md" ]] || continue
    basename "$path"
  done | LC_ALL=C sort
}

while (($#)); do
  case "$1" in
    --all) ALL=1 ;;
    --list) LIST_ONLY=1 ;;
    --link) MODE=link ;;
    --force) FORCE=1 ;;
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    --) shift; while (($#)); do SELECTED+=("$1"); shift; done; break ;;
    -*) fail "unknown option: $1" ;;
    *) SELECTED+=("$1") ;;
  esac
  shift
done

[[ -d "$SOURCE_ROOT" ]] || fail "skills directory not found: $SOURCE_ROOT"

if ((LIST_ONLY)); then
  available_skills
  exit 0
fi

if ((ALL)) && ((${#SELECTED[@]})); then
  fail "use either --all or named skills, not both"
fi

if ((ALL)) || ((${#SELECTED[@]} == 0)); then
  while IFS= read -r skill; do
    SELECTED+=("$skill")
  done < <(available_skills)
fi

((${#SELECTED[@]})) || fail "no skills found under $SOURCE_ROOT"

for skill in "${SELECTED[@]}"; do
  [[ "$skill" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]] || fail "invalid skill name: $skill"
  [[ -f "$SOURCE_ROOT/$skill/SKILL.md" ]] || fail "unknown or invalid skill: $skill"
done

if ((DRY_RUN)); then
  log "Would create: $DEST_ROOT"
else
  mkdir -p "$DEST_ROOT"
fi

commit="unknown"
if command -v git >/dev/null 2>&1; then
  commit="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || printf 'uncommitted')"
fi

for skill in "${SELECTED[@]}"; do
  src="$SOURCE_ROOT/$skill"
  dest="$DEST_ROOT/$skill"

  owned=0
  [[ -f "$dest/.aditya-vinodh-skills-install" ]] && owned=1
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    owned=1
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    ((owned || FORCE)) || fail "$dest already exists and is not managed by this repository (use --force to replace it)"
  fi

  if ((DRY_RUN)); then
    log "Would install $skill -> $dest ($MODE)"
    continue
  fi

  backup=""
  if [[ -e "$dest" || -L "$dest" ]]; then
    backup="$DEST_ROOT/.${skill}.backup.$$"
    rm -rf -- "$backup"
    mv -- "$dest" "$backup"
  fi

  if [[ "$MODE" == link ]]; then
    if ! ln -s "$src" "$dest"; then
      [[ -n "$backup" ]] && mv -- "$backup" "$dest"
      fail "failed to link $skill"
    fi
  else
    stage="$(mktemp -d "$DEST_ROOT/.${skill}.install.XXXXXX")"
    if ! cp -R "$src/." "$stage/"; then
      rm -rf -- "$stage"
      [[ -n "$backup" ]] && mv -- "$backup" "$dest"
      fail "failed to copy $skill"
    fi
    cat > "$stage/.aditya-vinodh-skills-install" <<EOF
repository=https://github.com/aditya-vinodh/skills
skill=$skill
commit=$commit
EOF
    if ! mv -- "$stage" "$dest"; then
      rm -rf -- "$stage"
      [[ -n "$backup" ]] && mv -- "$backup" "$dest"
      fail "failed to activate $skill"
    fi
  fi

  [[ -z "$backup" ]] || rm -rf -- "$backup"
  log "Installed $skill -> $dest ($MODE)"
done

log "Done. Restart or reload your agent client if it does not detect new skills automatically."
