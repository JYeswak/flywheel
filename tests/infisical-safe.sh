#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WRAPPER="$ROOT/.flywheel/scripts/infisical-safe.sh"

pass=0

expect_block() {
  local name="$1"
  shift
  if INFISICAL_SAFE_DRY_RUN=1 INFISICAL_REAL=/bin/echo "$WRAPPER" "$@" >/tmp/infisical-safe.out 2>/tmp/infisical-safe.err; then
    printf 'FAIL expected block: %s\n' "$name" >&2
    exit 1
  fi
  grep -q 'INFISICAL_SAFE_BLOCKED' /tmp/infisical-safe.err
  pass=$((pass + 1))
}

expect_allow() {
  local name="$1"
  shift
  INFISICAL_SAFE_DRY_RUN=1 INFISICAL_REAL=/bin/echo "$WRAPPER" "$@" >/tmp/infisical-safe.out 2>/tmp/infisical-safe.err
  grep -q 'INFISICAL_SAFE_ALLOW' /tmp/infisical-safe.out
  if grep -Eq 'secretValue|FAKE_|eyJ[A-Za-z0-9_-]{20,}' /tmp/infisical-safe.out /tmp/infisical-safe.err; then
    printf 'FAIL leaked synthetic secret marker: %s\n' "$name" >&2
    exit 1
  fi
  pass=$((pass + 1))
}

expect_block "table secrets list" secrets list --recursive --path=/prod
expect_block "plain secrets list" secrets list --silent --plain
expect_block "secrets get no silent" secrets get SUPABASE_SERVICE_ROLE_KEY
expect_block "infisical run" run --env=prod -- printenv
expect_allow "key-only json list" secrets list --recursive --path=/prod --silent --output=json
expect_allow "silent get for redirected caller" secrets get SUPABASE_URL --silent --output=json
expect_allow "login" login --silent --plain

printf 'infisical-safe tests passed: %s\n' "$pass"
