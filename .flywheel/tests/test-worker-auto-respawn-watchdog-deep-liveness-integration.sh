#!/usr/bin/env bash
# test-worker-auto-respawn-watchdog-deep-liveness-integration.sh
#
# Regression test for flywheel-8p6fz.1: the watchdog now consults
# worker-deep-liveness-probe.sh as a pre-respawn signal source.
# Three cases exercised: HUNG (triggers respawn), ALIVE (no action),
# UNKNOWN (graceful, no action).
#
# Run: bash .flywheel/tests/test-worker-auto-respawn-watchdog-deep-liveness-integration.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WATCHDOG="$ROOT/scripts/worker-auto-respawn-watchdog.sh"

PASS=0; FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMP="$(mktemp -d -t watdl.XXXXXX)" || { echo "ERR: mktemp failed" >&2; exit 1; }
TOPOLOGY="$TMP/topology.jsonl"
ATTEMPTS="$TMP/attempts.jsonl"
FIXTURE="$TMP/dl-fixture.json"
NTM_FAKE="$TMP/ntm-fake"

# Single-pane topology used across all 3 cases.
printf '%s\n' '{"session":"flywheel","ts":"2026-05-11T00:00:00Z","effective_at":"2026-05-11T00:00:00Z","worker_panes":[2]}' > "$TOPOLOGY"
: > "$ATTEMPTS"

# Fake ntm: wait returns rc=1 (not dead). The deep-liveness signal alone must
# drive respawn decisions in this test.
cat > "$NTM_FAKE" <<'FAKEEOF'
#!/usr/bin/env bash
case "${1:-}" in
  wait) printf 'not dead\n' >&2; exit 1 ;;
  respawn) printf '{"status":"respawned"}\n'; exit 0 ;;
  *) printf 'unknown ntm subcmd: %s\n' "$1" >&2; exit 2 ;;
esac
FAKEEOF
chmod +x "$NTM_FAKE"

run_case() {
  local label="$1"; local fixture_json="$2"
  printf '%s' "$fixture_json" > "$FIXTURE"
  "$WATCHDOG" --dry-run --json \
    --topology "$TOPOLOGY" --attempts "$ATTEMPTS" \
    --ntm-bin "$NTM_FAKE" --deep-liveness-fixture "$FIXTURE" 2>/dev/null
}

# Case 1: hung — expect would_auto_respawn reason=deep_liveness_hung
out_hung="$(run_case hung '{"status":"worker_deep_liveness_failed","worker_deep_liveness":[{"session":"flywheel","pane":2,"deep_liveness_state":"hung","secs_since_output":300}],"hung_count":1,"unknown_count":0}')"
if jq -e '.results[0] | (.action == "would_auto_respawn" and .reason == "deep_liveness_hung" and .deep_liveness_state == "hung" and (.session == "flywheel") and (.pane == 2))' <<<"$out_hung" >/dev/null; then
  pass "01 hung triggers would_auto_respawn reason=deep_liveness_hung"
else
  fail "01 hung case: $(jq -c '.results[0]' <<<"$out_hung")"
fi

# Case 2: alive — expect action=none reason=not_dead
out_alive="$(run_case alive '{"status":"ok","worker_deep_liveness":[{"session":"flywheel","pane":2,"deep_liveness_state":"alive","secs_since_output":0}],"hung_count":0,"unknown_count":0}')"
if jq -e '.results[0] | (.action == "none" and .reason == "not_dead" and .deep_liveness_state == "alive")' <<<"$out_alive" >/dev/null; then
  pass "02 alive — no action; reason=not_dead"
else
  fail "02 alive case: $(jq -c '.results[0]' <<<"$out_alive")"
fi

# Case 3: unknown — pane absent from fixture; expect action=none reason=not_dead
out_unknown="$(run_case unknown '{"status":"ok","worker_deep_liveness":[],"hung_count":0,"unknown_count":0}')"
if jq -e '.results[0] | (.action == "none" and .reason == "not_dead" and .deep_liveness_state == "unknown")' <<<"$out_unknown" >/dev/null; then
  pass "03 unknown (probe has no entry for this pane) — no action; deep_liveness_state=unknown"
else
  fail "03 unknown case: $(jq -c '.results[0]' <<<"$out_unknown")"
fi

# Case 4: missing probe + missing fixture — graceful degradation
out_missing="$("$WATCHDOG" --dry-run --json \
  --topology "$TOPOLOGY" --attempts "$ATTEMPTS" \
  --ntm-bin "$NTM_FAKE" \
  --deep-liveness-probe "$TMP/no-such-probe.sh" 2>/dev/null)"
if jq -e '.results[0] | (.action == "none" and .reason == "not_dead" and .deep_liveness_state == "unknown")' <<<"$out_missing" >/dev/null; then
  pass "04 missing probe — graceful degradation; no action"
else
  fail "04 missing probe case: $(jq -c '.results[0]' <<<"$out_missing")"
fi

if [[ "$FAIL" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$PASS" "$FAIL" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$PASS"
