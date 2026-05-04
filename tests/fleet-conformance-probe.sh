#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/fleet-conformance-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/fleet-conformance-probe-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

mkdir -p "$TMP/root/green/.flywheel" "$TMP/root/red/.flywheel" "$TMP/loops" "$TMP/doctor" "$TMP/cache"

chmod +x "$SCRIPT"
bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"

cat >"$TMP/canonical.md" <<'EOF'
## L1 — ONE
## L2 — TWO
## L3 — THREE
EOF

cat >"$TMP/root/green/AGENTS.md" <<'EOF'
## L1 — ONE
## L2 — TWO
## L3 — THREE
EOF
cat >"$TMP/root/red/AGENTS.md" <<'EOF'
## L1 — ONE
EOF

cat >"$TMP/root/green/.flywheel/META-RULE-CACHE.md" <<'EOF'
fresh meta rule cache
EOF
cat >"$TMP/root/green/.flywheel/MISSION.md" <<'EOF'
---
status: locked
locked_at: 2026-05-04T00:00:00Z
mission_lock_id: green-lock
---
green mission
EOF
cat >"$TMP/root/red/.flywheel/MISSION.md" <<'EOF'
red mission without lock metadata
EOF

cat >"$TMP/loops/green.json" <<EOF
{"session":"green","active":true,"repo":"$TMP/root/green","orchestrator_pane":1}
EOF
cat >"$TMP/loops/red.json" <<EOF
{"session":"red","active":true,"repo":"$TMP/root/red","orchestrator_pane":1}
EOF

cat >"$TMP/doctor/green.json" <<'EOF'
{"status":"ok","errors":[],"warnings":[],"identity_registry_drift":0,"fleet_identity_drift_count":0,"orchestrator_unknown_worker_identity_count":0,"identity_token_orphan_local":0,"agentmail_orphan_session_rows_count":0}
EOF
cat >"$TMP/doctor/red.json" <<'EOF'
{"status":"fail","errors":[{"code":"canonical_root_drift"}],"warnings":[],"identity_registry_drift":2,"fleet_identity_drift_count":2,"orchestrator_unknown_worker_identity_count":1,"identity_token_orphan_local":1,"agentmail_orphan_session_rows_count":1}
EOF

base_args=(
  --fleet
  --root "$TMP/root"
  --loops-dir "$TMP/loops"
  --canonical-agents "$TMP/canonical.md"
  --doctor-fixture-dir "$TMP/doctor"
  --cache-dir "$TMP/cache"
  --no-cache
  --now-epoch 1777939200
  --json
)

"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.mutates_only_with == "--apply without --dry-run" and (.canonical_cli_flags | index("--dry-run")) and .anti_agent_shaming == true' "info exposes canonical CLI and anti-shaming contract"

"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '(.required | index("fleet_conformance_red_count")) and .properties.fleet_conformance_min_score.type[0] == "integer"' "schema exposes doctor fields"

"$SCRIPT" "${base_args[@]}" >"$TMP/report.json" || true
assert_jq "$TMP/report.json" '.fleet_conformance_total_count == 2' "fleet checks both fixture sessions"
assert_jq "$TMP/report.json" '.fleet_conformance_green_count == 1 and .fleet_conformance_red_count == 1 and .fleet_conformance_yellow_count == 0' "fleet color counts are correct"
assert_jq "$TMP/report.json" '.fleet_conformance_worst_session == "red" and .fleet_conformance_min_score < 60' "worst session and min score are correct"
assert_jq "$TMP/report.json" '.fleet_conformance[] | select(.session == "green") | .status == "green" and .score >= 85' "known-green fixture is green"
assert_jq "$TMP/report.json" '.fleet_conformance[] | select(.session == "red") | .status == "red" and (.red_axes | index("doctor_status"))' "known-red fixture is red"
assert_jq "$TMP/report.json" '.fleet_conformance[] | select(.session == "red") | (.axes[] | select(.name == "canonical_l_rule_coverage") | .missing_count == 2)' "L-rule coverage axis detects missing rules"
assert_jq "$TMP/report.json" '.planned_packets | length == 1 and .[0].dry_run == true and (.[0].packet | contains("CONFORMANCE-DRIFT session=red"))' "dry-run packet shape targets red session"

cat >"$TMP/ntm" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$NTM_LOG"
exit 0
EOF
chmod +x "$TMP/ntm"
NTM_LOG="$TMP/ntm.log" "$SCRIPT" "${base_args[@]}" --apply --dry-run --ntm "$TMP/ntm" >"$TMP/apply-dry-run.json" || true
assert_jq "$TMP/apply-dry-run.json" '.planned_packets[0].dry_run == true and (.planned_packets[0] | has("sent") | not)' "apply dry-run does not send ntm"
[[ ! -f "$TMP/ntm.log" ]] && pass "fake ntm untouched during dry-run" || fail "fake ntm untouched during dry-run"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
