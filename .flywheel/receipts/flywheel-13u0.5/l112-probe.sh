#!/usr/bin/env bash
set -euo pipefail

repo="/Users/josh/Developer/flywheel"
pack="$repo/.flywheel/audit/flywheel-13u0.5/compliance-pack.md"

cd "$repo"

br show flywheel-7rr --json \
  | jq -e '.[0].status == "closed" and (.[0].title | test("Canonicalize br create source_repo"))' >/dev/null

br show flywheel-5ktw --json \
  | jq -e '.[0].status == "closed" and (.[0].external_ref == "https://github.com/Dicklesworthstone/beads_rust/issues/273") and (.[0].close_reason | test("Jeff fixed beads_rust#273"))' >/dev/null

br show flywheel-f505 --json \
  | jq -e '.[0].status == "closed" and (.[0].close_reason | test("source_repo"))' >/dev/null

br show flywheel-ap9n --json \
  | jq -e '.[0].status == "closed" and (.[0].close_reason | test("zero hits|no longer recurring"))' >/dev/null

grep -Fq 'Decision: merge into existing follow-up bead `flywheel-13u0.5`' .flywheel/audit/flywheel-13u0.4/disposition.md

grep -Fq 'Decision for the exact class `br-source-repo-dot-after-create`: `no_followup_needed`.' "$pack"
grep -Fq 'Do not add a separate local `INCIDENTS.md` entry' "$pack"
grep -Fq 'T2.4 found current `br create` writes a non-absolute basename value' "$pack"

printf 'pass\n'
