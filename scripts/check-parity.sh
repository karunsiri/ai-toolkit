#!/bin/sh
# Cross-tool parity checks for plugins/*. Run before a release.
# - manifest versions match across Claude Code, Cursor and Codex
# - every Claude Code agent (agents/) has a Cursor twin (agents-cursor/) and back
# - relative links in plugin markdown resolve
set -u
cd "$(dirname "$0")/.." || exit 1
fail=0
err() { echo "FAIL: $*" >&2; fail=1; }

for p in plugins/*/; do
  p=${p%/}
  versions=$(for m in "$p"/.claude-plugin/plugin.json "$p"/.cursor-plugin/plugin.json "$p"/.codex-plugin/plugin.json; do
    [ -f "$m" ] && sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' "$m"
  done | sort -u)
  [ "$(printf '%s\n' "$versions" | grep -c .)" -le 1 ] || err "$p manifest versions differ: $(echo $versions)"

  if [ -d "$p/agents" ] || [ -d "$p/agents-cursor" ]; then
    a=$(ls "$p/agents" 2>/dev/null | sort)
    c=$(ls "$p/agents-cursor" 2>/dev/null | sort)
    [ "$a" = "$c" ] || err "$p agents/ and agents-cursor/ differ: [$(echo $a)] vs [$(echo $c)]"
    grep -q '"agents": *"./agents-cursor/"' "$p/.cursor-plugin/plugin.json" 2>/dev/null \
      || err "$p .cursor-plugin/plugin.json must set \"agents\": \"./agents-cursor/\""
  fi

  # Relative markdown links to files or dirs (has a "/" or ends in .md); skips URLs and anchors.
  find "$p" -name '*.md' | while read -r f; do
    grep -o '](\([^)#: ]*\))' "$f" | sed 's/^](\(.*\))$/\1/' | grep -E '/|\.md$' | while read -r l; do
      [ -e "$(dirname "$f")/$l" ] || echo "FAIL: broken link in $f: $l"
    done
  done | grep . >&2 && fail=1
done

[ "$fail" -eq 0 ] && echo "parity OK"
exit "$fail"
