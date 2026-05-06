#!/usr/bin/env bash
set -euo pipefail

DRIVER="${FLYWHEEL_TICK_DRIVER_BIN_UNDER_TEST:-$HOME/.local/bin/flywheel-tick-driver}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-tick-driver.XXXXXX")"
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
    jq . "$file" >&2 || cat "$file" >&2
  fi
}

write_jsonl_lib() {
  local path="$1"
  cat >"$path" <<'SH'
fw_jsonl_append_validated() {
  local path="$1" row="$2"
  jq -e 'type == "object"' >/dev/null <<<"$row" || return 1
  mkdir -p "$(dirname "$path")"
  jq -c . <<<"$row" >>"$path"
}
SH
}

write_primitive() {
  local path="$1" body="$2"
  cat >"$path" <<SH
#!/usr/bin/env bash
set -euo pipefail
$body
SH
  chmod +x "$path"
}

write_fake_launchctl() {
  local path="$1" log="$2"
  cat >"$path" <<SH
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >>"$log"
if [[ "\${1:-}" == "list" ]]; then
  printf -- "-\\t0\\tcom.flywheel.tick\\n"
fi
SH
  chmod +x "$path"
}

hold_lock_and_run() {
  local lock="$1"; shift
  python3 - "$lock" "$@" <<'PY'
import fcntl
import os
import subprocess
import sys

lock = sys.argv[1]
cmd = sys.argv[2:]
os.makedirs(os.path.dirname(lock) or ".", exist_ok=True)
with open(lock, "w") as handle:
    fcntl.flock(handle, fcntl.LOCK_EX)
    proc = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    print(proc.stdout, end="")
    print(proc.stderr, end="", file=sys.stderr)
    sys.exit(proc.returncode)
PY
}

state="$TMP/state"
bin="$TMP/bin"
repo="$TMP/repo"
mkdir -p "$state" "$bin" "$repo/.flywheel/scripts"
append_lib="$TMP/jsonl-append.sh"
write_jsonl_lib "$append_lib"

write_primitive "$TMP/success.sh" 'printf "{\"status\":\"ok\"}\n"'
write_primitive "$TMP/error.sh" 'printf "boom\n" >&2; exit 7'
write_primitive "$TMP/timeout.sh" 'sleep 3'

manifest="$TMP/manifest.json"
cat >"$manifest" <<JSON
{
  "schema_version": "tick-driver-manifest.v1",
  "primitives": [
    {"name":"success","path":"$TMP/success.sh","args":["--apply"],"timeout_sec":2},
    {"name":"timeout","path":"$TMP/timeout.sh","args":["--apply"],"timeout_sec":1},
    {"name":"error","path":"$TMP/error.sh","args":["--apply"],"timeout_sec":2}
  ]
}
JSON

env_base=(
  "FLYWHEEL_TICK_DRIVER_HOME=$TMP/home"
  "FLYWHEEL_TICK_DRIVER_STATE_DIR=$state"
  "FLYWHEEL_TICK_DRIVER_MANIFEST=$manifest"
  "FLYWHEEL_TICK_DRIVER_REPO=$repo"
  "FLYWHEEL_TICK_DRIVER_LEDGER=$state/tick-driver.jsonl"
  "FLYWHEEL_TICK_DRIVER_FUCKUP_LOG=$state/fuckup-log.jsonl"
  "FLYWHEEL_TICK_DRIVER_CONTRACT_LEDGER=$state/substrate-loop-contract.jsonl"
  "FLYWHEEL_TICK_DRIVER_LOCK=$state/tick-driver.lock"
  "FLYWHEEL_JSONL_APPEND_LIB=$append_lib"
)

bash -n "$DRIVER"
env "${env_base[@]}" "$DRIVER" --json >"$TMP/run.json"
assert_jq "$TMP/run.json" '.primitive_count == 3 and .ok_count == 1 and .timeout_count == 1 and .error_count == 1' "synthetic_invokes_all"
assert_jq "$state/tick-driver.jsonl" '.primitive_count == 3 and .status == "degraded"' "ledger_row_written"
assert_jq "$state/fuckup-log.jsonl" '[inputs] | length >= 1' "fuckup_for_failed_primitive"

hold_lock_and_run "$state/tick-driver.lock" env "${env_base[@]}" "$DRIVER" --json >"$TMP/locked.json"
assert_jq "$TMP/locked.json" '.status == "skipped_lock"' "flock_prevents_overlap"

install_home="$TMP/install-home"
install_bin="$TMP/install-bin/flywheel-tick-driver"
install_plist="$install_home/Library/LaunchAgents/com.flywheel.tick.plist"
launchctl_log="$TMP/launchctl.log"
fake_launchctl="$TMP/fake-launchctl"
write_fake_launchctl "$fake_launchctl" "$launchctl_log"

env \
  FLYWHEEL_TICK_DRIVER_HOME="$install_home" \
  FLYWHEEL_TICK_DRIVER_STATE_DIR="$install_home/state" \
  FLYWHEEL_TICK_DRIVER_BIN="$install_bin" \
  FLYWHEEL_TICK_DRIVER_PLIST="$install_plist" \
  FLYWHEEL_TICK_DRIVER_LAUNCHCTL="$fake_launchctl" \
  FLYWHEEL_JSONL_APPEND_LIB="$append_lib" \
  "$DRIVER" --install --json >"$TMP/install.json"
test -x "$install_bin" && test -f "$install_plist" && grep -q 'load -w' "$launchctl_log"
env \
  FLYWHEEL_TICK_DRIVER_HOME="$install_home" \
  FLYWHEEL_TICK_DRIVER_STATE_DIR="$install_home/state" \
  FLYWHEEL_TICK_DRIVER_BIN="$install_bin" \
  FLYWHEEL_TICK_DRIVER_PLIST="$install_plist" \
  FLYWHEEL_TICK_DRIVER_LAUNCHCTL="$fake_launchctl" \
  FLYWHEEL_JSONL_APPEND_LIB="$append_lib" \
  "$DRIVER" --uninstall --json >"$TMP/uninstall.json"
if [[ ! -e "$install_bin" && ! -e "$install_plist" ]] && grep -q 'unload -w' "$launchctl_log"; then
  pass "install_uninstall_reversible"
else
  fail "install_uninstall_reversible"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAIL flywheel-tick-driver tests pass=%d/5 fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'OK flywheel-tick-driver tests pass=%d/5\n' "$pass_count"
