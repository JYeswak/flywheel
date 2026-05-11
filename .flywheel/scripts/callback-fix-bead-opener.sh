#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.1)
# L5 lint requires `set -euo pipefail`. The script uses explicit `|| true`
# and `set +e` around the `br create` block to preserve rc capture for the
# pass/jsonl_fallback bifurcation.
set -euo pipefail

VERSION="callback-fix-bead-opener.v1.1.0"
SCHEMA_VERSION="callback-fix-bead-opener/v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO="$REPO_DEFAULT"
LEDGER="${CALLBACK_FIX_BEAD_LEDGER:-$HOME/.local/state/flywheel/callback-fix-beads.jsonl}"
BR_BIN="${CALLBACK_FIX_BEAD_BR_BIN:-br}"
JSON_OUT=0
TASK_ID=""
BEAD=""
REASON=""
EXPECTED=""
ACTUAL=""
CMD=""
IDEMPOTENCY_KEY=""
APPLY_MODE=""
REPAIR_SCOPE=""
SUBCOMMAND_ARGS=()

usage() {
  cat <<'EOF'
usage:
  callback-fix-bead-opener.sh --task-id ID --reason REASON [--bead ID] [--expected TEXT] [--actual TEXT] [--repo PATH] [--json]
  callback-fix-bead-opener.sh --info --json
  callback-fix-bead-opener.sh --schema --json
  callback-fix-bead-opener.sh --examples [--json]
  callback-fix-bead-opener.sh doctor --json
  callback-fix-bead-opener.sh health --json
  callback-fix-bead-opener.sh repair --scope <ledger-prime|stale-dedupe> [--dry-run|--apply --idempotency-key KEY] [--json]
  callback-fix-bead-opener.sh validate --json
  callback-fix-bead-opener.sh audit --json [--limit N]
  callback-fix-bead-opener.sh why [reason] [--json]
  callback-fix-bead-opener.sh quickstart [--json]
  callback-fix-bead-opener.sh --help|-h
EOF
}

emit_info() {
  jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg name "callback-fix-bead-opener.sh" \
    --arg version "$VERSION" \
    --arg repo "$REPO_DEFAULT" \
    --arg ledger "$LEDGER" \
    '{
      schema_version:$sv,
      command:"info",
      name:$name,
      version:$version,
      repo:$repo,
      ledger:$ledger,
      purpose:"idempotently open callback L112 verification fix beads",
      subcommands:["doctor","health","repair","validate","audit","why","quickstart","schema"],
      canonical_flags:["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--task-id","--bead","--reason","--expected","--actual","--repo"],
      capabilities:["create-fix-bead","dedupe-by-task-reason","jsonl-fallback","ledger-append","idempotent-run"],
      apply_supported:true,
      dry_run_supported:true,
      idempotency_key_required_for_apply:true,
      mutates_state:true,
      env_vars:["CALLBACK_FIX_BEAD_LEDGER","CALLBACK_FIX_BEAD_BR_BIN"]
    }'
}

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"schema",
    input_schema:{
      type:"object",
      required:["task_id","reason"],
      properties:{
        task_id:{type:"string",description:"dispatch task id"},
        reason:{type:"string",description:"l112 failure reason (e.g., l112_verify_failed, l112_output_mismatch)"},
        bead:{type:"string",description:"parent bead id (optional)"},
        expected:{type:"string",description:"expected probe output"},
        actual:{type:"string",description:"actual probe output"},
        repo:{type:"string",description:"repo root path"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","ts","status","action","task_id","reason","dedupe_key","fix_bead_id"],
      properties:{
        schema_version:{const:$sv},
        ts:{type:"string",format:"date-time"},
        status:{enum:["pass"]},
        action:{enum:["reused","created","jsonl_fallback"]},
        task_id:{type:"string"},
        bead:{type:"string"},
        reason:{type:"string"},
        expected:{type:"string"},
        actual:{type:"string"},
        dedupe_key:{type:"string"},
        fix_bead_id:{type:"string"},
        br_rc:{type:"integer"},
        br_output:{type:"string"}
      }
    },
    exit_codes:{"0":"pass","2":"bad-args","3":"refused-apply-without-idempotency-key"}
  }'
}

emit_examples_text() {
  cat <<'EOF'
callback-fix-bead-opener.sh --task-id task-a --bead flywheel-a --reason l112_output_mismatch --expected OK --actual NO --json
CALLBACK_FIX_BEAD_BR_BIN=/tmp/fake-br callback-fix-bead-opener.sh --task-id task-a --reason l112_verify_failed --json
EOF
}

emit_examples_json() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"examples",
    examples:[
      {name:"open-fix-bead-on-output-mismatch",invocation:"callback-fix-bead-opener.sh --task-id task-a --bead flywheel-a --reason l112_output_mismatch --expected OK --actual NO --json",purpose:"open fix bead for callback whose l112 probe output did not match expected"},
      {name:"open-fix-bead-on-verify-failure",invocation:"CALLBACK_FIX_BEAD_BR_BIN=/tmp/fake-br callback-fix-bead-opener.sh --task-id task-a --reason l112_verify_failed --json",purpose:"open fix bead when l112 probe command exited non-zero (uses fake br for tests)"},
      {name:"doctor",invocation:"callback-fix-bead-opener.sh doctor --json",purpose:"verify jq, br binary, ledger writable, repo dir present"},
      {name:"health",invocation:"callback-fix-bead-opener.sh health --json",purpose:"report ledger row count + recent fix-bead actions"},
      {name:"repair-ledger-prime-dry-run",invocation:"callback-fix-bead-opener.sh repair --scope ledger-prime --dry-run --json",purpose:"dry-run: ensure ledger parent dir + empty file exist"},
      {name:"repair-apply-with-idem-key",invocation:"callback-fix-bead-opener.sh repair --scope ledger-prime --apply --idempotency-key fix-2026-05-11 --json",purpose:"apply ledger prime with idempotency key"}
    ]
  }'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"callback-fix-bead-opener.sh doctor --json"},
      {step:2,action:"check-health",command:"callback-fix-bead-opener.sh health --json"},
      {step:3,action:"open-fix-bead",command:"callback-fix-bead-opener.sh --task-id <TASK> --reason <REASON> --json"},
      {step:4,action:"verify-via-audit",command:"callback-fix-bead-opener.sh audit --json"}
    ],
    next_actions:["dispatch-callback-receipt-validator","tail-ledger"]
  }'
}

emit_why() {
  local topic="${1:-}"
  local body=""
  case "$topic" in
    ""|fix-bead-class)
      body='Fix-beads are auto-opened when a worker callback fails L112 verification. They carry the failed task_id, expected/actual probe output, and dedupe key so the orchestrator can route a repair without manual triage. The opener is idempotent: same (task_id, reason) returns the existing fix bead id from the ledger.'
      ;;
    dedupe-key)
      body='dedupe_key=<task_id>:<reason>. The opener looks up the ledger first; if a fix bead already exists for that (task,reason), it is returned with action=reused. Only the first failure creates a new bead.'
      ;;
    jsonl-fallback)
      body='If the br CLI is unavailable or fails (e.g., DB locked, network broker down), the opener writes the bead row directly into .beads/issues.jsonl with a deterministic id (flywheel-fix-<sha8>). This keeps the L112 retry pipeline moving and surfaces the bead at next br sync --import-only.'
      ;;
    *)
      body="unknown topic: $topic. known: fix-bead-class, dedupe-key, jsonl-fallback"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION" --arg topic "${topic:-fix-bead-class}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

doctor_checks() {
  local ts; ts="$(now_iso)"
  local jq_status="pass"; command -v jq >/dev/null 2>&1 || jq_status="fail"
  local br_status="pass"; local br_path; br_path="$(command -v "$BR_BIN" 2>/dev/null || true)"
  [[ -n "$br_path" ]] || br_status="warn"
  local ledger_dir; ledger_dir="$(dirname "$LEDGER")"
  local ledger_status="pass"
  if [[ -e "$LEDGER" ]]; then
    [[ -w "$LEDGER" ]] || ledger_status="fail"
  else
    [[ -d "$ledger_dir" ]] || ledger_status="warn"
  fi
  local repo_status="pass"
  [[ -d "$REPO_DEFAULT" ]] || repo_status="fail"
  local overall="pass"
  for s in "$jq_status" "$br_status" "$ledger_status" "$repo_status"; do
    case "$s" in
      fail) overall="fail" ;;
      warn) [[ "$overall" == "pass" ]] && overall="warn" ;;
    esac
  done
  jq -nc --arg sv "$SCHEMA_VERSION.doctor" --arg ts "$ts" --arg overall "$overall" \
    --arg jq_s "$jq_status" --arg br_s "$br_status" --arg br_path "${br_path:-}" \
    --arg ledger_s "$ledger_status" --arg ledger "$LEDGER" \
    --arg repo_s "$repo_status" --arg repo "$REPO_DEFAULT" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      checks:[
        {name:"jq",status:$jq_s,detail:"jq required for envelope emission"},
        {name:"br_binary",status:$br_s,path:$br_path,detail:"br CLI for bead create (falls back to jsonl-append on failure)"},
        {name:"ledger_writable",status:$ledger_s,path:$ledger,detail:"append-only fix-bead ledger"},
        {name:"repo_dir",status:$repo_s,path:$repo,detail:"flywheel repo root for jsonl-fallback path"}
      ]
    }'
}

health_summary() {
  local ts; ts="$(now_iso)"
  local row_count=0
  local last_ts=""
  local actions_summary='{}'
  if [[ -r "$LEDGER" ]]; then
    row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$row_count" ]] && row_count=0
    if [[ "$row_count" -gt 0 ]]; then
      last_ts="$(tail -n 1 "$LEDGER" 2>/dev/null | jq -r '.ts // empty' 2>/dev/null || true)"
      actions_summary="$(jq -cs 'group_by(.action) | map({key:.[0].action,value:length}) | from_entries' "$LEDGER" 2>/dev/null || printf '%s' '{}')"
      [[ -z "$actions_summary" ]] && actions_summary='{}'
    fi
  fi
  local status="pass"
  [[ "$row_count" -gt 200 ]] && status="warn"
  jq -nc --arg sv "$SCHEMA_VERSION.health" --arg ts "$ts" --arg status "$status" \
    --arg ledger "$LEDGER" --argjson row_count "${row_count:-0}" \
    --arg last_ts "${last_ts:-}" --argjson actions "$actions_summary" \
    '{
      schema_version:$sv,
      command:"health",
      ts:$ts,
      status:$status,
      ledger:$ledger,
      ledger_row_count:$row_count,
      last_action_ts:$last_ts,
      actions_summary:$actions
    }'
}

validate_self() {
  local ts; ts="$(now_iso)"
  local rows=0 invalid=0
  if [[ -r "$LEDGER" ]]; then
    rows="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$rows" ]] && rows=0
    if [[ "$rows" -gt 0 ]]; then
      invalid="$(jq -c 'select((.schema_version // "") != "callback-fix-bead-opener/v1" or (.dedupe_key // "") == "" or (.fix_bead_id // "") == "")' "$LEDGER" 2>/dev/null | wc -l | tr -d ' ')"
      [[ -z "$invalid" ]] && invalid=0
    fi
  fi
  local status="pass"
  [[ "$invalid" -gt 0 ]] && status="violations"
  jq -nc --arg sv "$SCHEMA_VERSION.validate" --arg ts "$ts" --arg status "$status" \
    --argjson rows "${rows:-0}" --argjson invalid "${invalid:-0}" --arg ledger "$LEDGER" \
    '{
      schema_version:$sv,
      command:"validate",
      ts:$ts,
      status:$status,
      ledger:$ledger,
      ledger_row_count:$rows,
      invalid_row_count:$invalid,
      check:"every row has schema_version=callback-fix-bead-opener/v1, non-empty dedupe_key + fix_bead_id"
    }'
}

audit_tail() {
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

repair_run() {
  local scope="$REPAIR_SCOPE"
  local mode="${APPLY_MODE:-dry_run}"
  local idem_key="$IDEMPOTENCY_KEY"
  local ts; ts="$(now_iso)"
  if [[ -z "$scope" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","reason":"--scope required (ledger-prime|stale-dedupe)","exit_code":2}\n' "$SCHEMA_VERSION"
    exit 2
  fi
  if [[ "$mode" == "apply" && -z "$idem_key" ]]; then
    printf '{"schema_version":"%s.repair","status":"refused","mode":"apply","scope":"%s","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION" "$scope"
    exit 3
  fi
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
    stale-dedupe)
      local stale_count=0
      if [[ -r "$LEDGER" ]]; then
        stale_count="$(jq -c 'select((.fix_bead_id // "") == "" or (.fix_bead_id // "") == "created_unparsed")' "$LEDGER" 2>/dev/null | wc -l | tr -d ' ')"
        [[ -z "$stale_count" ]] && stale_count=0
      fi
      jq -nc --arg sv "$SCHEMA_VERSION.repair" --arg ts "$ts" --arg scope "$scope" --arg mode "$mode" \
        --arg ledger "$LEDGER" --arg key "$idem_key" --argjson stale "${stale_count:-0}" \
        '{schema_version:$sv,command:"repair",ts:$ts,status:"pass",scope:$scope,mode:$mode,idempotency_key:$key,ledger:$ledger,stale_dedupe_rows:$stale,note:"read-only probe (rewriting historical ledger rows is operator concern, not auto-scope)"}'
      ;;
    *)
      printf '{"schema_version":"%s.repair","status":"refused","scope":"%s","reason":"unknown scope; known: ledger-prime, stale-dedupe","exit_code":2}\n' "$SCHEMA_VERSION" "$scope"
      exit 2
      ;;
  esac
}

fail_usage() {
  printf 'ERR: %s\n' "$1" >&2
  usage >&2
  exit 2
}

now_iso() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

safe_id_part() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9._-' '-' | sed 's/--*/-/g; s/^-//; s/-$//'
}

append_ledger() {
  mkdir -p "$(dirname "$LEDGER")" 2>/dev/null || return 1
  jq -c . <<<"$1" >>"$LEDGER" 2>/dev/null || true
}

dedupe_lookup() {
  [[ -f "$LEDGER" ]] || return 1
  jq -r --arg key "$1" 'select(.dedupe_key == $key) | .fix_bead_id' "$LEDGER" 2>/dev/null | head -1
}

emit() {
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$1"
  else
    printf 'status=%s fix_bead_id=%s action=%s\n' \
      "$(jq -r '.status' <<<"$1")" \
      "$(jq -r '.fix_bead_id' <<<"$1")" \
      "$(jq -r '.action' <<<"$1")"
  fi
}

append_jsonl_fallback() {
  local id="$1" title="$2" desc="$3"
  local jsonl="$REPO/.beads/issues.jsonl"
  local now row
  mkdir -p "$(dirname "$jsonl")"
  now="$(now_iso)"
  row="$(jq -nc \
    --arg id "$id" \
    --arg title "$title" \
    --arg description "$desc" \
    --arg now "$now" \
    --arg repo "$REPO" \
    '{id:$id,title:$title,description:$description,status:"open",priority:0,issue_type:"bug",created_at:$now,created_by:"callback-receipt-validator",updated_at:$now,source_repo:$repo,labels:["callback-receipt-validator","auto-fix"],compaction_level:0,original_size:0}')"
  if [[ -f "$jsonl" ]] && jq -e --arg id "$id" 'select(.id == $id)' "$jsonl" >/dev/null 2>&1; then
    return 0
  fi
  printf '%s\n' "$row" >>"$jsonl"
}

run_open() {
  local safe_task title desc dedupe existing output rc fix_id action row hash
  [[ -n "$TASK_ID" ]] || fail_usage "missing --task-id"
  [[ -n "$REASON" ]] || fail_usage "missing --reason"
  # flywheel-0u9ch + flywheel-j3dbv defensive guard: refuse to write prod beads
  # when (a) REPO resolves to this script's own owning repo (the live prod
  # flywheel repo) AND (b) --bead matches a known test-fixture sentinel name.
  #
  # Test-pollution class: the validator's open_fix_bead() side-effect was
  # creating phantom prod beads (`fix-t-1-l112-mismatch`,
  # `fix-test-1-l112-mismatch`) from tests that piped fake DONE callbacks
  # through `$VALIDATOR check` without isolating REPO or overriding
  # CALLBACK_RECEIPT_FIX_BEAD_OPENER. Tests SHOULD set the opener env var to
  # /bin/true (preferred) or pass --repo /tmp/fixture-repo.
  #
  # The two-axis check (prod-REPO AND sentinel-bead) means properly-isolated
  # tests (--repo /tmp/fixture) bypass the guard regardless of bead name —
  # the canonical-cli regression test (legacy run_open + idempotent) uses
  # --bead flywheel-x with --repo /tmp/* and is unaffected.
  local _resolved_repo
  _resolved_repo="$(cd "$REPO" 2>/dev/null && pwd -P || printf '%s' "$REPO")"
  if [[ "$_resolved_repo" == "$REPO_DEFAULT" ]]; then
    case "$BEAD" in
      flywheel-test|flywheel-parent|flywheel-x|flywheel-fixture)
        emit "$(jq -nc \
          --arg sv "$SCHEMA_VERSION" \
          --arg ts "$(now_iso)" \
          --arg task "$TASK_ID" \
          --arg bead "$BEAD" \
          --arg reason "$REASON" \
          --arg repo "$_resolved_repo" \
          '{schema_version:$sv,ts:$ts,status:"refused",action:"refused_test_fixture_bead",task_id:$task,bead:$bead,reason:$reason,repo:$repo,refusal:"caller-supplied --bead matches known test-fixture sentinel AND --repo points at the live prod flywheel repo; set CALLBACK_RECEIPT_FIX_BEAD_OPENER=/bin/true in test, or pass --repo /tmp/fixture-repo, or use a non-sentinel --bead value"}')"
        return 0
        ;;
    esac
  fi
  safe_task="$(safe_id_part "$TASK_ID")"
  [[ -n "$safe_task" ]] || safe_task="unknown"
  title="fix-${safe_task}-l112-mismatch"
  dedupe="${TASK_ID}:${REASON}"
  existing="$(dedupe_lookup "$dedupe" || true)"
  if [[ -n "$existing" ]]; then
    row="$(jq -nc \
      --arg sv "$SCHEMA_VERSION" \
      --arg ts "$(now_iso)" \
      --arg task_id "$TASK_ID" \
      --arg bead "$BEAD" \
      --arg reason "$REASON" \
      --arg dedupe "$dedupe" \
      --arg fix "$existing" \
      '{schema_version:$sv,ts:$ts,status:"pass",action:"reused",task_id:$task_id,bead:$bead,reason:$reason,dedupe_key:$dedupe,fix_bead_id:$fix}')"
    emit "$row"
    return 0
  fi
  desc="Callback L112 verification failed for ${TASK_ID}. Worker reported ${EXPECTED:-<missing>} but verify returned ${ACTUAL:-<missing>}. Re-author task or fix gap. Parent: ${BEAD:-unknown}. reason=${REASON}."
  set +e
  output="$(cd "$REPO" && "$BR_BIN" create "$title" --type bug --priority p0 --status open --description "$desc" --json 2>&1)"
  rc=$?
  set -e
  if [[ "$rc" -eq 0 ]]; then
    fix_id="$(jq -r 'if type == "array" then (.[0].id // empty) else (.id // .issue.id // empty) end' 2>/dev/null <<<"$output" || true)"
    [[ -n "$fix_id" ]] || fix_id="created_unparsed"
    action="created"
  else
    hash="$(printf '%s' "$dedupe" | shasum -a 256 | awk '{print substr($1,1,8)}')"
    fix_id="flywheel-fix-${hash}"
    append_jsonl_fallback "$fix_id" "$title" "$desc"
    action="jsonl_fallback"
  fi
  row="$(jq -nc \
    --arg sv "$SCHEMA_VERSION" \
    --arg ts "$(now_iso)" \
    --arg task_id "$TASK_ID" \
    --arg bead "$BEAD" \
    --arg reason "$REASON" \
    --arg expected "$EXPECTED" \
    --arg actual "$ACTUAL" \
    --arg dedupe "$dedupe" \
    --arg fix "$fix_id" \
    --arg action "$action" \
    --arg br_output "$output" \
    --argjson br_rc "$rc" \
    '{schema_version:$sv,ts:$ts,status:"pass",action:$action,task_id:$task_id,bead:$bead,reason:$reason,expected:$expected,actual:$actual,dedupe_key:$dedupe,fix_bead_id:$fix,br_rc:$br_rc,br_output:$br_output}')"
  append_ledger "$row" || true
  emit "$row"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="${2:-}"; shift 2 ;;
    --task-id) TASK_ID="${2:-}"; shift 2 ;;
    --bead) BEAD="${2:-}"; shift 2 ;;
    --reason) REASON="${2:-}"; shift 2 ;;
    --expected) EXPECTED="${2:-}"; shift 2 ;;
    --actual) ACTUAL="${2:-}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --info) emit_info; exit 0 ;;
    --schema) emit_schema; exit 0 ;;
    --examples)
      shift
      if [[ "${1:-}" == "--json" ]]; then emit_examples_json; else emit_examples_text; fi
      exit 0
      ;;
    doctor|health|validate|quickstart)
      CMD="$1"
      shift
      ;;
    repair|why|audit)
      CMD="$1"
      shift
      SUBCOMMAND_ARGS=("$@")
      break
      ;;
    --apply) APPLY_MODE="apply"; shift ;;
    --dry-run) APPLY_MODE="dry_run"; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:-}"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}"; shift ;;
    --help|-h) usage; exit 0 ;;
    *) fail_usage "unknown argument: $1" ;;
  esac
done

REPO="$(cd "$REPO" 2>/dev/null && pwd -P)" || fail_usage "repo not found: $REPO"

case "$CMD" in
  doctor) doctor_checks; exit 0 ;;
  health) health_summary; exit 0 ;;
  validate) validate_self; exit 0 ;;
  quickstart) emit_quickstart; exit 0 ;;
  audit)
    LIMIT=20
    set -- "${SUBCOMMAND_ARGS[@]:-}"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --limit) LIMIT="${2:-20}"; shift 2 ;;
        --json) shift ;;
        --help|-h) usage; exit 0 ;;
        "") shift ;;
        *) shift ;;
      esac
    done
    audit_tail "$LIMIT"
    exit 0
    ;;
  why)
    TOPIC=""
    set -- "${SUBCOMMAND_ARGS[@]:-}"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --json) shift ;;
        --help|-h) usage; exit 0 ;;
        "") shift ;;
        *) [[ -z "$TOPIC" ]] && TOPIC="$1"; shift ;;
      esac
    done
    emit_why "$TOPIC"
    exit 0
    ;;
  repair)
    set -- "${SUBCOMMAND_ARGS[@]:-}"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --scope) REPAIR_SCOPE="${2:-}"; shift 2 ;;
        --apply) APPLY_MODE="apply"; shift ;;
        --dry-run) APPLY_MODE="dry_run"; shift ;;
        --idempotency-key) IDEMPOTENCY_KEY="${2:-}"; shift 2 ;;
        --idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}"; shift ;;
        --json) shift ;;
        --help|-h) usage; exit 0 ;;
        "") shift ;;
        *) fail_usage "unknown repair arg: $1" ;;
      esac
    done
    repair_run
    exit 0
    ;;
  "") run_open ;;
  *) fail_usage "unknown subcommand: $CMD" ;;
esac
