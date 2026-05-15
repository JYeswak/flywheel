#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/tmp-aggressive-prune.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/tmp-prune-doctor.XXXXXX")"
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
    jq . "$file" >&2 || true
  fi
}

fixture_root="$TMP/root"
home="$TMP/home"
mkdir -p "$fixture_root" "$home/.local/state/flywheel"

if bash -n "$SCRIPT"; then
  pass "syntax"
else
  fail "syntax"
fi

HOME="$home" "$SCRIPT" --info >"$TMP/info.json"
assert_jq "$TMP/info.json" '(.canonical_surfaces.introspection | index("doctor")) and (.canonical_surfaces.introspection | index("--doctor")) and .doctor_schema == "tmp-aggressive-prune.doctor.v1"' "info advertises doctor"

HOME="$home" "$SCRIPT" --schema >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.output_modes[] | select(.mode == "doctor" and .schema_version == "tmp-aggressive-prune.doctor.v1")' "schema includes doctor mode"

if HOME="$home" "$SCRIPT" --examples | grep -Fq 'tmp-aggressive-prune.sh doctor --json'; then
  pass "examples include doctor"
else
  fail "examples include doctor"
fi

HOME="$home" "$SCRIPT" doctor --root "$fixture_root" --json >"$TMP/doctor.json"
assert_jq "$TMP/doctor.json" '.schema_version == "tmp-aggressive-prune.doctor.v1" and .command == "doctor" and .status == "pass" and .mode == "read_only" and .mutates == false and (.checks | length == 4)' "doctor read-only pass envelope"

if [[ ! -d "$home/.local/state/flywheel/tmp-prune-receipts" ]]; then
  pass "doctor does not create receipt dir"
else
  fail "doctor does not create receipt dir"
fi

HOME="$home" "$SCRIPT" --doctor --root "$fixture_root" --json >"$TMP/doctor-alias.json"
assert_jq "$TMP/doctor-alias.json" '.command == "doctor" and .mutates == false' "--doctor alias"

HOME="$home" "$SCRIPT" --root "$fixture_root" --json >"$TMP/dry-run.json"
assert_jq "$TMP/dry-run.json" '.status == "ok" and .apply == false and .root == "'"$fixture_root"'"' "dry-run still works"

set +e
HOME="$home" "$SCRIPT" --root "$fixture_root" --apply --json >"$TMP/apply-no-key.out" 2>"$TMP/apply-no-key.err"
rc=$?
set -e
if [[ "$rc" -eq 2 ]] && grep -Fq -- '--apply requires --idempotency-key' "$TMP/apply-no-key.err"; then
  pass "apply without idempotency key refuses"
else
  fail "apply without idempotency key refuses rc=$rc"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
