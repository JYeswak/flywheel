#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-.}"
SKILL="$ROOT/SKILL.md"
SELF_TEST="$ROOT/SELF-TEST.md"

fail() {
  local reason="$1"
  jq -nc --arg reason "$reason" '{status:"fail",reason:$reason}'
  exit 1
}

need_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "missing file: $path"
}

section_required() {
  local section="$1"
  grep -q "^## ${section}$" "$SKILL" || fail "missing section: $section"
}

term_required() {
  local term="$1"
  grep -q -- "$term" "$SKILL" || fail "missing term: $term"
}

need_file "$SKILL"
need_file "$SELF_TEST"
need_file "$ROOT/references/JEFF-EVIDENCE.md"
need_file "$ROOT/references/TRANSPORT-CONTRACT.md"
need_file "$ROOT/references/FLYWHEEL-ADAPTATION.md"

grep -q '^name: ipc-transport-contract$' "$SKILL" || fail "frontmatter name mismatch"

trigger_count="$(
  python3 - "$SKILL" <<'PY'
import re
import sys
text = open(sys.argv[1], encoding="utf-8").read()
match = re.search(r'^description:\s*"([^"]+)"', text, re.M)
if not match:
    print(0)
else:
    print(len(re.findall(r"'([^']+)'", match.group(1))))
PY
)"
[[ "$trigger_count" -ge 10 ]] || fail "expected >=10 trigger phrases, saw $trigger_count"

description_len="$(
  python3 - "$SKILL" <<'PY'
import re
import sys
text = open(sys.argv[1], encoding="utf-8").read()
match = re.search(r'^description:\s*"([^"]+)"', text, re.M)
print(len(match.group(1)) if match else 0)
PY
)"
[[ "$description_len" -le 500 ]] || fail "description exceeds 500 chars: $description_len"

for section in \
  "Hard Rules" \
  "THE EXACT PROMPT" \
  "Decision Tree" \
  "JSON Envelope Schema" \
  "Delivery Verification" \
  "Transport Health Shape" \
  "Resend And Idempotency" \
  "Durable Audit Rows" \
  "Source Evidence" \
  "Flywheel Adaptation Notes" \
  "Executable Self-Test" \
  "Publication Staging" \
  "Anti-Patterns"; do
  section_required "$section"
done

hard_rules="$(grep -c '^[0-9][0-9]*[.] ' "$SKILL")"
[[ "$hard_rules" -ge 10 ]] || fail "expected >=10 hard rules, saw $hard_rules"

anti_patterns="$(
  awk '
    /^## Anti-Patterns$/ {in_table=1; next}
    in_table && /^\| [^|]+ \| [^|]+ \| [^|]+ \|$/ && $0 !~ /^(\|---|\| Anti-Pattern)/ {count++}
    END {print count + 0}
  ' "$SKILL"
)"
[[ "$anti_patterns" -ge 5 ]] || fail "expected >=5 anti-pattern rows, saw $anti_patterns"

for term in \
  "schema_version" \
  "correlation_id" \
  "message_id" \
  "delivery verification" \
  "transport health" \
  "callback_expected_by" \
  "idempotency_key" \
  "audit row" \
  "DONE/BLOCKED" \
  "DID/DIDNT/GAPS" \
  "verify-callback-delivery.sh" \
  "jsm push" \
  "06-skill-enhancement-matrix.md" \
  "01-doctrine-cluster.md" \
  "02-code-patterns.md"; do
  term_required "$term"
done

jq -nc \
  --arg skill "ipc-transport-contract" \
  --argjson triggers "$trigger_count" \
  --argjson hard_rules "$hard_rules" \
  --argjson anti_patterns "$anti_patterns" \
  '{status:"pass",skill:$skill,triggers:$triggers,hard_rules:$hard_rules,anti_patterns:$anti_patterns}'
