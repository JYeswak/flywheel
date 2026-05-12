#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
SKILL="$ROOT/SKILL.md"

fail() {
  jq -nc --arg reason "$1" '{status:"fail",reason:$reason}'
  exit 1
}

need_file() {
  [[ -f "$1" ]] || fail "missing file: $1"
}

section_required() {
  grep -q "^## $1" "$SKILL" || fail "missing section: $1"
}

term_required() {
  grep -q "$1" "$SKILL" || fail "missing term: $1"
}

need_file "$SKILL"
need_file "$ROOT/scripts/self_test.sh"
need_file "$ROOT/references/JEFF-EVIDENCE.md"
need_file "$ROOT/references/TRIAD-CONTRACT.md"
need_file "$ROOT/references/FLYWHEEL-ADAPTATION.md"

grep -q '^name: doctor-repair-triad$' "$SKILL" || fail "bad frontmatter name"

for section in \
  "Hard Rules" \
  "THE EXACT PROMPT" \
  "Decision Tree" \
  "Doctor Signal Shape" \
  "Health Summary Shape" \
  "Repair Contract" \
  "L60 Producer Table" \
  "Source Evidence" \
  "Flywheel Adaptation Notes" \
  "Executable Self-Test" \
  "Publication Staging" \
  "Anti-Patterns"; do
  section_required "$section"
done

trigger_count="$(python3 - "$SKILL" <<'PY'
from pathlib import Path
import re, sys
text = Path(sys.argv[1]).read_text()
fm = text.split('---', 2)[1]
print(len(re.findall(r"'[^']+'", fm)))
PY
)"
[[ "$trigger_count" -ge 10 ]] || fail "expected >=10 trigger phrases, got $trigger_count"

hard_rules="$(grep -c '^[0-9][0-9]*[.] ' "$SKILL")"
[[ "$hard_rules" -ge 10 ]] || fail "expected >=10 hard rules, got $hard_rules"

anti_rows="$(awk '/^## Anti-Patterns/{flag=1; next} /^## /{flag=0} flag && index($0, "|") == 1 {count++} END{print count+0}' "$SKILL")"
[[ "$anti_rows" -ge 5 ]] || fail "anti-pattern table too small"

for term in \
  'doctor --json' \
  'health --json' \
  'repair --dry-run' \
  'repair --apply' \
  'schema_version' \
  'failure_class' \
  'idempotency_key' \
  'dry_run_plan_hash' \
  'producer' \
  'measurement' \
  'consumer' \
  'promotion_trigger' \
  'DID/DIDNT/GAPS' \
  'jsm push'; do
  term_required "$term"
done

jq -nc '{status:"pass",checks:12}'
