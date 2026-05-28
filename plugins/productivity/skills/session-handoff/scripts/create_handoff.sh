#!/usr/bin/env bash
set -euo pipefail

# Arg parsing: optional positional slug + --continues-from flag
SLUG=""
CONTINUES_FROM=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --continues-from) CONTINUES_FROM="$2"; shift 2 ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) SLUG="$1"; shift ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE="$SCRIPT_DIR/../references/handoff-template.md"

if [[ ! -f "$TEMPLATE" ]]; then
  echo "Error: template not found at $TEMPLATE" >&2
  exit 1
fi

PROJECT_PATH="$PWD"
HANDOFFS_DIR="$PROJECT_PATH/.agents/handoffs"

# Timestamp
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
FILE_TIMESTAMP=$(date "+%Y-%m-%d-%H%M%S")

# Sanitize slug: lowercase, spaces/underscores→hyphens, strip non-alphanumeric except hyphens
SLUG="${SLUG:-handoff}"
SLUG=$(echo "$SLUG" | tr '[:upper:]' '[:lower:]' | tr ' _' '-' | tr -cd 'a-z0-9-')
[[ -z "$SLUG" ]] && SLUG="handoff"

FILENAME="${FILE_TIMESTAMP}-${SLUG}.md"
FILEPATH="$HANDOFFS_DIR/$FILENAME"

mkdir -p "$HANDOFFS_DIR"

# Git info — check once, then run commands safely inside the block
if git rev-parse --git-dir > /dev/null 2>&1; then
  BRANCH=$(git branch --show-current)
  [[ -z "$BRANCH" ]] && BRANCH="[detached HEAD]"
  COMMITS=$(git log --oneline -5 --no-decorate | sed 's/^/  - /')
  [[ -z "$COMMITS" ]] && COMMITS="  - [no commits yet]"
  MODIFIED=$({ git diff --name-only; git diff --name-only --cached; } | sort -u)
else
  BRANCH="[not a git repo or detached HEAD]"
  COMMITS="  - [not a git repo]"
  MODIFIED=""
fi

# Modified files table rows
if [[ -n "$MODIFIED" ]]; then
  MOD_ROWS=$(echo "$MODIFIED" | head -10 | awk '{print "| " $0 " | [describe changes] | [why changed] |"}')
  MOD_COUNT=$(echo "$MODIFIED" | wc -l | tr -d ' ')
  if [[ "$MOD_COUNT" -gt 10 ]]; then
    EXTRA=$((MOD_COUNT - 10))
    MOD_ROWS="${MOD_ROWS}
| ... and ${EXTRA} more files | | |"
  fi
else
  MOD_ROWS="| [no modified files detected] | | |"
fi

# Chain section: look up previous handoff title from YAML frontmatter
if [[ -n "$CONTINUES_FROM" ]]; then
  PREV_FILE=$(ls "$HANDOFFS_DIR/"*"${CONTINUES_FROM}"* 2>/dev/null | head -1 || true)
  if [[ -n "$PREV_FILE" ]]; then
    PREV_TITLE=$(awk '/^---$/{if(++n==2) exit} n==1 && /^title:/{sub(/^title:[[:space:]]*/,""); print; exit}' "$PREV_FILE" 2>/dev/null || true)
    [[ -z "$PREV_TITLE" ]] && PREV_TITLE="[Unknown title]"
    PREV_FILENAME=$(basename "$PREV_FILE")
  else
    PREV_TITLE="Not found"
    PREV_FILENAME="$CONTINUES_FROM"
  fi
  CHAIN_SECTION=$(cat <<CHAIN
## Handoff Chain

- **Continues from**: [$PREV_FILENAME](./$PREV_FILENAME)
  - Previous title: $PREV_TITLE
- **Supersedes**: [list any older handoffs this replaces, or "None"]

> Review the previous handoff for full context before filling this one.
CHAIN
)
else
  CHAIN_SECTION=$(cat <<'CHAIN'
## Handoff Chain

- **Continues from**: None (fresh start)
- **Supersedes**: None

> This is the first handoff for this task.
CHAIN
)
fi

# Write handoff: read template, substitute {{TOKEN}} markers
# Single-line tokens via sed; multiline tokens via awk + temp files
COMMITS_FILE=$(mktemp)
CHAIN_FILE=$(mktemp)
MOD_FILE=$(mktemp)
printf '%s\n' "$COMMITS" > "$COMMITS_FILE"
printf '%s\n' "$CHAIN_SECTION" > "$CHAIN_FILE"
printf '%s\n' "$MOD_ROWS" > "$MOD_FILE"

sed \
  -e "s|{{TASK_TITLE}}|[TASK_TITLE - replace this]|g" \
  -e "s|{{TIMESTAMP}}|$TIMESTAMP|g" \
  -e "s|{{PROJECT_PATH}}|$PROJECT_PATH|g" \
  -e "s|{{GIT_BRANCH}}|$BRANCH|g" \
  "$TEMPLATE" | \
awk \
  -v cf="$COMMITS_FILE" \
  -v hf="$CHAIN_FILE" \
  -v mf="$MOD_FILE" \
  '
  /^{{RECENT_COMMITS}}$/ { while ((getline l < cf) > 0) print l; close(cf); next }
  /^{{CHAIN_SECTION}}$/  { while ((getline l < hf) > 0) print l; close(hf); next }
  /^{{MOD_ROWS}}$/       { while ((getline l < mf) > 0) print l; close(mf); next }
  { print }
  ' > "$FILEPATH"

rm -f "$COMMITS_FILE" "$CHAIN_FILE" "$MOD_FILE"

echo "Created handoff document: $FILEPATH"
echo ""
echo "Next steps:"
echo "1. Open $FILEPATH"
echo "2. Replace [TODO: ...] placeholders with actual content"
echo "3. Focus especially on 'Important Context' and 'Immediate Next Steps'"
echo "4. Run: bash scripts/validate_handoff.sh $FILEPATH"
echo "   (Checks for completeness and accidental secrets)"
