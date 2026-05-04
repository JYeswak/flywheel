#!/usr/bin/env bash
# Synthetic L57 loop-driver doctor verdict test. Does not touch launchctl state.
set -euo pipefail

FLYWHEEL_LOOP_BIN="${FLYWHEEL_LOOP_BIN:-/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="${TMPDIR:-/tmp}/flywheel-loop-driver-doctor.$$"
LOOPS="$TMP/loops"
LAUNCH_AGENTS="$TMP/LaunchAgents"
LOGS="$TMP/logs"
LAUNCHCTL_LIST="$TMP/launchctl-list.txt"

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

mkdir -p "$LOOPS" "$LAUNCH_AGENTS" "$LOGS"

ts_now() { date -u +%Y-%m-%dT%H:%M:%SZ; }
ts_old() {
  python3 - <<'PY'
from datetime import datetime, timedelta, timezone
print((datetime.now(timezone.utc) - timedelta(hours=3)).strftime("%Y-%m-%dT%H:%M:%SZ"))
PY
}

seed_repo() {
  local name="$1" repo
  repo="$TMP/repos/$name"
  mkdir -p "$repo"
  git -C "$repo" init -q
  cat >"$repo/README.md" <<EOF
# $name

Mission: exercise loop driver doctor fixtures.
Goal: produce deterministic loop driver verdicts.
State: synthetic only.
EOF
  cat >"$repo/Makefile" <<'EOF'
test:
	@true
EOF
  "$FLYWHEEL_LOOP_BIN" init --repo "$repo" --mission-source "$repo/README.md" --goal-source "$repo/README.md" --state-source "$repo/README.md" --json >/dev/null
  printf '%s\n' "$repo"
}

write_plist() {
  local project="$1" script="$2" interval="${3:-60}" plist
  plist="$LAUNCH_AGENTS/ai.zeststream.${project}-flywheel-loop.plist"
  cat >"$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>ai.zeststream.${project}-flywheel-loop</string>
  <key>ProgramArguments</key><array><string>/bin/bash</string><string>-lc</string><string>exec $script</string></array>
  <key>StartInterval</key><integer>$interval</integer>
</dict></plist>
EOF
}

write_tick_script() {
  local project="$1" script
  script="$TMP/${project}-flywheel-loop-tick"
  cat >"$script" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ntm send synthetic --pane=1 --file /tmp/synthetic-prompt --no-cass-check
EOF
  chmod +x "$script"
  printf '%s\n' "$script"
}

write_marker() {
  local project="$1" repo="$2" tier="$3" interval="$4" extra="${5:-}"
  cat >"$LOOPS/$project.json" <<EOF
{"project":"$project","repo":"$repo","tier":"$tier","interval":"$interval","active":true$extra}
EOF
}

doctor_json() {
  local repo="$1" out rc
  set +e
  out="$(
    FLYWHEEL_LOOP_MARKER_DIR="$LOOPS" \
    FLYWHEEL_LOOP_LAUNCH_AGENTS_DIR="$LAUNCH_AGENTS" \
    FLYWHEEL_LOOP_LOG_DIR="$LOGS" \
    FLYWHEEL_LOOP_LAUNCHCTL_LIST="$LAUNCHCTL_LIST" \
    FLYWHEEL_LOOP_MEM_CLI=/nonexistent/mem \
    FLYWHEEL_DOCTOR_NTM_HEALTH_DISABLED=1 \
    "$FLYWHEEL_LOOP_BIN" doctor --repo "$repo" --json 2>/dev/null
  )"
  rc=$?
  set -e
  printf '%s\n' "$out"
  return "$rc"
}

assert_case() {
  local label="$1" repo="$2" expected_driver="$3" expected_status="$4" expected_error="${5:-}" out rc driver status error_count
  set +e
  out="$(doctor_json "$repo")"
  rc=$?
  set -e
  driver="$(jq -r '.loop_driver.driver_status // empty' <<<"$out")"
  status="$(jq -r '.status // empty' <<<"$out")"
  if [[ "$driver" != "$expected_driver" ]]; then
    echo "FAIL $label: expected driver_status=$expected_driver got=$driver" >&2
    echo "$out" >&2
    exit 1
  fi
  if [[ "$status" != "$expected_status" ]]; then
    echo "FAIL $label: expected status=$expected_status got=$status" >&2
    echo "$out" >&2
    exit 1
  fi
  if [[ "$expected_status" == "fail" && "$rc" -eq 0 ]]; then
    echo "FAIL $label: expected non-zero doctor exit for fail status" >&2
    exit 1
  fi
  if [[ -n "$expected_error" ]]; then
    error_count="$(jq --arg code "$expected_error" '[.errors[]? | select(.code == $code)] | length' <<<"$out")"
    if [[ "$error_count" -lt 1 ]]; then
      echo "FAIL $label: missing error code $expected_error" >&2
      echo "$out" >&2
      exit 1
    fi
  fi
  echo "PASS $label driver_status=$driver status=$status"
}

verified_repo="$(seed_repo verified-proj)"
marker_only_repo="$(seed_repo marker-only-proj)"
stale_repo="$(seed_repo stale-proj)"
missing_repo="$(seed_repo missing-driver-proj)"

verified_script="$(write_tick_script verified-proj)"
stale_script="$(write_tick_script stale-proj)"
write_plist verified-proj "$verified_script" 60
write_plist stale-proj "$stale_script" 60

cat >"$LAUNCHCTL_LIST" <<EOF
PID	Status	Label
-	0	ai.zeststream.verified-proj-flywheel-loop
-	0	ai.zeststream.stale-proj-flywheel-loop
EOF

write_marker verified-proj "$verified_repo" active_high 60s
write_marker marker-only-proj "$marker_only_repo" active_normal 60s
write_marker stale-proj "$stale_repo" active_normal 60s
write_marker missing-driver-proj "$missing_repo" active_normal 60s ',"dispatch_mode":"launchd_prompt"'

printf '{"ts":"%s","event":"ntm_dispatch_sent"}\n' "$(ts_now)" >"$LOGS/verified-proj-flywheel-loop.jsonl"
printf '{"ts":"%s","event":"ntm_dispatch_sent"}\n' "$(ts_old)" >"$LOGS/stale-proj-flywheel-loop.jsonl"

assert_case VERIFIED "$verified_repo" VERIFIED ok
assert_case MARKER_ONLY "$marker_only_repo" MARKER_ONLY fail loop_driver_marker_only
assert_case STALE "$stale_repo" STALE warn
assert_case MISSING_DRIVER "$missing_repo" MISSING_DRIVER fail loop_driver_missing_driver

echo "PASS loop-driver doctor verdict taxonomy"
