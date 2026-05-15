#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/fleet-refill-signal.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/fleet-refill-signal.XXXXXX")"
TMP_REAL="$(cd "$TMP" && pwd -P)"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || cat "$file" >&2
  fi
}

write_config() {
  local local_ready="$1"
  local peer_ready="$2"
  cat >"$TMP/fleet.json" <<JSON
{
  "repos": [
    {
      "repo": "$TMP/flywheel",
      "session": "flywheel",
      "ready_file": "$local_ready",
      "opted_in": true
    },
    {
      "repo": "$TMP/mobile-eats",
      "session": "mobile-eats",
      "ready_file": "$peer_ready",
      "opted_in": true
    }
  ]
}
JSON
}

mkdir -p "$TMP/flywheel" "$TMP/mobile-eats"

if bash -n "$SCRIPT"; then
  pass "script syntax"
else
  fail "script syntax"
fi
rg -n "ntm assign|ntm send|send-text|raw_tokens_included.: true" "$SCRIPT" >/tmp/fleet-refill-signal-forbidden.$$ 2>/dev/null || true
if [[ -s /tmp/fleet-refill-signal-forbidden.$$ ]]; then
  cat /tmp/fleet-refill-signal-forbidden.$$ >&2
  rm -f /tmp/fleet-refill-signal-forbidden.$$
  fail "script does not contain direct peer dispatch surfaces"
else
  rm -f /tmp/fleet-refill-signal-forbidden.$$
  pass "script does not contain direct peer dispatch surfaces"
fi

# Fixture 1: local ready work exists. The refill decision remains local and no
# cross-orch signal is written.
printf '%s\n' '{"issues":[{"id":"flywheel-local","status":"open","priority":0}]}' >"$TMP/local-ready.json"
printf '%s\n' '{"issues":[{"id":"mobile-peer","status":"open","priority":0}]}' >"$TMP/peer-ready.json"
write_config "$TMP/local-ready.json" "$TMP/peer-ready.json"
"$SCRIPT" \
  --local-repo "$TMP/flywheel" \
  --local-session flywheel \
  --fleet-config "$TMP/fleet.json" \
  --ledger "$TMP/coord-local.jsonl" \
  --now 2026-05-15T04:00:00Z \
  --local-idle-capacity \
  --apply \
  --json >"$TMP/local.out"
assert_jq "$TMP/local.out" '.decision == "local_ready_dispatch_remains_local" and .local_idle_capacity == true and .local_ready_count == 1 and .candidate_signal == null and .ledger_written == false and .direct_dispatch_attempted == false' "local-ready dispatch remains local"
if [[ ! -s "$TMP/coord-local.jsonl" ]]; then
  pass "local-ready writes no peer signal"
else
  fail "local-ready writes no peer signal"
fi

# Fixture 2: local ready is empty and a peer repo has ready work. The helper
# writes only a cross-orch coordination row for the repo-owning orchestrator.
printf '%s\n' '{"issues":[]}' >"$TMP/local-empty.json"
printf '%s\n' '{"issues":[{"id":"mobile-p0","status":"open","priority":0},{"id":"mobile-p2","status":"open","priority":2}]}' >"$TMP/peer-ready-2.json"
write_config "$TMP/local-empty.json" "$TMP/peer-ready-2.json"
"$SCRIPT" \
  --local-repo "$TMP/flywheel" \
  --local-session flywheel \
  --fleet-config "$TMP/fleet.json" \
  --ledger "$TMP/coord-peer.jsonl" \
  --source-probe "fixture-probe" \
  --now 2026-05-15T04:01:00Z \
  --local-idle-capacity \
  --apply \
  --json >"$TMP/peer.out"
assert_jq "$TMP/peer.out" '.decision == "peer_ready_signal_only" and .local_idle_capacity == true and .local_ready_count == 0 and .candidate_signal.target_repo == "'"$TMP_REAL"'/mobile-eats" and .candidate_signal.target_session == "mobile-eats" and .candidate_signal.top_bead_id == "mobile-p0" and .candidate_signal.ready_count == 2 and .candidate_signal.source_probe == "fixture-probe" and .candidate_signal.direct_dispatch == false and .candidate_signal.raw_tokens_included == false and .ledger_written == true and .direct_dispatch_attempted == false' "peer-ready creates signal only"
assert_jq "$TMP/coord-peer.jsonl" 'select(.event == "fleet_refill_peer_ready_signal" and .target_repo == "'"$TMP_REAL"'/mobile-eats" and .target_session == "mobile-eats" and .top_bead_id == "mobile-p0" and .ready_count == 2 and .source_probe == "fixture-probe" and .raw_tokens_included == false and .direct_dispatch == false)' "peer-ready ledger row"

# Fixture 3: no local or peer ready work. Nothing is written.
printf '%s\n' '{"issues":[]}' >"$TMP/peer-empty.json"
write_config "$TMP/local-empty.json" "$TMP/peer-empty.json"
"$SCRIPT" \
  --local-repo "$TMP/flywheel" \
  --local-session flywheel \
  --fleet-config "$TMP/fleet.json" \
  --ledger "$TMP/coord-empty.jsonl" \
  --now 2026-05-15T04:02:00Z \
  --local-idle-capacity \
  --apply \
  --json >"$TMP/empty.out"
assert_jq "$TMP/empty.out" '.decision == "no_signal" and .reason == "no_peer_ready_work" and .candidate_signal == null and .ledger_written == false and .direct_dispatch_attempted == false' "no-ready creates no signal"
if [[ ! -s "$TMP/coord-empty.jsonl" ]]; then
  pass "no-ready writes no ledger"
else
  fail "no-ready writes no ledger"
fi

# Fixture 4: peer ready exists, but local idle capacity has not been proven.
# The helper must refuse to signal.
write_config "$TMP/local-empty.json" "$TMP/peer-ready-2.json"
"$SCRIPT" \
  --local-repo "$TMP/flywheel" \
  --local-session flywheel \
  --fleet-config "$TMP/fleet.json" \
  --ledger "$TMP/coord-no-capacity.jsonl" \
  --now 2026-05-15T04:03:00Z \
  --apply \
  --json >"$TMP/no-capacity.out"
assert_jq "$TMP/no-capacity.out" '.decision == "no_signal" and .reason == "no_local_idle_capacity" and .local_idle_capacity == false and .candidate_signal == null and .ledger_written == false' "no idle capacity creates no peer signal"
if [[ ! -s "$TMP/coord-no-capacity.jsonl" ]]; then
  pass "no idle capacity writes no ledger"
else
  fail "no idle capacity writes no ledger"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
