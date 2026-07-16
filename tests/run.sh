#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/personal-skills-test.XXXXXX")"
trap 'rm -rf -- "$TMP"' EXIT HUP INT TERM
DEST="$TMP/agents/skills"

fail() { printf 'FAIL: %s\n' "$*" >&2; exit 1; }

AGENTS_SKILLS_DIR="$DEST" "$ROOT/install.sh" gmail >/dev/null
[[ -f "$DEST/gmail/SKILL.md" ]] || fail "SKILL.md was not copied"
[[ -x "$DEST/gmail/scripts/gog.sh" ]] || fail "executable mode was not preserved"
[[ -f "$DEST/gmail/.aditya-vinodh-skills-install" ]] || fail "ownership marker missing"
grep -q 'repository=https://github.com/aditya-vinodh/skills' \
  "$DEST/gmail/.aditya-vinodh-skills-install" || fail "ownership marker is incorrect"

# A managed install can be updated idempotently.
AGENTS_SKILLS_DIR="$DEST" "$ROOT/install.sh" gmail >/dev/null

# An unowned destination is protected.
mkdir -p "$DEST/unowned"
printf '%s\n' test > "$DEST/unowned/SKILL.md"
mkdir -p "$TMP/repo/skills/unowned"
printf '%s\n' test > "$TMP/repo/skills/unowned/SKILL.md"
if AGENTS_SKILLS_DIR="$DEST" "$ROOT/uninstall.sh" unowned >/dev/null 2>&1; then
  fail "uninstall removed an unowned skill"
fi

AGENTS_SKILLS_DIR="$DEST" "$ROOT/uninstall.sh" gmail >/dev/null
[[ ! -e "$DEST/gmail" ]] || fail "managed skill was not removed"

# Link mode points at the repository source and is removable.
AGENTS_SKILLS_DIR="$DEST" "$ROOT/install.sh" --link gmail >/dev/null
[[ -L "$DEST/gmail" ]] || fail "link mode did not create a symlink"
[[ "$(readlink "$DEST/gmail")" == "$ROOT/skills/gmail" ]] || fail "symlink target is incorrect"
AGENTS_SKILLS_DIR="$DEST" "$ROOT/uninstall.sh" --all >/dev/null
[[ ! -L "$DEST/gmail" ]] || fail "linked skill was not removed by --all"

# The gog wrapper prefers an existing binary and preserves arguments.
mkdir -p "$TMP/fake-bin"
cat > "$TMP/fake-bin/gog" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$@"
EOF
chmod +x "$TMP/fake-bin/gog"
wrapper_output="$(PATH="$TMP/fake-bin:$PATH" "$ROOT/skills/gmail/scripts/gog.sh" gmail search 'newer_than:1d' --json)"
printf '%s\n' "$wrapper_output" | grep -q '^gmail$' || fail "gog wrapper did not invoke the PATH binary"
printf '%s\n' "$wrapper_output" | grep -q '^newer_than:1d$' || fail "gog wrapper did not preserve arguments"

printf 'All installer tests passed.\n'
