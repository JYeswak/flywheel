#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d -t ntm-lock-contract.XXXXXX)"

cleanup() {
  find "$TMP" -type f -delete 2>/dev/null || true
  find "$TMP" -depth -type d -empty -delete 2>/dev/null || true
}
trap cleanup EXIT

stdout="$TMP/stdout.json"
stderr="$TMP/stderr.txt"
lock_path="tests/ntm-lock-contract-fixture.txt"

set +e
AGENT_MAIL_URL="http://127.0.0.1:1/mcp/" \
AGENT_MAIL_TOKEN="fixture-token" \
  ntm lock flywheel "$lock_path" --reason "errJSONFailure contract smoke" --ttl 1m --json \
  >"$stdout" 2>"$stderr"
rc=$?
set -e

if [[ "$rc" -eq 0 ]]; then
  printf 'FAIL: ntm lock failure returned exit 0\n' >&2
  exit 1
fi

jq -e '.success == false and (.error // "" | length > 0)' "$stdout" >/dev/null

if grep -q '^Error:' "$stderr"; then
  printf 'FAIL: stderr contained decorated Error line\n' >&2
  cat "$stderr" >&2
  exit 1
fi

printf 'PASS ntm_lock_failure_contract rc=%s\n' "$rc"
