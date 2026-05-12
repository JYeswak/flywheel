#!/usr/bin/env bash
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/scripts/depersonalize.py"
FIXTURE="$ROOT/fixtures/depersonalize/source"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-depersonalize-table.XXXXXX")"
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

if python3 -m py_compile "$SCRIPT"; then
  pass "syntax"
else
  fail "syntax"
fi

cp -R "$FIXTURE" "$TMP/work"

run_capture "$TMP/scan-before.out" "$TMP/scan-before.err" \
  python3 "$SCRIPT" --scan-table --root "$TMP/work" --json
scan_before_rc=$?
if [[ "$scan_before_rc" -eq 40 ]] && jq -e '.status == "fail" and .exit_code == 40 and (.findings[] | select(.row_ids | index("operator-full-name"))) and (.findings[] | select(.row_ids | index("source-repo-path")))' "$TMP/scan-before.out" >/dev/null; then
  pass "scan finds table values"
else
  fail "scan finds table values rc=${scan_before_rc}"
fi

if ! rg -q 'Joshua Nowak|Blackfoot Telecom|/Users/josh/Developer/flywheel' "$TMP/scan-before.out"; then
  pass "scan omits matched content"
else
  fail "scan omits matched content"
fi

run_capture "$TMP/dry-run.out" "$TMP/dry-run.err" \
  python3 "$SCRIPT" --dry-run --root "$TMP/work" --json
dry_run_rc=$?
if [[ "$dry_run_rc" -eq 0 ]] && jq -e '.status == "pass" and .changed_files == 1 and (.changes[] | select(.path == "public.md" and (.row_ids | index("operator-full-name")) and (.row_ids | index("source-repo-path")) and (.row_ids | index("blackfoot-client")))) and (.diff | contains("<flywheel-repo>"))' "$TMP/dry-run.out" >/dev/null; then
  pass "dry-run emits reviewable patch"
else
  fail "dry-run emits reviewable patch rc=${dry_run_rc}"
fi

run_capture "$TMP/apply.out" "$TMP/apply.err" \
  python3 "$SCRIPT" --apply --root "$TMP/work" --json
apply_rc=$?
if [[ "$apply_rc" -eq 0 ]] && jq -e '.status == "pass" and .changed_files == 1 and (.changes[] | select(.path == "public.md"))' "$TMP/apply.out" >/dev/null; then
  pass "apply rewrites fixture"
else
  fail "apply rewrites fixture rc=${apply_rc}"
fi

if rg -q '<flywheel-repo>' "$TMP/work/public.md" && ! rg -q '\$HOME/Developer/flywheel' "$TMP/work/public.md"; then
  pass "specific path wins before home path"
else
  fail "specific path wins before home path"
fi

run_capture "$TMP/scan-after.out" "$TMP/scan-after.err" \
  python3 "$SCRIPT" --scan-table --root "$TMP/work" --json
scan_after_rc=$?
if [[ "$scan_after_rc" -eq 0 ]] && jq -e '.status == "pass" and (.findings | length == 0)' "$TMP/scan-after.out" >/dev/null; then
  pass "post-apply scan clean"
else
  fail "post-apply scan clean rc=${scan_after_rc}"
fi

mkdir -p "$TMP/blocked/.ntm"
printf '{}\n' >"$TMP/blocked/.ntm/rate_limits.json"
printf 'Joshua Nowak\n' >"$TMP/blocked/public.md"
run_capture "$TMP/blocked.out" "$TMP/blocked.err" \
  python3 "$SCRIPT" --dry-run --root "$TMP/blocked" --json
blocked_rc=$?
if [[ "$blocked_rc" -eq 30 ]] && jq -e '.status == "fail" and .exit_code == 30 and (.findings[] | select(.id == "repo-ntm-runtime"))' "$TMP/blocked.out" >/dev/null; then
  pass "denylist blocks codemod"
else
  fail "denylist blocks codemod rc=${blocked_rc}"
fi

if [[ "$FAIL" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$PASS" "$FAIL" >&2
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$PASS"
