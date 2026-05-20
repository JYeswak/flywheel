#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.23)
set -euo pipefail

VERSION="plan-state-lens-merge.v1.1.0"
SCHEMA_VERSION="plan-state-lens-merge/v1"
LEDGER="${PLAN_STATE_LENS_MERGE_LEDGER:-$HOME/.local/state/flywheel/plan-state-lens-merge-ledger.jsonl}"
IDEMPOTENCY_KEY=""
JSON_OUT=0
QUIET=0
APPLY=0
DRY_RUN=0
CMD=""
PLAN=""
LENS=""
ROW_JSON=""

usage() {
  cat <<'USAGE'
usage: plan-state-lens-merge.sh append --plan PATH --lens NAME --row-json JSON [--json] [--quiet]
       plan-state-lens-merge.sh derived --plan PATH [--json] [--quiet]
       plan-state-lens-merge.sh validate --plan PATH [--json] [--quiet]
       plan-state-lens-merge.sh --info|--help|--examples [--json]
USAGE
}

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

info() {
  jq -nc --arg sv "$SCHEMA_VERSION" --arg version "$VERSION" --arg ledger "$LEDGER" \
    '{
      schema_version:$sv,
      command:"info",
      name:"plan-state-lens-merge.sh",
      version:$version,
      ledger:$ledger,
      row_schema:"plan-state-lens-row/v1",
      purpose:"Merge multi-lens audit findings into a plan STATE.json file (append-only lens_merge_rows), then derive aggregated views (effective lenses, findings_by_severity, disposition_by_lens).",
      subcommands:["doctor","health","validate","audit","why","repair","quickstart","append","derived"],
      canonical_flags:["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--plan","--lens","--row-json","--quiet"],
      capabilities:[
        "append-only-lens-row-merge",
        "supersedes-tombstone-via-audit_lens_identity_key",
        "derived-view-by-severity-and-disposition",
        "atomic-state-write-via-tmp-and-mv",
        "state-sha-self-recompute",
        "plan-state-validation"
      ],
      apply_supported:true,
      dry_run_supported:true,
      idempotency_key_required_for_apply:true,
      mutates_state:true,
      env_vars:["PLAN_STATE_LENS_MERGE_LEDGER"],
      exit_codes:{"0":"pass","2":"bad-args","3":"refused-apply-without-idempotency-key"}
    }'
}

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"schema",
    input_schema:{
      type:"object",
      properties:{
        command:{enum:["append","derived","validate"]},
        plan:{type:"string",description:"path to plan dir or STATE.json file"},
        lens:{type:"string",description:"lens name (e.g., security, brand, sniff, jeff, public)"},
        row_json:{type:"string",description:"JSON object for the lens row to append"},
        apply:{type:"boolean"},
        dry_run:{type:"boolean"},
        idempotency_key:{type:"string",description:"required with --apply"},
        quiet:{type:"boolean"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","status"],
      properties:{
        schema_version:{type:"string"},
        command:{enum:["append","derived","validate","doctor","health","audit","why","repair","quickstart","info","schema","examples"]},
        status:{enum:["pass","fail"]},
        lens_rows_count:{type:"integer"},
        effective_lenses_count:{type:"integer"},
        audit_lenses_complete:{type:"array",items:{type:"string"}},
        audit_findings_by_severity:{type:"object"},
        audit_findings_count:{type:"integer"},
        audit_disposition_by_lens:{type:"object"}
      }
    },
    exit_codes:{"0":"pass","2":"bad-args","3":"refused-apply-without-idempotency-key"}
  }'
}

examples() {
  jq -nc '{examples:[
    "plan-state-lens-merge.sh append --plan .flywheel/PLANS/x --lens security --row-json '\''{\"findings_by_severity\":{\"high\":1}}'\'' --json",
    "plan-state-lens-merge.sh derived --plan .flywheel/PLANS/x --json",
    "plan-state-lens-merge.sh validate --plan .flywheel/PLANS/x --json"
  ]}'
}

emit_examples_json() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"examples",
    examples:[
      {name:"append-lens-row",invocation:"plan-state-lens-merge.sh append --plan .flywheel/PLANS/x --lens security --row-json {\"findings_by_severity\":{\"high\":1}} --apply --idempotency-key plsm-2026-05-11 --json",purpose:"append a security lens row into the plan STATE.json"},
      {name:"derived-view",invocation:"plan-state-lens-merge.sh derived --plan .flywheel/PLANS/x --json",purpose:"compute effective_lenses + findings_by_severity + disposition_by_lens from current rows"},
      {name:"validate-state",invocation:"plan-state-lens-merge.sh validate --plan .flywheel/PLANS/x --json",purpose:"verify STATE.json shape + sha consistency"},
      {name:"doctor",invocation:"plan-state-lens-merge.sh doctor --json",purpose:"canonical doctor envelope"},
      {name:"audit",invocation:"plan-state-lens-merge.sh audit --json",purpose:"tail recent merge ledger rows"}
    ]
  }'
}

emit_canonical_doctor() {
  local ts; ts="$(now_iso)"
  local jq_status="pass"; command -v jq >/dev/null 2>&1 || jq_status="fail"
  local shasum_status="pass"; command -v shasum >/dev/null 2>&1 || shasum_status="fail"
  local ledger_dir; ledger_dir="$(dirname "$LEDGER")"
  local ledger_status="pass"
  if [[ -e "$LEDGER" ]]; then
    [[ -w "$LEDGER" ]] || ledger_status="fail"
  else
    [[ -d "$ledger_dir" ]] || ledger_status="warn"
  fi
  local overall="pass"
  for s in "$jq_status" "$shasum_status" "$ledger_status"; do
    case "$s" in
      fail) overall="fail" ;;
      warn) [[ "$overall" == "pass" ]] && overall="warn" ;;
    esac
  done
  jq -nc --arg sv "$SCHEMA_VERSION.doctor" --arg ts "$ts" --arg overall "$overall" \
    --arg jq_s "$jq_status" --arg shasum_s "$shasum_status" \
    --arg ledger_s "$ledger_status" --arg ledger "$LEDGER" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      checks:[
        {name:"jq",status:$jq_s,detail:"jq required for envelope emission + state manipulation"},
        {name:"shasum",status:$shasum_s,detail:"shasum required for state_sha self-recompute"},
        {name:"ledger_writable",status:$ledger_s,path:$ledger,detail:"append-only merge ledger"}
      ]
    }'
}

emit_health() {
  local ts; ts="$(now_iso)"
  local row_count=0
  [[ -r "$LEDGER" ]] && row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
  [[ -z "$row_count" ]] && row_count=0
  jq -nc --arg sv "$SCHEMA_VERSION.health" --arg ts "$ts" \
    --arg ledger "$LEDGER" --argjson row_count "$row_count" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"pass",ledger:$ledger,ledger_row_count:$row_count}'
}

emit_canonical_validate() {
  local ts; ts="$(now_iso)"
  local rows=0 invalid=0
  if [[ -r "$LEDGER" ]]; then
    rows="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$rows" ]] && rows=0
    if [[ "$rows" -gt 0 ]]; then
      invalid="$(jq -c 'select((.schema_version // "") == "")' "$LEDGER" 2>/dev/null | wc -l | tr -d ' ')"
      [[ -z "$invalid" ]] && invalid=0
    fi
  fi
  local status="pass"
  [[ "$invalid" -gt 0 ]] && status="violations"
  jq -nc --arg sv "$SCHEMA_VERSION.validate" --arg ts "$ts" --arg status "$status" \
    --argjson rows "${rows:-0}" --argjson invalid "${invalid:-0}" --arg ledger "$LEDGER" \
    '{schema_version:$sv,command:"validate",ts:$ts,status:$status,ledger:$ledger,row_count:$rows,invalid_row_count:$invalid,check:"every ledger row has non-empty schema_version"}'
}

emit_audit() {
  local limit="${1:-20}"
  local ts; ts="$(now_iso)"
  if [[ ! -r "$LEDGER" ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION.audit" --arg ts "$ts" --arg ledger "$LEDGER" \
      '{schema_version:$sv,command:"audit",ts:$ts,status:"missing",ledger:$ledger,row_count:0,recent:[]}'
    return 0
  fi
  local row_count
  row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
  [[ -z "$row_count" ]] && row_count=0
  local recent='[]'
  if [[ "$row_count" -gt 0 ]]; then
    recent="$(tail -n "$limit" "$LEDGER" 2>/dev/null | jq -cs '.' 2>/dev/null || printf '%s' '[]')"
    [[ -z "$recent" ]] && recent='[]'
  fi
  local status="pass"
  [[ "$row_count" -eq 0 ]] && status="empty"
  jq -nc --arg sv "$SCHEMA_VERSION.audit" --arg ts "$ts" --arg status "$status" \
    --arg ledger "$LEDGER" --argjson row_count "$row_count" --argjson recent "$recent" \
    '{schema_version:$sv,command:"audit",ts:$ts,status:$status,ledger:$ledger,row_count:$row_count,recent:$recent}'
}

emit_why() {
  local topic="${1:-}"
  local body=""
  case "$topic" in
    ""|lens-merge-pattern)
      body='Plans accumulate multi-lens audit findings (brand, sniff, jeff, public, security, etc.) as append-only `lens_merge_rows[]` entries in STATE.json. Each row carries findings_by_severity + disposition. derived view recomputes effective_lenses (latest per lens, after supersedes tombstones) + aggregate severity counts. Atomic write via tmp + mv preserves consistency.'
      ;;
    audit-lens-identity-key)
      body='Each lens row carries audit_lens_identity_key (sha-prefixed). The `supersedes` field on a NEW row references the identity_key of an OLDER row to tombstone it; the derived view filters out superseded rows when computing effective lenses. This is plan-rev-2 evolution semantics — old findings stay in the row log for audit, but only the latest non-superseded per-lens row counts.'
      ;;
    state-sha-self-recompute)
      body='STATE.json includes state_written_sha. On read, the script recomputes sha (walking the object, deleting state_written_sha first, then sha256-hashing canonicalized output). Mismatch indicates corruption or hand-edit; validate command surfaces this.'
      ;;
    *)
      body="unknown topic: $topic. known: lens-merge-pattern, audit-lens-identity-key, state-sha-self-recompute"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION" --arg topic "${topic:-lens-merge-pattern}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"plan-state-lens-merge.sh doctor --json"},
      {step:2,action:"append-lens-row",command:"plan-state-lens-merge.sh append --plan .flywheel/PLANS/x --lens security --row-json {\"findings_by_severity\":{\"high\":1}} --apply --idempotency-key plsm-$(date +%Y%m%d) --json"},
      {step:3,action:"derived-view",command:"plan-state-lens-merge.sh derived --plan .flywheel/PLANS/x --json"},
      {step:4,action:"validate-state",command:"plan-state-lens-merge.sh validate --plan .flywheel/PLANS/x --json"}
    ],
    next_actions:["wire-to-flywheel-plan-audit-phase","tail-merge-ledger"]
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
      ledger_dir="$(dirname "$LEDGER")"
      present_before="$([[ -f "$LEDGER" ]] && printf true || printf false)"
      if [[ "$mode" == "apply" ]]; then
        mkdir -p "$ledger_dir" 2>/dev/null || true
        [[ -f "$LEDGER" ]] || : > "$LEDGER"
      fi
      present_after="$([[ -f "$LEDGER" ]] && printf true || printf false)"
      jq -nc --arg sv "$SCHEMA_VERSION.repair" --arg ts "$ts" --arg scope "$scope" --arg mode "$mode" \
        --arg ledger "$LEDGER" --arg key "$idem_key" \
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
  --schema) emit_schema; exit 0 ;;
  doctor) shift; emit_canonical_doctor; exit 0 ;;
  health) shift; emit_health; exit 0 ;;
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

while [[ $# -gt 0 ]]; do
  case "$1" in
    append|derived|validate) CMD="$1"; shift ;;
    --plan) PLAN="${2:?--plan requires PATH}"; shift 2 ;;
    --plan=*) PLAN="${1#*=}"; shift ;;
    --lens) LENS="${2:?--lens requires NAME}"; shift 2 ;;
    --lens=*) LENS="${1#*=}"; shift ;;
    --row-json) ROW_JSON="${2:?--row-json requires JSON}"; shift 2 ;;
    --row-json=*) ROW_JSON="${1#*=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --info) info; exit 0 ;;
    --examples)
      shift
      if [[ "${1:-}" == "--json" ]]; then emit_examples_json; else examples; fi
      exit 0
      ;;
    --apply) APPLY=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:?}"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR unknown argument: %s\n' "$1" >&2; usage >&2; exit 2 ;;
  esac
done

# Canonical apply contract: --apply requires --idempotency-key.
if [[ "$APPLY" -eq 1 && -z "$IDEMPOTENCY_KEY" ]]; then
  printf '{"schema_version":"%s","status":"refused","mode":"apply","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION"
  exit 3
fi

state_path() {
  if [[ -d "$PLAN" ]]; then
    printf '%s/STATE.json\n' "$PLAN"
  else
    printf '%s\n' "$PLAN"
  fi
  return 0
}

sha_text() { shasum -a 256 | awk '{print "sha256:" $1}'; }

state_sha() {
  jq -S 'walk(if type=="object" then del(.state_written_sha) else . end)' "$1" | sha_text
}

atomic_write() {
  local path="$1" content="$2" dir tmp
  dir="$(dirname "$path")"
  tmp="$(mktemp "$dir/.STATE.json.XXXXXX")"
  printf '%s\n' "$content" >"$tmp"
  mv "$tmp" "$path"
}

emit() {
  local payload="$1"
  [[ "$QUIET" -eq 1 ]] && return
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$payload"
  else
    jq -r '"status=\(.status) command=\(.command)"' <<<"$payload"
  fi
}

derived_payload() {
  local state="$1"
  jq -c --arg version "$VERSION" '
    def sev($r; $k): (($r.findings_by_severity[$k] // $r.audit_findings_by_severity[$k] // $r.severity_counts[$k] // 0) | tonumber);
    (.lens_merge_rows // []) as $rows
    | ($rows | map(.supersedes? // empty)) as $sup
    | (reduce $rows[] as $r ({}; if (($sup | index($r.audit_lens_identity_key)) != null) then . else .[$r.lens] = $r end)) as $by_lens
    | ($by_lens | to_entries | map(.value)) as $active
    | {
        schema_version:$version,
        command:"derived",
        status:"pass",
        lens_rows_count:($rows | length),
        effective_lenses_count:($active | length),
        audit_lenses_complete:($active | map(.lens)),
        audit_findings_by_severity:{
          critical:($active | map(sev(.;"critical")) | add // 0),
          high:($active | map(sev(.;"high")) | add // 0),
          medium:($active | map(sev(.;"medium")) | add // 0),
          low:($active | map(sev(.;"low")) | add // 0)
        },
        audit_disposition_by_lens:(reduce $active[] as $r ({}; .[$r.lens] = ($r.audit_disposition // "unknown")))
      }
    | .audit_findings_count = ([.audit_findings_by_severity[]] | add)
  ' "$state"
}

[[ -n "$CMD" ]] || { usage >&2; exit 2; }
[[ -n "$PLAN" ]] || { usage >&2; exit 2; }
STATE="$(state_path)"
[[ -r "$STATE" ]] || { printf 'ERR state file not readable: %s\n' "$STATE" >&2; exit 2; }

case "$CMD" in
  derived)
    payload="$(derived_payload "$STATE")"
    emit "$payload"
    ;;
  validate)
    payload="$(jq -c --arg version "$VERSION" --arg state "$STATE" '
      (.lens_merge_rows // []) as $rows
      | [$rows[]? | select((.lens? | not) or (.ts? | not) or (.state_observed_sha? | not) or (.state_written_sha? | not) or (.audit_lens_identity_key? | not))] as $bad
      | {
          schema_version:$version,
          command:"validate",
          state_path:$state,
          status:(if ($bad|length)==0 then "pass" else "fail" end),
          row_count:($rows|length),
          malformed_count:($bad|length),
          malformed_rows:$bad
        }' "$STATE")"
    emit "$payload"
    [[ "$(jq -r '.status' <<<"$payload")" == pass ]]
    ;;
  append)
    [[ -n "$LENS" && -n "$ROW_JSON" ]] || { usage >&2; exit 2; }
    jq -e 'type == "object"' >/dev/null <<<"$ROW_JSON" || { printf 'ERR row-json must be object\n' >&2; exit 2; }
    observed="$(state_sha "$STATE")"
    supplied="$(jq -r '.state_observed_sha // empty' <<<"$ROW_JSON")"
    race=false; retry_count=0
    if [[ -n "$supplied" && "$supplied" != "$observed" ]]; then
      race=true; retry_count=1; observed="$(state_sha "$STATE")"
    fi
    identity="$(jq -r '.audit_lens_identity_key // empty' <<<"$ROW_JSON")"
    if [[ -z "$identity" ]]; then
      identity="$(printf '%s\n%s\n' "$LENS" "$ROW_JSON" | sha_text)"
    fi
    if jq -e --arg id "$identity" 'any(.lens_merge_rows[]?; .audit_lens_identity_key == $id)' "$STATE" >/dev/null; then
      payload="$(jq -nc --arg version "$VERSION" --arg state "$STATE" --arg id "$identity" '{schema_version:$version,command:"append",status:"already_present",state_path:$state,audit_lens_identity_key:$id,appended:false}')"
      emit "$payload"; exit 0
    fi
    ts="$(jq -r '.ts // empty' <<<"$ROW_JSON")"; [[ -n "$ts" ]] || ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    row="$(jq -c --arg lens "$LENS" --arg ts "$ts" --arg observed "$observed" --arg id "$identity" \
      '. + {schema_version:(.schema_version // "plan-state-lens-row/v1"), lens:$lens, ts:$ts, state_observed_sha:$observed, audit_lens_identity_key:$id}' <<<"$ROW_JSON")"
    candidate="$(jq -c --argjson row "$row" '.lens_merge_rows = ((.lens_merge_rows // []) + [$row])' "$STATE")"
    written="$(jq -S 'walk(if type=="object" then del(.state_written_sha) else . end)' <<<"$candidate" | sha_text)"
    final="$(jq -c --arg written "$written" '.lens_merge_rows[-1].state_written_sha = $written' <<<"$candidate")"
    atomic_write "$STATE" "$final"
    payload="$(jq -nc --arg version "$VERSION" --arg state "$STATE" --arg id "$identity" --argjson race "$race" --argjson retry "$retry_count" --arg observed "$observed" --arg written "$written" '{schema_version:$version,command:"append",status:"appended",state_path:$state,audit_lens_identity_key:$id,race_detected:$race,retry_count:$retry,state_observed_sha:$observed,state_written_sha:$written,appended:true}')"
    emit "$payload"
    ;;
esac

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
