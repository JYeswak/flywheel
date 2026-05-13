#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/private-tmp-prune.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/private-tmp-prune-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }
assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi
}

mkdir -p \
  "$TMP/bin" \
  "$TMP/target/jsm-auth-isolation.old" \
  "$TMP/target/{proof-product}-L4-validate" \
  "$TMP/target/{proof-product}-next-stale-3u48-negative-test" \
  "$TMP/target/{proof-product}-e12-build-faeee5f.19kFkX" \
  "$TMP/target/{proof-product}-3dpx27-check" \
  "$TMP/target/{proof-product}-active-validate" \
  "$TMP/target/ordinary-dir"
printf 'x\n' >"$TMP/target/jsm-auth-isolation.old/payload"
printf 'x\n' >"$TMP/target/{proof-product}-L4-validate/payload"
printf 'x\n' >"$TMP/target/{proof-product}-next-stale-3u48-negative-test/payload"
printf 'x\n' >"$TMP/target/{proof-product}-e12-build-faeee5f.19kFkX/payload"
printf 'x\n' >"$TMP/target/{proof-product}-3dpx27-check/payload"
touch -t 202001010101 \
  "$TMP/target/jsm-auth-isolation.old" \
  "$TMP/target/{proof-product}-L4-validate" \
  "$TMP/target/{proof-product}-next-stale-3u48-negative-test" \
  "$TMP/target/{proof-product}-e12-build-faeee5f.19kFkX" \
  "$TMP/target/{proof-product}-3dpx27-check"

cat >"$TMP/bin/ntm" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$NTM_CALLS"
case "$*" in
  cleanup\ --dry-run\ --max-age\ 1\ --json)
    jq -nc --arg tmp "${TMPDIR:-}" '{dry_run:true,max_age_hours:1,total_files:1,deleted_files:1,results:[{path:($tmp + "/ntm-prompt-fixture.md"),pattern:"ntm-prompt-*.md",deleted:false}]}' ;;
  cleanup\ --max-age\ 1\ --json)
    jq -nc '{dry_run:false,max_age_hours:1,total_files:1,deleted_files:1,results:[{path:"ntm-prompt-fixture.md",pattern:"ntm-prompt-*.md",deleted:true}]}' ;;
  *) exit 2 ;;
esac
SH
chmod +x "$TMP/bin/ntm"

export NTM_CALLS="$TMP/ntm.calls"
bash -n "$SCRIPT" && pass "script syntax" || fail "script syntax"

PATH="$TMP/bin:$PATH" "$SCRIPT" --dry-run --json --target "$TMP/target" --min-age-hours 1 >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.schema_version == "private-tmp-prune.v2" and .split_contract.ntm_temp_cleanup == "ntm cleanup"' "schema records split cleanup contract"
assert_jq "$TMP/dry.json" '.ntm_cleanup.total_files == 1 and .flywheel_candidates_count == 5 and any(.flywheel_candidates[]; .path | test("{proof-product}-L4-validate")) and any(.flywheel_candidates[]; .path | test("{proof-product}-next-stale")) and any(.flywheel_candidates[]; .path | test("{proof-product}-e12-build")) and any(.flywheel_candidates[]; .path | test("{proof-product}-3dpx27-check")) and any(.flywheel_candidates[]; .path | test("jsm-auth-isolation"))' "dry-run includes targeted {proof-product} validation roots"
grep -qx 'cleanup --dry-run --max-age 1 --json' "$NTM_CALLS" && pass "dry-run delegates ntm cleanup" || fail "dry-run delegates ntm cleanup"
test -d "$TMP/target/jsm-auth-isolation.old" && pass "dry-run does not delete flywheel candidate" || fail "dry-run does not delete flywheel candidate"
test -d "$TMP/target/{proof-product}-active-validate" && pass "dry-run leaves too-young {proof-product} candidate" || fail "dry-run leaves too-young {proof-product} candidate"

set +e
PATH="$TMP/bin:$PATH" "$SCRIPT" --apply --json --target "$TMP/target" --min-age-hours 1 >"$TMP/apply-no-key.json" 2>"$TMP/apply-no-key.err"
no_key_rc=$?
set -e
[ "$no_key_rc" -eq 2 ] && grep -q -- '--apply requires --idempotency-key' "$TMP/apply-no-key.err" && pass "apply requires idempotency key" || fail "apply requires idempotency key"

PATH="$TMP/bin:$PATH" "$SCRIPT" --apply --idempotency-key test-private-tmp --json --target "$TMP/target" --min-age-hours 1 >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.ntm_cleanup.dry_run == false and .apply == true' "apply calls mutating ntm cleanup path"
grep -qx 'cleanup --max-age 1 --json' "$NTM_CALLS" && pass "apply delegates mutating ntm cleanup" || fail "apply delegates mutating ntm cleanup"
test ! -e "$TMP/target/jsm-auth-isolation.old" && pass "apply removes flywheel allowlisted candidate" || fail "apply removes flywheel allowlisted candidate"
test ! -e "$TMP/target/{proof-product}-L4-validate" && pass "apply removes {proof-product} validation candidate" || fail "apply removes {proof-product} validation candidate"
test ! -e "$TMP/target/{proof-product}-next-stale-3u48-negative-test" && pass "apply removes {proof-product} stale candidate" || fail "apply removes {proof-product} stale candidate"
test -d "$TMP/target/ordinary-dir" && pass "apply leaves non-allowlisted dir" || fail "apply leaves non-allowlisted dir"
test -d "$TMP/target/{proof-product}-active-validate" && pass "apply leaves too-young {proof-product} candidate" || fail "apply leaves too-young {proof-product} candidate"

if [ "$fail_count" -gt 0 ]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
