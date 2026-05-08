#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/flywheel-cron.sh"
TMP="$(mktemp -d -t flywheel-cron.XXXXXX)"
trap 'chmod -R u+w "$TMP" 2>/dev/null || true; find "$TMP" -mindepth 1 -delete 2>/dev/null || true; rmdir "$TMP" 2>/dev/null || true' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

run_refusal() {
  local command_path="$1" expected="$2" out rc=0
  out="$TMP/$expected.json"
  set +e
  "$SCRIPT" register --label "com.zeststream.fixture.$expected" --owner flywheel --command "$command_path" --interval 60 --dry-run --json >"$out"
  rc=$?
  set -e
  if [[ "$rc" -ne 0 ]] && jq -e --arg expected "$expected" '.status == "refused" and .reason_code == $expected' "$out" >/dev/null; then
    pass "$expected"
  else
    fail "$expected"
    cat "$out" >&2 || true
  fi
}

mkdir -p "$TMP/bin"
missing="$TMP/bin/missing.sh"
not_exec="$TMP/bin/not-exec.sh"
no_shebang="$TMP/bin/no-shebang.sh"
printf '#!/usr/bin/env bash\nexit 0\n' >"$not_exec"
printf 'printf fixture\n' >"$no_shebang"
chmod +x "$no_shebang"

run_refusal "$missing" "command_missing"
run_refusal "$not_exec" "command_not_executable"
run_refusal "$no_shebang" "command_missing_shebang"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 && "$pass_count" -ge 3 ]]
