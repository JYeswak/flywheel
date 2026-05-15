#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/sync-canonical-doctrine.sh"

pass=0
fail=0
p() { pass=$((pass + 1)); printf 'PASS %s\n' "$1"; }
f() { fail=$((fail + 1)); printf 'FAIL %s\n' "$1" >&2; }

if bash -n "$SCRIPT"; then
  p "syntax"
else
  f "syntax"
fi

if "$SCRIPT" doctor --json | jq -e '
  .schema_version == "sync-canonical-doctrine.doctor.v1"
  and .command == "doctor"
  and .mode == "read_only"
  and .mutates == false
  and (.status | IN("pass","warn","fail"))
  and (.checks | length) >= 6
  and (.checks | all(.name and (.status | IN("pass","warn","fail"))))
' >/dev/null; then
  p "doctor emits read-only checks"
else
  f "doctor read-only envelope"
fi

if "$SCRIPT" --doctor --json | jq -e '.command == "doctor" and .mutates == false' >/dev/null; then
  p "--doctor aliases doctor"
else
  f "--doctor alias"
fi

if "$SCRIPT" --info | jq -e '(.flags | index("doctor")) != null and (.flags | index("--doctor")) != null' >/dev/null; then
  p "info lists doctor flags"
else
  f "info doctor flags"
fi

if "$SCRIPT" --examples | grep -Fq "doctor --json"; then
  p "examples include doctor"
else
  f "examples doctor"
fi

if "$SCRIPT" --help | grep -Fq "doctor|--doctor"; then
  p "help includes doctor"
else
  f "help doctor"
fi

if [[ "$fail" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail" >&2
  exit 1
fi
printf 'SUMMARY pass=%d fail=0\n' "$pass"
