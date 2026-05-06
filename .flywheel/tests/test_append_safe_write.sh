#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/append-safe-write.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/append-safe-write.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

line_count() {
  [[ -f "$1" ]] || { printf '0'; return 0; }
  wc -l <"$1" | tr -d ' '
}

expect_rc() {
  local want="$1" label="$2"; shift 2
  set +e
  "$@"
  local got=$?
  set -e
  [[ "$got" -eq "$want" ]] && pass "$label" || fail "$label rc=$got want=$want"
}

assert_file_lines() {
  local file="$1" want="$2" label="$3"
  [[ "$(line_count "$file")" == "$want" ]] && pass "$label" || fail "$label"
}

chmod +x "$SCRIPT"
bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"
"$SCRIPT" --info --json | jq -e '.schema_version == "append-safe-write/v1" and .exit_codes."2"' >/dev/null \
  && pass "info json exposes contract" || fail "info json exposes contract"

basic="$TMP/basic.txt"
printf 'alpha\n' | "$SCRIPT" --target "$basic" --json >/dev/null
grep -qx 'alpha' "$basic" && pass "single writer appends" || fail "single writer appends"

parallel="$TMP/parallel.txt"
printf 'one\n' | "$SCRIPT" --target "$parallel" --json &
pid_a=$!
printf 'two\n' | "$SCRIPT" --target "$parallel" --json &
pid_b=$!
wait "$pid_a"; wait "$pid_b"
if sort "$parallel" | tr '\n' ',' | grep -qx 'one,two,'; then
  pass "two parallel writes survive"
else
  fail "two parallel writes survive"
fi

stale="$TMP/stale.txt"
lock="$stale.append-safe.lock"
mkdir "$lock"
python3 - "$lock/owner.json" <<'PY'
import json, os, sys, time
path = sys.argv[1]
with open(path, "w", encoding="utf-8") as handle:
    json.dump({"created_at_epoch": time.time() - 10}, handle)
os.utime(os.path.dirname(path), (time.time() - 10, time.time() - 10))
PY
printf 'after-stale\n' | "$SCRIPT" --target "$stale" --lease-ms 50 --json >/dev/null
grep -qx 'after-stale' "$stale" && [[ ! -d "$lock" ]] \
  && pass "stale lease stolen and released" || fail "stale lease stolen and released"

diverge="$TMP/diverge.txt"
printf 'seed\n' >"$diverge"
printf 'payload\n' | env APPEND_SAFE_TEST_DIVERGE_ONCE=1 "$SCRIPT" --target "$diverge" --json >/dev/null
grep -qx 'payload' "$diverge" && grep -qx 'test-diverge-1' "$diverge" \
  && pass "tail divergence retries then succeeds" || fail "tail divergence retries then succeeds"

exhaust="$TMP/exhaust.txt"
printf 'seed\n' >"$exhaust"
expect_rc 2 "tail divergence exhausted exits 2" \
  bash -c "printf 'payload\n' | env APPEND_SAFE_TEST_DIVERGE_EACH_ATTEMPT=1 '$SCRIPT' --target '$exhaust' --max-retries 2 >/dev/null"

expect_rc 3 "empty input exits 3" bash -c "printf '' | '$SCRIPT' --target '$TMP/empty.txt' >/dev/null"
expect_rc 3 "missing target exits 3" bash -c "printf 'x\n' | '$SCRIPT' >/dev/null"

missing="$TMP/missing/target.txt"
printf 'created\n' | "$SCRIPT" --target "$missing" --json >/dev/null
[[ -f "$missing" ]] && grep -qx 'created' "$missing" \
  && pass "missing target created" || fail "missing target created"

real="$TMP/real.txt"
link="$TMP/link.txt"
ln -s "$real" "$link"
printf 'via-link\n' | "$SCRIPT" --target "$link" --json >/dev/null
grep -qx 'via-link' "$real" && pass "symlink target followed" || fail "symlink target followed"

idem="$TMP/idempotent.txt"
row='{"append_safe_idempotency_key":"idem-1","value":1}'
printf '%s\n' "$row" | "$SCRIPT" --target "$idem" --idempotency-key idem-1 --json >/dev/null
printf '%s\n' "$row" | "$SCRIPT" --target "$idem" --idempotency-key idem-1 --json >/dev/null
assert_file_lines "$idem" 1 "idempotency key avoids duplicate append"

fresh="$TMP/fresh-lock.txt"
mkdir "$fresh.append-safe.lock"
python3 - "$fresh.append-safe.lock/owner.json" <<'PY'
import json, time
with open(__import__("sys").argv[1], "w", encoding="utf-8") as handle:
    json.dump({"created_at_epoch": time.time() + 10}, handle)
PY
expect_rc 1 "fresh held lease exits 1" \
  bash -c "printf 'blocked\n' | '$SCRIPT' --target '$fresh' --lease-ms 50 >/dev/null"
rm -rf "$fresh.append-safe.lock"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$pass_count" -ge 12 && "$fail_count" -eq 0 ]]
