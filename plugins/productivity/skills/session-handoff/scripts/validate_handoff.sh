#!/usr/bin/env bash
set -euo pipefail

FILEPATH="${1:-}"
if [[ -z "$FILEPATH" ]]; then
  echo "Usage: bash validate_handoff.sh <handoff-file>"
  echo "Example: bash validate_handoff.sh .claude/handoffs/2024-01-15-auth.md"
  exit 1
fi

if [[ ! -f "$FILEPATH" ]]; then
  echo "Error: File not found: $FILEPATH"
  exit 1
fi

# Base path: assume file lives at project/.claude/handoffs/file.md
BASE_PATH="$(cd "$(dirname "$FILEPATH")/../.." && pwd)"

# --- TODO check ---
TODO_COUNT=0
TODOS_CLEAR=1
REMAINING_TODOS=()

TODO_COUNT=$(grep -c '\[TODO:' "$FILEPATH" 2>/dev/null) || true
if [[ "$TODO_COUNT" -gt 0 ]]; then
  TODOS_CLEAR=0
  while IFS= read -r line; do
    REMAINING_TODOS+=("$line")
  done < <(grep -o '\[TODO:[^\]]*\]' "$FILEPATH" 2>/dev/null | head -5 || true)
fi

# --- Section body extractor: returns content between matched header and next ## header ---
section_body() {
  local section="$1" file="$2"
  awk -v sec="$section" '
    BEGIN { found=0; body="" }
    /^#{1,3}[[:space:]]/ {
      if (found) { exit }
      tmp = $0
      gsub(/^#{1,3}[[:space:]]+/, "", tmp)
      gsub(/[[:space:]]+$/, "", tmp)
      if (tolower(tmp) == tolower(sec)) { found=1; next }
    }
    found { body = body $0 "\n" }
    END { print body }
  ' "$file"
}

# --- Required sections check ---
REQUIRED_SECTIONS=("Current State Summary" "Important Context" "Immediate Next Steps")
MISSING_REQUIRED=()

for section in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -qiE "^#{1,3}[[:space:]]+${section}[[:space:]]*$" "$FILEPATH" 2>/dev/null; then
    MISSING_REQUIRED+=("${section} (missing)")
    continue
  fi
  body=$(section_body "$section" "$FILEPATH")
  body_stripped=$(echo "$body" | grep -v '^[[:space:]]*$' 2>/dev/null || true)
  body_len=$(echo -n "$body_stripped" | wc -c | tr -d ' ')
  if [[ "$body_len" -lt 50 ]] || echo "$body" | grep -q '\[TODO' 2>/dev/null; then
    MISSING_REQUIRED+=("${section} (incomplete)")
  fi
done

REQUIRED_COMPLETE=0
[[ ${#MISSING_REQUIRED[@]} -eq 0 ]] && REQUIRED_COMPLETE=1

# --- Recommended sections check ---
RECOMMENDED_SECTIONS=(
  "Architecture Overview"
  "Critical Files"
  "Files Modified"
  "Decisions Made"
  "Assumptions Made"
  "Potential Gotchas"
)
MISSING_RECOMMENDED=()

for section in "${RECOMMENDED_SECTIONS[@]}"; do
  if ! grep -qiE "^#{1,3}[[:space:]]+${section}[[:space:]]*$" "$FILEPATH" 2>/dev/null; then
    MISSING_RECOMMENDED+=("$section")
  fi
done

# --- Secret scan ---
SECRET_PATTERNS=(
  '[a-zA-Z_]*api[_-]?key[[:space:]]*[:=][[:space:]]*"[^"]{10,}"'
  '[a-zA-Z_]*password[[:space:]]*[:=][[:space:]]*"[^"]+"'
  '[a-zA-Z_]*secret[[:space:]]*[:=][[:space:]]*"[^"]{10,}"'
  '[a-zA-Z_]*token[[:space:]]*[:=][[:space:]]*"[^"]{20,}"'
  '[a-zA-Z_]*private[_-]?key[[:space:]]*[:=]'
  '-----BEGIN [A-Z]+ PRIVATE KEY-----'
  'mongodb(\+srv)?://[^/[:space:]]+:[^@[:space:]]+@'
  'postgres://[^/[:space:]]+:[^@[:space:]]+@'
  'mysql://[^/[:space:]]+:[^@[:space:]]+@'
  'Bearer[[:space:]]+[a-zA-Z0-9_.+-]+'
  'ghp_[a-zA-Z0-9]{36}'
  'sk-[a-zA-Z0-9]{48}'
  'xox[baprs]-[a-zA-Z0-9-]+'
)
SECRET_NAMES=(
  "API key"
  "Password"
  "Secret"
  "Token"
  "Private key"
  "PEM private key"
  "MongoDB connection string"
  "PostgreSQL connection string"
  "MySQL connection string"
  "Bearer token"
  "GitHub personal access token"
  "OpenAI API key"
  "Slack token"
)

SECRETS_FOUND=()
for i in "${!SECRET_PATTERNS[@]}"; do
  count=0
  count=$(grep -ciE "${SECRET_PATTERNS[$i]}" "$FILEPATH" 2>/dev/null) || true
  if [[ "$count" -gt 0 ]]; then
    SECRETS_FOUND+=("${SECRET_NAMES[$i]}: Found ${count} potential match(es)")
  fi
done

# --- File reference extraction + existence check ---
FILE_REFS=()
while IFS= read -r f; do
  [[ -n "$f" ]] && FILE_REFS+=("$f")
done < <(
  {
    # Table cells: | path/to/file.ext |
    grep -oE '\|[[:space:]]*[a-zA-Z0-9_./\-]+\.[a-zA-Z]+[[:space:]]*\|' "$FILEPATH" 2>/dev/null \
      | sed 's/|//g; s/[[:space:]]//g' || true
    # Line-number references: path/to/file.ext:123
    grep -oE '(^|[[:space:]])[a-zA-Z0-9_./\-]+\.[a-zA-Z]+:[0-9]+' "$FILEPATH" 2>/dev/null \
      | sed 's/:[0-9]*$//; s/^[[:space:]]*//' || true
  } | grep '/' | grep -v '^http' | sort -u
)

FILES_VERIFIED=0
FILES_MISSING=()
for f in "${FILE_REFS[@]}"; do
  if [[ -f "$BASE_PATH/$f" ]]; then
    FILES_VERIFIED=$(( FILES_VERIFIED + 1 ))
  else
    FILES_MISSING+=("$f")
  fi
done

# --- Quality score ---
SCORE=100

[[ "$TODOS_CLEAR" -eq 0 ]] && SCORE=$(( SCORE - 30 ))
SCORE=$(( SCORE - 10 * ${#MISSING_REQUIRED[@]} ))
[[ ${#SECRETS_FOUND[@]} -gt 0 ]] && SCORE=$(( SCORE - 20 ))

missing_files_cap=${#FILES_MISSING[@]}
[[ $missing_files_cap -gt 4 ]] && missing_files_cap=4
SCORE=$(( SCORE - 5 * missing_files_cap ))
SCORE=$(( SCORE - 2 * ${#MISSING_RECOMMENDED[@]} ))
[[ $SCORE -lt 0 ]] && SCORE=0

if [[ $SCORE -ge 90 ]]; then
  RATING="Excellent - Ready for handoff"
elif [[ $SCORE -ge 70 ]]; then
  RATING="Good - Minor improvements suggested"
elif [[ $SCORE -ge 50 ]]; then
  RATING="Fair - Needs attention before handoff"
else
  RATING="Poor - Significant work needed"
fi

# --- Report ---
echo ""
echo "============================================================"
echo "Handoff Validation Report"
echo "============================================================"
echo "File: $FILEPATH"
echo ""
echo "Quality Score: ${SCORE}/100 - ${RATING}"
echo "============================================================"

if [[ "$TODOS_CLEAR" -eq 1 ]]; then
  echo ""
  echo "[PASS] No TODO placeholders remaining"
else
  echo ""
  echo "[FAIL] ${TODO_COUNT} TODO placeholders found:"
  for todo in "${REMAINING_TODOS[@]}"; do
    echo "       - ${todo:0:50}..."
  done
fi

if [[ "$REQUIRED_COMPLETE" -eq 1 ]]; then
  echo ""
  echo "[PASS] All required sections complete"
else
  echo ""
  echo "[FAIL] Missing/incomplete required sections:"
  for section in "${MISSING_REQUIRED[@]}"; do
    echo "       - ${section}"
  done
fi

if [[ ${#SECRETS_FOUND[@]} -eq 0 ]]; then
  echo ""
  echo "[PASS] No potential secrets detected"
else
  echo ""
  echo "[WARN] Potential secrets detected:"
  for secret in "${SECRETS_FOUND[@]}"; do
    echo "       - ${secret}"
  done
fi

if [[ ${#FILES_MISSING[@]} -gt 0 ]]; then
  echo ""
  echo "[WARN] ${#FILES_MISSING[@]} referenced file(s) not found:"
  shown=0
  for f in "${FILES_MISSING[@]}"; do
    echo "       - ${f}"
    shown=$(( shown + 1 ))
    [[ $shown -ge 5 ]] && break
  done
else
  echo ""
  echo "[INFO] ${FILES_VERIFIED} file reference(s) verified"
fi

if [[ ${#MISSING_RECOMMENDED[@]} -gt 0 ]]; then
  echo ""
  echo "[INFO] Consider adding these sections:"
  for section in "${MISSING_RECOMMENDED[@]}"; do
    echo "       - ${section}"
  done
fi

echo ""
echo "============================================================"

if [[ $SCORE -ge 70 ]] && [[ ${#SECRETS_FOUND[@]} -eq 0 ]]; then
  echo "Verdict: READY for handoff"
  exit 0
elif [[ ${#SECRETS_FOUND[@]} -gt 0 ]]; then
  echo "Verdict: BLOCKED - Remove secrets before handoff"
  exit 1
else
  echo "Verdict: NEEDS WORK - Complete required sections"
  exit 1
fi
