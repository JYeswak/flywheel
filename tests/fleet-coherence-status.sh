#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="<flywheel-state>/bin/flywheel-loop"
LIB="<flywheel-state>/lib/drift-status.sh"
FIXTURE="$ROOT/.flywheel/fixtures/fleet-coherence-latest-v2.json"
TMP="$(mktemp -d -t drift-status.XXXXXX)"
trap 'rm -r "$TMP"' EXIT

NOW_EPOCH=1778112600

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_jq() {
    local file="$1" expr="$2" label="$3"
    jq -e "$expr" "$file" >/dev/null || fail "$label"
}

run_status() {
    "$BIN" drift-status --json --latest "$1" --log "$2" --now-epoch "$NOW_EPOCH" "${@:3}"
}

write_clean_log() {
    local path="$1"
    cat >"$path" <<'JSONL'
{"schema_version":"fleet-coherence-event/v2","id":"fixture-info","ts":"2026-05-07T00:00:00Z","class":"fleet_scan_heartbeat","severity":"info","state":"closed","session":"flywheel","pane":3,"raw_source_refs":["fixture:info"],"evidence":{"source_quality":{"ntm_health_activity_authoritative":true}},"l61":{"ntm_attempted":true,"agent_mail_attempted":true,"l61_pairing_status":"paired","degraded_reason":null},"l62":{"repair_callback_required":false,"sd_count":0,"sd_ids":[]},"l63":{"recovery_action_requires_drill":false,"recovery_drill_ids":[]},"actions":{"would_bead":false,"would_l61":false,"would_no_bead_reason":"closed_heartbeat","receipt_required":false}}
{"schema_version":"fleet-coherence-event/v2","id":"fixture-suppressed-warning","ts":"2026-05-07T00:01:00Z","class":"fleet_coherence_demo_warning","severity":"warning","state":"open","session":"flywheel","pane":3,"suppression_id":"suppression-demo-1","dedupe_key":"demo-warning","raw_source_refs":["fixture:warning"],"evidence":{"source_quality":{"ntm_health_activity_authoritative":true}},"l61":{"ntm_attempted":true,"agent_mail_attempted":true,"l61_pairing_status":"paired","degraded_reason":null},"l62":{"repair_callback_required":false,"sd_count":0,"sd_ids":[]},"l63":{"recovery_action_requires_drill":false,"recovery_drill_ids":[]},"actions":{"would_bead":false,"would_l61":false,"would_no_bead_reason":"suppressed_fixture_warning","receipt_required":false}}
{"schema_version":"fleet-coherence-event/v2","id":"fixture-closed-error","ts":"2026-05-07T00:02:00Z","class":"fleet_coherence_closed_error","severity":"error","state":"closed","session":"flywheel","pane":3,"raw_source_refs":["fixture:error"],"evidence":{"source_quality":{"ntm_health_activity_authoritative":true}},"l61":{"ntm_attempted":true,"agent_mail_attempted":true,"l61_pairing_status":"paired","degraded_reason":null},"l62":{"repair_callback_required":true,"sd_count":1,"sd_ids":["SD-fixture"]},"l63":{"recovery_action_requires_drill":true,"recovery_drill_ids":["drill-fixture"]},"actions":{"would_bead":true,"would_l61":false,"would_no_bead_reason":null,"receipt_required":true}}
JSONL
}

bash -n "$LIB"
bash -n "$BIN"

latest="$TMP/latest.json"
log="$TMP/fleet-coherence.jsonl"
cp "$FIXTURE" "$latest"
write_clean_log "$log"

run_status "$latest" "$log" >"$TMP/happy.json"
assert_jq "$TMP/happy.json" '.status == "ok"' "happy path status"
assert_jq "$TMP/happy.json" '.cached_only == true' "cached_only marker"
assert_jq "$TMP/happy.json" '.detector_heartbeat_age_seconds == 600' "heartbeat age"
assert_jq "$TMP/happy.json" '.severity_counts.info == 1 and .severity_counts.warning == 1 and .severity_counts.error == 1' "severity counts"
assert_jq "$TMP/happy.json" '.compliance_summary.l60.present == 3 and .compliance_summary.l61.present == 3 and .compliance_summary.l62.present == 3 and .compliance_summary.l63.present == 3 and .compliance_summary.l65.present == 3' "L60-L65 compliance counts"
assert_jq "$TMP/happy.json" '.active_suppressions | length >= 1' "active suppression visible"

stale="$TMP/stale.json"
jq '.generated_at = "2026-05-06T22:00:00Z" | .latest_event.ts = "2026-05-06T22:00:00Z"' "$FIXTURE" >"$stale"
touch -t 202605062200 "$stale"
if run_status "$stale" "$log" >"$TMP/stale-out.json" 2>"$TMP/stale-err.txt"; then
    fail "stale latest should exit nonzero"
fi
assert_jq "$TMP/stale-out.json" '.status == "stale" and .reason == "detector_heartbeat_stale"' "stale status"

error_log="$TMP/open-error.jsonl"
write_clean_log "$error_log"
printf '%s\n' '{"schema_version":"fleet-coherence-event/v2","id":"fixture-open-error","ts":"2026-05-07T00:03:00Z","class":"fleet_coherence_open_error","severity":"error","state":"open","session":"flywheel","pane":3,"raw_source_refs":["fixture:open-error"],"evidence":{"source_quality":{"ntm_health_activity_authoritative":true}},"l61":{"ntm_attempted":true,"agent_mail_attempted":true,"l61_pairing_status":"paired","degraded_reason":null},"l62":{"repair_callback_required":true,"sd_count":1,"sd_ids":["SD-open"]},"l63":{"recovery_action_requires_drill":true,"recovery_drill_ids":["drill-open"]},"actions":{"would_bead":true,"would_l61":false,"would_no_bead_reason":null,"receipt_required":true}}' >>"$error_log"
if run_status "$latest" "$error_log" >"$TMP/open-error-out.json" 2>"$TMP/open-error-err.txt"; then
    fail "open error row should exit nonzero"
fi
assert_jq "$TMP/open-error-out.json" '.status == "error" and .reason == "open_error_rows" and (.open_error_rows | length == 1)' "open error row handling"

empty_log="$TMP/empty.jsonl"
: >"$empty_log"
run_status "$latest" "$empty_log" >"$TMP/empty-log.json"
assert_jq "$TMP/empty-log.json" '.status == "ok" and .severity_counts == {}' "empty log ok with empty severity counts"

malformed="$TMP/malformed.json"
printf '{not-json\n' >"$malformed"
if run_status "$malformed" "$empty_log" >"$TMP/malformed-out.json" 2>"$TMP/malformed-err.txt"; then
    fail "malformed latest should exit nonzero"
fi
assert_jq "$TMP/malformed-out.json" '.status == "error" and .reason == "latest_unparseable"' "malformed latest handling"

p95_ms="$(
    python3 - "$BIN" "$latest" "$empty_log" "$NOW_EPOCH" <<'PY'
import subprocess
import sys
import time

bin_path, latest, log_path, now_epoch = sys.argv[1:5]
durations = []
for _ in range(20):
    start = time.perf_counter()
    subprocess.run(
        [bin_path, "drift-status", "--json", "--latest", latest, "--log", log_path, "--now-epoch", now_epoch],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    durations.append((time.perf_counter() - start) * 1000)
durations.sort()
idx = max(int(len(durations) * 0.95) - 1, 0)
print(int(durations[idx]))
PY
)"

[[ "$p95_ms" =~ ^[0-9]+$ ]] || fail "p95 measurement was not numeric"
if [[ "$p95_ms" -ge 2000 ]]; then
    fail "p95 too slow: ${p95_ms}ms"
fi

printf 'PASS fleet-coherence-status P95_MS=%s\n' "$p95_ms"
