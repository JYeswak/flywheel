#!/usr/bin/env bash
set -euo pipefail

VERSION="value-gap-probe.v1"
REPO="${VALUE_GAP_REPO:-/Users/josh/Developer/flywheel}"
STATE_DIR="${VALUE_GAP_STATE_DIR:-$HOME/.local/state/flywheel}"
LEDGER="${VALUE_GAP_LEDGER:-$STATE_DIR/value-gap-probe.jsonl}"
BR_BIN="${VALUE_GAP_BR_BIN:-br}"
PARENT_BEAD="${VALUE_GAP_PARENT_BEAD:-flywheel-1rmp}"
MODE="run"
JSON_OUT=0
DRY_RUN=1
APPLY=0
DIMENSION=""
IDEMPOTENCY_KEY=""
EXPLAIN=0

DIMENSIONS=(
  "cross-repo-failure-mode-harvester|We do not yet aggregate repeated failure modes across repos before they become doctrine.|Measure repeated trauma classes by repo and promote cross-repo patterns before the third rediscovery."
  "skill-bandit-auto-experiments|Skill selection is mostly static; we do not know which skill guidance actually improves outcomes.|Measure skill recommendation, adoption, success, and regression deltas per dispatch."
  "customer-facing-observability|Client projects have internal flywheel health, but customer-visible value and risk are not summarized back to us.|Measure customer-facing health receipts for ALPS, Blackfoot, TerraTitle, and active product surfaces."
  "cost-telemetry-token-burn|Dispatch cost and token burn are not visible at the same level as bead progress.|Measure per-dispatch model/runtime cost, retries, and token burn against delivered acceptance gates."
  "cross-skill-dependency-graph|Skill changes can break downstream workflows, but blast radius is not mapped.|Measure skill-to-skill and skill-to-script dependencies and flag high-radius edits."
  "mobile-eats-end-user-health|We measure mobile-eats ops health more than SaaS user health.|Measure user-facing flow checks, receipt freshness, and product KPI drift beside ops receipts."
  "operator-fatigue-gate|Joshua sustainability is treated as context, not as a measured stock.|Measure interrupt density, repeated escalation classes, and recommend step-away windows when fatigue signals rise."
  "cross-time-synthesis|Tick receipts answer current state but not what tomorrow's operator will wish was captured.|Measure missing handoff questions and write one tomorrow-you artifact per cycle."
  "adversarial-orchestrator-self-audit|Convergence and red-team audits run on plans, but not continuously on the orchestrator itself.|Measure a rotating adversarial self-audit dimension and file beads for systemic blind spots."
  "public-artifact-pipeline|Flywheel produces internal substrate but rarely routes showcase-worthy artifacts into public/product channels.|Measure publishable artifacts, proof quality, and candidate showcase backlog."
)

usage() {
  cat <<'USAGE'
Usage:
  value-gap-probe.sh [--json] [--dry-run|--apply] [--dimension N|name]
  value-gap-probe.sh --doctor [--json]
  value-gap-probe.sh --health [--json]
  value-gap-probe.sh repair [--dry-run|--apply] [--json]
  value-gap-probe.sh validate [--json]
  value-gap-probe.sh audit [--json]
  value-gap-probe.sh why <dimension> [--json]
  value-gap-probe.sh metrics [--json]
  value-gap-probe.sh logs [--json]
  value-gap-probe.sh --info [--json]
  value-gap-probe.sh --examples [--json]
  value-gap-probe.sh quickstart [--json]
  value-gap-probe.sh help <topic> [--json]
  value-gap-probe.sh completion <shell>
  value-gap-probe.sh schema [--json]

Step 4o value-gap hunter. Dry-run is the default. Mutating bead creation
requires --apply and is capped to one value-gap bead per invocation.
USAGE
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

json_array() {
  if [ "$#" -eq 0 ] || { [ "$#" -eq 1 ] && [ -z "${1:-}" ]; }; then
    printf '[]'
    return
  fi
  printf '%s\n' "$@" | jq -R . | jq -cs .
}

dimension_count() {
  printf '%s\n' "${#DIMENSIONS[@]}"
}

ledger_count() {
  if [ -s "$LEDGER" ]; then
    awk 'NF {n++} END {print n + 0}' "$LEDGER"
  else
    printf '0\n'
  fi
}

dimension_index_for() {
  local requested="${1:-}" count
  count="$(dimension_count)"
  if [ -z "$requested" ]; then
    printf '%s\n' "$(( $(ledger_count) % count ))"
    return
  fi
  if [[ "$requested" =~ ^[0-9]+$ ]]; then
    printf '%s\n' "$(( requested % count ))"
    return
  fi
  local i id
  for i in "${!DIMENSIONS[@]}"; do
    id="${DIMENSIONS[$i]%%|*}"
    if [ "$id" = "$requested" ]; then
      printf '%s\n' "$i"
      return
    fi
  done
  printf '%s\n' "0"
}

dimension_json() {
  local idx="$1" row id finding measurement
  row="${DIMENSIONS[$idx]}"
  id="${row%%|*}"
  row="${row#*|}"
  finding="${row%%|*}"
  measurement="${row#*|}"
  jq -nc \
    --arg id "$id" \
    --arg finding "$finding" \
    --arg measurement "$measurement" \
    --argjson index "$idx" \
    '{index:$index,id:$id,finding:$finding,proposed_measurement:$measurement}'
}

existing_bead_id() {
  local title="$1" out
  if ! command -v "$BR_BIN" >/dev/null 2>&1; then
    return 1
  fi
  out="$(cd "$REPO" && "$BR_BIN" list --json 2>/dev/null)" || return 1
  jq -r --arg title "$title" '(.issues // . // [])[]? | select((.title // "") == $title) | .id' <<<"$out" | head -1
}

file_bead() {
  local dim="$1" title desc existing create_args=() out
  title="[value-gap] $(jq -r .id <<<"$dim")"
  existing="$(existing_bead_id "$title" || true)"
  if [ -n "$existing" ]; then
    jq -nc --arg action "existing" --arg bead_id "$existing" '{action:$action,bead_filed_id:$bead_id}'
    return 0
  fi
  if ! command -v "$BR_BIN" >/dev/null 2>&1; then
    jq -nc '{action:"skipped",bead_filed_id:null,reason:"br_missing"}'
    return 0
  fi
  desc="$(jq -r '"## Goal\nAdd a measurement for the value gap dimension `" + .id + "`.\n\n## Finding\n" + .finding + "\n\n## Proposed measurement\n" + .proposed_measurement + "\n\n## Acceptance Criteria\n- Define the smallest recurring measurement that would make this gap visible.\n- Wire the result into a tick receipt, doctor signal, dashboard, or explicit no-surface reason.\n- Preserve Step 4o anti-pattern guardrails: do not dispatch directly from this finding.\n\n## Definition of Done\nClose with VALUE_GAP_DIMENSION=" + .id + " measurement=<path-or-reason> surfaced=<yes|no>." ' <<<"$dim")"
  create_args=("$title" "--priority" "P3" "--type" "task" "--description" "$desc")
  if [ -n "$PARENT_BEAD" ]; then
    create_args+=("--parent" "$PARENT_BEAD")
  fi
  if out="$(cd "$REPO" && "$BR_BIN" create "${create_args[@]}" --json 2>&1)"; then
    jq -nc --argjson raw "$out" '{action:"created",bead_filed_id:($raw.id // $raw.issue.id // null),raw:$raw}'
  else
    jq -nc --arg raw "$out" '{action:"error",bead_filed_id:null,raw:$raw}'
  fi
}

run_probe() {
  local idx dim mutation bead_id bead_action result
  idx="$(dimension_index_for "$DIMENSION")"
  dim="$(dimension_json "$idx")"
  mutation="$(jq -nc '{action:"dry_run",bead_filed_id:null}')"
  if [ "$APPLY" -eq 1 ]; then
    DRY_RUN=0
    mutation="$(file_bead "$dim")"
  fi
  bead_id="$(jq -r '.bead_filed_id // empty' <<<"$mutation")"
  bead_action="$(jq -r '.action // "unknown"' <<<"$mutation")"
  result="$(jq -nc \
    --arg schema_version "$VERSION" \
    --arg ts "$(now_iso)" \
    --arg repo "$REPO" \
    --arg ledger "$LEDGER" \
    --arg idempotency_key "$IDEMPOTENCY_KEY" \
    --argjson dry_run "$DRY_RUN" \
    --argjson dim "$dim" \
    --argjson mutation "$mutation" \
    '{
      schema_version:$schema_version,
      success:true,
      mode:"run",
      ts:$ts,
      repo:$repo,
      dry_run:$dry_run,
      value_gap_dimension_scanned:$dim.id,
      value_gap_dimension_index:$dim.index,
      value_gap_finding:$dim.finding,
      value_gap_proposed_measurement:$dim.proposed_measurement,
      bead_filed_id:($mutation.bead_filed_id // null),
      bead_action:($mutation.action // "unknown"),
      idempotency_key:$idempotency_key,
      ledger:$ledger,
      anti_patterns:["do_not_dispatch_directly","cap_one_bead_per_tick","lower_priority_than_repair_or_dispatch"]
    }')"
  if [ "$DRY_RUN" -eq 0 ]; then
    mkdir -p "$(dirname "$LEDGER")"
    printf '%s\n' "$result" >>"$LEDGER"
  fi
  printf '%s\n' "$result"
}

doctor_json() {
  local warnings=() ok=true
  command -v jq >/dev/null 2>&1 || { warnings+=("jq_missing"); ok=false; }
  command -v "$BR_BIN" >/dev/null 2>&1 || warnings+=("br_missing")
  [ -d "$REPO" ] || { warnings+=("repo_missing"); ok=false; }
  jq -nc \
    --arg schema_version "$VERSION" \
    --arg ts "$(now_iso)" \
    --arg repo "$REPO" \
    --arg ledger "$LEDGER" \
    --argjson dimension_count "$(dimension_count)" \
    --argjson ledger_count "$(ledger_count)" \
    --argjson success "$ok" \
    --argjson warnings "$(json_array "${warnings[@]:-}")" \
    '{schema_version:$schema_version,success:$success,mode:"doctor",ts:$ts,repo:$repo,ledger:$ledger,dimension_count:$dimension_count,ledger_count:$ledger_count,warnings:$warnings}'
}

schema_json() {
  jq -nc '{
    schema_version:"value-gap-probe.schema.v1",
    required:["schema_version","success","mode","ts","value_gap_dimension_scanned","value_gap_finding","bead_filed_id"],
    receipt_fields:["value_gap_dimension_scanned","value_gap_finding","bead_filed_id"],
    mutation_requires:["--apply"],
    default_mode:"dry-run"
  }'
}

info_json() {
  jq -nc \
    --arg schema_version "$VERSION" \
    --arg repo "$REPO" \
    --arg ledger "$LEDGER" \
    --arg parent "$PARENT_BEAD" \
    --argjson dimension_count "$(dimension_count)" \
    '{schema_version:$schema_version,mode:"info",repo:$repo,ledger:$ledger,parent_bead:$parent,dimension_count:$dimension_count,canonical_cli_scoping:"partial-script-surface"}'
}

examples_json() {
  jq -nc '{examples:[
    ".flywheel/scripts/value-gap-probe.sh --json",
    ".flywheel/scripts/value-gap-probe.sh --dry-run --dimension 3 --json",
    ".flywheel/scripts/value-gap-probe.sh --apply --idempotency-key tick-123 --json",
    ".flywheel/scripts/value-gap-probe.sh --doctor --json"
  ]}'
}

audit_json() {
  if [ -s "$LEDGER" ]; then
    jq -sc '{mode:"audit",rows:length,recent:.[-10:]}' "$LEDGER"
  else
    jq -nc '{mode:"audit",rows:0,recent:[]}'
  fi
}

metrics_json() {
  if [ -s "$LEDGER" ]; then
    jq -sc '{mode:"metrics",ledger_rows:length,dimensions_seen:([.[].value_gap_dimension_scanned] | unique | length),beads_filed:([.[] | select(.bead_filed_id != null)] | length)}' "$LEDGER"
  else
    jq -nc '{mode:"metrics",ledger_rows:0,dimensions_seen:0,beads_filed:0}'
  fi
}

emit_human_or_json() {
  local payload="$1"
  if [ "$JSON_OUT" -eq 1 ]; then
    printf '%s\n' "$payload"
  else
    jq -r 'if .mode == "run" then "value-gap " + .value_gap_dimension_scanned + ": " + .value_gap_finding else (.mode + " success=" + (.success|tostring)) end' <<<"$payload"
  fi
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --doctor|doctor) MODE="doctor"; shift ;;
    --health|health) MODE="health"; shift ;;
    repair) MODE="repair"; shift ;;
    validate) MODE="validate"; shift ;;
    audit) MODE="audit"; shift ;;
    why) MODE="why"; DIMENSION="${2:-}"; shift 2 ;;
    metrics) MODE="metrics"; shift ;;
    logs) MODE="logs"; shift ;;
    --info|info) MODE="info"; shift ;;
    --examples|examples) MODE="examples"; shift ;;
    quickstart) MODE="quickstart"; shift ;;
    help) MODE="topic_help"; DIMENSION="${2:-overview}"; shift 2 ;;
    completion) MODE="completion"; DIMENSION="${2:-bash}"; shift 2 ;;
    schema|--schema) MODE="schema"; shift ;;
    --repo) REPO="$2"; shift 2 ;;
    --state-dir) STATE_DIR="$2"; LEDGER="$STATE_DIR/value-gap-probe.jsonl"; shift 2 ;;
    --ledger) LEDGER="$2"; shift 2 ;;
    --dimension) DIMENSION="$2"; shift 2 ;;
    --parent) PARENT_BEAD="$2"; shift 2 ;;
    --idempotency-key) IDEMPOTENCY_KEY="$2"; shift 2 ;;
    --explain) EXPLAIN=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
  esac
done

case "$MODE" in
  run) emit_human_or_json "$(run_probe)" ;;
  doctor|health) emit_human_or_json "$(doctor_json)" ;;
  repair)
    mkdir -p "$(dirname "$LEDGER")"
    jq -nc --arg mode "$(if [ "$APPLY" -eq 1 ]; then printf applied; else printf dry_run; fi)" '{success:true,mode:"repair",repair_mode:$mode,actions:["ensure_ledger_dir"]}'
    ;;
  validate) jq -nc --argjson doctor "$(doctor_json)" '{success:($doctor.success == true),mode:"validate",doctor:$doctor}' ;;
  audit) audit_json ;;
  why) dimension_json "$(dimension_index_for "$DIMENSION")" | jq '{mode:"why"} + .' ;;
  metrics) metrics_json ;;
  logs) audit_json | jq '{mode:"logs",rows:.recent}' ;;
  info) info_json ;;
  examples) examples_json ;;
  quickstart) jq -nc '{mode:"quickstart",steps:["Run --doctor --json","Run --dry-run --json","Review the proposed measurement","Use --apply only from tick or a worker with bead permission"]}' ;;
  topic_help) jq -nc --arg topic "$DIMENSION" '{mode:"help",topic:$topic,summary:"Step 4o scans for missing leverage measurements and files at most one bead."}' ;;
  completion) printf 'complete -W "--json --dry-run --apply --doctor --health --info --examples --dimension --repo --ledger" value-gap-probe.sh\n' ;;
  schema) schema_json ;;
  *) usage >&2; exit 2 ;;
esac
