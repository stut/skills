#!/usr/bin/env bash
# Install skills from this repo into ~/.claude/skills/.
# Each subdirectory containing a SKILL.md is treated as an installable skill.
#
# By default, skills are symlinked (so updates from the repo flow through).
# Pass --copy to copy instead — useful on systems where symlinks are awkward
# (e.g. Windows without Developer Mode).

set -euo pipefail

METHOD=link
for arg in "$@"; do
  case "$arg" in
    --copy) METHOD=copy ;;
    --link) METHOD=link ;;
    -h|--help)
      sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
      echo
      echo "Usage: $(basename "$0") [--copy|--link]"
      exit 0
      ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"

echo "Repo:   $REPO_DIR"
echo "Target: $TARGET_DIR"
echo "Method: $METHOD"
echo

# Find skill directories (any subdir with a SKILL.md at its root).
SKILLS=()
while IFS= read -r f; do
  SKILLS+=("$(dirname "$f")")
done < <(find "$REPO_DIR/skills" -mindepth 2 -maxdepth 2 -name SKILL.md 2>/dev/null | sort)

if [[ ${#SKILLS[@]} -eq 0 ]]; then
  echo "No skills found (looked for skills/*/SKILL.md under $REPO_DIR)." >&2
  exit 1
fi

echo "Found ${#SKILLS[@]} skill(s):"
for skill in "${SKILLS[@]}"; do
  echo "  - $(basename "$skill")"
done
echo

# Prompt for overwrite policy if any conflicts exist.
CONFLICTS=()
for skill in "${SKILLS[@]}"; do
  name="$(basename "$skill")"
  dest="$TARGET_DIR/$name"
  if [[ -e "$dest" || -L "$dest" ]]; then
    CONFLICTS+=("$name")
  fi
done

OVERWRITE=skip
if [[ ${#CONFLICTS[@]} -gt 0 ]]; then
  echo
  echo "Existing entries found in $TARGET_DIR for:"
  for c in "${CONFLICTS[@]}"; do echo "  - $c"; done
  read -rp "(o)verwrite, (s)kip, or (a)bort? [o/s/a] " RESP
  case "${RESP,,}" in
    o|overwrite) OVERWRITE=overwrite ;;
    s|skip)      OVERWRITE=skip ;;
    *)           echo "Aborted." >&2; exit 1 ;;
  esac
fi

mkdir -p "$TARGET_DIR"

INSTALLED=0
SKIPPED=0
for skill in "${SKILLS[@]}"; do
  name="$(basename "$skill")"
  dest="$TARGET_DIR/$name"

  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$OVERWRITE" == skip ]]; then
      echo "skip:    $name (already exists)"
      SKIPPED=$((SKIPPED+1))
      continue
    fi
    rm -rf "$dest"
  fi

  case "$METHOD" in
    link) ln -s "$skill" "$dest";        echo "linked:  $name" ;;
    copy) cp -R "$skill" "$dest";        echo "copied:  $name" ;;
  esac
  INSTALLED=$((INSTALLED+1))
done

echo
echo "Done. Installed: $INSTALLED, skipped: $SKIPPED."
echo "Restart your Claude Code session to pick up changes."
