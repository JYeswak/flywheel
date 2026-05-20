#!/usr/bin/env bash
# Meta-pattern Adoption stance:
# Embodies MP-73-score-triggered-lifecycle-playbook.md and MP-41-gate-class-separation.md.
# Source: /Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/
set -euo pipefail

VERSION="track-classifier/v1"
STATE_DIR="${TRACK_CLASSIFIER_STATE_DIR:-$HOME/.local/state/flywheel}"
OVERRIDE_LOG="${TRACK_CLASSIFIER_OVERRIDE_LOG:-$STATE_DIR/track-override-log.jsonl}"
FUCKUP_LOG="${TRACK_CLASSIFIER_FUCKUP_LOG:-$STATE_DIR/fuckup-log.jsonl}"
COMMAND="${1:-classify}"
[[ $# -gt 0 ]] && shift || true

usage() {
  cat <<'EOF'
usage:
  track-classifier.sh classify (--surface TEXT | --file PATH) [--json]
  track-classifier.sh gate (--surface TEXT | --file PATH) [--task-id ID] [--dispatch-log PATH] [--override-track-separation --joshua-approval TEXT] [--json]
  track-classifier.sh --info|--schema|--examples|--help

Classes: track1, track2, track3, cross_orch_relay, unknown.
EOF
}

emit_info() {
  jq -nc --arg version "$VERSION" \
    '{name:"track-classifier",version:$version,classes:["track1","track2","track3","cross_orch_relay","unknown"],override_log:"~/.local/state/flywheel/track-override-log.jsonl",trauma_class:"cross_track_dispatch_collision"}'
}

emit_schema() {
  jq -nc --arg version "$VERSION" \
    '{schema_version:$version,input:{surface:"string",file:"path"},output:{classification:"track1|track2|track3|cross_orch_relay|unknown",matched_terms:"array",decision:"allow|refuse|override"},logs:{override:"track-override-log.jsonl",refusal_trauma_class:"cross_track_dispatch_collision"}}'
}

emit_examples() {
  jq -nc '{examples:[
    {name:"classify file",command:".flywheel/scripts/track-classifier.sh classify --file /tmp/dispatch_task.md --json"},
    {name:"dispatch gate",command:".flywheel/scripts/track-classifier.sh gate --file /tmp/dispatch_task.md --task-id flywheel-abc --json"},
    {name:"approved override",command:".flywheel/scripts/track-classifier.sh gate --file /tmp/dispatch_task.md --override-track-separation --joshua-approval \"Joshua approved YYYY-MM-DDTHH:MMZ\" --json"}
  ]}'
}

die_usage() {
  printf 'ERR: %s\n' "$1" >&2
  exit 2
}

case "$COMMAND" in
  --info|info) emit_info; exit 0 ;;
  --schema|schema) emit_schema; exit 0 ;;
  --examples|examples) emit_examples; exit 0 ;;
  --help|-h|help) usage; exit 0 ;;
  classify|gate) ;;
  *) die_usage "unknown command: $COMMAND" ;;
esac

SURFACE=""
FILE_PATH=""
JSON_OUT=0
TASK_ID=""
DISPATCH_LOG=""
OVERRIDE=0
JOSHUA_APPROVAL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --surface) [[ $# -ge 2 ]] || die_usage "--surface requires TEXT"; SURFACE="$2"; shift 2 ;;
    --surface=*) SURFACE="${1#*=}"; shift ;;
    --file) [[ $# -ge 2 ]] || die_usage "--file requires PATH"; FILE_PATH="$2"; shift 2 ;;
    --file=*) FILE_PATH="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --task-id) [[ $# -ge 2 ]] || die_usage "--task-id requires ID"; TASK_ID="$2"; shift 2 ;;
    --task-id=*) TASK_ID="${1#*=}"; shift ;;
    --dispatch-log) [[ $# -ge 2 ]] || die_usage "--dispatch-log requires PATH"; DISPATCH_LOG="$2"; shift 2 ;;
    --dispatch-log=*) DISPATCH_LOG="${1#*=}"; shift ;;
    --override-track-separation) OVERRIDE=1; shift ;;
    --joshua-approval) [[ $# -ge 2 ]] || die_usage "--joshua-approval requires TEXT"; JOSHUA_APPROVAL="$2"; shift 2 ;;
    --joshua-approval=*) JOSHUA_APPROVAL="${1#*=}"; shift ;;
    --*) die_usage "unknown argument: $1" ;;
    *) die_usage "unexpected argument: $1" ;;
  esac
done

if [[ -n "$FILE_PATH" ]]; then
  [[ -r "$FILE_PATH" ]] || die_usage "file not readable: $FILE_PATH"
  SURFACE="$(printf '%s\n' "$FILE_PATH"; sed -n '1,240p' "$FILE_PATH")"
fi
[[ -n "$SURFACE" ]] || die_usage "one of --surface or --file is required"

RESULT="$(python3 - "$SURFACE" <<'PY'
import json
import re
import sys

surface = sys.argv[1]
lower = surface.lower()

patterns = {
    "track1": [
        r"(^|[/\s.])mission\.md\b",
        r"(^|[/\s.])goal\.md\b",
        r"\b(edit|update|rewrite|draft|change|author)\s+(the\s+)?(mission|goal)\b",
        r"\b(mission|goal)\s+(doc|document|strategy|directive)\b",
        r"\bcompany mission\b",
    ],
    "track2": [
        r"(^|/)legal/",
        r"\b(review|draft|edit|update|negotiate|approve)\s+(the\s+)?(legal|contract|agreement|terms|privacy|msa|dpa)\b",
        r"\blegal\s+(review|approval|matter|doc|document)\b",
        r"\bterms of service\b",
        r"\bprivacy policy\b",
        r"\bcounsel\b",
    ],
    "track3": [
        r"\btrack\s*3\b",
        r"\bsubstrate\b",
        r"\bvalidator\b",
        r"\bfixture\b",
        r"\bdispatch[-_ ]log\b",
        r"\bdispatch\b",
        r"\btrauma[-_ ]class\b",
        r"\.flywheel/scripts/",
        r"(^|/)tests/",
        r"\.beads/issues\.jsonl",
    ],
    "cross_orch_relay": [
        r"\bcross[-_ ]orch\b",
        r"\borch(?:estrator)?[-_ ]relay\b",
        r"\bskillos_handoff\b",
        r"\bskillos\b.*\bhandoff\b",
        r"\bntm send skillos\b",
        r"\bpane=1\b.*\bnotify\b",
    ],
}

hits = {}
for track, pats in patterns.items():
    terms = []
    for pat in pats:
        if re.search(pat, lower):
            terms.append(pat)
    if terms:
        hits[track] = terms

if hits.get("track2"):
    classification = "track2"
elif hits.get("track1"):
    classification = "track1"
elif hits.get("cross_orch_relay"):
    classification = "cross_orch_relay"
elif hits.get("track3"):
    classification = "track3"
else:
    classification = "unknown"

print(json.dumps({
    "schema_version": "track-classifier.result/v1",
    "classification": classification,
    "matched_tracks": sorted(hits),
    "matched_terms": hits,
}))
PY
)"

classification="$(printf '%s' "$RESULT" | jq -r '.classification')"

if [[ "$COMMAND" == "classify" ]]; then
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$RESULT"
  else
    printf '%s\n' "$classification"
  fi
  exit 0
fi

ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
decision="allow"
reason="track_allowed"
rc=0

if [[ "$classification" == "track1" || "$classification" == "track2" ]]; then
  if [[ "$OVERRIDE" -eq 1 && -n "$JOSHUA_APPROVAL" ]]; then
    decision="override"
    reason="joshua_approved_track_separation_override"
    mkdir -p "$(dirname "$OVERRIDE_LOG")"
    jq -nc \
      --arg schema_version "track-separation-override/v1" \
      --arg ts "$ts" \
      --arg task_id "$TASK_ID" \
      --arg classification "$classification" \
      --arg approval "$JOSHUA_APPROVAL" \
      --arg dispatch_log "$DISPATCH_LOG" \
      '{schema_version:$schema_version,ts:$ts,task_id:($task_id//""),classification:$classification,approval:$approval,dispatch_log:($dispatch_log//""),decision:"override"}' >>"$OVERRIDE_LOG"
  else
    decision="refuse"
    if [[ "$OVERRIDE" -eq 1 ]]; then
      reason="joshua_approval_required"
    else
      reason="track_separation_refused"
    fi
    mkdir -p "$(dirname "$FUCKUP_LOG")"
    jq -nc \
      --arg ts "$ts" \
      --arg class "cross_track_dispatch_collision" \
      --arg trauma_class "cross_track_dispatch_collision" \
      --arg task_id "$TASK_ID" \
      --arg classification "$classification" \
      --arg reason "$reason" \
      '{ts:$ts,class:$class,trauma_class:$trauma_class,severity:"high",session:"flywheel",task_id:($task_id//""),classification:$classification,what_happened:("dispatch refused by track classifier: " + $classification + " " + $reason)}' >>"$FUCKUP_LOG"
    rc=5
  fi
fi

OUT="$(printf '%s' "$RESULT" | jq \
  --arg command "gate" \
  --arg decision "$decision" \
  --arg reason "$reason" \
  --arg task_id "$TASK_ID" \
  --arg override_log "$OVERRIDE_LOG" \
  --arg trauma_class "cross_track_dispatch_collision" \
  '. + {command:$command,decision:$decision,reason:$reason,task_id:($task_id//""),override_log:$override_log,trauma_class:$trauma_class}')"

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$OUT"
else
  printf '%s %s %s\n' "$decision" "$classification" "$reason"
fi
exit "$rc"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
