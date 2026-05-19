#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/inventory-tier-refine.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/inventory-tier-refine-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

repo_a="$TMP/repo-a"
repo_b="$TMP/repo-b"
mkdir -p "$repo_a/scripts" "$repo_a/tests" "$repo_a/.flywheel" "$repo_b/scripts"

for file in hot canon fixture new old doctor; do
  cat >"$repo_a/scripts/$file.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  --json) printf '{"ok":true}\n' ;;
  *) printf 'usage\n' ;;
esac
SH
  chmod +x "$repo_a/scripts/$file.sh"
done
cat >"$repo_b/scripts/doctor.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf 'doctor\n'
SH
chmod +x "$repo_b/scripts/doctor.sh"

cat >>"$repo_a/scripts/canon.sh" <<'SH'
# canonical-cli-scoping fixture hook
SH

cat >"$repo_a/tests/fixture-coverage.sh" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
bash scripts/fixture.sh --json
SH
chmod +x "$repo_a/tests/fixture-coverage.sh"

{
  for idx in $(seq 1 10); do
    jq -nc --arg idx "$idx" '{timestamp:"2026-05-18T00:00:00Z",task_id:("hot-"+$idx),evidence:"scripts/hot.sh"}'
  done
  jq -nc '{timestamp:"2026-04-01T00:00:00Z",task_id:"old-window",evidence:"scripts/fixture.sh"}'
} >"$repo_a/.flywheel/dispatch-log.jsonl"

inventory="$TMP/inventory.jsonl"
jq -nc --arg repo_path "$repo_a" '{schema_version:"system-inventory.surface/v1",repo:"repo-a",repo_path:$repo_path,path:"scripts/hot.sh",class:"other",language:"bash",lines:8,exec_bit:true,tier:"T2 common",invoke_count_30d:0,canonical_cli_present:false,age_days:5,missing_repo:false}' >>"$inventory"
jq -nc --arg repo_path "$repo_a" '{schema_version:"system-inventory.surface/v1",repo:"repo-a",repo_path:$repo_path,path:"scripts/canon.sh",class:"other",language:"bash",lines:9,exec_bit:true,tier:"T3 internal",invoke_count_30d:0,canonical_cli_present:false,age_days:5,missing_repo:false}' >>"$inventory"
jq -nc --arg repo_path "$repo_a" '{schema_version:"system-inventory.surface/v1",repo:"repo-a",repo_path:$repo_path,path:"scripts/fixture.sh",class:"other",language:"bash",lines:8,exec_bit:true,tier:"T3 internal",invoke_count_30d:0,canonical_cli_present:false,age_days:5,missing_repo:false}' >>"$inventory"
jq -nc --arg repo_path "$repo_a" '{schema_version:"system-inventory.surface/v1",repo:"repo-a",repo_path:$repo_path,path:"scripts/new.sh",class:"other",language:"bash",lines:8,exec_bit:true,tier:"T2 common",invoke_count_30d:0,canonical_cli_present:false,age_days:3,missing_repo:false}' >>"$inventory"
jq -nc --arg repo_path "$repo_a" '{schema_version:"system-inventory.surface/v1",repo:"repo-a",repo_path:$repo_path,path:"scripts/old.sh",class:"other",language:"bash",lines:8,exec_bit:true,tier:"T3 internal",invoke_count_30d:0,canonical_cli_present:false,age_days:45,missing_repo:false}' >>"$inventory"
jq -nc --arg repo_path "$repo_a" '{schema_version:"system-inventory.surface/v1",repo:"repo-a",repo_path:$repo_path,path:"scripts/doctor.sh",class:"doctor",language:"bash",lines:8,exec_bit:true,tier:"T2 common",invoke_count_30d:0,canonical_cli_present:false,age_days:5,missing_repo:false}' >>"$inventory"
jq -nc --arg repo_path "$repo_b" '{schema_version:"system-inventory.surface/v1",repo:"repo-b",repo_path:$repo_path,path:"scripts/doctor.sh",class:"doctor",language:"bash",lines:3,exec_bit:true,tier:"T2 common",invoke_count_30d:0,canonical_cli_present:false,age_days:5,missing_repo:false}' >>"$inventory"

out_a="$TMP/out-a"
out_b="$TMP/out-b"
INVENTORY_TIER_REFINE_NOW="2026-05-19T00:00:00Z" "$SCRIPT" --write-report --inventory "$inventory" --output-dir "$out_a" --dispatch-log "$TMP/missing-dispatch.jsonl" >/dev/null
INVENTORY_TIER_REFINE_NOW="2026-05-19T00:00:00Z" "$SCRIPT" --write-report --inventory "$inventory" --output-dir "$out_b" --dispatch-log "$TMP/missing-dispatch.jsonl" >/dev/null

if cmp -s "$out_a/inventory-tier-refined.jsonl" "$out_b/inventory-tier-refined.jsonl" && cmp -s "$out_a/TIER-REFINEMENT.md" "$out_b/TIER-REFINEMENT.md"; then
  pass "rerun_idempotent"
else
  fail "rerun_idempotent"
fi

jq -e 'select(.path=="scripts/hot.sh" and .tier=="T1 fleet-critical" and .invoke_count_30d >= 10 and (.tier_reason|index("invoke_count_30d>=10")))' "$out_a/inventory-tier-refined.jsonl" >/dev/null \
  && pass "invoke_threshold_promotes_t1" || fail "invoke_threshold_promotes_t1"

jq -e 'select(.path=="scripts/canon.sh" and .tier=="T1 fleet-critical" and .canonical_cli_present==true)' "$out_a/inventory-tier-refined.jsonl" >/dev/null \
  && pass "canonical_cli_promotes_t1" || fail "canonical_cli_promotes_t1"

jq -e 'select(.path=="scripts/fixture.sh" and .tier=="T2 common" and .has_fixture_coverage==true)' "$out_a/inventory-tier-refined.jsonl" >/dev/null \
  && pass "fixture_coverage_promotes_t2" || fail "fixture_coverage_promotes_t2"

jq -e 'select(.path=="scripts/new.sh" and .tier=="T3 internal")' "$out_a/inventory-tier-refined.jsonl" >/dev/null \
  && pass "new_zero_invoke_is_t3" || fail "new_zero_invoke_is_t3"

jq -e 'select(.path=="scripts/old.sh" and .tier=="T4 deprecated")' "$out_a/inventory-tier-refined.jsonl" >/dev/null \
  && pass "old_zero_invoke_is_t4" || fail "old_zero_invoke_is_t4"

jq -e 'select(.path=="scripts/doctor.sh" and .tier=="T1 fleet-critical" and .cross_repo_consumer_count>=1)' "$out_a/inventory-tier-refined.jsonl" >/dev/null \
  && pass "doctor_cross_repo_promotes_t1" || fail "doctor_cross_repo_promotes_t1"

grep -q 'Top 20 T1 Surfaces Queued For Phase 3 Ergonomics Audit' "$out_a/TIER-REFINEMENT.md" \
  && pass "report_names_phase3_queue" || fail "report_names_phase3_queue"

"$SCRIPT" --json --inventory "$inventory" --dispatch-log "$TMP/missing-dispatch.jsonl" --now "2026-05-19T00:00:00Z" >"$TMP/stdout.jsonl"
[[ "$(wc -l <"$TMP/stdout.jsonl" | tr -d ' ')" == "7" ]] \
  && pass "json_mode_emits_same_rows" || fail "json_mode_emits_same_rows"

printf 'SUMMARY pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$fail_count" == "0" ]]
