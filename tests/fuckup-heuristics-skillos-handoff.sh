#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
HEURISTICS="$ROOT/templates/fuckup-heuristics.json"
FUCKUP_LIB="$HOME/.claude/skills/.flywheel/lib/fuckup.sh"
TMP="$(mktemp -d -t skillos-handoff-heuristic.XXXXXX)"

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

require_jq() {
  local filter="$1" label="$2"
  if jq -e "$filter" "$HEURISTICS" >/dev/null; then
    pass "$label"
  else
    fail "$label"
  fi
}

if jq -e '.schema_version == 1 and (.heuristics | type == "array")' "$HEURISTICS" >/dev/null; then
  pass "heuristics json parses with schema version"
else
  fail "heuristics json parses with schema version"
fi

require_jq '
  [.heuristics[] | select(.pattern == "skill-shipped-without-skillos-handoff")] | length == 1
' "skillos handoff heuristic is registered exactly once"

require_jq '
  .heuristics[] | select(.pattern == "skill-shipped-without-skillos-handoff")
  | .match == "exact"
  and .severity == "medium"
  and .should_become == "canonical-L-rule"
  and .promotion_target == "INCIDENTS.md per L56 ladder"
  and (.remediation | contains("handoff-skill-to-skillos.sh"))
' "skillos handoff heuristic carries routing metadata"

require_jq '
  .heuristics[] | select(.pattern == "skill-shipped-without-skillos-handoff")
  | .detection.log_pattern == "files_reserved=.*~/.claude/skills/"
  and .detection.missing_field == "skillos_handoff_message_id"
  and .detection.exclude_if_field_set == "skillos_handoff_skipped_reason"
' "skillos handoff heuristic carries detection contract"

require_jq '
  all(.heuristics[]; (.pattern | type == "string") and (.match | type == "string") and (.should_become | type == "string") and (.recommended_action | type == "string"))
' "all heuristics keep required schema fields"

if rg -q '## skill-shipped-without-skillos-handoff' "$ROOT/INCIDENTS.md" \
  && rg -q 'skillos_handoff_message_id' "$ROOT/INCIDENTS.md" \
  && rg -q 'handoff-skill-to-skillos.sh' "$ROOT/INCIDENTS.md"; then
  pass "INCIDENTS.md references rule and remediation helper"
else
  fail "INCIDENTS.md references rule and remediation helper"
fi

if python3 - "$ROOT/.flywheel/dispatch-log.jsonl" <<'PY' >"$TMP/historical-match.json"
from __future__ import annotations

import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
matches = []
for line_number, line in enumerate(path.read_text().splitlines(), 1):
    try:
        row = json.loads(line)
    except Exception:
        continue
    reserved = str(row.get("files_reserved") or "")
    has_skill_reservation = "~/.claude/skills/" in reserved or "/.claude/skills/" in reserved
    has_message = bool(row.get("skillos_handoff_message_id"))
    has_skip = bool(row.get("skillos_handoff_skipped_reason"))
    if has_skill_reservation and not has_message and not has_skip:
        matches.append(
            {
                "line": line_number,
                "task_id": row.get("task_id"),
                "files_reserved": reserved,
            }
        )
print(json.dumps({"match_count": len(matches), "matches": matches[:5]}, separators=(",", ":")))
PY
then
  if jq -e '.match_count >= 1 and any(.matches[]; .task_id == "info-source-watchtower-rebuild-2026_05_03")' "$TMP/historical-match.json" >/dev/null; then
    pass "historical dispatch event matches detection contract"
  else
    fail "historical dispatch event matches detection contract"
  fi
else
  fail "historical dispatch event matches detection contract"
fi

now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat >"$TMP/fuckup-log.jsonl" <<EOF
{"ts":"$now","trauma_class":"skill-shipped-without-skillos-handoff","severity":"medium","what_happened":"files_reserved=/Users/josh/.claude/skills/info-source-watchtower/SKILL.md callback omitted skillos_handoff_message_id"}
EOF

if FLYWHEEL_FUCKUP_LOG="$TMP/fuckup-log.jsonl" \
  FUCKUP_HEURISTICS_PATH="$HEURISTICS" \
  bash -lc "source '$FUCKUP_LIB'; fuckup_triage_compute_json" >"$TMP/triage.json" \
  && jq -e '
    .status == "warn"
    and (.candidates[] | select(.trauma_class == "skill-shipped-without-skillos-handoff")
      and .frequency == 1
      and .severity == "medium"
      and .should_become == "canonical-L-rule"
      and (.reasoning | contains("exact pattern skill-shipped-without-skillos-handoff"))
      and (.recommended_action | contains("handoff-skill-to-skillos.sh")))
  ' "$TMP/triage.json" >/dev/null; then
  pass "fuckup triage dry-run classifies historical handoff gap"
else
  fail "fuckup triage dry-run classifies historical handoff gap"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
