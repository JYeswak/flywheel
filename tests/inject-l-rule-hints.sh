#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="${L_RULE_HINTS_BIN:-$ROOT/.flywheel/scripts/inject-l-rule-hints.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/l-rule-hints.XXXXXX")"
cleanup() {
  find "$TMP" -type f -delete 2>/dev/null || true
  find "$TMP" -depth -type d -exec rmdir {} + 2>/dev/null || true
}
trap cleanup EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_contains() {
  local file="$1" pattern="$2" name="$3"
  if rg -q "$pattern" "$file"; then pass "$name"; else fail "$name"; fi
}

mkdir -p "$TMP/rules"
cat >"$TMP/rules/L50.md" <<'EOF'
## L50 — SOCRATICODE-MANDATORY-IN-EVERY-DISPATCH

---
id: L50
title: Socraticode mandatory in every dispatch
trauma_class: substrate-amnesia
---

Every dispatch packet requires a Socraticode survey before implementation.
EOF

cat >"$TMP/rules/L51.md" <<'EOF'
## L51 — DISPATCH-FILE-RESERVATIONS-MANDATORY

---
id: L51
title: Dispatch file reservations mandatory
trauma_class: concurrent-worker-drift
---

Workers reserve shared paths before edits and release them on close.
EOF

cat >"$TMP/rules/L120.md" <<'EOF'
## L120 — DISPATCH-CALLBACK-MUST-INCLUDE-BR-CLOSE-EXECUTED

---
id: L120
title: Dispatch callback must include br close executed
trauma_class: callback-before-close
---

DONE callbacks include br_close_executed after br close exits successfully.
EOF

cat >"$TMP/rules/L999.md" <<'EOF'
## L999 — UNRELATED

---
id: L999
title: Unrelated doctrine
trauma_class: unrelated
---

No matching words here.
EOF

cat >"$TMP/packet.md" <<'EOF'
# DISPATCH PACKET

This worker must run Socraticode, reserve shared files before edits, and close
the bead before DONE with br_close_executed.
EOF

export FLYWHEEL_L_RULES_DIR="$TMP/rules"
export FLYWHEEL_L_RULE_HINTS_LOG="$TMP/hints.jsonl"
export FLYWHEEL_RULE_HINT_USAGE_LOG="$TMP/usage.jsonl"
"$BIN" "$TMP/packet.md" fixture-task "$TMP/repo" >"$TMP/out.md"

assert_contains "$TMP/out.md" '^## L-RULE HINTS$' "hint block emitted"
assert_contains "$TMP/out.md" '^l_rule_hints=3$' "max three hints"
assert_contains "$TMP/out.md" 'l_rule_hints_matched=.*L50' "socraticode rule matched"
assert_contains "$TMP/out.md" 'l_rule_hints_matched=.*L51' "reservation rule matched"
assert_contains "$TMP/out.md" 'l_rule_hints_matched=.*L120' "br close rule matched"
if jq -e 'select(.schema_version=="rule-hint-usage/v1" and .rule_id=="L50" and .dispatch_id=="fixture-task" and .bead_id=="fixture-task")' "$TMP/usage.jsonl" >/dev/null; then
  pass "usage log records hint injection"
else
  fail "usage log records hint injection"
fi
if rg -q 'L999' "$TMP/out.md"; then fail "unrelated rule excluded"; else pass "unrelated rule excluded"; fi

"$BIN" "$TMP/packet.md" fixture-task "$TMP/repo" >"$TMP/dedup.md"
if rg -q '^## L-RULE HINTS$' "$TMP/dedup.md"; then
  fail "dedup suppresses repeat hints"
else
  pass "dedup suppresses repeat hints"
fi

FLYWHEEL_L_RULES_DIR="$TMP/missing" "$BIN" "$TMP/packet.md" missing-task "$TMP/repo" >"$TMP/missing.md"
if cmp -s "$TMP/packet.md" "$TMP/missing.md"; then
  pass "missing rules dir passthrough"
else
  fail "missing rules dir passthrough"
fi

before="$(shasum "$TMP/packet.md" | awk '{print $1}')"
L_RULE_HINTS_DISABLED=1 "$BIN" "$TMP/packet.md" disabled "$TMP/repo" >"$TMP/disabled.md"
after="$(shasum "$TMP/packet.md" | awk '{print $1}')"
if [[ "$before" == "$after" ]] && cmp -s "$TMP/packet.md" "$TMP/disabled.md"; then
  pass "disabled passthrough unchanged"
else
  fail "disabled passthrough unchanged"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
