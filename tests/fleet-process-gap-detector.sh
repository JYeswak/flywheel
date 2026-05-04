#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/fleet-process-gap-detector.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/fleet-process-gap-detector.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

mkdir -p "$TMP/repo/templates/flywheel-install" "$TMP/ticks" "$TMP/state" "$TMP/bin"
git -C "$TMP/repo" init -q

for n in 1 2 3 4 5 6 7 8 9 10; do
  printf '## L%s -- fixture\n\n' "$n" >>"$TMP/repo/AGENTS.md"
done
for n in 1 2 3; do
  printf '## L%s -- fixture\n\n' "$n" >>"$TMP/repo/templates/flywheel-install/AGENTS.md"
done

cat >"$TMP/fuckups.jsonl" <<'JSONL'
{"ts":"2026-05-04T19:00:00Z","trauma_class":"repeat-fixture","severity":"medium"}
{"ts":"2026-05-04T19:10:00Z","trauma_class":"repeat-fixture","severity":"medium"}
{"ts":"2026-05-04T19:20:00Z","trauma_class":"repeat-fixture","severity":"medium"}
{"ts":"2026-05-03T18:00:00Z","trauma_class":"stale-promotion","severity":"medium","promote":true}
JSONL

cat >"$TMP/ticks/t1.json" <<'JSON'
{"ts":"2026-05-04T17:00:00Z","repo":"fixture","doctor":{"errors":[{"code":"same_error"}],"closed_bead_audit_gap_count":0,"fleet_identity_drift_count":0,"fleet_watcher_coverage_count":1,"fleet_watcher_coverage_total":2}}
JSON
cat >"$TMP/ticks/t2.json" <<'JSON'
{"ts":"2026-05-04T18:00:00Z","repo":"fixture","doctor":{"errors":[{"code":"same_error"}],"closed_bead_audit_gap_count":1,"fleet_identity_drift_count":0,"fleet_watcher_coverage_count":1,"fleet_watcher_coverage_total":2}}
JSON
cat >"$TMP/ticks/t3.json" <<'JSON'
{"ts":"2026-05-04T19:00:00Z","repo":"fixture","doctor":{"errors":[{"code":"same_error"}],"closed_bead_audit_gap_count":1,"fleet_identity_drift_count":1,"fleet_watcher_coverage_count":1,"fleet_watcher_coverage_total":2,"fleet_watcher_coverage_hole_age_seconds":90000}}
JSON

cat >"$TMP/bin/br" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_BR_LOG:?}"
idx="$(wc -l <"${FAKE_BR_LOG}" | tr -d ' ')"
printf '{"id":"flywheel-auto-%s"}\n' "$idx"
SH
chmod +x "$TMP/bin/br"

cat >"$TMP/bin/br-fallback" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_BR_FALLBACK_LOG:?}"
if [[ "${1:-}" != "--no-db" ]]; then
  printf 'database disk image is malformed: invalid b-tree page type flag: 0x00\n' >&2
  exit 2
fi
idx="$(grep -c '^--no-db create ' "${FAKE_BR_FALLBACK_LOG}" | tr -d ' ')"
printf '{"id":"flywheel-fallback-%s"}\n' "$idx"
SH
chmod +x "$TMP/bin/br-fallback"

run_detector() {
  "$SCRIPT" \
    --repo "$TMP/repo" \
    --fleet-repo "$TMP/repo" \
    --fuckup-log "$TMP/fuckups.jsonl" \
    --tick-dir "$TMP/ticks" \
    --state-dir "$TMP/state" \
    --now 2026-05-04T20:00:00Z \
    --json "$@"
}

bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"
"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "fleet-process-gap-detector" and (.doctor_fields | index("fleet_process_health_score"))' "info exposes doctor fields"
"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "fleet-process-gap-detector/v1" and .properties.process_health_score.maximum == 100' "schema exposes v1 score bounds"
"$SCRIPT" --examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '(.examples | length) >= 3' "examples surface"

run_detector >"$TMP/out.json"
assert_jq "$TMP/out.json" '.schema_version == "fleet-process-gap-detector/v1"' "detector emits v1 schema"
assert_jq "$TMP/out.json" '.open_gap_count >= 6 and (.signals_implemented | length) == 7' "all seven signals implemented"
assert_jq "$TMP/out.json" 'any(.top_gaps[]; .class == "sticky_doctor_error:same_error" and .severity == "high")' "sticky doctor error flagged"
assert_jq "$TMP/out.json" 'any(.top_gaps[]; .class == "fleet_identity_drift")' "identity drift flagged"
assert_jq "$TMP/out.json" '.top_gaps | length == 3' "top gaps capped at three"
assert_jq "$TMP/out.json" '.process_health_score >= 0 and .process_health_score <= 100' "health score bounded"

run_detector --max-gaps 10 >"$TMP/out-all.json"
assert_jq "$TMP/out-all.json" 'any(.top_gaps[]; .class == "repeat-fixture" and .occurrences == 3)' "repeating fuckup class flagged"
assert_jq "$TMP/out-all.json" 'any(.top_gaps[]; .class == "three_surface_drift:repo")' "3-surface delta of seven flagged"
assert_jq "$TMP/out-all.json" 'any(.top_gaps[]; .class == "unprocessed_promotion:stale-promotion")' "stale promotion candidate flagged"
assert_jq "$TMP/out-all.json" 'any(.top_gaps[]; .class == "closed_bead_audit_gap")' "closed bead audit gap flagged"
assert_jq "$TMP/out-all.json" 'any(.top_gaps[]; .class == "fleet_watcher_coverage_hole")' "watcher coverage hole flagged"
assert_jq "$TMP/out-all.json" 'all(.top_gaps[]; .proposed_remediation and .remediation_skill)' "top gaps include remediation and skill"

run_detector --apply --dry-run --br-bin "$TMP/bin/br" >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '(.planned_actions | length) == 3 and (.actual_actions | length) == 0 and all(.planned_actions[]; .action == "create")' "apply dry-run produces bead-create plan"

FAKE_BR_FALLBACK_LOG="$TMP/br-fallback.log" run_detector --state-dir "$TMP/state-fallback" --apply --idempotency-key fallback-key --br-bin "$TMP/bin/br-fallback" >"$TMP/apply-fallback.json"
assert_jq "$TMP/apply-fallback.json" '(.fix_beads_filed | length) == 3 and all(.actual_actions[]; .applied == true and .fallback_used == true)' "apply falls back to no-db for beads DB failures"
test "$(grep -c '^--no-db create ' "$TMP/br-fallback.log" | tr -d ' ')" = "3" && pass "no-db fallback attempted once per planned bead" || fail "no-db fallback attempted once per planned bead"

FAKE_BR_LOG="$TMP/br.log" run_detector --apply --idempotency-key test-key --br-bin "$TMP/bin/br" >"$TMP/apply1.json"
assert_jq "$TMP/apply1.json" '(.fix_beads_filed | length) == 3 and (.actual_actions | map(select(.applied == true)) | length) == 3' "apply files three fake beads"
FAKE_BR_LOG="$TMP/br.log" run_detector --apply --idempotency-key test-key --br-bin "$TMP/bin/br" >"$TMP/apply2.json"
assert_jq "$TMP/apply2.json" '(.fix_beads_filed | length) == 0 and all(.actual_actions[]; .applied == false and .reason == "deduped_existing_bead")' "second apply dedupes by stable marker"
test "$(grep -c '^create ' "$TMP/br.log" | tr -d ' ')" = "3" && pass "dedupe suppresses duplicate br calls" || fail "dedupe suppresses duplicate br calls"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
