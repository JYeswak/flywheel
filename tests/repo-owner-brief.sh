#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/repo-owner-brief.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

require_file() {
  local rel="$1"
  if [[ -s "$ROOT/$rel" ]]; then
    pass "file exists: $rel"
  else
    fail "file exists: $rel"
  fi
}

require_file "scripts/render_repo_owner_brief.py"
require_file "docs/evidence/flywheel-owner-brief.json"
require_file "docs/stories/flywheel-owner-brief.md"

if python3 "$ROOT/scripts/render_repo_owner_brief.py" \
  --story-json "$ROOT/docs/evidence/flywheel-trajectory.json" \
  --write-json "$TMP/owner-brief.json" \
  --write-md "$TMP/owner-brief.md"; then
  pass "owner brief renderer runs"
else
  fail "owner brief renderer runs"
fi

if python3 - "$TMP/owner-brief.json" "$ROOT/docs/evidence/flywheel-owner-brief.json" <<'PY'
import json
import sys
from pathlib import Path

for raw_path in sys.argv[1:]:
    data = json.loads(Path(raw_path).read_text(encoding="utf-8"))
    if data.get("schema_version") != "zeststream.repo_owner_story_brief.v0":
        raise SystemExit("schema mismatch")
    if data.get("source_story_schema") != "zeststream.repo_git_story.v0":
        raise SystemExit("source story schema mismatch")
    if data.get("source_message_schema") != "zeststream.repo_story_message.v0":
        raise SystemExit("source message schema mismatch")
    if data.get("source_frontend_schema") != "zeststream.repo_frontend_story.v0":
        raise SystemExit("source frontend schema mismatch")
    if data.get("headline") != "Buy back the time hiding between your tools.":
        raise SystemExit("headline mismatch")
    if data.get("primary_cta") != "Map my workflow":
        raise SystemExit("primary CTA mismatch")
    if data.get("method_name") != "The Yuzu Method":
        raise SystemExit("method name mismatch")
    if len(data.get("method_steps", [])) != 5:
        raise SystemExit("method steps mismatch")
    if len(data.get("trust_answers", [])) != 10:
        raise SystemExit("trust answers mismatch")
    if len(data.get("page_rooms", [])) < 8:
        raise SystemExit("page rooms mismatch")
    contract = data.get("frontend_contract", {})
    if contract.get("component_package") != "@zeststream/ui":
        raise SystemExit("component package mismatch")
    if contract.get("token_package") != "@zeststream/story-system":
        raise SystemExit("token package mismatch")
    if contract.get("component_count", 0) < 9:
        raise SystemExit("component count mismatch")
    checks = data.get("public_copy_checks", {})
    if checks.get("hype_phrases_absent") is not True:
        raise SystemExit("hype phrase check missing")
    if checks.get("private_paths_absent") is not True:
        raise SystemExit("private path check missing")
PY
then
  pass "owner brief JSON contract"
else
  fail "owner brief JSON contract"
fi

if rg -qF "The Yuzu Method" "$TMP/owner-brief.md" "$ROOT/docs/stories/flywheel-owner-brief.md" \
  && rg -qF "Buy back the time hiding between your tools." "$TMP/owner-brief.md" "$ROOT/docs/stories/flywheel-owner-brief.md" \
  && rg -qF "Map my workflow" "$TMP/owner-brief.md" "$ROOT/docs/stories/flywheel-owner-brief.md" \
  && rg -qF "Page Rooms" "$TMP/owner-brief.md" "$ROOT/docs/stories/flywheel-owner-brief.md" \
  && rg -qF "scripts/zs-frontend-quality-gate.sh --json --strict" "$TMP/owner-brief.md" "$ROOT/docs/stories/flywheel-owner-brief.md"; then
  pass "owner brief markdown contract"
else
  fail "owner brief markdown contract"
fi

if rg -q "AI will transform your business|fully autonomous|set it and forget it|we have many commits, so trust us|all systems are supported without receipts|Here's why|Let's dive in|At its core|not just|game changer|—|/Users/josh|/Developer/" \
  "$TMP/owner-brief.json" "$TMP/owner-brief.md" "$ROOT/docs/evidence/flywheel-owner-brief.json" "$ROOT/docs/stories/flywheel-owner-brief.md"; then
  fail "owner brief avoids blocked public copy markers"
else
  pass "owner brief avoids blocked public copy markers"
fi

if python3 "$ROOT/scripts/depersonalize.py" --scan-table --root "$ROOT/docs/evidence/flywheel-owner-brief.json" --json >/dev/null \
  && python3 "$ROOT/scripts/depersonalize.py" --scan-table --root "$ROOT/docs/stories/flywheel-owner-brief.md" --json >/dev/null; then
  pass "owner brief depersonalization scan"
else
  fail "owner brief depersonalization scan"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
