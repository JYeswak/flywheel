#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BIN="$ROOT/.flywheel/scripts/caam-recovery-path-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/caam-recovery-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
pass=0

fail(){ printf 'FAIL %s\n' "$1" >&2; exit 1; }
ok(){ printf 'PASS %s\n' "$1"; pass=$((pass+1)); }
assert_jq(){ jq -e "$2" "$1" >/dev/null || { jq . "$1" >&2 || true; fail "$3"; }; ok "$3"; }

write_profiles(){
  cat >"$1" <<'JSON'
{"profiles":[
  {"tool":"claude","name":"a","health":{"status":"critical"}},
  {"tool":"claude","name":"b","health":{"status":"warning"}},
  {"tool":"claude","name":"c","health":{"status":"healthy"}}
]}
JSON
}

bash -n "$BIN" && ok "script syntax"
"$BIN" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name=="caam-recovery-path-probe.sh" and (.verbs|index("--quiet"))' "info json"
"$BIN" --examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '(.examples|length) >= 3' "examples json"

mkdir -p "$TMP/plists" "$TMP/logs"
for label in com.caam.daemon com.caam.auth-agent com.caam.auth-coordinator; do
  : >"$TMP/plists/$label.plist"
done
printf '1\t0\tcom.caam.daemon\n2\t0\tcom.caam.auth-agent\n3\t0\tcom.caam.auth-coordinator\n' >"$TMP/launchctl.txt"
write_profiles "$TMP/profiles.json"

CAAM_PROBE_NOW=2026-05-06T16:00:00Z \
CAAM_PROBE_LAUNCH_AGENTS_DIR="$TMP/plists" \
CAAM_PROBE_LAUNCHCTL_LIST="$TMP/launchctl.txt" \
CAAM_PROBE_CAAM_LS_JSON="$TMP/profiles.json" \
CAAM_PROBE_LOG_DIRS="$TMP/no-logs" \
"$BIN" --json >"$TMP/missing-log.json"
assert_jq "$TMP/missing-log.json" '.verdict=="rotation_path_unverified" and .rotation_log_path==null and .profiles_total==3 and .profiles_expired==1 and .profiles_ok==1' "missing rotation log"

mkdir -p "$TMP/empty"
: >"$TMP/empty-launchctl.txt"
CAAM_PROBE_NOW=2026-05-06T16:00:00Z \
CAAM_PROBE_LAUNCH_AGENTS_DIR="$TMP/empty" \
CAAM_PROBE_LAUNCHCTL_LIST="$TMP/empty-launchctl.txt" \
CAAM_PROBE_CAAM_LS_JSON="$TMP/profiles.json" \
CAAM_PROBE_LOG_DIRS="$TMP/no-logs" \
"$BIN" --json >"$TMP/missing-plists.json"
assert_jq "$TMP/missing-plists.json" '.caam_plists_loaded_count==0 and .verdict=="rotation_path_unverified"' "missing plists graceful"

cat >"$TMP/logs/auth-coordinator.log" <<'LOG'
time=2026-05-06T15:00:00Z level=WARN msg="Anthropic 429 rate limit detected"
LOG
CAAM_PROBE_NOW=2026-05-06T16:00:00Z \
CAAM_PROBE_LAUNCH_AGENTS_DIR="$TMP/plists" \
CAAM_PROBE_LAUNCHCTL_LIST="$TMP/launchctl.txt" \
CAAM_PROBE_CAAM_LS_JSON="$TMP/profiles.json" \
CAAM_PROBE_LOG_DIRS="$TMP/logs" \
"$BIN" --json >"$TMP/broken.json"
assert_jq "$TMP/broken.json" '.verdict=="rotation_path_broken" and .auto_rotation_health_score==0 and .rotation_429_detections_last_24h==1 and .rotation_events_last_24h==0' "429 without rotation broken"

cat >"$TMP/logs/auth-coordinator.log" <<'LOG'
time=2026-05-06T15:00:00Z level=WARN msg="Anthropic 429 rate limit detected"
time=2026-05-06T15:00:01Z level=INFO msg="rotation event switching claude profile"
time=2026-05-06T15:00:02Z level=INFO msg="rotation success switched profile"
LOG
CAAM_PROBE_NOW=2026-05-06T16:00:00Z \
CAAM_PROBE_LAUNCH_AGENTS_DIR="$TMP/plists" \
CAAM_PROBE_LAUNCHCTL_LIST="$TMP/launchctl.txt" \
CAAM_PROBE_CAAM_LS_JSON="$TMP/profiles.json" \
CAAM_PROBE_LOG_DIRS="$TMP/logs" \
"$BIN" --json >"$TMP/healthy.json"
assert_jq "$TMP/healthy.json" '.verdict=="rotation_path_healthy" and .auto_rotation_health_score==1 and .rotation_success_last_24h==1' "healthy rotation"

"$BIN" --quiet >/tmp/caam-probe-quiet.out && ok "quiet verb"
printf 'OK caam_recovery_path_probe cases=%s\n' "$pass"
