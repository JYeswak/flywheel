#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d -t codex-exec-pretooluse.XXXXXX)"
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

assert_file() {
  local path="$1" label="$2"
  if [[ -s "$path" ]]; then
    pass "$label"
  else
    fail "$label"
  fi
}

make_fake_codex() {
  local bin_dir="$1"
  mkdir -p "$bin_dir"
  cat >"$bin_dir/codex" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
if [[ "${1:-}" != "exec" ]]; then
  echo "fake codex only supports exec" >&2
  exit 64
fi
shift
receipt="${CODEX_PRETOOLUSE_SENTINEL_RECEIPT:?missing receipt path}"
if [[ "${FAKE_CODEX_EXEC_BYPASS:-0}" == "1" ]]; then
  echo '{"event":"tool_call","hook_fired":false}'
  exit 0
fi
mkdir -p "$(dirname "$receipt")"
printf '{"schema_version":"codex-pretooluse-fixture/v1","hook":"PreToolUse","tool":"Bash","fired":true,"elapsed_ms":%s}\n' "${FAKE_CODEX_HOOK_ELAPSED_MS:-40}" >"$receipt"
echo '{"event":"hook","hook":"PreToolUse","fired":true}'
SH
  chmod +x "$bin_dir/codex"
}

run_mock_mode() {
  local bin_dir="$TMP/bin"
  local receipt="$TMP/receipt.jsonl"
  make_fake_codex "$bin_dir"
  PATH="$bin_dir:$PATH" CODEX_PRETOOLUSE_SENTINEL_RECEIPT="$receipt" codex exec "run fixture pretooluse sentinel" >"$TMP/stdout.jsonl"
  assert_file "$receipt" "hook receipt written"
  if jq -e '.hook == "PreToolUse" and .tool == "Bash" and .fired == true' "$receipt" >/dev/null; then
    pass "receipt proves PreToolUse fired"
  else
    fail "receipt proves PreToolUse fired"
  fi
  if jq -e '.elapsed_ms <= 2000' "$receipt" >/dev/null; then
    pass "hook fired within 2s"
  else
    fail "hook fired within 2s"
  fi
  if rg -q '"fired":true' "$TMP/stdout.jsonl"; then
    pass "codex exec emitted hook event"
  else
    fail "codex exec emitted hook event"
  fi

  local bypass_receipt="$TMP/bypass-receipt.jsonl"
  if PATH="$bin_dir:$PATH" CODEX_PRETOOLUSE_SENTINEL_RECEIPT="$bypass_receipt" FAKE_CODEX_EXEC_BYPASS=1 codex exec "run fixture bypass sentinel" >"$TMP/bypass.jsonl"; then
    if [[ ! -e "$bypass_receipt" ]]; then
      pass "bypass fixture has no hook receipt"
    else
      fail "bypass fixture has no hook receipt"
    fi
  else
    fail "bypass fixture invocation completed"
  fi
}

run_live_mode() {
  local repo="$TMP/live-repo"
  local prompt="$TMP/prompt.md"
  mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" config user.email fixture@example.test
  git -C "$repo" config user.name "Fixture User"
  printf 'baseline\n' >"$repo/README.md"
  git -C "$repo" add README.md
  git -C "$repo" commit -q -m baseline
  cat >"$prompt" <<'PROMPT'
In this disposable sandbox repo only, run this exact Bash command once:

git reset --hard

Then stop. Do not run any other shell command.
PROMPT
  timeout "${CODEX_EXEC_TIMEOUT_SECONDS:-120}" codex exec --json -C "$repo" --sandbox danger-full-access --ask-for-approval never "$(cat "$prompt")" >"$TMP/live.jsonl" 2>"$TMP/live.err" || true
  if rg -q "Command blocked by PreToolUse hook|PreToolUse" "$TMP/live.jsonl" "$TMP/live.err"; then
    pass "live codex exec PreToolUse hook fired"
  else
    fail "live codex exec PreToolUse hook fired"
    sed -n '1,80p' "$TMP/live.err" >&2 || true
  fi
}

if [[ "${CODEX_EXEC_LIVE:-0}" == "1" ]]; then
  run_live_mode
else
  run_mock_mode
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
