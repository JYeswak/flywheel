#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/dispatch-log-fitness-invariant.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/codex-app-server-metadata.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'ok %d - %s\n' "$pass_count" "$1"
}

fail() {
  fail_count=$((fail_count + 1))
  printf 'not ok %d - %s\n' "$((pass_count + fail_count))" "$1" >&2
}

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

make_repo() {
  local repo="$1"
  mkdir -p "$repo/.flywheel"
  git -C "$repo" init -q
  git -C "$repo" config user.email fixture@example.test
  git -C "$repo" config user.name "Fixture User"
  printf 'fixture\n' >"$repo/README.md"
  git -C "$repo" add README.md
  git -C "$repo" commit -q -m fixture
}

clean_repo="$TMP/clean-repo"
make_repo "$clean_repo"

jq -nc \
  --arg cwd "$clean_repo" \
  --arg repo_path "$clean_repo" \
  '{
    schema_version:"callback-envelope/v1",
    ts:"2026-05-19T20:30:00Z",
    event:"worker_callback",
    status:"DONE",
    task_id:"fixture-clean",
    cwd:$cwd,
    repo_path:$repo_path,
    originator:"DustyMarsh",
    agent:"DustyMarsh"
  }' >"$clean_repo/.flywheel/dispatch-log.jsonl"

set +e
NTM_TIMELINE_JSON='{"events":[]}' bash "$BIN" --repo "$clean_repo" --json >"$TMP/clean.json"
clean_rc=$?
set -e

if [[ "$clean_rc" -eq 0 ]]; then
  pass "clean metadata exits 0"
else
  fail "clean metadata exits 0"
fi
assert_jq "$TMP/clean.json" '.status == "PASS"' "clean status PASS"
assert_jq "$TMP/clean.json" '.metadata_integrity_status == "PASS"' "clean metadata integrity PASS"
assert_jq "$TMP/clean.json" '.cwd_integrity_checked == 1' "clean row checked"
assert_jq "$TMP/clean.json" '.cwd_integrity_violation_count == 0' "clean row has no cwd violation"
assert_jq "$TMP/clean.json" '.originator_integrity_violation_count == 0' "clean row has no originator violation"

bad_repo="$TMP/bad-repo"
other_repo="$TMP/other-repo"
make_repo "$bad_repo"
make_repo "$other_repo"

jq -nc \
  --arg cwd "$other_repo" \
  --arg repo_path "$bad_repo" \
  '{
    schema_version:"callback-envelope/v1",
    ts:"2026-05-19T20:31:00Z",
    event:"worker_callback",
    status:"DONE",
    task_id:"fixture-polluted",
    cwd:$cwd,
    repo_path:$repo_path,
    originator:"DustyMarsh",
    agent:"DustyMarsh"
  }' >"$bad_repo/.flywheel/dispatch-log.jsonl"

set +e
NTM_TIMELINE_JSON='{"events":[]}' bash "$BIN" --repo "$bad_repo" --json >"$TMP/bad.json"
bad_rc=$?
set -e

if [[ "$bad_rc" -eq 2 ]]; then
  pass "polluted metadata exits 2"
else
  fail "polluted metadata exits 2"
fi
assert_jq "$TMP/bad.json" '.status == "FAIL"' "polluted status FAIL"
assert_jq "$TMP/bad.json" '.metadata_integrity_status == "FAIL"' "polluted metadata integrity FAIL"
assert_jq "$TMP/bad.json" '.cwd_integrity_violation_count == 1' "polluted row has one cwd violation"
assert_jq "$TMP/bad.json" '.originator_integrity_violation_count == 0' "polluted row keeps originator clean"
assert_jq "$TMP/bad.json" '.cwd_integrity_violations[0].type == "cwd_repo_path_mismatch"' "polluted violation type recorded"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
