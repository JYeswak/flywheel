#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/tmp-aggressive-prune.sh"
TMP="$(mktemp -d /tmp/tmp-aggressive-prune-test.XXXXXX)"
trap 'chmod -R u+w "$TMP" 2>/dev/null || true; rm -R "$TMP" 2>/dev/null || true' EXIT

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
    jq . "$file" >&2 || true
  fi
}

make_old_dir() {
  local path="$1"
  mkdir -p "$path"
  printf 'payload\n' >"$path/payload.txt"
  touch -t 202001010101 "$path/payload.txt" "$path"
}

make_socket() {
  local path="$1"
  python3 - "$path" <<'PY'
import socket
import sys

sock = socket.socket(socket.AF_UNIX)
sock.bind(sys.argv[1])
sock.close()
PY
}

bash -n "$SCRIPT" && pass "script_syntax" || fail "script_syntax"

fixture="$TMP/private-tmp"
mkdir -p "$fixture/tmux-501" "$fixture/agentmail-501" "$fixture/generic-socket-dir"
make_socket "$fixture/tmux-501/default"
make_socket "$fixture/generic-socket-dir/control.sock"
printf 'payload\n' >"$fixture/agentmail-501/payload.txt"
make_old_dir "$fixture/ordinary-old"
make_old_dir "$fixture/launchd-fixture"
touch -t 202001010101 \
  "$fixture/tmux-501" \
  "$fixture/tmux-501/default" \
  "$fixture/agentmail-501" \
  "$fixture/agentmail-501/payload.txt" \
  "$fixture/generic-socket-dir" \
  "$fixture/generic-socket-dir/control.sock" \
  "$fixture/launchd-fixture"

"$SCRIPT" --root "$fixture" --max-mtime-days 1 --dry-run --json >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.status == "ok" and .apply == false and .root == "'"$fixture"'"' "dry_run_root_fixture"
assert_jq "$TMP/dry.json" '.candidates_count == 1 and .protected_count >= 4' "only_ordinary_old_planned"
assert_jq "$TMP/dry.json" '.protected_sample | test("tmux-501=ipc-name")' "tmux_socket_dir_protected"

"$SCRIPT" --root "$fixture" --max-mtime-days 1 --apply --idempotency-key=test-tmux-socket --json >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.status == "ok" and .apply == true and .deleted_count == 1 and .protected_count >= 4' "apply_deletes_only_unprotected"

for protected in tmux-501 agentmail-501 generic-socket-dir launchd-fixture; do
  if [ -e "$fixture/$protected" ]; then
    pass "protected_survives/$protected"
  else
    fail "protected_survives/$protected"
  fi
done

if [ ! -e "$fixture/ordinary-old" ]; then
  pass "ordinary_old_removed"
else
  fail "ordinary_old_removed"
fi

if [ "$fail_count" -ne 0 ]; then
  printf 'FAIL: %s failures, %s passes\n' "$fail_count" "$pass_count" >&2
  exit 1
fi
printf 'PASS tmp_socket_ipc_guard: %s checks\n' "$pass_count"
