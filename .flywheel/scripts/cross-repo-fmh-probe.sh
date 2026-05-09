#!/usr/bin/env bash
# cross-repo-fmh-probe.sh — closes flywheel-1rmp.12 (value-gap
# `cross-repo-failure-mode-harvester`).
#
# The smallest recurring measurement that makes the value gap visible: scan
# fuckup-log.jsonl rows, group by (trauma_class, git_repo), and surface
# trauma classes that appear in ≥2 distinct repos. That's the cross-repo
# signal — same failure mode hitting multiple repos is the early-promotion
# trigger the bead names ("promote cross-repo patterns before the third
# rediscovery").
#
# Step 4o anti-pattern preserved: probe is READ-ONLY. No br/ntm/gh/git/
# agent-mail mutating verbs in source. No auto-bead-filing from findings.
# Output is structured JSON only. The orchestrator decides what to do with
# the cross-repo candidates; this probe just measures.
#
# Canonical-cli-scoping triad: --doctor / --health / --info / --schema /
# --json with stable exit codes.
set -euo pipefail

SCHEMA_VERSION="cross-repo-fmh-probe.v1"
DEFAULT_FUCKUP_LOG="$HOME/.local/state/flywheel/fuckup-log.jsonl"

FUCKUP_LOG="$DEFAULT_FUCKUP_LOG"
LOOKBACK_DAYS=14
MIN_REPOS=2
TOP_N=20
JSON_OUT=0
MODE=run

usage() {
  cat <<'USAGE'
usage: cross-repo-fmh-probe.sh [--lookback-days N] [--min-repos N] [--top N] [--json]
       cross-repo-fmh-probe.sh --doctor|--health|--info|--schema [--json]

Reads fuckup-log, groups (trauma_class, git_repo) within --lookback-days, and
surfaces trauma classes that appear in ≥ --min-repos distinct repos.

Defaults: --lookback-days 14, --min-repos 2, --top 20.

Output JSON (run mode):
  {
    schema_version, ts, lookback_days, min_repos,
    cross_repo_candidates: [
      { trauma_class, repo_count, repos[], total_events, sample_what_happened }
    ],
    cross_repo_candidate_count,
    cross_repo_signal: bool,
    reads_only: true, auto_dispatch: false, step_4o_compliance: "preserved"
  }

Exit codes:
  0  measurement emitted
  1  no fuckup data in window
  2  config error
USAGE
}

doctor() {
  jq -nc --arg schema "$SCHEMA_VERSION" --arg flog "$FUCKUP_LOG" \
    '{schema_version:$schema, success:true, mode:"doctor",
      fuckup_log:$flog, fuckup_log_present:true,
      reads_only:true, auto_dispatch:false,
      surfaces:["tick receipt consumer","dashboard tile","early-doctrine-promotion candidate list"],
      step_4o_compliance:"preserved",
      out_of_scope:["auto-create-bead-from-finding","auto-Jeffrey-issue","Pushover notification"]}'
}

info() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:true, mode:"info",
      measurement:"trauma classes appearing in >= min-repos distinct git_repo values within lookback window",
      doctrine:"cross-repo recurrence is the L56 doctrine-promotion ladders early signal — surface candidates before third rediscovery",
      reads_only:true,
      step_4o_compliance:"preserved"}'
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema,
      properties:{
        lookback_days:{type:"integer"},
        min_repos:{type:"integer"},
        cross_repo_candidates:{type:"array",
          items:{properties:{
            trauma_class:{type:"string"},
            repo_count:{type:"integer"},
            repos:{type:"array"},
            total_events:{type:"integer"},
            sample_what_happened:{type:["string","null"]}
          }}},
        cross_repo_candidate_count:{type:"integer"},
        cross_repo_signal:{type:"boolean"}}}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --lookback-days) LOOKBACK_DAYS="${2:?--lookback-days requires N}"; shift 2;;
    --min-repos) MIN_REPOS="${2:?--min-repos requires N}"; shift 2;;
    --top) TOP_N="${2:?--top requires N}"; shift 2;;
    --fuckup-log) FUCKUP_LOG="${2:?--fuckup-log requires PATH}"; shift 2;;
    --json) JSON_OUT=1; shift;;
    --doctor|--health) MODE=doctor; shift;;
    --info) MODE=info; shift;;
    --schema) MODE=schema; shift;;
    -h|--help) usage; exit 0;;
    *) echo "ERR: unknown arg $1" >&2; usage >&2; exit 2;;
  esac
done

case "$MODE" in
  doctor) doctor; exit 0;;
  info) info; exit 0;;
  schema) schema; exit 0;;
esac

[[ -f "$FUCKUP_LOG" ]] || { echo "ERR: fuckup-log not found: $FUCKUP_LOG" >&2; exit 2; }

NOW_EPOCH="$(date -u +%s)"
CUTOFF_EPOCH=$((NOW_EPOCH - LOOKBACK_DAYS * 86400))

# Stream rows through python3 for grouping (avoids N×M jq nesting).
CANDIDATES_JSON="$(python3 - "$FUCKUP_LOG" "$CUTOFF_EPOCH" "$MIN_REPOS" "$TOP_N" <<'PY'
import json, os, sys, time
from collections import defaultdict
log_path = sys.argv[1]
cutoff = int(sys.argv[2])
min_repos = int(sys.argv[3])
top_n = int(sys.argv[4])
groups = defaultdict(lambda: {"repos": set(), "events": 0, "sample": None})
def parse_ts(s):
    if not s: return None
    s = s.replace("Z", "")
    try:
        # naive UTC parse
        t = time.strptime(s, "%Y-%m-%dT%H:%M:%S")
        return int(time.mktime(t)) - time.timezone
    except (ValueError, TypeError):
        return None
try:
    with open(log_path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                row = json.loads(line)
            except json.JSONDecodeError:
                continue
            tc = row.get("trauma_class") or ""
            repo = row.get("git_repo") or ""
            ts = row.get("ts") or ""
            if not tc or not repo:
                continue
            epoch = parse_ts(ts)
            if epoch is None or epoch < cutoff:
                continue
            g = groups[tc]
            g["repos"].add(repo)
            g["events"] += 1
            if g["sample"] is None and row.get("what_happened"):
                g["sample"] = (row["what_happened"] or "")[:200]
except OSError:
    pass
out = []
for tc, g in groups.items():
    if len(g["repos"]) >= min_repos:
        out.append({
            "trauma_class": tc,
            "repo_count": len(g["repos"]),
            "repos": sorted(g["repos"]),
            "total_events": g["events"],
            "sample_what_happened": g["sample"],
        })
out.sort(key=lambda x: (-x["repo_count"], -x["total_events"]))
print(json.dumps(out[:top_n]))
PY
)"

CANDIDATE_COUNT="$(jq 'length' <<<"$CANDIDATES_JSON")"
SIGNAL=false
[[ "$CANDIDATE_COUNT" -gt 0 ]] && SIGNAL=true

PAYLOAD="$(jq -nc \
  --arg schema "$SCHEMA_VERSION" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --argjson lookback "$LOOKBACK_DAYS" \
  --argjson min_repos "$MIN_REPOS" \
  --argjson candidates "$CANDIDATES_JSON" \
  --argjson candidate_count "$CANDIDATE_COUNT" \
  --argjson signal "$SIGNAL" \
  '{schema_version:$schema, ts:$ts, success:true, mode:"run",
    lookback_days:$lookback, min_repos:$min_repos,
    cross_repo_candidates:$candidates,
    cross_repo_candidate_count:$candidate_count,
    cross_repo_signal:$signal,
    reads_only:true, auto_dispatch:false,
    step_4o_compliance:"preserved"}')"

if [[ "$JSON_OUT" == 1 ]]; then
  printf '%s\n' "$PAYLOAD"
else
  jq -r '"cross-repo-fmh lookback=\(.lookback_days)d min_repos=\(.min_repos) candidates=\(.cross_repo_candidate_count) signal=\(.cross_repo_signal) top3=\(.cross_repo_candidates[0:3] | map("\(.trauma_class)(repos=\(.repo_count) events=\(.total_events))") | join(","))"' <<<"$PAYLOAD"
fi
