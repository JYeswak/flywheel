#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/sync-four-lens-validator.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/four-lens-sync-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

need() {
  command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

need jq
[ -x "$SCRIPT" ] || fail "sync script not executable"

repo1="$TMP/one"
repo2="$TMP/two"
mkdir -p "$repo1" "$repo2"

set +e
"$SCRIPT" --repo "$repo1" --repo "$repo2" --dry-run --json >"$TMP/dry.json"
dry_rc=$?
set -e
[ "$dry_rc" -eq 1 ] || fail "dry-run should report missing validators"
jq -e '.mode == "dry-run" and .all_executable == false and .total == 2' "$TMP/dry.json" >/dev/null || fail "dry-run json shape wrong"

"$SCRIPT" --repo "$repo1" --repo "$repo2" --apply --json >"$TMP/apply.json"
jq -e '.mode == "apply" and .all_executable == true and .synced == 2' "$TMP/apply.json" >/dev/null || fail "apply json shape wrong"
[ -x "$repo1/.flywheel/scripts/validate-callback-before-close.sh" ] || fail "repo1 validator missing"
[ -x "$repo2/.flywheel/scripts/validate-callback-before-close.sh" ] || fail "repo2 validator missing"

"$SCRIPT" --repo "$repo1" --repo "$repo2" --audit --json >"$TMP/audit.json"
jq -e '.mode == "audit" and .all_executable == true and .present == 2' "$TMP/audit.json" >/dev/null || fail "audit json shape wrong"

"$SCRIPT" --help >/dev/null
"$SCRIPT" --version >/dev/null

echo "PASS: sync-four-lens-validator"
