#!/usr/bin/env bash
set -euo pipefail

ROW_ID="jr-2026-05-18T190016Z-816"
MISSION=".flywheel/MISSION.md"
ARCHIVE=".flywheel/josh-requests-archive/2026-05.md"

if [[ -n "$(git status --short -- "$MISSION")" ]]; then
  echo "FAIL mission dirty" >&2
  git status --short -- "$MISSION" >&2
  exit 1
fi

if rg -q "$ROW_ID" "$MISSION"; then
  echo "FAIL row still present in MISSION" >&2
  exit 1
fi

rg -q "$ROW_ID" "$ARCHIVE"
git diff --cached --quiet -- "$MISSION"
bash tests/josh-request-capture-archive.sh >/tmp/flywheel-m7ywp-josh-request-archive-test.out

printf 'PASS flywheel-m7ywp l112-probe\n'
