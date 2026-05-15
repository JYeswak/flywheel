#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
ARTIFACT="$ROOT/.flywheel/research/jeff-pattern-internalization-2026-05-15.md"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

require_literal() {
  local literal="$1"
  local label="$2"
  if rg -qF -- "$literal" "$ARTIFACT"; then
    pass "$label"
  else
    fail "$label"
  fi
}

if [[ -s "$ARTIFACT" ]]; then
  pass "artifact exists"
else
  fail "artifact exists"
fi

require_literal "https://www.jeffreyemanuel.com/" "cites Jeffrey home"
require_literal "https://agent-flywheel.com/" "cites Agent Flywheel"
require_literal "https://asupersync.com/" "cites ASupersync"
require_literal "https://frankentui.com/" "cites FrankenTUI"
require_literal "https://mcpagentmail.com/" "cites MCP Agent Mail"
require_literal "https://frankensqlite.com/" "cites FrankenSQLite"
require_literal "What Jeffrey's Sites Do Well" "names extraction section"
require_literal "What Not To Copy" "names anti-copy section"
require_literal "Deltas Against Current Flywheel Doctrine" "names flywheel delta section"
require_literal "Meadows Analysis" "names Meadows section"
require_literal "ZestStream Brand Voice Translation" "names brand voice section"
require_literal "Frontend Foundation Requirements" "names frontend foundation section"
require_literal "STOCK: reusable story and design capital" "names system stock"
require_literal "LEVERAGE_POINT: Meadows #2 paradigm and #4 self-organization" "names leverage point"
require_literal "I help SMB owners buy their time back." "includes canon line"
require_literal "Jeffrey Emanuel owns" "preserves attribution"
require_literal "RoomSystem" "names reusable room primitive"
require_literal "ReferencePatternDrawer" "names reference pattern primitive"
require_literal "FitFilter" "names fit filter primitive"
require_literal "Does this page show what the owner gets back this week?" "names review question"

if rg -n "The Yuzu Method ®|transformation|handoff" "$ARTIFACT" >/tmp/jeff-pattern-internalization-banned.$$ 2>/dev/null; then
  cat /tmp/jeff-pattern-internalization-banned.$$ >&2
  rm -f /tmp/jeff-pattern-internalization-banned.$$
  fail "avoids banned public-copy terms"
else
  rm -f /tmp/jeff-pattern-internalization-banned.$$
  pass "avoids banned public-copy terms"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
