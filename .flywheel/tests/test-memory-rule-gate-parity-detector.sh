#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/memory-rule-gate-parity-detector.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/memory-rule-gate-parity-decision.schema.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/memory-rule-gate-parity-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then pass "$label"; else jq . "$file" >&2 || true; fail "$label"; fi
}

expect_rc() {
  local label="$1" want="$2"; shift 2
  set +e
  "$@" >"$TMP/$label.out" 2>"$TMP/$label.err"
  local rc=$?
  set -e
  [[ "$rc" == "$want" ]] || { cat "$TMP/$label.err" >&2; fail "$label rc=$rc want=$want"; }
  pass "$label rc"
}

make_repo() {
  local name="$1" repo
  repo="$TMP/$name/repo"
  mkdir -p "$repo/.flywheel/scripts" "$repo/.flywheel/tests" "$repo/.beads"
  : >"$repo/.beads/issues.jsonl"
  : >"$repo/INCIDENTS.md"
  printf '%s\n' "$repo"
}

make_memory() {
  local name="$1" mem
  mem="$TMP/$name/memory"
  mkdir -p "$mem"
  printf '%s\n' "$mem"
}

write_meta() {
  local mem="$1" stem="$2"
  cat >"$mem/feedback_${stem}.md" <<EOF
---
description: META-RULE fixture for ${stem}
---
META-RULE: ${stem}
EOF
}

write_non_meta() {
  local mem="$1" stem="$2"
  printf 'ordinary note\n' >"$mem/feedback_${stem}.md"
}

run_detector() {
  local label="$1" repo="$2" mem="$3"; shift 3
  local hooks="$TMP/$label/hooks" settings="$TMP/$label/settings.json" ledger="$TMP/$label/ledger.jsonl"
  mkdir -p "$hooks" "$(dirname "$settings")"
  printf '{"hooks":{"Stop":[],"PreCompact":[]}}\n' >"$settings"
  MEMORY_RULE_GATE_PARITY_HOOKS_DIR="$hooks" \
  MEMORY_RULE_GATE_PARITY_SETTINGS_JSON="$settings" \
  MEMORY_RULE_GATE_PARITY_LEDGER="$ledger" \
    "$SCRIPT" check --repo "$repo" --memory-dir "$mem" --json "$@" >"$TMP/$label.json"
}

validate_payload() {
  python3 - "$SCHEMA" "$1" <<'PY'
import json, sys
from jsonschema import Draft202012Validator
schema = json.load(open(sys.argv[1], encoding="utf-8"))
payload = json.load(open(sys.argv[2], encoding="utf-8"))
Draft202012Validator.check_schema(schema)
Draft202012Validator(schema).validate(payload)
PY
}

bash -n "$SCRIPT" && pass "script_syntax"
"$SCRIPT" --help >/dev/null && pass "help_passes"
"$SCRIPT" --examples >/dev/null && pass "examples_passes"
jq empty "$SCHEMA" && pass "schema_json_parses"

repo="$(make_repo green)"; mem="$(make_memory green)"
write_meta "$mem" "alpha_rule"
printf '#!/usr/bin/env bash\n# alpha-rule\n' >"$repo/.flywheel/scripts/alpha-rule-gate.sh"
printf '#!/usr/bin/env bash\n' >"$repo/.flywheel/tests/test-alpha-rule.sh"
mkdir -p "$TMP/green/hooks"
printf '#!/usr/bin/env bash\n' >"$TMP/green/hooks/flywheel-alpha-rule-hook.sh"
printf 'alpha-rule incident\n' >"$repo/INCIDENTS.md"
MEMORY_RULE_GATE_PARITY_HOOKS_DIR="$TMP/green/hooks" MEMORY_RULE_GATE_PARITY_LEDGER="$TMP/green/ledger.jsonl" \
  "$SCRIPT" check --repo "$repo" --memory-dir "$mem" --json >"$TMP/green.json"
assert_jq "$TMP/green.json" '.signal == "GREEN" and .wired == 1 and .unwired == 0' "all_wired_green"
validate_payload "$TMP/green.json" && pass "green_schema_valid"

repo="$(make_repo yellow)"; mem="$(make_memory yellow)"
write_meta "$mem" "lonely_rule"
run_detector yellow "$repo" "$mem"
assert_jq "$TMP/yellow.json" '.signal == "YELLOW" and .unwired == 1 and (.beads_would_file | length) == 1' "one_unwired_yellow_would_file"
[[ ! -s "$repo/.beads/issues.jsonl" ]] && pass "dry_run_no_issue_append" || fail "dry_run_no_issue_append"

repo="$(make_repo red)"; mem="$(make_memory red)"
write_meta "$mem" "one_rule"; write_meta "$mem" "two_rule"; write_meta "$mem" "three_rule"
run_detector red "$repo" "$mem"
assert_jq "$TMP/red.json" '.signal == "RED" and .unwired == 3 and (.beads_would_file | length) == 3' "three_unwired_red"

repo="$(make_repo nonmeta)"; mem="$(make_memory nonmeta)"
write_non_meta "$mem" "ordinary_rule"
run_detector nonmeta "$repo" "$mem"
assert_jq "$TMP/nonmeta.json" '.signal == "GREEN" and .total_meta_rules == 0 and .not_meta_rule == 1' "non_meta_ignored"

repo="$(make_repo idem)"; mem="$(make_memory idem)"
write_meta "$mem" "idem_rule"
run_detector idem1 "$repo" "$mem" --auto-bead
run_detector idem2 "$repo" "$mem" --auto-bead
[[ "$(wc -l <"$repo/.beads/issues.jsonl" | tr -d ' ')" == "1" ]] || fail "auto_bead_duplicate"
assert_jq "$TMP/idem1.json" '.beads_filed[0].action == "jsonl_fallback"' "auto_bead_first_append"
assert_jq "$TMP/idem2.json" '.beads_filed[0].action == "reused"' "auto_bead_second_reused"

repo="$(make_repo missing)"
expect_rc missing 2 env MEMORY_RULE_GATE_PARITY_LEDGER="$TMP/missing-ledger.jsonl" "$SCRIPT" check --repo "$repo" --memory-dir "$TMP/does-not-exist" --json
assert_jq "$TMP/missing.out" '.signal == "GRAY" and .exit_code == 2 and (.warnings | index("memory_dir_missing"))' "missing_memory_gray"
[[ "$(wc -l <"$TMP/missing-ledger.jsonl" | tr -d ' ')" == "1" ]] || fail "missing_memory_ledger"
pass "ledger_appended_on_missing_memory"

validate_payload "$TMP/red.json" && pass "red_schema_valid"
printf 'PASS cases=7 assertions=%s failures=0\n' "$pass_count"
