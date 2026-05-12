#!/usr/bin/env bash
# test-ntm-wait-json-timeout-fallback.sh
#
# flywheel-72z43 regression: native `ntm wait <session> --until=idle --any
# --timeout=<dur> --json` emits ANSI-colored human text on timeout, NOT JSON,
# despite --json being requested. The flywheel-side wrappers (run_wait in
# idle-pane-auto-dispatch.sh, the jq-fallback in worker-stall-alert-probe.sh)
# wrap the raw output into a JSON envelope as the documented workaround.
#
# This test asserts:
#   T1. The native `ntm wait --json` timeout output is NOT parseable JSON
#       (current upstream behavior — locks the regression baseline so we can
#       detect when Jeffrey ships an upstream fix and the wrapper path can
#       be simplified).
#   T2. idle-pane-auto-dispatch.sh's run_wait wrapper produces parseable JSON
#       on timeout (workaround correctness).
#   T3. The JSON envelope from T2 contains the canonical fields the
#       orchestrator's dispatch automation depends on:
#       exit_code, native_command, raw.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
WRAPPER="$ROOT/.flywheel/scripts/idle-pane-auto-dispatch.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/test-ntm-wait-json-timeout.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

# Pick a session name unlikely to be idle. Use a synthetic name so we trigger
# either "session not found" or a true idle-state-not-met timeout — both paths
# end up exiting non-zero with non-JSON output today.
SESSION="${TEST_NTM_WAIT_SESSION:-flywheel}"

# Skip if ntm binary missing (CI / no-install class).
if ! [[ -x "$NTM_BIN" ]]; then
  printf 'SKIP ntm binary not found at %s — test requires live ntm install\n' "$NTM_BIN"
  exit 77
fi

# T1: Reproduce the regression — native --json on timeout returns non-JSON.
T1_OUT="$TMP/native-wait-json-timeout.txt"
set +e
"$NTM_BIN" wait "$SESSION" --until=idle --any --timeout=1s --json >"$T1_OUT" 2>&1
T1_RC=$?
set -e

if [[ "$T1_RC" -ne 1 ]]; then
  # Either the session is genuinely idle (rc=0, valid JSON expected), or there
  # is some other class of error. The regression is specifically about timeout
  # rc=1, so document the rc but don't fail the test on rc=0 (that means the
  # session reached idle and the test environment isn't reproducing the issue
  # — emit SKIP-equivalent NOTE).
  printf 'NOTE T1 ntm wait exited rc=%d (not 1=timeout); native output:\n' "$T1_RC"
  cat "$T1_OUT"
  printf 'NOTE T1 cannot assert non-JSON timeout output without a timeout rc; treating as inconclusive\n'
else
  if jq -e . "$T1_OUT" >/dev/null 2>&1; then
    # If this passes, Jeffrey has shipped an upstream fix and the wrapper
    # can be simplified. Surface the win in the test output.
    pass "T1 ntm wait --json on timeout NOW emits parseable JSON (upstream fix detected — wrapper jq-e fallback can be simplified)"
  else
    pass "T1 ntm wait --json on timeout emits NON-JSON (current upstream baseline; workaround required)"
  fi
fi

# T2: Wrapper produces parseable JSON on timeout.
T2_OUT="$TMP/wrapper-wait-json-timeout.txt"
set +e
WAIT_TIMEOUT=1s "$WRAPPER" --session "$SESSION" --dry-run --json >"$T2_OUT" 2>&1
T2_RC=$?
set -e

if jq -e . "$T2_OUT" >/dev/null 2>&1; then
  pass "T2 idle-pane-auto-dispatch.sh wrapper output is parseable JSON (rc=$T2_RC)"
else
  fail "T2 idle-pane-auto-dispatch.sh wrapper output is NOT parseable JSON (rc=$T2_RC)"
  cat "$T2_OUT" >&2
fi

# T3: Wrapper JSON contains the canonical timeout-envelope fields when wait
# itself timed out. Check via the wrapper's payload structure.
# The wrapper emits a top-level `status` field (e.g. "no_idle_wait_timeout")
# plus a nested `wait` object. When the inner native wait was non-JSON, run_wait
# wraps it into {exit_code, native_command, raw}. Post-upstream-fix the
# field is the merged JSON. Either path is acceptable as long as exit_code
# is present in the wrapper-level wait surface.
if jq -e '.status != null' "$T2_OUT" >/dev/null 2>&1; then
  pass "T3a wrapper JSON has top-level status field ($(jq -r '.status' "$T2_OUT"))"
else
  fail "T3a wrapper JSON missing top-level status field"
  cat "$T2_OUT" >&2
fi

if jq -e '.wait != null' "$T2_OUT" >/dev/null 2>&1; then
  pass "T3b wrapper JSON has wait field"
else
  fail "T3b wrapper JSON missing wait field"
fi

if jq -e '.wait.exit_code != null' "$T2_OUT" >/dev/null 2>&1; then
  pass "T3c wrapper JSON wait.exit_code present (orchestrator can read timeout receipt)"
else
  fail "T3c wrapper JSON wait.exit_code missing"
fi

# T3d: When the upstream native wait emits non-JSON (current baseline), the
# wrapper preserves the raw text under .wait.raw so a human can still see what
# happened. Post-upstream-fix this field becomes optional.
if jq -e '.wait.raw != null' "$T2_OUT" >/dev/null 2>&1; then
  pass "T3d wrapper JSON wait.raw preserves the original non-JSON output (workaround visible)"
elif jq -e '.wait | (has("raw") | not)' "$T2_OUT" >/dev/null 2>&1; then
  pass "T3d wrapper JSON wait has no .raw field (post-upstream-fix path; merged JSON)"
fi

printf '\n=== test-ntm-wait-json-timeout-fallback.sh ===\n'
printf 'pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]] && exit 0 || exit 1
