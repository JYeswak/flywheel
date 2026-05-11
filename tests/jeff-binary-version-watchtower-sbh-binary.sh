#!/usr/bin/env bash
# tests/jeff-binary-version-watchtower-sbh-binary.sh
#
# Regression test for flywheel-90k49.3: sbh canonical-binary version probe
# + upstream release watch. The watch:
#   1. probes `sbh --version` (or SBH_VERSION_FIXTURE)
#   2. fetches `gh api repos/Dicklesworthstone/storage_ballast_helper/releases/latest`
#      (or SBH_RELEASE_FIXTURE)
#   3. emits a row with status not_installed | ok | stale | ahead | unknown
#   4. wires into canonical rows[] when installed; stays out of rows[] when not
#   5. surfaces drift in stale[] when behind
#
# Uses two fixtures (SBH_VERSION_FIXTURE, SBH_RELEASE_FIXTURE) for deterministic
# state without depending on real sbh install or gh availability.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeff-binary-version-watchtower.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMP="$(mktemp -d -t sbh-binary-watch.XXXXXX)"

# Test 1: syntax ok
if bash -n "$SCRIPT" 2>/dev/null; then
  pass "syntax"
else
  fail "syntax"
fi

# Test 2: sbh_binary_version_watch function defined + wired
if grep -q 'sbh_binary_version_watch()' "$SCRIPT"; then
  pass "sbh_binary_version_watch function defined"
else
  fail "sbh_binary_version_watch function missing"
fi
if grep -q 'sbh_binary_watch=' "$SCRIPT"; then
  pass "sbh_binary_version_watch wired into main result"
else
  fail "sbh_binary_version_watch not wired"
fi

# Test 3: live probe (no fixture) — sbh NOT installed → status=not_installed
out="$TMP/probe-live.json"
if timeout 30 "$SCRIPT" --dry-run --json >"$out" 2>"$TMP/probe-live.err"; then
  status=$(jq -r '.watchlists.sbh_binary_release.status' "$out")
  cmd=$(jq -r '.watchlists.sbh_binary_release.recommended_command' "$out")
  if [[ "$status" == "not_installed" ]]; then
    pass "live probe: sbh status=not_installed (no fixture, no sbh on PATH)"
  else
    fail "live probe: expected status=not_installed, got status=$status"
  fi
  if [[ "$cmd" == "brew tap Dicklesworthstone/sbh && brew install sbh" ]]; then
    pass "live probe: recommended_command points to brew tap+install"
  else
    fail "live probe: unexpected recommended_command: $cmd"
  fi
  # canonical_binary_count stays 1 when sbh not installed (only ntm counts)
  cnt=$(jq -r '.canonical_binary_count' "$out")
  if [[ "$cnt" == "1" ]]; then
    pass "live probe: canonical_binary_count=1 (sbh excluded while not_installed)"
  else
    fail "live probe: canonical_binary_count=$cnt (expected 1)"
  fi
else
  fail "live probe failed to run"
fi

# Test 4: fixture-driven CURRENT state (installed == latest)
cat >"$TMP/version-current.txt" <<'EOF'
sbh 0.4.6
EOF
cat >"$TMP/release-current.json" <<'EOF'
{"tag_name":"v0.4.6","name":"v0.4.6"}
EOF
out="$TMP/probe-current.json"
SBH_VERSION_FIXTURE="$TMP/version-current.txt" \
  SBH_RELEASE_FIXTURE="$TMP/release-current.json" \
  timeout 30 "$SCRIPT" --dry-run --json >"$out" 2>"$TMP/probe-current.err"
status=$(jq -r '.watchlists.sbh_binary_release.status' "$out")
relation=$(jq -r '.watchlists.sbh_binary_release.relation' "$out")
if [[ "$status" == "ok" && "$relation" == "current" ]]; then
  pass "fixture CURRENT: status=ok relation=current (installed==latest)"
else
  fail "fixture CURRENT: status=$status relation=$relation (expected ok/current)"
fi

# Test 5: fixture-driven BEHIND state (installed < latest)
cat >"$TMP/version-behind.txt" <<'EOF'
sbh 0.4.5
EOF
cat >"$TMP/release-behind.json" <<'EOF'
{"tag_name":"v0.4.6","name":"v0.4.6"}
EOF
out="$TMP/probe-behind.json"
SBH_VERSION_FIXTURE="$TMP/version-behind.txt" \
  SBH_RELEASE_FIXTURE="$TMP/release-behind.json" \
  timeout 30 "$SCRIPT" --dry-run --json >"$out" 2>"$TMP/probe-behind.err"
status=$(jq -r '.watchlists.sbh_binary_release.status' "$out")
relation=$(jq -r '.watchlists.sbh_binary_release.relation' "$out")
cmd=$(jq -r '.watchlists.sbh_binary_release.recommended_command' "$out")
stale_count=$(jq -r '.stale_count' "$out")
priority=$(jq -r '.highest_priority' "$out")
canonical=$(jq -r '.canonical_binary_count' "$out")
if [[ "$status" == "stale" && "$relation" == "behind" && "$cmd" == "brew upgrade sbh" && "$stale_count" == "1" && "$priority" == "P1" && "$canonical" == "2" ]]; then
  pass "fixture BEHIND: status=stale, relation=behind, recommended=brew-upgrade, stale_count=1, P1, canonical=2"
else
  fail "fixture BEHIND: status=$status relation=$relation cmd=$cmd stale=$stale_count priority=$priority canonical=$canonical"
fi
# Also check stale[] contains the sbh row
if jq -e '.stale[] | select(.name == "sbh")' "$out" >/dev/null; then
  pass "fixture BEHIND: stale[] contains sbh row"
else
  fail "fixture BEHIND: stale[] missing sbh row"
fi

# Test 6: rows[] contains sbh when installed (regardless of state)
if jq -e '.rows[] | select(.name == "sbh" and .source_bead == "flywheel-90k49.3")' "$out" >/dev/null; then
  pass "fixture BEHIND: rows[] contains sbh with source_bead=flywheel-90k49.3"
else
  fail "fixture BEHIND: rows[] missing sbh"
fi

# Test 7: latest_source field documents the upstream probe (gh api releases)
src=$(jq -r '.watchlists.sbh_binary_release.row.latest_source' "$out")
if [[ "$src" == "gh api releases/latest" ]]; then
  pass "fixture BEHIND: latest_source documents gh api releases/latest"
else
  fail "fixture BEHIND: latest_source=$src"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
