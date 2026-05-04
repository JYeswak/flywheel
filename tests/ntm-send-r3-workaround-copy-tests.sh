#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-send-r3-workaround.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

fake_ntm="$TMP/fake-ntm"
log="$TMP/fake-ntm.log"

cat >"$fake_ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" != "send" ]]; then
  printf 'expected send command\n' >&2
  exit 2
fi
shift
session="${1:?session required}"
shift
prompt="${*: -1}"
printf 'Continue anyway? [y/N]: ' >&2
IFS= read -r answer
case "${answer,,}" in
  y|yes)
    printf 'session=%s prompt=%s\n' "$session" "$prompt" >>"${FAKE_NTM_LOG:?}"
    ;;
  *)
    exit 1
    ;;
esac
SH
chmod +x "$fake_ntm"

if printf 'y\n' | FAKE_NTM_LOG="$log" "$fake_ntm" send flywheel --pane=4 --no-cass-check "codex --dangerously-bypass-approvals-and-sandbox"; then
  if grep -q 'session=flywheel prompt=codex --dangerously-bypass-approvals-and-sandbox' "$log"; then
    pass "finite y pipe confirms positional prompt send"
  else
    fail "finite y pipe confirms positional prompt send"
  fi
else
  fail "finite y pipe confirms positional prompt send"
fi

if command -v timeout >/dev/null 2>&1; then
  timeout_bin=timeout
elif command -v gtimeout >/dev/null 2>&1; then
  timeout_bin=gtimeout
else
  timeout_bin=""
fi

if [[ -n "$timeout_bin" ]] && FAKE_NTM_LOG="$log" "$timeout_bin" 2s bash -c 'yes | "$0" send flywheel --pane=4 --no-cass-check "status probe"' "$fake_ntm"; then
  if grep -q 'session=flywheel prompt=status probe' "$log"; then
    pass "yes pipe fallback confirms without hanging"
  else
    fail "yes pipe fallback confirms without hanging"
  fi
else
  fail "yes pipe fallback confirms without hanging"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
