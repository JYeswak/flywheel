#!/usr/bin/env bash
set -euo pipefail

SCRIPT="${ECOSYSTEM_POLISH_SCRIPT:-$HOME/.claude/skills/ecosystem-polish-scaffold/scripts/apply-to-repo.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ecosystem-polish.XXXXXX")"
STATE="$TMP/state"

cleanup() {
  python3 - "$TMP" <<'PY'
import shutil
import sys
from pathlib import Path
shutil.rmtree(Path(sys.argv[1]), ignore_errors=True)
PY
}
trap cleanup EXIT

repo="$TMP/repo"
mkdir -p "$repo" "$STATE"
git -C "$repo" init -q

HOME="$TMP/home" XDG_STATE_HOME="$STATE" "$SCRIPT" "$repo" \
  --mission "test-anchor" \
  --tech-stack "bash" \
  --apply \
  --idempotency-key "test" \
  > "$TMP/out.json"

for file in README.md ARCHITECTURE.md CONTRIBUTING.md ROADMAP.md SECURITY.md; do
  test -f "$repo/$file"
done

for file in \
  .github/ISSUE_TEMPLATE/bug.md \
  .github/ISSUE_TEMPLATE/feature.md \
  .github/ISSUE_TEMPLATE/trauma.md \
  .github/PULL_REQUEST_TEMPLATE.md; do
  test -f "$repo/$file"
done

grep -Fxq 'AGENTS.md.bak.*' "$repo/.gitignore"
grep -Fxq '.beads.bak.*' "$repo/.gitignore"
grep -Fxq '.beads.failed.*' "$repo/.gitignore"
grep -Fxq '.git-archive/' "$repo/.gitignore"
grep -Fxq '.git-archive/*' "$repo/.gitignore"
grep -Fxq '.flywheel/.STATE.md.preview.*' "$repo/.gitignore"

receipt_path="$(jq -r '.receipt_path' "$TMP/out.json")"
test -f "$receipt_path"
jq -e '.row.mode == "apply" and .row.idempotency_key == "test" and .row.mission_anchor == "test-anchor"' "$TMP/out.json" >/dev/null

jsonl="$(dirname "$receipt_path")/receipts.jsonl"
test -f "$jsonl"
tail -1 "$jsonl" | jq -e '.schema_version == "ecosystem-polish-scaffold/receipt/v1"' >/dev/null

printf 'OK ecosystem polish scaffold applies docs templates gitignore and receipt\n'
