#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
CMD="/Users/josh/.claude/commands/flywheel/adopt.md"
HELPER="$ROOT/.flywheel/scripts/flywheel-adopt.sh"
TMPDIR="$(mktemp -d -t zih9.XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

test -f "$CMD" || fail "missing adopt command"
test -x "$HELPER" || fail "missing executable adopt helper"

rg -n "flywheel:adopt|--dry-run|--first-run-audit|--start-loop|--reconcile|INCIDENTS.md|substrate-registry|skill catalog" \
  "$CMD" "$HELPER" "$ROOT/tests" >/dev/null

for step in 0 1 2 3 4 5 6 7 8 9 10 11; do
  rg -q "STEP $step" "$CMD" || fail "missing STEP $step"
done

for flag in --json --dry-run --first-run-audit --start-loop --reconcile; do
  rg -q -- "$flag" "$CMD" || fail "missing flag $flag"
done

rg -q "Dry-run is the default" "$CMD" || fail "default safe mode not documented"
rg -q -- "--apply.*requires.*--idempotency-key|--idempotency-key.*Required" "$CMD" \
  || fail "explicit mutation guard not documented"

repo="$TMPDIR/legacy-repo"
mkdir -p "$repo"
git -C "$repo" init -q
export FLYWHEEL_SUBSTRATE_REGISTRY="$TMPDIR/substrate-registry.jsonl"
cat > "$repo/AGENTS.md" <<'EOF'
# Legacy Agent Notes
EOF

before="$(find "$repo" -maxdepth 3 -type f | sort)"
dry_json="$TMPDIR/dry.json"
"$HELPER" --repo "$repo" --dry-run --json > "$dry_json"
after="$(find "$repo" -maxdepth 3 -type f | sort)"
[ "$before" = "$after" ] || fail "dry-run modified legacy repo"

python3 - "$dry_json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
assert data["schema_version"] == "flywheel-adopt/v1"
assert data["command"] == "flywheel:adopt"
assert data["dry_run"] is True
assert data["counts"]["ready"] >= 0
assert data["counts"]["missing"] >= 1
assert data["counts"]["drifted"] >= 0
PY

if "$HELPER" --repo "$repo" --apply --json >"$TMPDIR/apply-without-key.out" 2>"$TMPDIR/apply-without-key.err"; then
  fail "apply without idempotency key succeeded"
fi
rg -q "adopt_apply_requires_idempotency_key" "$TMPDIR/apply-without-key.err" \
  || fail "apply guard reason missing"

apply_json="$TMPDIR/apply.json"
"$HELPER" --repo "$repo" --apply --idempotency-key test-zih9 --json > "$apply_json"

test -d "$repo/.flywheel" || fail "apply did not create .flywheel"
test -f "$repo/.flywheel/AGENTS-CANONICAL.md" || fail "apply did not create canonical doctrine"
test -f "$repo/INCIDENTS.md" || fail "apply did not create INCIDENTS scaffold"
test -f "$repo/.flywheel/install-log.jsonl" || fail "apply did not create install receipt"

python3 - "$apply_json" "$repo/.flywheel/install-log.jsonl" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
receipt = json.loads(open(sys.argv[2], encoding="utf-8").read().strip().splitlines()[-1])
assert data["status"] == "applied"
assert data["beads_db_health"]["repair_path_invoked"] is False
for key in ["findings", "fixed", "registered", "audited", "orchestrator_session", "next_operator_action"]:
    assert key in receipt
PY

loop_json="$TMPDIR/loop.json"
"$HELPER" --repo "$repo" --dry-run --json --start-loop > "$loop_json"
python3 - "$loop_json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
assert "flywheel-loop start" in data["planned_loop_start"]
assert "--dry-run" in data["planned_loop_start"]
PY

echo "flywheel adopt command contract fixture passes"
