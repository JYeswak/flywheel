#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
NTM_BIN="${RECENCY_CLASSIFIER_NTM_BIN:-/Users/josh/.local/bin/ntm}"
SESSION=""
PANE=""
LINES=80
JSON_OUT=0
DECAY_HALF_LIFE_S=5
MODE="classify"

usage() {
  cat <<'EOF'
usage:
  recency-weighted-two-truth-classifier.sh [--json] [--lines N] < tail.txt
  recency-weighted-two-truth-classifier.sh --session NAME --pane N [--lines N] [--json]
  recency-weighted-two-truth-classifier.sh --info|--check [--json]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info) MODE="info"; shift ;;
    --check) MODE="check"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --session) SESSION="${2:?session required}"; shift 2 ;;
    --session=*) SESSION="${1#*=}"; shift ;;
    --pane) PANE="${2:?pane required}"; shift 2 ;;
    --pane=*) PANE="${1#*=}"; shift ;;
    --lines) LINES="${2:?lines required}"; shift 2 ;;
    --lines=*) LINES="${1#*=}"; shift ;;
    --decay-half-life-s) DECAY_HALF_LIFE_S="${2:?seconds required}"; shift 2 ;;
    --decay-half-life-s=*) DECAY_HALF_LIFE_S="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "invalid arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

emit_info() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -nc --arg root "$ROOT" '{name:"recency_weighted_two_truth_classifier",schema_version:"recency-weighted-two-truth-classifier/v1",root:$root,verdicts:["WAITING","THINKING","ERROR","UNKNOWN"],exit_codes:{"0":"verdict-emitted","1":"insufficient-evidence","2":"invalid-args"}}'
  else
    echo "recency_weighted_two_truth_classifier v1"
  fi
}

if [[ "$MODE" == "info" ]]; then
  emit_info
  exit 0
fi

if [[ "$MODE" == "check" ]]; then
  sample=$'ERROR failed_text from old tool\nold api_error\n❯ '
  out="$(printf '%s\n' "$sample" | "$0" --json)"
  jq -e '.verdict == "WAITING"' >/dev/null <<<"$out" || exit 1
  [[ "$JSON_OUT" -eq 1 ]] && jq -nc '{status:"pass"}' || echo "pass"
  exit 0
fi

[[ "$LINES" =~ ^[0-9]+$ && "$LINES" -gt 0 ]] || { echo "invalid --lines" >&2; exit 2; }
[[ "$DECAY_HALF_LIFE_S" =~ ^[0-9]+([.][0-9]+)?$ ]] || { echo "invalid --decay-half-life-s" >&2; exit 2; }

TMP="$(mktemp "${TMPDIR:-/tmp}/recency-classifier.XXXXXX")"
trap 'rm -f "$TMP"' EXIT
ACTIVITY_JSON="${RECENCY_CLASSIFIER_ACTIVITY_JSON:-}"

if [[ -n "$SESSION" || -n "$PANE" ]]; then
  [[ -n "$SESSION" && -n "$PANE" ]] || { echo "--session and --pane must be paired" >&2; exit 2; }
  if [[ -x "$NTM_BIN" ]]; then
    tail_json="$("$NTM_BIN" "--robot-tail=$SESSION" "--panes=$PANE" "--lines=$LINES" 2>/dev/null || true)"
    jq -r --arg p "$PANE" '(.panes[$p].lines // .panes[($p|tostring)].lines // [])[]?' <<<"$tail_json" >"$TMP" 2>/dev/null || : >"$TMP"
    if [[ -z "$ACTIVITY_JSON" ]]; then
      ACTIVITY_JSON="$("$NTM_BIN" "--robot-activity=$SESSION" "--panes=$PANE" --json 2>/dev/null || true)"
    fi
  else
    : >"$TMP"
    ACTIVITY_JSON="${ACTIVITY_JSON:-{}}"
  fi
else
  cat >"$TMP"
  ACTIVITY_JSON="${ACTIVITY_JSON:-{}}"
fi

export RECENCY_CLASSIFIER_TAIL_FILE="$TMP" RECENCY_CLASSIFIER_ACTIVITY_JSON="$ACTIVITY_JSON"
export RECENCY_CLASSIFIER_SESSION="$SESSION" RECENCY_CLASSIFIER_PANE="$PANE"
export RECENCY_CLASSIFIER_JSON_OUT="$JSON_OUT" RECENCY_CLASSIFIER_DECAY_HALF_LIFE_S="$DECAY_HALF_LIFE_S"

python3 - <<'PY'
from __future__ import annotations

import json
import os
import re
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

tail = Path(os.environ["RECENCY_CLASSIFIER_TAIL_FILE"]).read_text(encoding="utf-8", errors="replace")
lines = tail.splitlines()
json_out = os.environ.get("RECENCY_CLASSIFIER_JSON_OUT") == "1"
pane, session = os.environ.get("RECENCY_CLASSIFIER_PANE", ""), os.environ.get("RECENCY_CLASSIFIER_SESSION", "")
half_life = float(os.environ.get("RECENCY_CLASSIFIER_DECAY_HALF_LIFE_S", "5"))

def norm_state(value: object) -> str:
    state = str(value or "UNKNOWN").upper()
    return "THINKING" if state == "GENERATING" else state if state in {"WAITING", "THINKING", "ERROR"} else "UNKNOWN"

try:
    activity = json.loads(os.environ.get("RECENCY_CLASSIFIER_ACTIVITY_JSON") or "{}")
except Exception:
    activity = {}

def activity_agent() -> dict:
    agents = activity.get("agents") if isinstance(activity, dict) else None
    if not isinstance(agents, list):
        return {}
    for agent in agents:
        if not isinstance(agent, dict):
            continue
        raw = agent.get("pane_idx", agent.get("pane"))
        if pane and str(raw) == str(pane):
            return agent
    return agents[0] if agents and isinstance(agents[0], dict) else {}

agent = activity_agent()
activity_verdict = norm_state(agent.get("state"))

ts_re = re.compile(r"20\d\d-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?Z")
waiting_re = re.compile(r"(^|\s)(❯|›)\s*$|codex_chevron_prompt|bypass permissions|^>\s*$")
thinking_re = re.compile(r"Working \(|esc to interrupt|Waiting for background terminal|⏺|• Ran|Running|tool_call|exec_command|apply_patch", re.I)
error_re = re.compile(r"failed_text|api_error|Traceback|Exception|ERROR|failed|error:", re.I)
fatal_re = re.compile(r"\b(panic|SIGKILL|killed|segmentation fault|fatal)\b", re.I)
tool_re = re.compile(r"⏺|• Ran|Working \(|Waiting for background terminal|exec_command|apply_patch|tool_call|Bash\(", re.I)

def parsed_age(line: str, fallback: float) -> float:
    match = ts_re.search(line)
    if not match:
        return fallback
    raw = match.group(0).replace("Z", "+00:00")
    try:
        return max(0.0, time.time() - datetime.fromisoformat(raw).timestamp())
    except Exception:
        return fallback

def decay(age: float) -> float:
    if age <= half_life:
        return 1.0
    if age <= half_life * 3:
        return 0.5
    return 0.1

scores = {"WAITING": 0.0, "THINKING": 0.0, "ERROR": 0.0}
best_age = {"WAITING": 999999.0, "THINKING": 999999.0, "ERROR": 999999.0}
evidence = []
chevron_present = False
last_tool_age = None
line_count = len(lines)

for idx, line in enumerate(lines):
    fallback_age = max(0, line_count - idx - 1)
    age = parsed_age(line, fallback_age)
    d = decay(age)
    if waiting_re.search(line):
        chevron_present = True
        score = 4.0 * d
        if score > scores["WAITING"] or (score == scores["WAITING"] and age < best_age["WAITING"]):
            scores["WAITING"] = score
            best_age["WAITING"] = age
        evidence.append({"verdict": "WAITING", "line": idx + 1, "age_s": age, "score": score, "text": line[-120:]})
    if thinking_re.search(line):
        score = 4.0 * d
        if score > scores["THINKING"] or (score == scores["THINKING"] and age < best_age["THINKING"]):
            scores["THINKING"] = score
            best_age["THINKING"] = age
        evidence.append({"verdict": "THINKING", "line": idx + 1, "age_s": age, "score": score, "text": line[-120:]})
    if fatal_re.search(line):
        score = 7.0 * d
        if score > scores["ERROR"] or (score == scores["ERROR"] and age < best_age["ERROR"]):
            scores["ERROR"] = score
            best_age["ERROR"] = age
        evidence.append({"verdict": "ERROR", "line": idx + 1, "age_s": age, "score": score, "fatal": True, "text": line[-120:]})
    elif error_re.search(line):
        score = 3.5 * d
        if score > scores["ERROR"] or (score == scores["ERROR"] and age < best_age["ERROR"]):
            scores["ERROR"] = score
            best_age["ERROR"] = age
        evidence.append({"verdict": "ERROR", "line": idx + 1, "age_s": age, "score": score, "text": line[-120:]})
    if tool_re.search(line):
        last_tool_age = age if last_tool_age is None else min(last_tool_age, age)

ordered = sorted(scores.items(), key=lambda kv: (-kv[1], best_age[kv[0]], kv[0]))
direct_verdict = "UNKNOWN" if not ordered or ordered[0][1] <= 0 else ordered[0][0]
if len(ordered) > 1 and ordered[0][1] - ordered[1][1] < 0.25 and activity_verdict in {ordered[0][0], ordered[1][0]}:
    verdict = activity_verdict
else:
    verdict = direct_verdict
if verdict == "UNKNOWN" and activity_verdict != "UNKNOWN" and not lines:
    verdict = "UNKNOWN"

payload = {
    "schema_version": "recency-weighted-two-truth-classifier/v1",
    "session": session or None,
    "pane": int(pane) if str(pane).isdigit() else pane or None,
    "verdict": verdict,
    "direct_buffer_verdict": direct_verdict,
    "robot_activity_verdict": activity_verdict,
    "scores": scores,
    "chevron_present": chevron_present,
    "last_tool_call_age_s": last_tool_age,
    "line_count": line_count,
    "evidence": sorted(evidence, key=lambda item: item["score"], reverse=True)[:6],
}
if json_out:
    print(json.dumps(payload, sort_keys=True, separators=(",", ":")))
else:
    print(verdict)
sys.exit(1 if verdict == "UNKNOWN" and not lines and activity_verdict == "UNKNOWN" else 0)
PY
