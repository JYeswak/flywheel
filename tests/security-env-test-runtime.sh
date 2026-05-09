#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
FIXTURES="$ROOT/tests/fixtures/security-env-test-runtime"
RUNTIME_FIXTURE="$FIXTURES/runtime-failure-fixture.sh"
RECEIPT="$ROOT/.flywheel/security/v1/env-test-migration-receipt.json"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/security-env-test-runtime.XXXXXX")"
export TMP

cleanup() {
  python3 - <<'PY'
import os
import shutil
from pathlib import Path

tmp = os.environ.get("TMP")
if tmp:
    shutil.rmtree(Path(tmp), ignore_errors=True)
PY
}
trap cleanup EXIT HUP INT TERM

pass_count=0
fail_count=0

pass() {
  printf 'PASS %s\n' "$1"
  pass_count=$((pass_count + 1))
}

fail() {
  printf 'FAIL %s\n' "$1" >&2
  fail_count=$((fail_count + 1))
}

need() {
  command -v "$1" >/dev/null 2>&1 || {
    printf 'FAIL missing dependency: %s\n' "$1" >&2
    exit 1
  }
}

assert_file_clean_of_values() {
  output_file="$1"
  shift
  for raw in "$@"; do
    if grep -Fq "$raw" "$output_file"; then
      fail "runtime output leaked raw fixture value"
      sed 's/^/  /' "$output_file" >&2
      exit 1
    fi
  done
}

validate_env_test() {
  env_file="$1"
  findings="$2"
  : >"$findings"

  line_no=0
  while IFS= read -r line || [ -n "$line" ]; do
    line_no=$((line_no + 1))
    case "$line" in
      ""|\#*) continue ;;
    esac

    synthetic=false
    case "$line" in
      *"# synthetic-ok"*|*"=CANARY_TEST_"*|*"=FIXTURE_"*|*"=SYNTHETIC_"*|*"=EXAMPLE_"*) synthetic=true ;;
    esac

    if [ "$synthetic" = true ]; then
      continue
    fi

    if printf '%s\n' "$line" | grep -Eq 'sk_live_'; then
      printf 'line=%s class=openai_live_secret\n' "$line_no" >>"$findings"
    fi
    if printf '%s\n' "$line" | grep -Eq 'AKIA[0-9A-Z]{16}'; then
      printf 'line=%s class=aws_access_key_id\n' "$line_no" >>"$findings"
    fi
    if printf '%s\n' "$line" | grep -Eq 'BEGIN PRIVATE KEY|END PRIVATE KEY'; then
      printf 'line=%s class=private_key_pem\n' "$line_no" >>"$findings"
    fi
    if printf '%s\n' "$line" | grep -Eq 'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'; then
      printf 'line=%s class=jwt\n' "$line_no" >>"$findings"
    fi
  done <"$env_file"

  test ! -s "$findings"
}

expect_env_pass() {
  name="$1"
  file="$2"
  if validate_env_test "$file" "$TMP/$name.findings"; then
    pass "$name"
  else
    fail "$name should pass"
    cat "$TMP/$name.findings" >&2
    exit 1
  fi
}

expect_env_fail_class() {
  name="$1"
  file="$2"
  expected="$3"
  if validate_env_test "$file" "$TMP/$name.findings"; then
    fail "$name should fail"
    exit 1
  fi
  if grep -Fxq "line=1 class=$expected" "$TMP/$name.findings"; then
    pass "$name"
  else
    fail "$name expected class $expected"
    cat "$TMP/$name.findings" >&2
    exit 1
  fi
}

need jq

bash -n "$0"
bash -n "$RUNTIME_FIXTURE"
test -s "$FIXTURES/synthetic/.env.test" || {
  printf 'FAIL missing synthetic .env.test fixture\n' >&2
  exit 1
}

expect_env_pass "synthetic_env_test_fixture_passes" "$FIXTURES/synthetic/.env.test"

suffix="abcdefghijklmnopqrstuvwxyz123456"
aws_tail="1234567890ABCDEF"
jwt_value="eyJ${suffix}.eyJpayloadfixture123.signaturefixture123"
private_begin="-----BEGIN "
private_end="-----END "

printf 'OPENAI_API_KEY=%s\n' "sk_live_${suffix}" >"$TMP/openai.env.test"
expect_env_fail_class "live_openai_shape_fails" "$TMP/openai.env.test" "openai_live_secret"

printf 'AWS_ACCESS_KEY_ID=%s\n' "AKIA${aws_tail}" >"$TMP/aws.env.test"
expect_env_fail_class "live_aws_shape_fails" "$TMP/aws.env.test" "aws_access_key_id"

printf 'PRIVATE_KEY=%sPRIVATE KEY-----fixture%sPRIVATE KEY-----\n' "$private_begin" "$private_end" >"$TMP/private-key.env.test"
expect_env_fail_class "private_key_shape_fails" "$TMP/private-key.env.test" "private_key_pem"

printf 'SESSION_JWT=%s\n' "$jwt_value" >"$TMP/jwt.env.test"
expect_env_fail_class "jwt_shape_fails" "$TMP/jwt.env.test" "jwt"

printf 'OPENAI_API_KEY=%s # synthetic-ok\n' "sk_live_${suffix}" >"$TMP/marked-synthetic.env.test"
expect_env_pass "explicit_synthetic_live_shape_passes" "$TMP/marked-synthetic.env.test"

runtime_env="$TMP/runtime.env.test"
{
  printf 'OPENAI_API_KEY=%s\n' "sk_live_${suffix}"
  printf 'AWS_ACCESS_KEY_ID=%s\n' "AKIA${aws_tail}"
  printf 'SESSION_JWT=%s\n' "$jwt_value"
} >"$runtime_env"

set +e
"$RUNTIME_FIXTURE" "$runtime_env" >"$TMP/runtime.out" 2>"$TMP/runtime.err"
runtime_rc=$?
set -e
test "$runtime_rc" -eq 1 || {
  fail "runtime fixture should fail with rc=1"
  exit 1
}
cat "$TMP/runtime.out" "$TMP/runtime.err" >"$TMP/runtime.combined"
assert_file_clean_of_values "$TMP/runtime.combined" "sk_live_${suffix}" "AKIA${aws_tail}" "$jwt_value"
grep -q '\[REDACTED:runtime_secret\]' "$TMP/runtime.combined" || {
  fail "runtime fixture did not redact output"
  cat "$TMP/runtime.combined" >&2
  exit 1
}
pass "runtime_failure_fixture_redacts_raw_values"

jq -e '
  .schema_version == "security-env-test-migration-receipt/v1"
  and .secret_values_recorded == false
  and (.checks | length >= 1)
  and all(.checks[]; has("repo") and ((.status == "migration_not_required") or has("blocked_by") or has("migration_receipt")))
' "$RECEIPT" >/dev/null || {
  fail "migration receipt shape"
  jq . "$RECEIPT" >&2 || true
  exit 1
}
pass "prod_env_repos_have_migration_receipt_or_blocked_by"

if grep -Eq 'sk_live_|AKIA[0-9A-Z]{16}|BEGIN PRIVATE KEY|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}' "$RECEIPT"; then
  fail "migration receipt contains live-shaped secret material"
  exit 1
fi
pass "migration_receipt_has_no_live_shapes"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
test "$fail_count" -eq 0
