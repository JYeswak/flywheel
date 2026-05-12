#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/depersonalize.py"
DENYLIST="$ROOT/state/live-state-denylist.yaml"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-denylist.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$1"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$1" >&2; }

run_capture() {
  local out="$1" err="$2"
  shift 2
  set +e
  "$@" >"$out" 2>"$err"
  local rc=$?
  set +e
  return "$rc"
}

if python3 -m py_compile "$SCRIPT" && python3 "$SCRIPT" --help >/dev/null; then
  pass "syntax"
else
  fail "syntax"
fi

if [[ -s "$DENYLIST" ]] && rg -q '^schema_version: flywheel\.live_state_denylist\.v0$' "$DENYLIST"; then
  pass "denylist present"
else
  fail "denylist present"
fi

mkdir -p "$TMP/ntm/.ntm"
printf '{}\n' >"$TMP/ntm/.ntm/rate_limits.json"
run_capture "$TMP/ntm.out" "$TMP/ntm.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/ntm" --json
ntm_rc=$?
if [[ "$ntm_rc" -eq 30 ]] && jq -e '.status == "fail" and .exit_code == 30 and (.findings[] | select(.id == "repo-ntm-runtime" and .reason_code == "private_pane_runtime"))' "$TMP/ntm.out" >/dev/null; then
  pass "ntm runtime blocked"
else
  fail "ntm runtime blocked rc=${ntm_rc}"
fi

mkdir -p "$TMP/manual/.flywheel/handoffs"
printf 'synthetic handoff\n' >"$TMP/manual/.flywheel/handoffs/example.md"
run_capture "$TMP/manual.out" "$TMP/manual.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/manual" --json
manual_rc=$?
if [[ "$manual_rc" -eq 31 ]] && jq -e '.status == "manual_review_required" and (.findings[] | select(.id == "repo-handoffs"))' "$TMP/manual.out" >/dev/null; then
  pass "manual review surfaced"
else
  fail "manual review surfaced rc=${manual_rc}"
fi

mkdir -p "$TMP/credential"
printf 'FIXTURE_TOKEN=CANARY_TEST_VALUE\n' >"$TMP/credential/.env.local"
run_capture "$TMP/credential.out" "$TMP/credential.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/credential" --json
credential_rc=$?
if [[ "$credential_rc" -eq 32 ]] && jq -e '.status == "fail" and .exit_code == 32 and (.findings[] | select(.id == "env-files"))' "$TMP/credential.out" >/dev/null; then
  pass "credential-shaped path blocked"
else
  fail "credential-shaped path blocked rc=${credential_rc}"
fi

mkdir -p "$TMP/vendor/node_modules/pkg/tokenizer" "$TMP/vendor/node_modules/next/dist/compiled/cookie"
printf 'synthetic package file\n' >"$TMP/vendor/node_modules/pkg/tokenizer/index.js"
printf 'synthetic package file\n' >"$TMP/vendor/node_modules/next/dist/compiled/cookie/index.js"
run_capture "$TMP/vendor.out" "$TMP/vendor.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/vendor" --json
vendor_rc=$?
run_capture "$TMP/vendor-deep.out" "$TMP/vendor-deep.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/vendor" --include-ignored-dirs --json
vendor_deep_rc=$?
if [[ "$vendor_rc" -eq 0 ]] && [[ "$vendor_deep_rc" -eq 32 ]] && jq -e '.status == "pass"' "$TMP/vendor.out" >/dev/null && jq -e '.status == "fail" and (.findings[] | select(.reason_code == "credential_state_path"))' "$TMP/vendor-deep.out" >/dev/null; then
  pass "dependency dirs ignored by default"
else
  fail "dependency dirs ignored by default rc=${vendor_rc} deep_rc=${vendor_deep_rc}"
fi

mkdir -p "$TMP/safe/templates" "$TMP/safe/docs"
printf 'repo={{ repo_path }}\n' >"$TMP/safe/templates/loop.tmpl"
printf '# Public docs\n' >"$TMP/safe/docs/first-run.md"
run_capture "$TMP/safe.out" "$TMP/safe.err" python3 "$SCRIPT" --probe-denylist --root "$TMP/safe" --json
safe_rc=$?
if [[ "$safe_rc" -eq 0 ]] && jq -e '.status == "pass" and (.findings | length == 0)' "$TMP/safe.out" >/dev/null; then
  pass "safe template allowed"
else
  fail "safe template allowed rc=${safe_rc}"
fi

if ! rg -n 'secret|TOKEN|CANARY_TEST_VALUE|synthetic handoff' "$TMP"/*.out >/dev/null; then
  pass "outputs avoid file contents"
else
  fail "outputs avoid file contents"
fi

if [[ "$FAIL" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$PASS" "$FAIL" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$PASS"
