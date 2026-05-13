#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/state-md-miner.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/state-md-miner-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

make_repo() {
  local name="$1"
  local repo="$TMP/$name"
  mkdir -p "$repo/.flywheel" "$repo/.beads"
  git -C "$repo" init -q >/dev/null 2>&1
  (cd "$repo" && br init --prefix "$name" --json >/dev/null)
  printf '%s\n' "$repo"
}

repo1="$(make_repo r1)"
repo2="$(make_repo r2)"
repo3="$(make_repo r3)"

cat >"$repo1/.flywheel/STATE.md" <<'EOF'
# State

## Next Actions

- Add callback validation surface to README.

## Known Gaps

- Missing doctor signal for callback validation.

## Deferred

- 2026-04-01 revisit stale queue drain.
EOF

cat >"$repo2/.flywheel/STATE.md" <<'EOF'
# State

## Known Gaps

- Missing doctor signal for callback validation.
- Existing bead covered by flywheel-abcd.
EOF

cat >"$repo3/STATE.md" <<'EOF'
# State

## Known Gaps

- Missing doctor signal for callback validation.
EOF

roster="$TMP/fleet-roster.json"
jq -nc \
  --arg r1 "$repo1" \
  --arg r2 "$repo2" \
  --arg r3 "$repo3" \
  '{members:[{name:"r1",repo:$r1},{name:"r2",repo:$r2},{name:"r3",repo:$r3}]}' >"$roster"

dry="$TMP/dry.json"
"$SCRIPT" --roster "$roster" --state-dir "$TMP/state" --now 2026-05-04T00:00:00Z --dry-run --json >"$dry"
jq -e '.schema_version == "state-md-miner/v1"' "$dry" >/dev/null || fail "schema version missing"
jq -e '.findings_count >= 5' "$dry" >/dev/null || fail "expected at least five findings"
jq -e '.class_counts.pattern >= 3' "$dry" >/dev/null || fail "expected cross-repo pattern class"
jq -e 'any(.findings[]; .class == "stale")' "$dry" >/dev/null || fail "expected stale finding"
jq -e 'any(.decisions[]; .decision == "existing_bead_reference")' "$dry" >/dev/null || fail "expected existing bead no-action decision"

apply="$TMP/apply.json"
"$SCRIPT" --roster "$roster" --state-dir "$TMP/state" --now 2026-05-04T00:05:00Z --apply --max-beads-per-repo 1 --json >"$apply"
jq -e '.decisions | any(.decision == "bead_filed_or_existing")' "$apply" >/dev/null || fail "expected bead filing"
jq -e '.decisions | any(.no_bead_reason == "daily_auto_bead_cap_exceeded")' "$apply" >/dev/null || fail "expected cap no-bead reason"
test -s "$TMP/state/decisions.jsonl" || fail "decision ledger missing"
test -s "$TMP/state/latest.json" || fail "latest digest missing"

doctor="$TMP/doctor.json"
"$SCRIPT" --roster "$roster" --state-dir "$TMP/state" --now 2026-05-04T00:10:00Z --doctor --json >"$doctor"
jq -e '.state_md_findings_count >= 5 and .state_md_unmined_count == 0 and .state_md_mined_count == .state_md_findings_count and .state_md_last_run_age_hours == 0.08' "$doctor" >/dev/null || fail "doctor signal missing mined decision accounting"
jq -e '.status == "pass"' "$doctor" >/dev/null || fail "doctor should pass when all current findings have applied decisions"

echo "PASS state-md-miner dry-run apply cap existing-bead pattern stale doctor"
