#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.24)
set -euo pipefail

VERSION="orchestrator-callback-artifact-fix-bead.v1.1.0"
SCHEMA_VERSION="orchestrator-callback-artifact-fix-bead/v1"
REPO="$PWD"
LEDGER="${ORCH_CALLBACK_ARTIFACT_FIX_BEAD_LEDGER:-$HOME/.local/state/flywheel/orchestrator-callback-artifact-fix-beads.jsonl}"
TASK_ID="" BEAD="" REASON="" DISPATCH_FILE="" ARTIFACT_LIST="" JSON_OUT=0

usage() {
  cat <<'EOF'
usage:
  orchestrator-callback-artifact-fix-bead.sh --task-id ID --reason REASON --dispatch-file PATH --artifact-list TEXT [--bead ID] [--repo PATH] [--json]
  orchestrator-callback-artifact-fix-bead.sh --info --json
  orchestrator-callback-artifact-fix-bead.sh --schema --json
  orchestrator-callback-artifact-fix-bead.sh --examples [--json]
  orchestrator-callback-artifact-fix-bead.sh doctor --json
  orchestrator-callback-artifact-fix-bead.sh health --json
  orchestrator-callback-artifact-fix-bead.sh validate --json
  orchestrator-callback-artifact-fix-bead.sh audit --json [--limit N]
  orchestrator-callback-artifact-fix-bead.sh why [topic] [--json]
  orchestrator-callback-artifact-fix-bead.sh quickstart [--json]
  orchestrator-callback-artifact-fix-bead.sh repair --scope <ledger-prime> [--dry-run|--apply --idempotency-key KEY] [--json]
  orchestrator-callback-artifact-fix-bead.sh --help|-h
EOF
}

info() {
  jq -nc --arg sv "$SCHEMA_VERSION" --arg version "$VERSION" --arg ledger "$LEDGER" \
    '{
      schema_version:$sv,
      command:"info",
      name:"orchestrator-callback-artifact-fix-bead.sh",
      version:$version,
      ledger:$ledger,
      purpose:"idempotently open acceptance-artifact fix beads via JSONL fallback when a worker callback claims artifacts that are missing or subthreshold",
      subcommands:["doctor","health","validate","audit","why","repair","quickstart"],
      canonical_flags:["--info","--schema","--examples","--json","--task-id","--bead","--reason","--dispatch-file","--artifact-list","--repo"],
      capabilities:[
        "dedupe-by-task-reason-artifact-hash",
        "jsonl-fallback-bead-creation",
        "reused-on-existing-fix-bead",
        "task-id-sanitization",
        "ledger-append-per-fix-bead"
      ],
      apply_supported:false,
      dry_run_supported:false,
      idempotency_key_required_for_apply:false,
      mutates_state:true,
      env_vars:["ORCH_CALLBACK_ARTIFACT_FIX_BEAD_LEDGER"],
      exit_codes:{"0":"pass","2":"bad-args"}
    }'
}

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"schema",
    input_schema:{
      type:"object",
      required:["task_id","reason","dispatch_file"],
      properties:{
        task_id:{type:"string"},
        bead:{type:"string"},
        reason:{type:"string",description:"e.g., artifact_missing, artifact_subthreshold, artifact_malformed"},
        dispatch_file:{type:"string",description:"path to the dispatch packet that produced this callback"},
        artifact_list:{type:"string",description:"newline-separated list of missing/malformed artifact paths"},
        repo:{type:"string"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","ts","status","action","task_id","reason","dedupe_key","fix_bead_id"],
      properties:{
        schema_version:{const:"orchestrator-callback-artifact-fix-bead/v1"},
        ts:{type:"string",format:"date-time"},
        status:{enum:["pass"]},
        action:{enum:["reused","jsonl_fallback"]},
        task_id:{type:"string"},
        bead:{type:"string"},
        reason:{type:"string"},
        dispatch_file:{type:"string"},
        artifact_list:{type:"array",items:{type:"string"}},
        dedupe_key:{type:"string"},
        fix_bead_id:{type:"string"}
      }
    },
    exit_codes:{"0":"pass","2":"bad-args"}
  }'
}

examples() {
  cat <<'EOF'
orchestrator-callback-artifact-fix-bead.sh --task-id task-a --reason artifact_missing --dispatch-file /tmp/dispatch.md --artifact-list 'a.sh' --json
ORCH_CALLBACK_ARTIFACT_FIX_BEAD_LEDGER=/tmp/fix-ledger.jsonl orchestrator-callback-artifact-fix-bead.sh --repo /tmp/repo --task-id task-a --reason artifact_subthreshold --dispatch-file /tmp/dispatch.md --artifact-list $'a.sh\nb.json' --json
EOF
}

emit_examples_json() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"examples",
    examples:[
      {name:"open-fix-bead-single-artifact",invocation:"orchestrator-callback-artifact-fix-bead.sh --task-id task-a --reason artifact_missing --dispatch-file /tmp/dispatch.md --artifact-list a.sh --json",purpose:"open fix bead for a single missing artifact"},
      {name:"multi-artifact-fixture-test",invocation:"ORCH_CALLBACK_ARTIFACT_FIX_BEAD_LEDGER=/tmp/fix.jsonl orchestrator-callback-artifact-fix-bead.sh --repo /tmp/repo --task-id task-a --reason artifact_subthreshold --dispatch-file /tmp/d.md --artifact-list $'a.sh\\nb.json' --json",purpose:"open fix bead for multiple subthreshold artifacts (newline-separated)"},
      {name:"doctor",invocation:"orchestrator-callback-artifact-fix-bead.sh doctor --json",purpose:"verify jq, shasum, ledger writable, repo .beads dir"},
      {name:"audit",invocation:"orchestrator-callback-artifact-fix-bead.sh audit --json",purpose:"tail recent fix-bead ledger rows"}
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
        {name:"jq",status:$jq_s,detail:"jq required for envelope emission + JSONL append"},
        {name:"shasum",status:$shasum_s,detail:"shasum required for dedupe-by-task-reason-artifact hash"},
        {name:"ledger_writable",status:$ledger_s,path:$ledger,detail:"append-only fix-bead ledger"}
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
    '{schema_version:$sv,command:"validate",ts:$ts,status:$status,ledger:$ledger,row_count:$rows,invalid_row_count:$invalid,check:"every fix-bead row has non-empty schema_version"}'
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
    ""|artifact-validator-companion)
      body='Companion to orchestrator-callback-artifact-validator.sh: when validator flags missing or subthreshold acceptance artifacts in a worker callback, this script opens a fix bead via direct JSONL append to .beads/issues.jsonl. Dedupe-by-(task_id, reason, artifact_list_sha) ensures repeat callbacks for the same gap reuse the existing fix bead.'
      ;;
    dedupe-key-format)
      body='dedupe_key = "<task_id>:<reason>:<sha12-of-artifact-list>". Same task, same reason, same artifact set → same key → returns existing fix bead with action:"reused". Different artifact list → new key → new fix bead. Prevents fix-bead spam when the same callback comes back multiple times.'
      ;;
    jsonl-fallback-only)
      body='This surface ONLY uses JSONL fallback (direct .beads/issues.jsonl append) — it does NOT shell out to `br create`. Reason: callback-validation is an orchestrator-side surface that may run when br is wedged. Direct append keeps the validator loop unblocked. Beads daemon picks up new rows on next sync.'
      ;;
    *)
      body="unknown topic: $topic. known: artifact-validator-companion, dedupe-key-format, jsonl-fallback-only"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION" --arg topic "${topic:-artifact-validator-companion}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"orchestrator-callback-artifact-fix-bead.sh doctor --json"},
      {step:2,action:"open-fix-bead",command:"orchestrator-callback-artifact-fix-bead.sh --task-id task-x --reason artifact_missing --dispatch-file /tmp/d.md --artifact-list a.sh --json"},
      {step:3,action:"verify-no-duplicate",command:"orchestrator-callback-artifact-fix-bead.sh --task-id task-x --reason artifact_missing --dispatch-file /tmp/d.md --artifact-list a.sh --json # should action=reused"},
      {step:4,action:"audit",command:"orchestrator-callback-artifact-fix-bead.sh audit --json"}
    ],
    next_actions:["wire-to-orchestrator-callback-artifact-validator","tail-fix-bead-ledger"]
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
fail_usage() { printf 'ERR: %s\n' "$1" >&2; usage >&2; exit 2; }
now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
safe_part() { printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '-' | sed 's/--*/-/g; s/^-//; s/-$//'; }
append_ledger() { mkdir -p "$(dirname "$LEDGER")" 2>/dev/null || return 1; jq -c . <<<"$1" >>"$LEDGER" 2>/dev/null; }
dedupe_lookup() { [[ -f "$LEDGER" ]] || return 1; jq -r --arg key "$1" 'select(.dedupe_key == $key) | .fix_bead_id' "$LEDGER" 2>/dev/null | head -1; }
emit() { [[ "$JSON_OUT" -eq 1 ]] && printf '%s\n' "$1" || jq -r '"status=\(.status) action=\(.action) fix_bead_id=\(.fix_bead_id)"' <<<"$1"; }

# Canonical no-dash subcommand intercept BEFORE main arg parser.
case "${1:-}" in
  --schema) emit_schema; exit 0 ;;
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

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 ;;
    --task-id) TASK_ID="${2:-}"; shift 2 ;;
    --bead) BEAD="${2:-}"; shift 2 ;;
    --reason) REASON="${2:-}"; shift 2 ;;
    --dispatch-file) DISPATCH_FILE="${2:-}"; shift 2 ;;
    --artifact-list) ARTIFACT_LIST="${2:-}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --info) info; exit 0 ;;
    --examples)
      shift
      if [[ "${1:-}" == "--json" ]]; then emit_examples_json; else examples; fi
      exit 0
      ;;
    --help|-h) usage; exit 0 ;;
    *) fail_usage "unknown argument: $1" ;;
  esac
done

REPO="$(cd "$REPO" 2>/dev/null && pwd -P)" || fail_usage "repo not found: $REPO"
[[ -n "$TASK_ID" ]] || fail_usage "missing --task-id"
[[ -n "$REASON" ]] || fail_usage "missing --reason"
[[ -n "$DISPATCH_FILE" ]] || fail_usage "missing --dispatch-file"

safe_task="$(safe_part "$TASK_ID")"; [[ -n "$safe_task" ]] || safe_task="unknown"
dedupe_hash="$(printf '%s:%s:%s' "$TASK_ID" "$REASON" "$ARTIFACT_LIST" | shasum -a 256 | awk '{print substr($1,1,12)}')"
dedupe_key="${TASK_ID}:${REASON}:${dedupe_hash}"
existing="$(dedupe_lookup "$dedupe_key" || true)"
if [[ -n "$existing" ]]; then
  row="$(jq -nc --arg ts "$(now_iso)" --arg task "$TASK_ID" --arg reason "$REASON" --arg dedupe "$dedupe_key" --arg fix "$existing" '{schema_version:"orchestrator-callback-artifact-fix-bead/v1",ts:$ts,status:"pass",action:"reused",task_id:$task,reason:$reason,dedupe_key:$dedupe,fix_bead_id:$fix}')"
  emit "$row"; exit 0
fi

fix_id="flywheel-fix-${dedupe_hash}"
title="fix-${safe_task}-acceptance-artifacts"
desc="$(jq -Rs . <<EOF
Acceptance artifact validation failed for ${TASK_ID}.

reason=${REASON}
parent_bead=${BEAD:-unknown}
dispatch_file=${DISPATCH_FILE}

Missing or malformed artifacts:
${ARTIFACT_LIST:-<none>}
EOF
)"
jsonl="$REPO/.beads/issues.jsonl"
mkdir -p "$(dirname "$jsonl")"
if ! jq -e --arg id "$fix_id" 'select(.id == $id)' "$jsonl" >/dev/null 2>&1; then
  jq -nc --arg id "$fix_id" --arg title "$title" --argjson description "$desc" --arg now "$(now_iso)" --arg repo "$REPO" \
    '{id:$id,title:$title,description:$description,status:"open",priority:0,issue_type:"bug",created_at:$now,created_by:"orchestrator-callback-artifact-validator",updated_at:$now,source_repo:$repo,labels:["orchestrator-callback-artifact-validator","auto-fix"],compaction_level:0,original_size:0}' >>"$jsonl"
fi

row="$(jq -nc --arg ts "$(now_iso)" --arg task "$TASK_ID" --arg bead "$BEAD" --arg reason "$REASON" --arg dispatch "$DISPATCH_FILE" --arg artifacts "$ARTIFACT_LIST" --arg dedupe "$dedupe_key" --arg fix "$fix_id" '{schema_version:"orchestrator-callback-artifact-fix-bead/v1",ts:$ts,status:"pass",action:"jsonl_fallback",task_id:$task,bead:$bead,reason:$reason,dispatch_file:$dispatch,artifact_list:($artifacts | split("\n") | map(select(length > 0))),dedupe_key:$dedupe,fix_bead_id:$fix}')"
append_ledger "$row" || true
emit "$row"
