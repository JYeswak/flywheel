#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
VALIDATOR="$ROOT/.flywheel/scripts/three-judges-publishability-validator.sh"
OPENER="$ROOT/.flywheel/scripts/three-judges-rework-bead-opener.sh"
SCHEMA="$ROOT/.flywheel/validation-schema/v1/three-judges-publishability-decision.schema.json"
WRAPPER="/Users/josh/.claude/commands/flywheel/_shared/three-judges-publishability-precheck.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/three-judges-publishability.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; exit 1; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  jq -e "$expr" "$file" >/dev/null || { jq . "$file" >&2 || true; fail "$label"; }
  pass "$label"
}

expect_rc() {
  local name="$1" want="$2"
  shift 2
  set +e
  "$@" >"$TMP/$name.out" 2>"$TMP/$name.err"
  local got=$?
  set -e
  [[ "$got" -eq "$want" ]] || { cat "$TMP/$name.out" >&2 || true; cat "$TMP/$name.err" >&2 || true; fail "$name rc expected=$want got=$got"; }
}

write_repo() {
  local repo="$1" verdicts="$2" idx=0 verdict
  mkdir -p "$repo/.flywheel" "$repo/.beads" "$repo/tests"
  git -C "$repo" init -q >/dev/null 2>&1
  printf '# Fixture\n\nQuick start demo.\n' >"$repo/README.md"
  printf '# Mission\n' >"$repo/.flywheel/MISSION.md"
  printf '# Incidents\n' >"$repo/INCIDENTS.md"
  printf '#!/usr/bin/env bash\nexit 0\n' >"$repo/tests/smoke.sh"
  chmod +x "$repo/tests/smoke.sh"
  {
    printf '# Publishability Audit\n\nPublic repo: no\n\n'
    printf '| facet_id | facet | verdict | evidence |\n'
    printf '|---|---|---|---|\n'
    for facet in \
      "F1|README front-door" \
      "F2|Doctrine clarity" \
      "F3|Doctor/health/repair triad" \
      "F4|Executable tests" \
      "F5|Idempotent install + uninstall" \
      "F6|Code aesthetic" \
      "F7|Demo-ability"; do
      idx=$((idx + 1))
      verdict="$(printf '%s\n' "$verdicts" | cut -d',' -f"$idx")"
      printf '| %s | %s | %s | fixture |\n' "${facet%%|*}" "${facet#*|}" "$verdict"
    done
    printf '\n## ZestStream Voice Gate\n\n'
    printf '| field | value |\n|---|---|\n'
    printf '| Public voice gate | EXEMPT_INTERNAL |\n| ZestStream voice score | 100 |\n| Banned words count | 0 |\n| Ungrounded claims count | 0 |\n| Scorecard log | fixture |\n'
  } >"$repo/.flywheel/PUBLISHABILITY-AUDIT.md"
}

ledger="$TMP/ledger.jsonl"
export THREE_JUDGES_PUBLISHABILITY_LEDGER="$ledger"
export THREE_JUDGES_REWORK_OPENER="$OPENER"

bash -n "$VALIDATOR"
bash -n "$OPENER"
bash -n "$WRAPPER"
"$VALIDATOR" --help >/dev/null
"$VALIDATOR" --examples >/dev/null
"$VALIDATOR" --info | jq -e '.schema_version == "three-judges-publishability/v1"' >/dev/null
pass "cli_help_examples_info"

high="$TMP/high"; write_repo "$high" "YES,YES,YES,YES,YES,YES,YES"
expect_rc high 0 "$VALIDATOR" check --repo "$high" --bead-id flywheel-high --mode strict --json
assert_jq "$TMP/high.out" '.decision == "PASS" and .composite_score == 9 and (.failed_facets | length) == 0' "high_quality_pass"

mid="$TMP/mid"; write_repo "$mid" "YES,YES,YES,YES,YES,NO,NO"
expect_rc mid 0 "$VALIDATOR" check --repo "$mid" --bead-id flywheel-mid --mode strict --json
assert_jq "$TMP/mid.out" '.decision == "WARN" and .composite_score == 7.57 and (.failed_facets | length) == 2' "mid_quality_warn"

low="$TMP/low"; write_repo "$low" "YES,YES,NO,NO,NO,NO,NO"
expect_rc low_strict 1 "$VALIDATOR" check --repo "$low" --bead-id flywheel-low --mode strict --json
assert_jq "$TMP/low_strict.out" '.decision == "REFUSE" and .close_allowed == false and .composite_score == 5.43' "strict_low_refuses"
assert_jq "$TMP/low_strict.out" '(.failed_facets | length) == 5 and all(.failed_facets[]; .score < 5)' "failed_facet_detection"

expect_rc low_advisory 0 "$VALIDATOR" check --repo "$low" --bead-id flywheel-low --mode advisory --json
assert_jq "$TMP/low_advisory.out" '.decision == "REFUSE" and .close_allowed == true and .mode == "advisory"' "advisory_low_allows"

before_lines="$(wc -l <"$low/.beads/issues.jsonl")"
expect_rc low_strict_again 1 "$VALIDATOR" check --repo "$low" --bead-id flywheel-low --mode strict --json
after_lines="$(wc -l <"$low/.beads/issues.jsonl")"
[[ "$before_lines" == "$after_lines" ]] || fail "rework idempotent line count"
assert_jq "$TMP/low_strict.out" '(.rework_beads_filed | length) == 5 and all(.rework_beads_filed[]; .action == "jsonl_fallback")' "rework_beads_filed"
assert_jq "$TMP/low_strict_again.out" '(.rework_beads_filed | length) == 5 and all(.rework_beads_filed[]; .action == "reused")' "rework_beads_idempotent"

ledger_lines="$(wc -l <"$ledger")"
[[ "$ledger_lines" -ge 5 ]] || fail "ledger rows missing"
pass "ledger_row_appended_every_decision"

python3 - "$SCHEMA" "$TMP/high.out" <<'PY'
import json, sys
from jsonschema import Draft202012Validator
schema = json.load(open(sys.argv[1], encoding="utf-8"))
payload = json.load(open(sys.argv[2], encoding="utf-8"))
Draft202012Validator.check_schema(schema)
Draft202012Validator(schema).validate(payload)
PY
pass "schema_valid"

jq -e '((([.per_facet_scores[].score] | add) / 7) * 100 | round / 100) == .composite_score' "$TMP/mid.out" >/dev/null
pass "composite_arithmetic_avg_of_7"

printf strict >"$low/.flywheel/three-judges-mode"
expect_rc wrapper_strict 1 env THREE_JUDGES_PUBLISHABILITY_VALIDATOR="$VALIDATOR" THREE_JUDGES_REWORK_OPENER="$OPENER" THREE_JUDGES_PUBLISHABILITY_LEDGER="$ledger" "$WRAPPER" --repo "$low" --bead-id flywheel-low --json
assert_jq "$TMP/wrapper_strict.out" '.mode == "strict" and .decision == "REFUSE"' "strict_opt_in_wrapper_blocks"

[[ "$pass_count" -eq 12 ]] || fail "expected 12 assertions got $pass_count"
printf 'PASS cases=10 assertions=%s failures=0\n' "$pass_count"
