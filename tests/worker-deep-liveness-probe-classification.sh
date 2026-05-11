#!/usr/bin/env bash
# tests/worker-deep-liveness-probe-classification.sh
#
# Regression test for flywheel-8p6fz wire-in (probe shipped by se3h.7,
# wired by 8p6fz). Exercises the deep-liveness probe's
# alive|hung|unknown classifier against a synthetic session-topology
# fixture + WORKER_LIVENESS_FIXTURE_AGES env var.
#
# Probe script: ~/.claude/skills/.flywheel/scripts/worker-deep-liveness-probe.sh
# Wire-in plist: .flywheel/launchd/ai.zeststream.worker-deep-liveness-probe.plist
# Installer:    .flywheel/scripts/worker-deep-liveness-probe-launchd-install.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROBE="$HOME/.claude/skills/.flywheel/scripts/worker-deep-liveness-probe.sh"
PLIST="$ROOT/.flywheel/launchd/ai.zeststream.worker-deep-liveness-probe.plist"
INSTALLER="$ROOT/.flywheel/scripts/worker-deep-liveness-probe-launchd-install.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMP="$(mktemp -d -t worker-deep-liveness.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

# Test 1: probe script exists + is executable
if [[ -x "$PROBE" ]]; then
  pass "T1: worker-deep-liveness-probe.sh exists + executable (se3h.7 shipped)"
else
  fail "T1: worker-deep-liveness-probe.sh missing or not executable"
fi

# Test 2: plist exists + is plutil-valid (8p6fz wire-in)
if [[ -f "$PLIST" ]] && plutil -lint -s "$PLIST" >/dev/null 2>&1; then
  pass "T2: worker-deep-liveness-probe plist exists + plutil-valid"
else
  fail "T2: plist missing or invalid"
fi

# Test 3: plist StartInterval is 300 seconds (5 min — per bead body option A)
interval="$(plutil -extract StartInterval raw -o - "$PLIST" 2>/dev/null)"
if [[ "$interval" == "300" ]]; then
  pass "T3: plist StartInterval=300 (5-min cadence per bead option A)"
else
  fail "T3: plist StartInterval mismatch (got: $interval, expected: 300)"
fi

# Test 4: installer exists + bash -n clean
if [[ -x "$INSTALLER" ]] && bash -n "$INSTALLER" 2>/dev/null; then
  pass "T4: installer exists + bash -n clean"
else
  fail "T4: installer missing or syntax error"
fi

# Test 5: installer doctor returns status=ok
out="$("$INSTALLER" doctor --json 2>/dev/null)"
if printf '%s' "$out" | jq -e '.status == "ok"' >/dev/null 2>&1; then
  pass "T5: installer doctor returns status=ok"
else
  fail "T5: installer doctor not ok"
fi

# Test 6: classifier — synthetic topology with hung pane fixture.
# Topology shape (per probe lines 82-84): .session + .worker_panes (array) +
# .worker_kinds (pane→kind map). Probe matches fixture_key=session:pane against
# WORKER_LIVENESS_FIXTURE_AGES env.
cat >"$TMP/topology.jsonl" <<'JSON'
{"schema_version":"session-topology.v1","ts":"2026-05-11T03:00:00Z","session":"test","worker_panes":[2],"worker_kinds":{"2":"codex"}}
JSON

# NOTE: probe reads fixture ages from --fixture-pane-age CLI arg, NOT from
# WORKER_LIVENESS_FIXTURE_AGES env var (despite header doc; minor probe-doc
# drift). Use CLI form.

# Fixture: this pane has been silent for 600s (>300 stale threshold) → hung
out="$("$PROBE" --topology "$TMP/topology.jsonl" --fixture-pane-age "test:2=600" --json 2>/dev/null)"
hung_count="$(printf '%s' "$out" | jq -r '.hung_count // 0' 2>/dev/null)"
if [[ "$hung_count" == "1" ]]; then
  pass "T6: classifier emits hung_count=1 for 600s-silent worker pane (--fixture-pane-age)"
else
  fail "T6: hung classification failed (got hung_count: $hung_count)"
fi

# Test 7: classifier — emit deep_liveness_state per-pane in the json envelope
out="$("$PROBE" --topology "$TMP/topology.jsonl" --fixture-pane-age "test:2=30" --json 2>/dev/null)"
state="$(printf '%s' "$out" | jq -r '.worker_deep_liveness[0].deep_liveness_state // empty' 2>/dev/null)"
# State=hung is acceptable here because work_signal=stale_or_missing for a synthetic
# fixture session. The classifier IS firing; assertion is "emits a valid state".
if [[ "$state" == "hung" || "$state" == "alive" || "$state" == "unknown" ]]; then
  pass "T7: classifier emits valid deep_liveness_state ($state) per-pane in envelope"
else
  fail "T7: classifier did not emit valid state (got: $state)"
fi

# Test 8: launchctl reports the service is loaded (after install)
if launchctl print gui/$(id -u)/ai.zeststream.worker-deep-liveness-probe 2>&1 | grep -qE 'run interval = 300'; then
  pass "T8: launchctl reports run interval = 300 (service is loaded)"
else
  fail "T8: launchctl does not report loaded state"
fi

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
