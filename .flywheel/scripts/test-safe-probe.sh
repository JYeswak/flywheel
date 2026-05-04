#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SAFE_PROBE="$SCRIPT_DIR/safe-probe.sh"

command -v rg >/dev/null 2>&1 || {
  printf 'SKIP: rg is required for safe-probe regression\n' >&2
  exit 77
}

tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/secret-safe-test.XXXXXX")"
captures="$(mktemp -d "${TMPDIR:-/tmp}/secret-safe-captures.XXXXXX")"
trap 'rm -rf "$tmp_root" "$captures"' EXIT HUP INT TERM

fake_github="FAKE_GITHUB_TOKEN_1234567890"
fake_infisical="FAKE_INFISICAL_CACHE_VALUE_1234567890"

mkdir -p "$tmp_root/normal-docs" "$tmp_root/.opencode/secrets" "$tmp_root/.config/infisical"
printf 'normal docs mention safe probe and token names only\n' > "$tmp_root/normal-docs/README.md"
printf 'GITHUB_TOKEN=%s\n' "$fake_github" > "$tmp_root/.opencode/secrets/infisical-cache.env"
printf 'INFISICAL_TOKEN=%s\n' "$fake_infisical" > "$tmp_root/.config/infisical/cubcloud-cache.env"
printf 'credential helper body: %s\n' "$fake_github" > "$tmp_root/credential-helper-output.txt"

assert_no_fake_output() {
  local file="$1"
  if grep -Fq "$fake_github" "$file" || grep -Fq "$fake_infisical" "$file"; then
    printf 'FAIL: fake token leaked in %s\n' "$file" >&2
    exit 1
  fi
}

run_expect_rc() {
  local name="$1"
  local expected="$2"
  shift 2
  local out="$captures/$name.out"
  local err="$captures/$name.err"
  local rc

  set +e
  "$@" >"$out" 2>"$err"
  rc=$?
  set -e

  assert_no_fake_output "$out"
  assert_no_fake_output "$err"

  if [ "$rc" -ne "$expected" ]; then
    printf 'FAIL: %s rc=%s expected=%s\n' "$name" "$rc" "$expected" >&2
    printf 'stderr:\n' >&2
    sed 's/^/  /' "$err" >&2
    exit 1
  fi

  printf 'PASS: %s rc=%s\n' "$name" "$rc"
}

run_expect_rc "blocked-tree-rg" 2 "$SAFE_PROBE" rg FAKE "$tmp_root"
run_expect_rc "safe-rg" 0 "$SAFE_PROBE" rg "safe probe" "$tmp_root/normal-docs"
run_expect_rc "blocked-credential-file" 2 "$SAFE_PROBE" cat "$tmp_root/credential-helper-output.txt"
run_expect_rc "blocked-env-command" 2 env FAKE_TEST_TOKEN="$fake_github" "$SAFE_PROBE" env
run_expect_rc "blocked-gh-auth-token" 2 "$SAFE_PROBE" gh auth token
run_expect_rc "env-names" 0 env FAKE_TEST_TOKEN="$fake_github" INFISICAL_CACHE_VALUE="$fake_infisical" "$SAFE_PROBE" env-names
run_expect_rc "has-env" 0 env GITHUB_TOKEN="$fake_github" "$SAFE_PROBE" has-env GITHUB_TOKEN

grep -q '^FAKE_TEST_TOKEN=SET$' "$captures/env-names.out" || {
  printf 'FAIL: env-names did not report FAKE_TEST_TOKEN status\n' >&2
  exit 1
}

grep -q '^GITHUB_TOKEN=SET$' "$captures/has-env.out" || {
  printf 'FAIL: has-env did not report GITHUB_TOKEN status\n' >&2
  exit 1
}

printf 'PASS: safe-probe synthetic regression complete\n'
