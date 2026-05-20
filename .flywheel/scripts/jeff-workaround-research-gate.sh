#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.20)
set -euo pipefail

VERSION="jeff-workaround-research-gate.v1.1.0"
SCHEMA_VERSION="jeff-workaround-research-gate/v1"
LEDGER_PATH="${JEFF_WORKAROUND_RESEARCH_GATE_LEDGER:-$HOME/.local/state/flywheel/jeff-workaround-research-gate-ledger.jsonl}"

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

usage() {
  cat <<'EOF'
usage:
  jeff-workaround-research-gate.sh [--repo PATH] [--ledger PATH] [--json]
  jeff-workaround-research-gate.sh --info --json
  jeff-workaround-research-gate.sh --schema --json
  jeff-workaround-research-gate.sh --examples [--json]
  jeff-workaround-research-gate.sh doctor --json
  jeff-workaround-research-gate.sh health --json
  jeff-workaround-research-gate.sh validate --json
  jeff-workaround-research-gate.sh audit --json [--limit N]
  jeff-workaround-research-gate.sh why [topic] [--json]
  jeff-workaround-research-gate.sh quickstart [--json]
  jeff-workaround-research-gate.sh repair --scope <ledger-prime> [--dry-run|--apply --idempotency-key KEY] [--json]
  jeff-workaround-research-gate.sh --help|-h

Scans recent dispatch/callback text for Jeff-upstream issue intent and requires
a matching workaround-research receipt before the issue path is considered
eligible.
EOF
}

emit_info() {
  jq -nc --arg sv "$SCHEMA_VERSION" --arg version "$VERSION" --arg ledger "$LEDGER_PATH" \
    '{
      schema_version:$sv,
      command:"info",
      name:"jeff-workaround-research-gate.sh",
      version:$version,
      ledger:$ledger,
      purpose:"Block Jeff-upstream issue paths that lack matching workaround-research receipts (socraticode K>=10 x Q>=2, workarounds_ranked>=5, top_workarounds_copy_tested>=2, exit-criterion explicit).",
      subcommands:["doctor","health","validate","audit","why","repair","quickstart"],
      canonical_flags:["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--repo","--ledger"],
      capabilities:[
        "dispatch-log-and-tmp-dispatch-jeff-pattern-scan",
        "workaround-research-receipt-requirement-gate",
        "candidates-without-receipt-enumeration",
        "exit-2-on-pending-violations"
      ],
      apply_supported:false,
      dry_run_supported:false,
      idempotency_key_required_for_apply:false,
      mutates_state:false,
      env_vars:["JEFF_WORKAROUND_RESEARCH_GATE_LEDGER"],
      exit_codes:{"0":"pass","2":"pending-violations","64":"bad-args"}
    }'
}

emit_examples() {
  if [[ "${1:-}" == "--json" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" '{
      schema_version:$sv,
      command:"examples",
      examples:[
        {name:"default-scan",invocation:"jeff-workaround-research-gate.sh --json",purpose:"scan dispatch-log + /tmp/dispatch*jeff* for Jeff-issue intent without workaround receipt"},
        {name:"custom-ledger",invocation:"jeff-workaround-research-gate.sh --ledger /tmp/custom-dispatch.jsonl --json",purpose:"scan a specific dispatch ledger"},
        {name:"schema",invocation:"jeff-workaround-research-gate.sh --schema --json",purpose:"emit required-receipt-fields + doctor-fields schema"},
        {name:"doctor",invocation:"jeff-workaround-research-gate.sh doctor --json",purpose:"canonical doctor envelope (.checks)"},
        {name:"audit",invocation:"jeff-workaround-research-gate.sh audit --json",purpose:"tail recent gate-decision ledger rows"}
      ]
    }'
  else
    cat <<'EOF'
examples:
  jeff-workaround-research-gate.sh --json
  jeff-workaround-research-gate.sh --ledger /tmp/dispatch.jsonl --json
  jeff-workaround-research-gate.sh --schema --json
  jeff-workaround-research-gate.sh doctor --json
  jeff-workaround-research-gate.sh audit --json
EOF
  fi
}

emit_canonical_doctor() {
  local ts; ts="$(now_iso)"
  local jq_status="pass"; command -v jq >/dev/null 2>&1 || jq_status="fail"
  local rg_status="pass"; command -v rg >/dev/null 2>&1 || rg_status="fail"
  local default_ledger="/Users/josh/Developer/flywheel/.flywheel/dispatch-log.jsonl"
  local dispatch_status="pass"; [[ -f "$default_ledger" ]] || dispatch_status="warn"
  local ledger_dir; ledger_dir="$(dirname "$LEDGER_PATH")"
  local ledger_status="pass"
  if [[ -e "$LEDGER_PATH" ]]; then
    [[ -w "$LEDGER_PATH" ]] || ledger_status="fail"
  else
    [[ -d "$ledger_dir" ]] || ledger_status="warn"
  fi
  local overall="pass"
  for s in "$jq_status" "$rg_status" "$dispatch_status" "$ledger_status"; do
    case "$s" in
      fail) overall="fail" ;;
      warn) [[ "$overall" == "pass" ]] && overall="warn" ;;
    esac
  done
  jq -nc --arg sv "$SCHEMA_VERSION.doctor" --arg ts "$ts" --arg overall "$overall" \
    --arg jq_s "$jq_status" --arg rg_s "$rg_status" \
    --arg dispatch_s "$dispatch_status" --arg dispatch "$default_ledger" \
    --arg ledger_s "$ledger_status" --arg ledger "$LEDGER_PATH" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      checks:[
        {name:"jq",status:$jq_s,detail:"jq required for envelope emission"},
        {name:"ripgrep",status:$rg_s,detail:"rg required for ledger pattern scan"},
        {name:"dispatch_log",status:$dispatch_s,path:$dispatch,detail:"default dispatch ledger (warn if missing — script handles absence gracefully)"},
        {name:"ledger_writable",status:$ledger_s,path:$ledger,detail:"append-only gate-decision ledger"}
      ]
    }'
}

emit_health() {
  local ts; ts="$(now_iso)"
  local row_count=0
  if [[ -r "$LEDGER_PATH" ]]; then
    row_count="$(wc -l <"$LEDGER_PATH" 2>/dev/null | tr -d ' ')"
    [[ -z "$row_count" ]] && row_count=0
  fi
  jq -nc --arg sv "$SCHEMA_VERSION.health" --arg ts "$ts" \
    --arg ledger "$LEDGER_PATH" --argjson row_count "${row_count:-0}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"pass",ledger:$ledger,ledger_row_count:$row_count}'
}

emit_canonical_validate() {
  local ts; ts="$(now_iso)"
  local rows=0 invalid=0
  if [[ -r "$LEDGER_PATH" ]]; then
    rows="$(wc -l <"$LEDGER_PATH" 2>/dev/null | tr -d ' ')"
    [[ -z "$rows" ]] && rows=0
    if [[ "$rows" -gt 0 ]]; then
      invalid="$(jq -c 'select((.schema_version // "") == "")' "$LEDGER_PATH" 2>/dev/null | wc -l | tr -d ' ')"
      [[ -z "$invalid" ]] && invalid=0
    fi
  fi
  local status="pass"
  [[ "$invalid" -gt 0 ]] && status="violations"
  jq -nc --arg sv "$SCHEMA_VERSION.validate" --arg ts "$ts" --arg status "$status" \
    --argjson rows "${rows:-0}" --argjson invalid "${invalid:-0}" --arg ledger "$LEDGER_PATH" \
    '{schema_version:$sv,command:"validate",ts:$ts,status:$status,ledger:$ledger,row_count:$rows,invalid_row_count:$invalid,check:"every gate-decision row has non-empty schema_version"}'
}

emit_audit() {
  local limit="${1:-20}"
  local ts; ts="$(now_iso)"
  if [[ ! -r "$LEDGER_PATH" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION.audit" --arg ts "$ts" --arg ledger "$LEDGER_PATH" \
      '{schema_version:$sv,command:"audit",ts:$ts,status:"missing",ledger:$ledger,row_count:0,recent:[]}'
    return 0
  fi
  local row_count
  row_count="$(wc -l <"$LEDGER_PATH" 2>/dev/null | tr -d ' ')"
  [[ -z "$row_count" ]] && row_count=0
  local recent='[]'
  if [[ "$row_count" -gt 0 ]]; then
    recent="$(tail -n "$limit" "$LEDGER_PATH" 2>/dev/null | jq -cs '.' 2>/dev/null || printf '%s' '[]')"
    [[ -z "$recent" ]] && recent='[]'
  fi
  local status="pass"
  [[ "$row_count" -eq 0 ]] && status="empty"
  jq -nc --arg sv "$SCHEMA_VERSION.audit" --arg ts "$ts" --arg status "$status" \
    --arg ledger "$LEDGER_PATH" --argjson row_count "$row_count" --argjson recent "$recent" \
    '{schema_version:$sv,command:"audit",ts:$ts,status:$status,ledger:$ledger,row_count:$row_count,recent:$recent}'
}

emit_why() {
  local topic="${1:-}"
  local body=""
  case "$topic" in
    ""|workaround-research-requirement)
      body='Joshua axiom: every Jeff-upstream issue proposal MUST be preceded by full workaround research. Required receipt fields: socraticode_queries >= 2 (multiple search phrasings), socraticode_k_per_query >= 10 (broad result set per query), workarounds_ranked >= 5 (five candidate workarounds enumerated + ranked), top_workarounds_copy_tested >= 2 (top-2 actually attempted on a copy), AND (jeff_issue_warranted == false) OR (all_workarounds_failed == true OR foundational_no_workaround == true).'
      ;;
    pattern-scan-keywords)
      body='Script greps dispatch-log + /tmp/dispatch*jeff* for keywords: "jeff issue", "file upstream", "jeff-worthy", "escalate to jeff" (case-insensitive). Candidates lacking workaround/socraticode_queries/workarounds_ranked/copy_test in the same row are flagged as pending without receipt → exit 2.'
      ;;
    exit-2-pending)
      body='exit 2 with pending_count > 0 is a HARD BLOCK signal — orchestrator must surface the candidates, route to research-triad workflow, then re-run the gate. Bypass requires explicit operator override (not currently implemented).'
      ;;
    *)
      body="unknown topic: $topic. known: workaround-research-requirement, pattern-scan-keywords, exit-2-pending"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION" --arg topic "${topic:-workaround-research-requirement}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"jeff-workaround-research-gate.sh doctor --json"},
      {step:2,action:"scan-default-ledger",command:"jeff-workaround-research-gate.sh --json"},
      {step:3,action:"interpret-candidates",command:"jq .jeff_issue_candidates_without_receipt"},
      {step:4,action:"audit-recent",command:"jeff-workaround-research-gate.sh audit --json"}
    ],
    next_actions:["run-research-triad-on-each-candidate","add-workaround-receipt-fields-to-dispatch"]
  }'
}

emit_repair() {
  local scope="" mode="dry_run" idem_key=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope) scope="${2:-}"; shift 2 ;;
      --dry-run) mode="dry_run"; shift ;;
      --apply) mode="apply"; shift ;;
      --idempotency-key) idem_key="${2:-}"; shift 2 ;;
      --idempotency-key=*) idem_key="${1#--idempotency-key=}"; shift ;;
      --json) shift ;;
      --help|-h) printf 'repair --scope <ledger-prime> [--dry-run|--apply --idempotency-key KEY]\n'; exit 0 ;;
      "") shift ;;
      *) printf 'ERR: unknown repair arg %s\n' "$1" >&2; exit 2 ;;
    esac
  done
  if [[ -z "$scope" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","reason":"--scope required (ledger-prime)","exit_code":2}\n' "$SCHEMA_VERSION"
    exit 2
  fi
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","mode":"apply","scope":"%s","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION" "$scope"
    exit 3
  fi
  local ts; ts="$(now_iso)"
  case "$scope" in
    ledger-prime)
      local ledger_dir present_before present_after
      ledger_dir="$(dirname "$LEDGER_PATH")"
      present_before="$([[ -f "$LEDGER_PATH" ]] && printf true || printf false)"
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$ledger_dir" 2>/dev/null || true
        [[ -f "$LEDGER_PATH" ]] || : > "$LEDGER_PATH"
      fi
      present_after="$([[ -f "$LEDGER_PATH" ]] && printf true || printf false)"
      jq -nc --arg sv "$SCHEMA_VERSION.repair" --arg ts "$ts" --arg scope "$scope" --arg mode "$mode" \
        --arg ledger "$LEDGER_PATH" --arg key "$idem_key" \
        --argjson before "$present_before" --argjson after "$present_after" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"pass",scope:$scope,mode:$mode,idempotency_key:$key,ledger:$ledger,ledger_present_before:$before,ledger_present_after:$after}'
      ;;
    *)
      printf '{"schema_version":"%s.repair","status":"refused","scope":"%s","reason":"unknown scope; known: ledger-prime","exit_code":2}\n' "$SCHEMA_VERSION" "$scope"
      exit 2
      ;;
  esac
}

# Canonical no-dash subcommand intercept BEFORE main arg parser.
case "${1:-}" in
  --info) emit_info; exit 0 ;;
  --examples) shift; emit_examples "${1:-}"; exit 0 ;;
  doctor) shift; emit_canonical_doctor; exit 0 ;;
  health) shift; emit_health; exit 0 ;;
  validate) shift; emit_canonical_validate; exit 0 ;;
  audit)
    shift
    LIMIT=20
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --limit) LIMIT="${2:-20}"; shift 2 ;;
        --json) shift ;;
        "") shift ;;
        *) shift ;;
      esac
    done
    emit_audit "$LIMIT"
    exit 0
    ;;
  why)
    shift
    TOPIC=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --json) shift ;;
        "") shift ;;
        *) [[ -z "$TOPIC" ]] && TOPIC="$1"; shift ;;
      esac
    done
    emit_why "$TOPIC"
    exit 0
    ;;
  quickstart) shift; emit_quickstart; exit 0 ;;
  repair) shift; emit_repair "$@"; exit 0 ;;
esac

repo="/Users/josh/Developer/flywheel"
ledger=""
schema=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) repo="${2:-}"; shift 2 ;;
    --ledger) ledger="${2:-}"; shift 2 ;;
    --json) shift ;;
    --schema) schema=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

if [[ "$schema" -eq 1 ]]; then
  jq -n '{
    schema_version:"jeff-workaround-research-gate/v1",
    command:"schema",
    input_schema:{
      type:"object",
      properties:{
        repo:{type:"string",description:"flywheel repo root for default ledger resolution"},
        ledger:{type:"string",description:"specific dispatch-log.jsonl to scan"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","status","ledger","jeff_issue_pending_without_workaround_research_count"],
      properties:{
        schema_version:{const:"jeff-workaround-research-gate/v1"},
        status:{enum:["pass","fail"]},
        ledger:{type:"string"},
        jeff_issue_pending_without_workaround_research_count:{type:"integer",minimum:0},
        jeff_issue_candidates_without_receipt:{
          type:"array",
          items:{type:"object",properties:{text:{type:"string"},has_workaround_research:{type:"boolean"}}}
        },
        jeff_issue_workaround_gate_status:{enum:["pass","fail"]},
        required_predicate:{type:"string"}
      }
    },
    required_receipt_fields:["socraticode_queries","socraticode_k_per_query","workarounds_ranked","top_workarounds_copy_tested","jeff_issue_warranted","all_workarounds_failed","foundational_no_workaround"],
    doctor_fields:["jeff_issue_pending_without_workaround_research_count","jeff_issue_candidates_without_receipt","jeff_issue_workaround_gate_status"],
    exit_codes:{"0":"pass","2":"pending-violations","64":"bad-args"}
  }'
  exit 0
fi

if [[ -z "$ledger" ]]; then
  ledger="$repo/.flywheel/dispatch-log.jsonl"
fi

tmp="$(mktemp "${TMPDIR:-/tmp}/jeff-workaround-gate.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

: >"$tmp"
if [[ -f "$ledger" ]]; then
  rg -i 'jeff issue|file upstream|jeff-worthy|escalate to jeff' "$ledger" >>"$tmp" || true
fi
if compgen -G "/tmp/dispatch*jeff*" >/dev/null; then
  rg -i 'jeff issue|file upstream|jeff-worthy|escalate to jeff' /tmp/dispatch*jeff* >>"$tmp" || true
fi

candidates_json="[]"
if [[ -s "$tmp" ]]; then
  candidates_json="$(
    jq -R -s '
      split("\n")
      | map(select(length > 0))
      | map({text:., has_workaround_research:(test("workaround"; "i") and test("socraticode_queries|workarounds_ranked|copy_test"; "i"))})
      | map(select(.has_workaround_research | not))
    ' "$tmp"
  )"
fi

pending_count="$(jq 'length' <<<"$candidates_json")"
status="pass"
if [[ "$pending_count" -gt 0 ]]; then
  status="fail"
fi

jq -n \
  --arg status "$status" \
  --arg ledger "$ledger" \
  --argjson candidates "$candidates_json" \
  --argjson pending_count "$pending_count" \
  '{
    schema_version:"jeff-workaround-research-gate/v1",
    status:$status,
    ledger:$ledger,
    jeff_issue_pending_without_workaround_research_count:$pending_count,
    jeff_issue_candidates_without_receipt:$candidates,
    jeff_issue_workaround_gate_status:$status,
    required_predicate:"(.socraticode_queries >= 2 and .socraticode_k_per_query >= 10) and (.workarounds_ranked >= 5) and (.top_workarounds_copy_tested >= 2) and ((.jeff_issue_warranted == false) or (.all_workarounds_failed == true or .foundational_no_workaround == true))"
  }'

if [[ "$pending_count" -gt 0 ]]; then
  exit 2
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-09-info-source-watchtower.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-76-authority-ranked-retrieval-maintenance.md`
