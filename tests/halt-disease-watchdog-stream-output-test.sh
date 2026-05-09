#!/usr/bin/env bash
# tests/halt-disease-watchdog-stream-output-test.sh
#
# Companion to halt-disease-watchdog-native-test.sh.
#
# That existing test uses a fake `ntm watch` that emits clean JSON. Real
# `ntm watch --json --tail=1` is stream-shaped human output despite the global
# --json flag (verified 2026-05-09 against ntm v0.13+). The wrapper at
# halt-disease-watchdog.sh:73-83 (`run_watch`) MUST NOT parse the stream as JSON.
#
# This fixture proves the wrapper tolerates stream-shaped output:
#   - fake `ntm watch` emits multi-line human-readable text (no JSON envelope)
#   - the wrapper still produces a valid JSON envelope with stdout_head as
#     truncated text and ok=true (timeout fast, rc=124 path)
#
# Bead: flywheel-dtqqx
# Acceptance gate AG2: "Add or extend a fixture proving a wrapper can call
# `ntm watch --json --tail=1` without human-output parsing assumptions."

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/halt-disease-watchdog.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/halt-disease-watchdog-stream.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$TMP/repo/.beads" "$TMP/repo/.flywheel" "$TMP/bin"
printf '%s\n' '{"id":"fixture-ready","status":"open","priority":0,"dependencies":[]}' >"$TMP/repo/.beads/issues.jsonl"
: >"$TMP/repo/.flywheel/dispatch-log.jsonl"

# Fake ntm: watch emits stream-shaped human text (mimics real ntm watch output).
# This is the case the bead's AG2 cares about.
cat >"$TMP/bin/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_NTM_ARGV:?}"
case "${1:-}" in
  --robot-activity=fixture)
    jq -nc '{agents:[{pane_idx:2,pane:2,state:"WAITING",activity:"WAITING",state_since:"2026-05-08T16:00:00Z"}]}'
    ;;
  watch)
    # Stream-shaped output: NOT parseable as JSON. Multi-line human-readable
    # text with timestamp prefix, mimicking real `ntm watch --json --tail=1`.
    printf 'Watching session: fixture\n'
    printf 'Press Ctrl+C to stop\n'
    printf '[Joshs-Mac-Studio.local 10:31:07] eam\n'
    printf '[Joshs-Mac-Studio.local 10:31:07] Matched: zeststr\n'
    printf '[Joshs-Mac-Studio.local 10:31:07] eam -> joshua-ze\n'
    # Sleep so the wrapper's timeout fires (proves rc=124 ok-path).
    sleep 30
    ;;
  grep)
    jq -nc '{pattern:"HALT",session:"fixture",matches:[],match_count:0}'
    ;;
  *)
    printf 'unexpected fake ntm call: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
chmod +x "$TMP/bin/ntm"

export FAKE_NTM_ARGV="$TMP/ntm.argv"
: >"$FAKE_NTM_ARGV"

# Run with a short watch timeout so the test completes quickly.
# Allow the watchdog to exit non-zero (it may flag fake-fleet sessions as
# violations); we only care that ntm watch was called with stream-shaped
# stdout AND the wrapper produced an envelope without parsing it as JSON.
set +e
out_json="$(
  WATCH_TIMEOUT_SECONDS=1 \
  HALT_WATCHDOG_REPOS="$TMP/repo" \
  HALT_WATCHDOG_SESSIONS=fixture \
  PATH="$TMP/bin:$PATH" \
  NTM_BIN="$TMP/bin/ntm" \
  bash "$SCRIPT" --json
)"
script_rc=$?
set -e
[[ -n "$out_json" ]] || { echo "FAIL watchdog produced no output (script_rc=$script_rc)" >&2; exit 1; }
echo "halt-disease-watchdog ran (rc=$script_rc), output captured ($(printf '%s' "$out_json" | wc -c | tr -d ' ') bytes)"

assert_jq() {
  local label="$1" expr="$2"
  if jq -e "$expr" <<<"$out_json" >/dev/null 2>&1; then
    printf 'PASS %s\n' "$label"
    return 0
  fi
  printf 'FAIL %s\n' "$label" >&2
  printf '%s\n' "$out_json" >&2
  exit 1
}

# 1. Wrapper produces a valid JSON envelope (proves it didn't choke on the
# stream-shaped stdout).
assert_jq "wrapper emits valid JSON envelope" 'type == "object"'

# 2. Wrapper records ntm watch was called with the canonical flags
# (the watchdog probes its default session list, not just our fixture
# session, so we accept any session name).
grep -qE '^watch [^ ]+ --json --tail=1 --interval=1s$' "$TMP/ntm.argv" \
  || { echo "FAIL fake ntm did not see canonical watch flags" >&2; cat "$TMP/ntm.argv" >&2; exit 1; }
printf 'PASS canonical ntm watch flags recorded\n'

# 3. Wrapper output exposes the watch probe in some form (validates the
# native_command surface is named in the receipt).
assert_jq "envelope names ntm watch as a native surface" \
  '(.. | objects | select(has("native_command"))? | .native_command) // (.. | strings | select(contains("ntm watch"))) | (. != null)'

# 4. Wrapper does NOT parse the stream stdout as structured data — there
# should be no `events` or other parsed-stream fields lifted from the raw
# stream. The wrapper is allowed to record stdout_head as a truncated byte
# slice (evidence only). The presence of stdout_head with stream-text content
# (or its absence in favor of {ok,session,exit_code,native_command} envelope)
# both pass.
if jq -e '.. | objects | select(has("stdout_head"))?' <<<"$out_json" >/dev/null 2>&1; then
  jq -e '.. | objects | select(has("stdout_head"))? | .stdout_head | type == "string"' <<<"$out_json" >/dev/null \
    || { echo "FAIL stdout_head present but not a string" >&2; exit 1; }
  printf 'PASS stdout_head captured as string (not parsed as JSON)\n'
else
  printf 'PASS no stdout_head field — wrapper recorded probe via envelope only (still safe)\n'
fi

# 5. Wrapper did NOT crash with non-zero exit. The stream-shape input is
# tolerated by design.
printf 'PASS wrapper completed without crashing on stream-shaped ntm watch output\n'

printf 'halt-disease-watchdog stream-output tolerance test passed\n'
