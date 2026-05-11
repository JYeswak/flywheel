#!/usr/bin/env bash
# tests/jeff-binary-version-watchtower-homebrew-sbh.sh
#
# Regression test for flywheel-90k49.1: homebrew-sbh Formula publication watch.
# The watch reads Dicklesworthstone/homebrew-sbh/Formula/ contents via gh API
# and emits status tap_initialized_no_formula | formula_published | unknown.
#
# Uses HOMEBREW_SBH_FORMULA_FIXTURE env var to override the gh probe so the
# test exercises both branches deterministically without depending on remote
# state or gh availability.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeff-binary-version-watchtower.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

TMP="$(mktemp -d -t homebrew-sbh-watch.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

# Fixture A: tap initialized, no formula published yet (current real state at 2026-05-11).
# Fixture matches the SHAPE the watch's gh-call returns, BUT fixture replaces the
# raw gh output AND the row envelope (jq -c .). So we provide the post-jq row.
cat >"$TMP/fixture-no-formula.json" <<'JSON'
{
  "repo": "Dicklesworthstone/homebrew-sbh",
  "url": "https://github.com/Dicklesworthstone/homebrew-sbh",
  "tap_name": "Dicklesworthstone/sbh",
  "formula_dir": "Formula",
  "rb_file_count": 0,
  "rb_files": [],
  "status": "tap_initialized_no_formula",
  "installation_recommended": false,
  "recommended_command": null,
  "sister_repo": "Dicklesworthstone/storage_ballast_helper",
  "parent_bead": "flywheel-90k49.1"
}
JSON

# Fixture B: formula published (post-trigger state).
cat >"$TMP/fixture-published.json" <<'JSON'
{
  "repo": "Dicklesworthstone/homebrew-sbh",
  "url": "https://github.com/Dicklesworthstone/homebrew-sbh",
  "tap_name": "Dicklesworthstone/sbh",
  "formula_dir": "Formula",
  "rb_file_count": 1,
  "rb_files": ["sbh.rb"],
  "status": "formula_published",
  "installation_recommended": true,
  "recommended_command": "brew tap Dicklesworthstone/sbh && brew install sbh",
  "sister_repo": "Dicklesworthstone/storage_ballast_helper",
  "parent_bead": "flywheel-90k49.1"
}
JSON

# Test 1: pre-trigger fixture → status tap_initialized_no_formula
out="$(HOMEBREW_SBH_FORMULA_FIXTURE="$TMP/fixture-no-formula.json" "$SCRIPT" run --json 2>/dev/null)"
status="$(printf '%s' "$out" | jq -r '.watchlists.homebrew_sbh_formula.status')"
if [[ "$status" == "tap_initialized_no_formula" ]]; then
  pass "T1: pre-trigger fixture emits status=tap_initialized_no_formula"
else
  fail "T1: pre-trigger fixture emits status=tap_initialized_no_formula (got: $status)"
fi

# Test 2: pre-trigger installation_recommended=false
install_rec="$(printf '%s' "$out" | jq -r '.watchlists.homebrew_sbh_formula.installation_recommended')"
if [[ "$install_rec" == "false" ]]; then
  pass "T2: pre-trigger installation_recommended=false"
else
  fail "T2: pre-trigger installation_recommended=false (got: $install_rec)"
fi

# Test 3: pre-trigger recommended_command is null
rec_cmd="$(printf '%s' "$out" | jq -r '.watchlists.homebrew_sbh_formula.recommended_command')"
if [[ "$rec_cmd" == "null" ]]; then
  pass "T3: pre-trigger recommended_command is null"
else
  fail "T3: pre-trigger recommended_command is null (got: $rec_cmd)"
fi

# Test 4: post-trigger fixture → status formula_published
out="$(HOMEBREW_SBH_FORMULA_FIXTURE="$TMP/fixture-published.json" "$SCRIPT" run --json 2>/dev/null)"
status="$(printf '%s' "$out" | jq -r '.watchlists.homebrew_sbh_formula.status')"
if [[ "$status" == "formula_published" ]]; then
  pass "T4: post-trigger fixture emits status=formula_published"
else
  fail "T4: post-trigger fixture emits status=formula_published (got: $status)"
fi

# Test 5: post-trigger installation_recommended=true
install_rec="$(printf '%s' "$out" | jq -r '.watchlists.homebrew_sbh_formula.installation_recommended')"
if [[ "$install_rec" == "true" ]]; then
  pass "T5: post-trigger installation_recommended=true"
else
  fail "T5: post-trigger installation_recommended=true (got: $install_rec)"
fi

# Test 6: post-trigger recommended_command points at canonical brew commands
rec_cmd="$(printf '%s' "$out" | jq -r '.watchlists.homebrew_sbh_formula.recommended_command')"
if [[ "$rec_cmd" == "brew tap Dicklesworthstone/sbh && brew install sbh" ]]; then
  pass "T6: post-trigger recommended_command is canonical brew tap+install"
else
  fail "T6: post-trigger recommended_command (got: $rec_cmd)"
fi

# Test 7: tap_name uses homebrew convention (homebrew- prefix stripped)
tap_name="$(printf '%s' "$out" | jq -r '.watchlists.homebrew_sbh_formula.tap_name')"
if [[ "$tap_name" == "Dicklesworthstone/sbh" ]]; then
  pass "T7: tap_name uses homebrew shortname convention (no homebrew- prefix)"
else
  fail "T7: tap_name uses homebrew shortname (got: $tap_name)"
fi

# Test 8: source_bead set correctly in the watchlist envelope
source_bead="$(printf '%s' "$out" | jq -r '.watchlists.homebrew_sbh_formula.source_bead')"
if [[ "$source_bead" == "flywheel-90k49.1" ]]; then
  pass "T8: watchlist envelope cites source_bead=flywheel-90k49.1"
else
  fail "T8: watchlist source_bead (got: $source_bead)"
fi

# Test 9: release_watch_count incremented to include this watch
count="$(printf '%s' "$out" | jq -r '.release_watch_count')"
if (( count >= 2 )); then
  pass "T9: release_watch_count incremented (≥2 watches now active; was 1 pre-fix)"
else
  fail "T9: release_watch_count (got: $count)"
fi

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
