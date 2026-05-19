#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/agent-ergonomics-fleet-audit.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/agent-ergo-fleet.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass(){ printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail(){ printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

mkdir -p "$TMP/repo/bin"
cat >"$TMP/repo/bin/sample-cli" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  --help|-h) printf 'usage: sample-cli capabilities --json | robot-docs | doctor --json\nAgent automation: use capabilities --json first.\n' ;;
  capabilities) jq -nc '{schema_version:"sample.capabilities/v1",command:"capabilities",features:["json_output","robot_docs"],exit_codes:{"0":"success"}}' ;;
  robot-docs) printf 'sample robot guide\n' ;;
  doctor) jq -nc '{schema_version:"sample.doctor/v1",status:"pass"}' ;;
  *) printf 'ERR: unknown argument; try sample-cli --help\n' >&2; exit 2 ;;
esac
SH
chmod +x "$TMP/repo/bin/sample-cli"
cat >"$TMP/surfaces.txt" <<EOF
bin/sample-cli|CLI|11|capabilities --json|robot-docs|doctor --json
EOF

out="$TMP/out"
(
  cd "$TMP/repo"
  AGENT_ERGONOMICS_AUDIT_ROOT="$TMP/repo" "$SCRIPT" --surface-list-file "$TMP/surfaces.txt" --output-dir "$out" --json >"$TMP/result.json"
)

jq -e '.status == "PASS" and .surface_count == 1 and .median_score >= 750' "$TMP/result.json" >/dev/null \
  && pass "json_result_pass" || fail "json_result_pass"

[[ -s "$TMP/repo/bin/sample-cli__agent_ergonomics_audit/scorecard.json" ]] \
  && pass "workspace_scorecard_written" || fail "workspace_scorecard_written"

bash "$TMP/repo/bin/sample-cli__agent_ergonomics_audit/regression-tests.sh" >/dev/null \
  && pass "generated_regression_passes" || fail "generated_regression_passes"

grep -q 'Median final score' "$out/SUMMARY.md" \
  && pass "summary_written" || fail "summary_written"

printf 'SUMMARY pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" == "0" ]]
