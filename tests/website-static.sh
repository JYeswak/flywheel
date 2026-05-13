#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SITE="$ROOT/site"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

require_file() {
  local rel="$1"
  if [[ -s "$SITE/$rel" ]]; then
    pass "file exists: $rel"
  else
    fail "file exists: $rel"
  fi
}

require_literal() {
  local rel="$1" literal="$2" label="$3"
  if rg -qF "$literal" "$SITE/$rel"; then
    pass "$label"
  else
    fail "$label"
  fi
}

reject_literal() {
  local literal="$1" label="$2"
  if rg -qF "$literal" "$SITE"; then
    fail "$label"
  else
    pass "$label"
  fi
}

for rel in \
  index.html \
  what-is/index.html \
  for-developers/index.html \
  methodology/index.html \
  about/index.html \
  contact/index.html \
  styles.css \
  assets/loop-map.svg; do
  require_file "$rel"
done

while IFS= read -r -d '' html; do
  rel="${html#"$SITE/"}"
  require_literal "$rel" '<html lang="en">' "lang present: $rel"
  require_literal "$rel" '<meta name="viewport"' "viewport present: $rel"
  require_literal "$rel" '<h1' "h1 present: $rel"
done < <(find "$SITE" -name '*.html' -print0 | sort -z)

require_literal "index.html" "scripts/journey-smoke.sh --matrix reduced --dry-run --json" "landing has reduced first run"
require_literal "index.html" "https://github.com/JYeswak/flywheel" "landing links github"
require_literal "what-is/index.html" "SkillOS is a capability control plane integration point" "what-is names SkillOS boundary"
require_literal "for-developers/index.html" "Claude Code" "developer page names Claude"
require_literal "for-developers/index.html" "Codex CLI" "developer page names Codex"
require_literal "for-developers/index.html" "Gemini CLI" "developer page names Gemini"
require_literal "for-developers/index.html" "OpenClaw" "developer page names OpenClaw"
require_literal "for-developers/index.html" "Reduced local mode" "developer page names reduced mode"
require_literal "methodology/index.html" "fully redacted, explicitly consented, or replaced" "methodology names consent fallback"
require_literal "about/index.html" "joshua@zeststream.ai" "about includes public contact"
require_literal "about/index.html" 'alt="Joshua Nowak and ZestStream operating map for Flywheel"' "about image alt text"
require_literal "contact/index.html" "%5BFlywheel%5D%20Public%20site%20inquiry" "contact uses required subject prefix"
require_literal "contact/index.html" '<label for="topic">' "contact topic label"
require_literal "contact/index.html" '<label for="message">' "contact message label"

for private_term in "Blackfoot" "ALPS" "TerraTitle" "/Users/josh" ".ntm/pids" "mobile-eats"; do
  reject_literal "$private_term" "private term absent: $private_term"
done

if rg -q '<img [^>]*alt=""' "$SITE"; then
  fail "no empty image alt text"
else
  pass "no empty image alt text"
fi

if ROOT="$ROOT" python3 <<'PY'
import re
import sys
from pathlib import Path

root = Path(__import__("os").environ["ROOT"])
evidence = (root / "docs/evidence/publication-evidence.md").read_text(encoding="utf-8")
methodology = (root / "site/methodology/index.html").read_text(encoding="utf-8")
evidence_match = re.search(
    r"Fresh export status pass with ([\d,]+) classified files, ([\d,]+) copied "
    r"public-safe files, and ([\d,]+) denylist-excluded files; .*? ([\d,]+) "
    r"manual-review rows",
    evidence,
    flags=re.S,
)
if not evidence_match:
    sys.exit(1)
classified, copied, _excluded, manual_review = evidence_match.groups()
for value in (classified, copied, manual_review):
    if value not in methodology:
        sys.exit(1)
PY
then
  pass "methodology metrics match publication evidence"
else
  fail "methodology metrics match publication evidence"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
