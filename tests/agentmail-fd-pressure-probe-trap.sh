#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/agentmail-fd-pressure-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/agentmail-fd-pressure-probe-trap.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_no_pid_alive() {
  local pid_file="$1" label="$2" pid state alive=0
  while IFS= read -r pid; do
    [[ -n "$pid" ]] || continue
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      sleep 0.1
      state="$(ps -o stat= -p "$pid" 2>/dev/null | tr -d '[:space:]' || true)"
      if [[ -n "$state" && "$state" != Z* ]]; then
        alive=$((alive + 1))
      fi
    fi
  done <"$pid_file"
  if [[ "$alive" -eq 0 ]]; then
    pass "$label"
  else
    while IFS= read -r pid; do
      [[ -n "$pid" ]] || continue
      ps -o pid=,ppid=,stat=,command= -p "$pid" 2>/dev/null || true
    done <"$pid_file" >&2
    fail "$label alive=$alive"
  fi
}

mkdir -p "$TMP/bin"
cat >"$TMP/bin/launchctl" <<'SH'
#!/usr/bin/env bash
if [[ "${1:-}" == list ]]; then
  printf '123\t0\tai.zeststream.mcp-agent-mail-local\n'
fi
SH
cat >"$TMP/bin/lsof" <<'SH'
#!/usr/bin/env bash
count_file="${FAKE_LSOF_COUNT:?}"
count=0
[[ -f "$count_file" ]] && count="$(cat "$count_file")"
count=$((count + 1))
printf '%s\n' "$count" >"$count_file"
if [[ "$count" -eq 1 ]]; then
  printf 'COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME\n'
  printf 'python 123 josh txt REG 1,1 0 1 /tmp/a\n'
  printf 'python 123 josh txt REG 1,1 0 2 /tmp/b\n'
  exit 0
fi
pid_file="${FAKE_CURL_PIDS:?}"
for _ in 1 2 3 4 5 6 7 8 9 10; do
  if [[ -f "$pid_file" ]] && [[ "$(wc -l <"$pid_file" | tr -d ' ')" -ge 2 ]]; then
    break
  fi
  sleep 0.1
done
exit 42
SH
cat >"$TMP/bin/curl" <<'SH'
#!/usr/bin/env bash
count_file="${FAKE_CURL_COUNT:?}"
pid_file="${FAKE_CURL_PIDS:?}"
count=0
[[ -f "$count_file" ]] && count="$(cat "$count_file")"
count=$((count + 1))
printf '%s\n' "$count" >"$count_file"
if [[ "$count" -eq 1 ]]; then
  exit 0
fi
printf '%s\n' "${BASHPID:-$$}" >>"$pid_file"
exec sleep 30
SH
chmod +x "$TMP/bin/launchctl" "$TMP/bin/lsof" "$TMP/bin/curl"

if bash -n "$SCRIPT"; then
  pass "syntax"
else
  fail "syntax"
fi

if rg -q 'trap cleanup_burst_workers EXIT ERR' "$SCRIPT" \
  && rg -q 'BURST_WORKER_PIDS' "$SCRIPT" \
  && rg -q 'pkill -TERM -P' "$SCRIPT"; then
  pass "cleanup trap is wired to worker pid registry"
else
  fail "cleanup trap wiring missing"
fi

start_ts="$(date +%s)"
FAKE_LSOF_COUNT="$TMP/lsof-count" \
FAKE_CURL_COUNT="$TMP/curl-count" \
FAKE_CURL_PIDS="$TMP/curl-pids" \
PATH="$TMP/bin:$PATH" \
  "$SCRIPT" --probe --workers 2 --duration 5 --json >"$TMP/out.json" 2>"$TMP/err.log" && rc=0 || rc=$?
elapsed="$(( $(date +%s) - start_ts ))"

if [[ "$rc" -ne 0 ]]; then
  pass "fixture forces early probe exit after worker spawn"
else
  fail "fixture should have forced early probe exit"
fi

sleep 0.5
touch "$TMP/curl-pids"
assert_no_pid_alive "$TMP/curl-pids" "cleanup kills spawned curl workers on early exit"
if [[ "$elapsed" -lt 10 ]]; then
  pass "cleanup returns before fake curl sleep expires"
else
  fail "cleanup returns before fake curl sleep expires elapsed=${elapsed}s"
fi

"$SCRIPT" --probe --workers 1 --duration 1 --dry-run --json >"$TMP/dry-run.json"
if jq -e '.mode == "probe" and .dry_run == true and .workers == 1 and .duration_sec == 1' "$TMP/dry-run.json" >/dev/null; then
  pass "dry-run envelope preserved"
else
  fail "dry-run envelope preserved"
fi

if "$SCRIPT" --info | jq -e '.schema_version == "agentmail-fd-pressure-probe/v1"' >/dev/null; then
  pass "info envelope preserved"
else
  fail "info envelope preserved"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
