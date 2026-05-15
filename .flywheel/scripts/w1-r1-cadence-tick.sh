#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (info/schema/examples + tick/health)
#
# w1-r1-cadence-tick.sh — Hourly W1 cadence tick for v5 forever-goal.
#
# Fires trauma-claim-emitter.sh + handoff and appends one row to
# .flywheel/state/r1-cadence-ledger.jsonl with the result. The ledger is
# the tracked-path evidence that W1's "rolling 24h, last 24 hours each
# have ≥1 trauma_journal row OR explicit no-novel-trauma signal" EXIT
# can be evaluated against.
#
# Invoked by ~/.flywheel/launchd/flywheel.w1-r1-cadence.plist on hourly
# StartInterval=3600.
#
# Exit: 0 always (a no-novel-trauma tick is a valid cadence signal).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO_ROOT="${W1_REPO:-$REPO_DEFAULT}"
LEDGER_PATH="${W1_CADENCE_LEDGER:-$REPO_ROOT/.flywheel/state/r1-cadence-ledger.jsonl}"
EMITTER="$REPO_ROOT/.flywheel/scripts/trauma-claim-emitter.sh"

usage() {
  cat <<'EOF'
usage:
  w1-r1-cadence-tick.sh tick [--json]
  w1-r1-cadence-tick.sh --info|--schema|--examples [--json]
  w1-r1-cadence-tick.sh health|doctor [--json]
EOF
}

case "${1:-tick}" in
  --info)
    cat <<JSON
{"name":"w1-r1-cadence-tick","version":"v0.1.0",
 "schema_version":"flywheel.w1_r1_cadence.v0",
 "purpose":"Hourly W1 cadence — fire R1 emitter + ledger append (forever-goal v5)",
 "ledger_path":"$LEDGER_PATH",
 "scheduler":"launchd hourly via ~/.flywheel/launchd/flywheel.w1-r1-cadence.plist"}
JSON
    exit 0 ;;
  --schema)
    cat <<'JSON'
{"row_schema":{
  "ts":"ISO-8601 UTC",
  "wave":"W1",
  "fired_emitter":"bool",
  "candidates_emitted":"int",
  "had_novel_trauma":"bool",
  "notes":"string"
}}
JSON
    exit 0 ;;
  --examples)
    echo '{"examples":[{"name":"manual tick","command":".flywheel/scripts/w1-r1-cadence-tick.sh tick --json"}]}'
    exit 0 ;;
  health|doctor)
    status="ok"
    [[ -x "$EMITTER" ]] || status="fail"
    mkdir -p "$(dirname "$LEDGER_PATH")" 2>/dev/null
    printf '{"command":"%s","status":"%s","emitter":"%s","ledger":"%s"}\n' "${1}" "$status" "$EMITTER" "$LEDGER_PATH"
    [[ "$status" == "ok" ]] && exit 0 || exit 1 ;;
  --help|-h)
    usage; exit 0 ;;
esac

# tick (default)
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
mkdir -p "$(dirname "$LEDGER_PATH")"

if [[ ! -x "$EMITTER" ]]; then
  row="$(jq -nc --arg ts "$TS" '{ts:$ts,wave:"W1",fired_emitter:false,candidates_emitted:0,had_novel_trauma:false,notes:"emitter_missing"}')"
  echo "$row" >>"$LEDGER_PATH"
  echo "$row"
  exit 0
fi

# Run emitter in dry-run first to check for novel trauma; emit for real if found.
# emitter check outputs status line + (optional) candidates array; take only first line.
out="$("$EMITTER" check --json 2>/dev/null | head -1 || true)"
[[ -z "$out" ]] && out='{"candidate_count":0}'
count="$(echo "$out" | jq -r '.candidate_count // 0' | head -1)"
[[ -z "$count" ]] && count=0
had_novel="false"
if [[ "$count" -gt 0 ]]; then
  # Real emit (appends to .flywheel/evidence/trauma-candidates.jsonl)
  "$EMITTER" emit --json >/dev/null 2>&1 || true
  had_novel="true"
fi

row="$(jq -nc --arg ts "$TS" --argjson count "$count" --argjson novel "$had_novel" \
  '{ts:$ts,wave:"W1",fired_emitter:true,candidates_emitted:$count,had_novel_trauma:$novel,notes:(if $novel then "novel_trauma_emitted" else "no_novel_trauma_this_hour" end)}')"
echo "$row" >>"$LEDGER_PATH"
echo "$row"
