#!/usr/bin/env bash
# Canonical receiver for .flywheel/scripts/canonical-doctrine-sync.sh.
# This is the alias surface for sync-canonical-doctrine.sh; the test keeps the
# alias visible to gap-hunt without mutating fleet doctrine surfaces.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/canonical-doctrine-sync.sh"
TARGET="$ROOT/.flywheel/scripts/sync-canonical-doctrine.sh"
TMP="$(mktemp -d -t canonical-doctrine-sync-test.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
p() { pass=$((pass + 1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail + 1)); printf 'FAIL %s\n' "$1" >&2; }

if [[ -x "$SCRIPT" ]] && bash -n "$SCRIPT"; then
  p "alias exists and syntax-checks"
else
  f "alias missing or syntax-broken"
fi

if "$SCRIPT" --info-alias >"$TMP/alias.json"; then
  p "--info-alias exits 0"
else
  f "--info-alias failed"
fi

if jq -e --arg target "$TARGET" '
  .name == "canonical-doctrine-sync.sh"
  and .alias_for == $target
  and .authored_by == "flywheel-rhdcq.2"
' "$TMP/alias.json" >/dev/null; then
  p "--info-alias reports target relationship"
else
  f "--info-alias envelope mismatch"
fi

if "$SCRIPT" doctor --json >"$TMP/doctor.json" 2>"$TMP/doctor.err"; then
  p "doctor exits 0"
else
  f "doctor failed"
fi

if jq -e --arg target "$TARGET" '
  .schema_version == "canonical-doctrine-sync.doctor.v1"
  and .command == "doctor"
  and .name == "canonical-doctrine-sync.sh"
  and .alias_for == $target
  and .delegated_schema_version == "sync-canonical-doctrine.doctor.v1"
  and .mode == "read_only"
  and .mutates == false
  and (.status | IN("pass","warn","fail"))
  and (.checks | length) >= 6
' "$TMP/doctor.json" >/dev/null; then
  p "doctor emits alias read-only envelope"
else
  f "doctor envelope mismatch"
fi

if "$SCRIPT" --doctor --json | jq -e '.command == "doctor" and .mutates == false' >/dev/null; then
  p "--doctor aliases doctor"
else
  f "--doctor alias"
fi

if "$SCRIPT" --info >"$TMP/passthrough-info.json" 2>"$TMP/passthrough-info.err"; then
  p "--info passthrough exits 0"
else
  f "--info passthrough failed"
fi

if jq -e '
  .schema_version == "tool-info/v1"
  and .name == "sync-canonical-doctrine.sh"
' "$TMP/passthrough-info.json" >/dev/null; then
  p "--info passthrough delegates to sync-canonical-doctrine.sh"
else
  f "--info passthrough did not delegate"
fi

if CANONICAL_DOCTRINE_SYNC_TARGET="$TMP/missing-target.sh" "$SCRIPT" --info >"$TMP/missing.out" 2>"$TMP/missing.err"; then
  f "missing target unexpectedly succeeded"
else
  rc=$?
  if [[ "$rc" -eq 2 ]] && grep -Fq "target not executable" "$TMP/missing.err"; then
    p "missing target fails closed with rc=2"
  else
    f "missing target failure contract drifted rc=$rc"
  fi
fi

if [[ "$fail" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass"
