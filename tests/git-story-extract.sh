#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

JSON_OUT="$TMP_DIR/story.json"
MD_OUT="$TMP_DIR/story.md"

python3 "$ROOT/scripts/extract_git_story.py" \
  --repo "$ROOT" \
  --repo-label Flywheel \
  --write-json "$JSON_OUT" \
  --write-md "$MD_OUT"

if python3 - "$JSON_OUT" <<'PY'
import json
import sys
from pathlib import Path

data = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
required_chapters = {"foundation", "proof-loop", "friction", "reuse", "story"}
message_pack = data.get("message_pack", {})
if data.get("schema_version") != "zeststream.repo_git_story.v0":
    raise SystemExit(1)
if message_pack.get("schema_version") != "zeststream.repo_story_message.v0":
    raise SystemExit(1)
if data.get("repo_label") != "Flywheel":
    raise SystemExit(1)
if data.get("commit_span", {}).get("total_commits", 0) <= 0:
    raise SystemExit(1)
if {row.get("id") for row in data.get("chapters", [])} != required_chapters:
    raise SystemExit(1)
for chapter in data["chapters"]:
    if not chapter.get("owner_value") or not chapter.get("sales_translation"):
        raise SystemExit(1)
if len(message_pack.get("story_arc", [])) != 5:
    raise SystemExit(1)
if len(message_pack.get("trust_objections", [])) != 10:
    raise SystemExit(1)
if len(message_pack.get("visual_primitives", [])) < 8:
    raise SystemExit(1)
if len(message_pack.get("proof_translation", [])) < 4:
    raise SystemExit(1)
if "Map my workflow" != message_pack.get("primary_cta"):
    raise SystemExit(1)
PY
then
  pass "git story JSON contract"
else
  fail "git story JSON contract"
fi

if rg -qF "show the proof, do not sell the dream" "$MD_OUT" \
  && rg -qF "Flywheel has a history, not just a homepage." "$JSON_OUT" \
  && rg -qF "Foundation: make the work visible" "$MD_OUT" \
  && rg -qF "Friction: expose the parts that were not ready" "$MD_OUT" \
  && rg -qF "zeststream.repo_story_message.v0" "$JSON_OUT" "$MD_OUT" \
  && rg -qF "Buy back the time hiding between your tools." "$JSON_OUT" \
  && rg -qF "A slice is one bounded workflow improvement" "$JSON_OUT" "$MD_OUT" \
  && rg -qF "OperatingRoomHero" "$JSON_OUT" "$MD_OUT" \
  && rg -qF "AI will make a mess." "$JSON_OUT"; then
  pass "git story owner language"
else
  fail "git story owner language"
fi

if rg -q "(/Users/josh|Blackfoot|ALPS|TerraTitle|mobile-eats|Compatibility target until)" "$JSON_OUT" "$MD_OUT"; then
  fail "git story private or stale markers absent"
else
  pass "git story private or stale markers absent"
fi

if python3 "$ROOT/scripts/depersonalize.py" --scan-table --root "$JSON_OUT" --json >/dev/null \
  && python3 "$ROOT/scripts/depersonalize.py" --scan-table --root "$MD_OUT" --json >/dev/null; then
  pass "git story depersonalization scan"
else
  fail "git story depersonalization scan"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
