#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/hub-blocker-detect.sh"
BR_BIN="${BR_BIN:-$HOME/.cargo/bin/br}"
TMP="$(mktemp -d -t hub-blocker-test.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

repo="$TMP/repo"
mkdir -p "$repo"
git -C "$repo" init -q
(cd "$repo" && "$BR_BIN" init --prefix flywheel --json >/dev/null)

child="$(cd "$repo" && "$BR_BIN" create "hub child fixture" --type task --priority 2 --description "fixture" --json | jq -r '.id')"
for n in 1 2 3 4; do
  parent="$(cd "$repo" && "$BR_BIN" create "parent $n fixture" --type task --priority 1 --description "fixture" --json | jq -r '.id')"
  (cd "$repo" && "$BR_BIN" dep add "$child" "$parent" >/dev/null)
done

set +e
BR_BIN="$BR_BIN" "$SCRIPT" --repo "$repo" --threshold 3 --json >"$TMP/check.json"
check_rc=$?
set -e
[[ "$check_rc" -eq 1 ]] && pass "check exits 1 when hub blocker exists" || fail "check exits 1 when hub blocker exists rc=$check_rc"
assert_jq "$TMP/check.json" '.hub_blocker_count == 1' "detects one hub blocker"
assert_jq "$TMP/check.json" '.hub_blockers[0].id == "'"$child"'" and .hub_blockers[0].parent_block_count == 4' "reports parent block count"
assert_jq "$TMP/check.json" '.hub_blockers[0].would_promote == true' "plans priority promotion"
assert_jq "$TMP/check.json" '.dashboard_line | contains("Hub blockers: 1 active")' "emits status dashboard line"

FLYWHEEL_FUCKUP_LOG="$TMP/fuckups.jsonl" \
BR_BIN="$BR_BIN" \
FLYWHEEL_LOOP_BIN="$HOME/.claude/skills/.flywheel/bin/flywheel-loop" \
  "$SCRIPT" --repo "$repo" --threshold 3 --apply --json >"$TMP/apply.json" || true
assert_jq "$TMP/apply.json" '.promoted_count == 1 and .fuckup_log_count == 1' "apply promotes and logs fuckup"
show="$(cd "$repo" && "$BR_BIN" show "$child" --json)"
jq -e '.[0].priority == 0 and (.[0].labels | index("hub_blocker"))' <<<"$show" >/dev/null \
  && pass "child priority and label updated through br" \
  || { fail "child priority and label updated through br"; jq . <<<"$show" >&2; }
jq -e 'select(.trauma_class == "hub-blocker" and (.what_happened | contains("ops-manager"))) | true' "$TMP/fuckups.jsonl" >/dev/null \
  && pass "fuckup row carries Joshua ops-manager lens" \
  || fail "fuckup row carries Joshua ops-manager lens"

solo_repo="$TMP/solo"
mkdir -p "$solo_repo"
git -C "$solo_repo" init -q
(cd "$solo_repo" && "$BR_BIN" init --prefix flywheel --json >/dev/null)
(cd "$solo_repo" && "$BR_BIN" create "solo fixture" --type task --priority 2 --description "fixture" --json >/dev/null)
BR_BIN="$BR_BIN" "$SCRIPT" --repo "$solo_repo" --threshold 3 --json >"$TMP/solo.json"
assert_jq "$TMP/solo.json" '.status == "pass" and .hub_blocker_count == 0' "clean repo passes"

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
