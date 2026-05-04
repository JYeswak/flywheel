#!/usr/bin/env bash
set -euo pipefail

blocked=0
allowed=0

expect_block() {
  local name="$1"
  shift
  if dcg test "$*" >/tmp/dcg-secret-leak.out 2>/tmp/dcg-secret-leak.err; then
    printf 'FAIL expected DCG block: %s\n' "$name" >&2
    exit 1
  fi
  grep -q 'Result: BLOCKED' /tmp/dcg-secret-leak.out
  blocked=$((blocked + 1))
}

expect_allow() {
  local name="$1"
  shift
  dcg test "$*" >/tmp/dcg-secret-leak.out 2>/tmp/dcg-secret-leak.err
  grep -q 'Result: ALLOWED' /tmp/dcg-secret-leak.out
  allowed=$((allowed + 1))
}

expect_block "raw list" infisical secrets list --recursive --path=/prod
expect_block "raw get" infisical secrets get SUPABASE_SERVICE_ROLE_KEY
expect_block "plain list" infisical secrets list --silent --plain
expect_block "run" infisical run -- printenv
expect_block "export" infisical export --env=prod
expect_allow "safe wrapper list" /Users/josh/.flywheel/bin/infisical-safe secrets list --silent --output=json '| jq -r ".[].secretKey"'

printf 'dcg secret-leak overrides passed: blocked=%s allowed=%s\n' "$blocked" "$allowed"
