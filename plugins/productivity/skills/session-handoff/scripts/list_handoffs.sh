#!/usr/bin/env bash
set -euo pipefail

PROJECT_PATH="${1:-$(pwd)}"
HANDOFFS_DIR="$PROJECT_PATH/.agents/handoffs"

if [[ ! -d "$HANDOFFS_DIR" ]]; then
  echo "No handoffs found in $PROJECT_PATH/.agents/handoffs/"
  echo ""
  echo "To create a handoff, run: bash scripts/create_handoff.sh [task-slug]"
  exit 0
fi

# Collect .md files, sort newest-first (filenames are YYYY-MM-DD-HHMMSS-slug.md)
# Use while-read loop (not mapfile) — macOS ships bash 3.2, mapfile requires bash 4+
FILES=()
while IFS= read -r line; do
  FILES+=("$line")
done < <(ls -1 "$HANDOFFS_DIR"/*.md 2>/dev/null | sort -r)

if [[ ${#FILES[@]} -eq 0 ]]; then
  echo "No handoffs found in $PROJECT_PATH/.agents/handoffs/"
  echo ""
  echo "To create a handoff, run: bash scripts/create_handoff.sh [task-slug]"
  exit 0
fi

echo "Found ${#FILES[@]} handoff(s) in $HANDOFFS_DIR"
echo ""
echo "--------------------------------------------------------------------------------"

for FILE in "${FILES[@]}"; do
  FILENAME="$(basename "$FILE")"

  # --- Title: read from YAML frontmatter title: field only ---
  TITLE=$(awk '/^---$/{if(++n==2) exit} n==1 && /^title:/{sub(/^title:[[:space:]]*/,""); print; exit}' "$FILE" || true)
  if [[ -z "$TITLE" ]]; then
    TITLE="[Unable to read title]"
  elif [[ "$TITLE" =~ ^\[.*\]$ ]]; then
    TITLE="[Untitled - needs completion]"
  elif [[ ${#TITLE} -gt 50 ]]; then
    TITLE="${TITLE:0:50}..."
  fi

  # --- Status: count incomplete placeholders ---
  TODO_COUNT=$(grep -c '\[TODO:' "$FILE" 2>/dev/null || true)
  if [[ "$TODO_COUNT" -eq 0 ]]; then
    STATUS="Complete"
  elif [[ "$TODO_COUNT" -le 3 ]]; then
    STATUS="In Progress ($TODO_COUNT TODOs)"
  else
    STATUS="Needs Work ($TODO_COUNT TODOs)"
  fi

  # --- Date from filename: YYYY-MM-DD-HHMMSS-slug.md ---
  if [[ "$FILENAME" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2})-([0-9]{2})([0-9]{2})([0-9]{2})- ]]; then
    DATE_DISPLAY="${BASH_REMATCH[1]} ${BASH_REMATCH[2]}:${BASH_REMATCH[3]}"
  else
    DATE_DISPLAY="Unknown date"
  fi

  echo "  Date: $DATE_DISPLAY"
  echo "  Title: $TITLE"
  echo "  Status: $STATUS"
  echo "  File: $FILENAME"
  echo "--------------------------------------------------------------------------------"
done

echo ""
echo "To resume from a handoff, read the document and follow the resume checklist."
echo "Most recent: ${FILES[0]}"
