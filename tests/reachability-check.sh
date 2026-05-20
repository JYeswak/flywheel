#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/reachability-check.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/reachability-check.XXXXXX")"
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

assert_rc() {
  local expected="$1" label="$2"
  shift 2
  local rc
  set +e
  "$@" >"$TMP/out.json" 2>"$TMP/err.txt"
  rc=$?
  set -e
  if [[ "$rc" -eq "$expected" ]]; then
    pass "$label rc=$expected"
  else
    fail "$label rc expected=$expected got=$rc"
    cat "$TMP/out.json" >&2 || true
    cat "$TMP/err.txt" >&2 || true
  fi
}

assert_jq() {
  local expr="$1" label="$2"
  if jq -e "$expr" "$TMP/out.json" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    cat "$TMP/out.json" >&2 || true
  fi
}

repo="$TMP/repo"
mkdir -p "$repo/scripts" "$repo/tests" "$repo/.flywheel"
git -C "$repo" init -q
git -C "$repo" config user.email fixture@example.test
git -C "$repo" config user.name "Fixture User"

cat >"$repo/scripts/hot.sh" <<'SH'
#!/usr/bin/env bash
printf 'hot\n'
SH
cat >"$repo/scripts/called.sh" <<'SH'
#!/usr/bin/env bash
printf 'called\n'
SH
cat >"$repo/scripts/cold.sh" <<'SH'
#!/usr/bin/env bash
printf 'cold\n'
SH
cat >"$repo/scripts/logged.sh" <<'SH'
#!/usr/bin/env bash
printf 'logged\n'
SH
cat >"$repo/tests/called-test.sh" <<'SH'
#!/usr/bin/env bash
bash scripts/called.sh
SH
chmod +x "$repo"/scripts/*.sh "$repo/tests/called-test.sh"
git -C "$repo" add scripts tests
git -C "$repo" commit -q -m seed

inventory="$TMP/inventory.jsonl"
{
  jq -nc --arg repo_path "$repo" '{repo:"fixture",repo_path:$repo_path,path:"scripts/hot.sh",invoke_count_30d:3}'
  jq -nc --arg repo_path "$repo" '{repo:"fixture",repo_path:$repo_path,path:"scripts/called.sh",invoke_count_30d:0}'
  jq -nc --arg repo_path "$repo" '{repo:"fixture",repo_path:$repo_path,path:"scripts/cold.sh",invoke_count_30d:0}'
  jq -nc --arg repo_path "$repo" '{repo:"fixture",repo_path:$repo_path,path:"scripts/logged.sh",invoke_count_30d:0}'
  jq -nc --arg repo_path "$repo" '{repo:"fixture",repo_path:$repo_path,path:"scripts/missing.sh",invoke_count_30d:0}'
} >"$inventory"

jq -nc '{ts:"2026-05-19T12:00:00Z",event:"worker_callback",evidence:"scripts/logged.sh"}' >"$repo/.flywheel/dispatch-log.jsonl"

assert_rc 0 "invoke_count surface reachable" "$SCRIPT" --json --inventory "$inventory" "$repo/scripts/hot.sh"
assert_jq '.reachable == true and .reason == "invoke_count_30d" and .invoke_count_30d == 3' "invoke_count reason"

assert_rc 0 "inbound caller surface reachable" "$SCRIPT" --json --inventory "$inventory" "$repo/scripts/called.sh"
assert_jq '.reachable == true and .reason == "tracked_inbound_reference" and .inbound_caller_count >= 1' "inbound caller reason"

assert_rc 0 "dispatch log surface reachable" "$SCRIPT" --json --inventory "$inventory" "$repo/scripts/logged.sh"
assert_jq '.reachable == true and .reason == "dispatch_log_reference" and .dispatch_log_hits == 1' "dispatch log reason"

assert_rc 1 "cold surface dead" "$SCRIPT" --json --inventory "$inventory" "$repo/scripts/cold.sh"
assert_jq '.reachable == false and .reason == "no_invoke_or_tracked_inbound_reference"' "cold reason"

assert_rc 1 "missing surface dead" "$SCRIPT" --json --inventory "$inventory" "$repo/scripts/missing.sh"
assert_jq '.reachable == false and .reason == "missing_surface"' "missing reason"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
