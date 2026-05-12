#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
STATUS_MD="$HOME/.claude/commands/flywheel/status.md"
FLYWHEEL="$HOME/.claude/skills/.flywheel/bin/flywheel"
CHECKER="$HOME/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh"

case "${1:-}" in
  doctor|health|completion)
    if [[ "${2:-}" == "--help" || "${2:-}" == "-h" ]]; then
      printf 'usage: %s [doctor|health|completion --help] [--help]\n' "$(basename "$0")"
      exit 0
    fi
    ;;
  --help|-h|--info|--examples|quickstart|help)
    printf 'usage: %s\n' "$(basename "$0")"
    exit 0
    ;;
esac

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

grep -q 'Dispatch fitness:' "$STATUS_MD" && pass "status_md/dispatch_fitness_line_present" || fail "status_md/dispatch_fitness_line_present"
grep -q 'dispatch_log_fitness' "$STATUS_MD" && pass "status_md/doctor_json_key_present" || fail "status_md/doctor_json_key_present"

sample_line="$(jq -rn --argjson d '{"coverage_pct":90,"drift_count":0,"window":50,"status":"PASS"}' '
  "🎯 Dispatch fitness: \($d.coverage_pct)% (drift=\($d.drift_count), last \($d.window))" +
  (if $d.status == "PASS" then "" else " " + $d.status end)
')"
case "$sample_line" in
  "🎯 Dispatch fitness: "*"% (drift="*", last 50)"*) pass "line_format/sample_matches" ;;
  *) fail "line_format/sample_matches: $sample_line" ;;
esac

set +e
doctor_json="$("$FLYWHEEL" doctor --json 2>/dev/null)"
set -e
printf '%s\n' "$doctor_json" | jq -e '.dispatch_log_fitness.coverage_pct != null and .dispatch_log_fitness.drift_count != null and (.dispatch_log_fitness.status | test("PASS|WARN|FAIL"))' >/dev/null \
  && pass "flywheel_doctor_json/dispatch_log_fitness_present" || fail "flywheel_doctor_json/dispatch_log_fitness_present"

bash "$CHECKER" "$0" >/dev/null && pass "canonical_cli_scoping/status_dashboard_test" || fail "canonical_cli_scoping/status_dashboard_test"

printf '\nResults: %d PASS  %d FAIL\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]] || exit 1
