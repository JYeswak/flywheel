#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/repo-hygiene-check.sh"
TEMPLATE="$ROOT/templates/flywheel-install/scripts/repo-hygiene-check.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/repo-hygiene-doctor.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || cat "$file" >&2
  fi
}

mkdir -p "$TMP/repo/.flywheel/doctrine"
(
  cd "$TMP/repo"
  git init -q
  git config user.email test@example.com
  git config user.name test
  printf 'hygiene fixture\n' >README.md
  printf 'doctrine fixture\n' >.flywheel/doctrine/repo-hygiene-operational-protocol.md
  git add README.md .flywheel/doctrine/repo-hygiene-operational-protocol.md
  git commit -q -m init
)

for bin in "$SCRIPT" "$TEMPLATE"; do
  name="$(basename "$(dirname "$(dirname "$bin")")")/$(basename "$bin")"
  if bash -n "$bin"; then
    pass "$name syntax"
  else
    fail "$name syntax"
  fi

  "$bin" doctor --repo "$TMP/repo" --json >"$TMP/doctor.json"
  assert_jq "$TMP/doctor.json" '
    .schema == "flywheel.repo_hygiene_check.doctor.v1"
    and .command == "doctor"
    and .mode == "read_only"
    and .mutates == false
    and .status == "pass"
    and ([.checks[] | select(.name == "doctor_read_only").status][0] == "pass")
    and ([.checks[] | select(.name == "cleanup_not_embedded").status][0] == "pass")
  ' "$name doctor emits read-only pass envelope"

  "$bin" --doctor --repo "$TMP/repo" --json >"$TMP/doctor-alias.json"
  assert_jq "$TMP/doctor-alias.json" '.command == "doctor" and .mutates == false' "$name --doctor alias"

  missing="$TMP/missing-repo"
  if "$bin" doctor --repo "$missing" --json >"$TMP/missing.json" 2>/dev/null; then
    fail "$name missing repo exits nonzero"
  else
    assert_jq "$TMP/missing.json" '.status == "fail" and ([.checks[] | select(.name == "repo_directory_readable").status][0] == "fail")' "$name missing repo fails cleanly"
  fi
done

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
