#!/usr/bin/env bash
set -euo pipefail

HANDOFF_PATH="${1:-}"
if [[ -z "$HANDOFF_PATH" ]]; then
  echo "Usage: bash check_staleness.sh <handoff-file>"
  echo "Example: bash check_staleness.sh .claude/handoffs/2024-01-15-auth.md"
  exit 1
fi

if [[ ! -f "$HANDOFF_PATH" ]]; then
  echo "Error: Handoff file not found: $HANDOFF_PATH"
  exit 1
fi

# --- Cross-platform timestamp → epoch ---
timestamp_to_epoch() {
  local ts="$1"
  if date -j -f "%Y-%m-%d %H:%M:%S" "2000-01-01 00:00:00" "+%s" >/dev/null 2>&1; then
    date -j -f "%Y-%m-%d %H:%M:%S" "$ts" "+%s" 2>/dev/null || echo ""
  else
    date -d "$ts" "+%s" 2>/dev/null || echo ""
  fi
}

# --- YAML frontmatter field extractor ---
parse_frontmatter() {
  local file="$1" field="$2"
  awk -v field="$field" '
    /^---$/ { if (++n == 2) exit }
    n == 1 && $0 ~ "^"field":" {
      sub("^"field":[[:space:]]*", "")
      print
      exit
    }
  ' "$file"
}

# --- Parse metadata ---
CREATED=$(parse_frontmatter "$HANDOFF_PATH" "created")
HANDOFF_BRANCH=$(parse_frontmatter "$HANDOFF_PATH" "branch")
PROJECT_PATH_FROM_FILE=$(parse_frontmatter "$HANDOFF_PATH" "project")

PROJECT_PATH=""
if [[ -n "$PROJECT_PATH_FROM_FILE" ]] && [[ -d "$PROJECT_PATH_FROM_FILE" ]]; then
  PROJECT_PATH="$PROJECT_PATH_FROM_FILE"
else
  PROJECT_PATH="$(cd "$(dirname "$HANDOFF_PATH")/../.." && pwd)"
fi

# --- Extract modified files from table cells ---
MODIFIED_FILES=()
while IFS= read -r f; do
  [[ -n "$f" ]] && MODIFIED_FILES+=("$f")
done < <(
  grep -oE '\|[[:space:]]*[a-zA-Z0-9_./\-]+\.[a-zA-Z]+[[:space:]]*\|' "$HANDOFF_PATH" 2>/dev/null \
    | sed 's/|//g; s/[[:space:]]//g' \
    | grep '/' || true
)

# --- Git check ---
IS_GIT_REPO=0
if git -C "$PROJECT_PATH" rev-parse --git-dir > /dev/null 2>&1; then
  IS_GIT_REPO=1
fi

# --- Calculate age ---
DAYS_OLD=""
HOURS_OLD=""
if [[ -n "$CREATED" ]]; then
  created_epoch=$(timestamp_to_epoch "$CREATED")
  if [[ -n "$created_epoch" ]]; then
    now_epoch=$(date +%s)
    seconds_old=$(( now_epoch - created_epoch ))
    DAYS_OLD=$(( seconds_old / 86400 ))
    HOURS_OLD=$(( seconds_old / 3600 ))
  fi
fi

# --- Git-based checks ---
CURRENT_BRANCH=""
BRANCH_MATCHES=1
COMMITS_SINCE=0
RECENT_COMMITS=()
FILES_CHANGED_COUNT=0
FILES_CHANGED=()
REFERENCED_FILES_EXIST=0
REFERENCED_FILES_MISSING=()

if [[ "$IS_GIT_REPO" -eq 1 ]]; then
  CURRENT_BRANCH=$(git -C "$PROJECT_PATH" branch --show-current 2>/dev/null || echo "")

  if [[ -n "$HANDOFF_BRANCH" ]] && ! [[ "$HANDOFF_BRANCH" =~ ^\[ ]]; then
    [[ "$CURRENT_BRANCH" != "$HANDOFF_BRANCH" ]] && BRANCH_MATCHES=0
  fi

  if [[ -n "$CREATED" ]]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && RECENT_COMMITS+=("$line")
    done < <(git -C "$PROJECT_PATH" log --since="$CREATED" --oneline --no-decorate 2>/dev/null || true)
    COMMITS_SINCE=${#RECENT_COMMITS[@]}

    while IFS= read -r f; do
      [[ -n "$f" ]] && FILES_CHANGED+=("$f")
    done < <(
      git -C "$PROJECT_PATH" log --since="$CREATED" --name-only --pretty=format: 2>/dev/null \
        | grep -v '^$' | sort -u || true
    )
    FILES_CHANGED_COUNT=${#FILES_CHANGED[@]}
  fi

  for f in "${MODIFIED_FILES[@]}"; do
    if [[ -f "$PROJECT_PATH/$f" ]]; then
      REFERENCED_FILES_EXIST=$(( REFERENCED_FILES_EXIST + 1 ))
    else
      REFERENCED_FILES_MISSING+=("$f")
    fi
  done
fi

# --- Staleness scoring (mirrors Python thresholds exactly) ---
STALENESS_SCORE=0
ISSUES=()

if [[ -n "$DAYS_OLD" ]]; then
  if [[ $DAYS_OLD -gt 30 ]]; then
    STALENESS_SCORE=$(( STALENESS_SCORE + 3 ))
    ISSUES+=("Handoff is ${DAYS_OLD} days old")
  elif [[ $DAYS_OLD -gt 7 ]]; then
    STALENESS_SCORE=$(( STALENESS_SCORE + 2 ))
    ISSUES+=("Handoff is ${DAYS_OLD} days old")
  elif [[ $DAYS_OLD -gt 1 ]]; then
    STALENESS_SCORE=$(( STALENESS_SCORE + 1 ))
  fi
fi

if [[ $COMMITS_SINCE -gt 50 ]]; then
  STALENESS_SCORE=$(( STALENESS_SCORE + 3 ))
  ISSUES+=("${COMMITS_SINCE} commits since handoff - significant changes")
elif [[ $COMMITS_SINCE -gt 20 ]]; then
  STALENESS_SCORE=$(( STALENESS_SCORE + 2 ))
  ISSUES+=("${COMMITS_SINCE} commits since handoff")
elif [[ $COMMITS_SINCE -gt 5 ]]; then
  STALENESS_SCORE=$(( STALENESS_SCORE + 1 ))
fi

if [[ "$BRANCH_MATCHES" -eq 0 ]]; then
  STALENESS_SCORE=$(( STALENESS_SCORE + 2 ))
  ISSUES+=("Current branch differs from handoff branch")
fi

missing_ref_count=${#REFERENCED_FILES_MISSING[@]}
if [[ $missing_ref_count -gt 5 ]]; then
  STALENESS_SCORE=$(( STALENESS_SCORE + 2 ))
  ISSUES+=("${missing_ref_count} referenced files no longer exist")
elif [[ $missing_ref_count -gt 0 ]]; then
  STALENESS_SCORE=$(( STALENESS_SCORE + 1 ))
  ISSUES+=("${missing_ref_count} referenced file(s) missing")
fi

if [[ $FILES_CHANGED_COUNT -gt 20 ]]; then
  STALENESS_SCORE=$(( STALENESS_SCORE + 2 ))
  ISSUES+=("${FILES_CHANGED_COUNT} files changed since handoff")
elif [[ $FILES_CHANGED_COUNT -gt 5 ]]; then
  STALENESS_SCORE=$(( STALENESS_SCORE + 1 ))
fi

if [[ $STALENESS_SCORE -eq 0 ]]; then
  STALENESS_LEVEL="FRESH"
  RECOMMENDATION="Safe to resume - minimal changes since handoff"
elif [[ $STALENESS_SCORE -le 2 ]]; then
  STALENESS_LEVEL="SLIGHTLY_STALE"
  RECOMMENDATION="Generally safe to resume - review changes before continuing"
elif [[ $STALENESS_SCORE -le 4 ]]; then
  STALENESS_LEVEL="STALE"
  RECOMMENDATION="Proceed with caution - significant changes may affect context"
else
  STALENESS_LEVEL="VERY_STALE"
  RECOMMENDATION="Consider creating new handoff - too many changes since original"
fi

# --- Report ---
echo ""
echo "============================================================"
echo "Handoff Staleness Report"
echo "============================================================"
echo "File: $HANDOFF_PATH"
echo "Project: $PROJECT_PATH"

if [[ -n "$CREATED" ]]; then
  echo "Created: $CREATED"
  if [[ -n "$DAYS_OLD" ]]; then
    if [[ $DAYS_OLD -lt 1 ]]; then
      echo "Age: ${HOURS_OLD} hours"
    else
      echo "Age: ${DAYS_OLD} days"
    fi
  fi
fi

echo ""
echo "============================================================"
echo "Staleness Level: $STALENESS_LEVEL"
echo "============================================================"
echo ""
echo "Recommendation: $RECOMMENDATION"

if [[ ${#ISSUES[@]} -gt 0 ]]; then
  echo ""
  echo "Issues detected:"
  for issue in "${ISSUES[@]}"; do
    echo "  - ${issue}"
  done
fi

if [[ "$IS_GIT_REPO" -eq 1 ]]; then
  echo ""
  echo "--- Git Status ---"
  echo "Handoff branch: ${HANDOFF_BRANCH:-Unknown}"
  echo "Current branch: ${CURRENT_BRANCH:-Unknown}"
  if [[ "$BRANCH_MATCHES" -eq 1 ]]; then
    echo "Branch matches: Yes"
  else
    echo "Branch matches: No"
  fi
  echo "Commits since handoff: $COMMITS_SINCE"
  echo "Files changed: $FILES_CHANGED_COUNT"

  if [[ ${#RECENT_COMMITS[@]} -gt 0 ]]; then
    echo ""
    echo "Recent commits:"
    shown=0
    for commit in "${RECENT_COMMITS[@]}"; do
      echo "  ${commit}"
      shown=$(( shown + 1 ))
      [[ $shown -ge 5 ]] && break
    done
  fi

  if [[ ${#REFERENCED_FILES_MISSING[@]} -gt 0 ]]; then
    echo ""
    echo "Missing referenced files:"
    shown=0
    for f in "${REFERENCED_FILES_MISSING[@]}"; do
      echo "  - ${f}"
      shown=$(( shown + 1 ))
      [[ $shown -ge 5 ]] && break
    done
  fi
fi

echo ""
echo "============================================================"

case "$STALENESS_LEVEL" in
  FRESH)          echo "Verdict: [OK] Safe to resume" ;;
  SLIGHTLY_STALE) echo "Verdict: [OK] Review changes, then resume" ;;
  STALE)          echo "Verdict: [CAUTION] Verify context before resuming" ;;
  VERY_STALE)     echo "Verdict: [WARNING] Consider creating fresh handoff" ;;
  *)              echo "Verdict: [UNKNOWN] Manual verification needed" ;;
esac

case "$STALENESS_LEVEL" in
  FRESH|SLIGHTLY_STALE) exit 0 ;;
  STALE)                exit 1 ;;
  *)                    exit 2 ;;
esac
