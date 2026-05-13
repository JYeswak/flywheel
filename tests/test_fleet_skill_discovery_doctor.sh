#!/usr/bin/env bash
set -euo pipefail

LOOP="${LOOP:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d -t 5gyv.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

make_repo() {
  local repo="$1"
  mkdir -p "$repo/.flywheel"
  git -C "$repo" init -q
  printf '# Mission\n' >"$repo/.flywheel/MISSION.md"
  printf '# Goal\n' >"$repo/.flywheel/GOAL.md"
  printf '# State\n' >"$repo/.flywheel/STATE.md"
}

run_doctor() {
  local repo="$1" discoveries="$2" dispatch_log="$3" out="$4"
  FLYWHEEL_SKILL_DISCOVERY_PATH="$discoveries" \
  FLYWHEEL_SKILL_DISCOVERY_DISPATCH_LOG="$dispatch_log" \
  FLYWHEEL_SKILL_DISCOVERY_NOW="2026-05-08T01:00:00Z" \
    "$LOOP" doctor --repo "$repo" --json >"$out" 2>/dev/null || true
}

repo_missing="$TMP/repo-missing"
make_repo "$repo_missing"
missing_discoveries="$TMP/missing/skill-discoveries.jsonl"
missing_dispatch="$TMP/missing/dispatch-log.jsonl"
mkdir -p "$(dirname "$missing_dispatch")"
: >"$missing_dispatch"
run_doctor "$repo_missing" "$missing_discoveries" "$missing_dispatch" "$TMP/missing.json"
jq -e '
  .fleet_skill_discovery
  and (.fleet_skill_discovery.file_present == false)
  and (.fleet_skill_discovery.total_discoveries == 0)
  and (.fleet_skill_discovery.last_24h_discoveries == 0)
  and (.fleet_skill_discovery.status == "ok" or .fleet_skill_discovery.status == "warn")
' "$TMP/missing.json" >/dev/null || {
  jq '.fleet_skill_discovery' "$TMP/missing.json" >&2 || true
  fail "missing discovery file should not crash doctor"
}

repo_counts="$TMP/repo-counts"
make_repo "$repo_counts"
discoveries="$TMP/counts/skill-discoveries.jsonl"
dispatch_log="$TMP/counts/dispatch-log.jsonl"
mkdir -p "$(dirname "$discoveries")"
python3 - "$discoveries" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
rows = [
    ("fixture-alpha", "flywheel", 1),
    ("fixture-alpha", "{session}", 2),
    ("fixture-alpha", "{capability-control-plane}", 3),
    ("fixture-beta", "{session}", 4),
    ("fixture-beta", "{proof-product}", 5),
    ("fixture-gamma", "zesttube", 6),
    ("fixture-delta", "vrtx", 7),
]
with path.open("w", encoding="utf-8") as handle:
    handle.write("{not-json}\n")
    for candidate, session, idx in rows:
        handle.write(json.dumps({
            "schema_version": "skill-discovery/v1",
            "ts": f"2026-05-08T00:{idx:02d}:00Z",
            "discovery_id": f"sd-5gyv-{idx:03d}",
            "session": session,
            "worker_pane": idx,
            "worker_kind": "codex",
            "task_context": "fixture",
            "discovery_kind": "pattern-recurrence" if idx > 1 else "pattern-emerged",
            "candidate_skill_name": candidate,
            "evidence": {"fixture": idx},
            "promotion_signal": f"sighting_{idx}",
            "should_become": "skill-builder candidate",
            "blocking_current_work": False,
        }, sort_keys=True) + "\n")
PY
{
  jq -nc '{schema_version:2,event:"dispatch_sent",task_id:"long-1",ts:"2026-05-07T20:00:00Z"}'
  jq -nc '{schema_version:2,event:"worker_callback",task_id:"long-1",callback_status:"DONE",ts:"2026-05-07T23:00:00Z",skill_discoveries:0,sd_ids:"none"}'
  jq -nc '{schema_version:2,event:"dispatch_sent",task_id:"long-2",ts:"2026-05-07T21:00:00Z"}'
  jq -nc '{schema_version:2,event:"worker_callback",task_id:"long-2",callback_status:"DONE",ts:"2026-05-08T00:00:00Z",skill_discoveries:0,sd_ids:"none"}'
  jq -nc '{schema_version:2,event:"dispatch_sent",task_id:"long-3",ts:"2026-05-07T22:00:00Z"}'
  jq -nc '{schema_version:2,event:"worker_callback",task_id:"long-3",callback_status:"DONE",ts:"2026-05-08T01:00:00Z",skill_discoveries:0,sd_ids:"none"}'
} >"$dispatch_log"

run_doctor "$repo_counts" "$discoveries" "$dispatch_log" "$TMP/counts.json"
jq -e '
  .fleet_skill_discovery.last_24h_discoveries == 7
  and .fleet_skill_discovery.malformed_rows_count == 1
  and .fleet_skill_discovery.top_candidates[0].candidate_skill_name == "fixture-alpha"
  and .fleet_skill_discovery.top_candidates[0].sighting_count == 3
  and .fleet_skill_discovery.pending_coordinator_action_count == 1
  and .fleet_skill_discovery.pending_coordinator_actions[0].action == "skill_builder_bead_needed"
  and .fleet_skill_discovery.suspicious_callback_warning_count == 1
  and .fleet_skill_discovery.skipped_discovery_duty_streak == 3
  and (.fleet_skill_discovery.warning_classes | index("skill_discovery_duty_skipped"))
' "$TMP/counts.json" >/dev/null || {
  jq '.fleet_skill_discovery' "$TMP/counts.json" >&2 || true
  fail "expected malformed/top-candidate/pending-action/suspicious-callback fields"
}

printf 'OK fleet skill discovery doctor\n'
