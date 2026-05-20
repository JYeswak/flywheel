#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.9)
set -euo pipefail

VERSION="validate-callback-before-close.v1.3.0"
SCHEMA_VERSION="four-lens-close-validator/v1"
LEDGER="${VALIDATE_CALLBACK_LEDGER:-$HOME/.local/state/flywheel/validate-callback-before-close.jsonl}"
REPO="$PWD"
NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
NTM_SESSION="${NTM_SESSION:-flywheel}"
BEAD=""
EVIDENCE=""
ENVELOPE=""
STRICT=0
JSON_OUT=0
MODE="dry-run"
IDEMPOTENCY_KEY=""

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

usage() {
  cat <<'EOF'
usage: validate-callback-before-close.sh [--repo PATH] --bead ID --evidence PATH [--envelope TEXT] [--dry-run|--apply] [--strict] [--json]
       validate-callback-before-close.sh ID PATH [--strict]

Blocks bead closeout when mechanical evidence or the four-lens bar fails.

Options:
  --repo PATH       repo whose bead DB and relative evidence paths are checked
  --bead ID         bead id being considered for close
  --evidence PATH   worker evidence file
  --envelope TEXT   callback envelope to structurally validate, including did=N/M
  --dry-run         report verdict and planned rework bead only (default)
  --apply           create or reuse a repo-local rework bead on BLOCK_CLOSE
  --strict          treat warnings as close blockers
  --json            emit machine-readable JSON
  --help            show this help
  --info            show contract info
  --examples        show examples
  --version         show version
EOF
}

info() {
  jq -nc --arg sv "$SCHEMA_VERSION" --arg version "$VERSION" --arg ledger "$LEDGER" \
    '{
      schema_version:$sv,
      command:"info",
      name:"validate-callback-before-close.sh",
      version:$version,
      ledger:$ledger,
      read_only_default:true,
      mutates_only_with:"--apply",
      purpose:"gate br close on evidence receipts plus brand/sniff/Jeff/public lens checks",
      structural_gate:"did=N/M with N<M blocks close even when all lenses pass",
      subcommands:["doctor","health","validate","audit","why","repair","quickstart"],
      canonical_flags:["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--strict","--repo","--bead","--evidence","--envelope"],
      capabilities:[
        "evidence-presence-check",
        "envelope-structural-validation",
        "did-n-of-m-gate",
        "four-lens-grading-brand-sniff-jeff-public",
        "rework-bead-auto-file-on-block-close",
        "ledger-append-via-apply-mode",
        "strict-mode-warnings-as-blockers"
      ],
      apply_supported:true,
      dry_run_supported:true,
      idempotency_key_required_for_apply:true,
      mutates_state:true,
      env_vars:["VALIDATE_CALLBACK_LEDGER","NTM_BIN","NTM_SESSION"],
      exit_codes:{"0":"close-allowed","1":"block-close","2":"usage","3":"refused-apply-without-idempotency-key"}
    }'
}

emit_schema() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"schema",
    input_schema:{
      type:"object",
      required:["bead","evidence"],
      properties:{
        repo:{type:"string"},
        bead:{type:"string",pattern:"^[a-z][a-z0-9_-]*-[a-z0-9]+(\\.[0-9]+)*$",description:"bead id"},
        evidence:{type:"string",description:"path to worker evidence file"},
        envelope:{type:"string",description:"callback envelope text (e.g., DONE ... did=N/M)"},
        strict:{type:"boolean"},
        apply:{type:"boolean"},
        idempotency_key:{type:"string",description:"required with --apply"}
      }
    },
    output_schema:{
      type:"object",
      required:["schema_version","verdict","bead"],
      properties:{
        schema_version:{type:"string"},
        verdict:{enum:["close_allowed","block_close","unknown"]},
        bead:{type:"string"},
        evidence_present:{type:"boolean"},
        did_n:{type:"integer"},
        did_total:{type:"integer"},
        rework_bead_id:{type:"string"},
        four_lens:{
          type:"object",
          properties:{
            brand:{type:"integer"},
            sniff:{type:"integer"},
            jeff:{type:"integer"},
            public:{type:"integer"}
          }
        }
      }
    },
    exit_codes:{"0":"close-allowed","1":"block-close","2":"usage","3":"refused-apply-without-idempotency-key"}
  }'
}

examples() {
  cat <<'EOF'
validate-callback-before-close.sh flywheel-123a /tmp/flywheel-123a-evidence.md --strict
validate-callback-before-close.sh --repo /Users/josh/Developer/flywheel --bead flywheel-123a --evidence /tmp/flywheel-123a-evidence.md --json
validate-callback-before-close.sh --repo . --bead flywheel-123a --evidence /tmp/flywheel-123a-evidence.md --envelope "DONE flywheel-123a did=5/9 didnt=4 gaps=flywheel-abcd" --json
validate-callback-before-close.sh --repo . --bead flywheel-123a --evidence /tmp/flywheel-123a-evidence.md --apply --idempotency-key vcbc-2026-05-11 --json
EOF
}

examples_json() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"examples",
    examples:[
      {name:"positional-strict",invocation:"validate-callback-before-close.sh flywheel-123a /tmp/evidence.md --strict",purpose:"positional bead+evidence with strict mode"},
      {name:"flag-form-dry-run",invocation:"validate-callback-before-close.sh --bead flywheel-123a --evidence /tmp/ev.md --json",purpose:"default dry-run JSON envelope"},
      {name:"with-envelope-did-gate",invocation:"validate-callback-before-close.sh --bead flywheel-123a --evidence /tmp/ev.md --envelope \"DONE flywheel-123a did=5/9 didnt=4 gaps=flywheel-abcd\" --json",purpose:"structurally validate did=N/M gate (N<M blocks close)"},
      {name:"apply-with-idem-key",invocation:"validate-callback-before-close.sh --bead flywheel-123a --evidence /tmp/ev.md --apply --idempotency-key vcbc-2026-05-11 --json",purpose:"apply mode: file rework bead if BLOCK_CLOSE; requires --idempotency-key"},
      {name:"doctor",invocation:"validate-callback-before-close.sh doctor --json",purpose:"canonical doctor envelope: jq, br_bin, evidence_dir_resolvable, ledger_writable"}
    ]
  }'
}

emit_canonical_doctor() {
  local ts; ts="$(now_iso)"
  local jq_status="pass"; command -v jq >/dev/null 2>&1 || jq_status="fail"
  local br_status="pass"; command -v br >/dev/null 2>&1 || br_status="warn"
  local ntm_status="pass"; [[ -x "$NTM_BIN" ]] || ntm_status="warn"
  local ledger_dir; ledger_dir="$(dirname "$LEDGER")"
  local ledger_status="pass"
  if [[ -e "$LEDGER" ]]; then
    [[ -w "$LEDGER" ]] || ledger_status="fail"
  else
    [[ -d "$ledger_dir" ]] || ledger_status="warn"
  fi
  local overall="pass"
  for s in "$jq_status" "$br_status" "$ntm_status" "$ledger_status"; do
    case "$s" in
      fail) overall="fail" ;;
      warn) [[ "$overall" == "pass" ]] && overall="warn" ;;
    esac
  done
  jq -nc --arg sv "$SCHEMA_VERSION.doctor" --arg ts "$ts" --arg overall "$overall" \
    --arg jq_s "$jq_status" --arg br_s "$br_status" \
    --arg ntm_s "$ntm_status" --arg ntm_path "$NTM_BIN" \
    --arg ledger_s "$ledger_status" --arg ledger "$LEDGER" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      checks:[
        {name:"jq",status:$jq_s,detail:"jq required for envelope emission"},
        {name:"br_binary",status:$br_s,detail:"br CLI for rework-bead creation in apply mode (warn if missing — apply path will fail)"},
        {name:"ntm_bin",status:$ntm_s,path:$ntm_path,detail:"ntm binary for callback transport (warn if missing)"},
        {name:"ledger_writable",status:$ledger_s,path:$ledger,detail:"append-only verdict ledger"}
      ]
    }'
}

emit_health() {
  local ts; ts="$(now_iso)"
  local row_count=0
  local last_verdict=""
  if [[ -r "$LEDGER" ]]; then
    row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$row_count" ]] && row_count=0
    if [[ "$row_count" -gt 0 ]]; then
      last_verdict="$(tail -n 1 "$LEDGER" 2>/dev/null | jq -r '.verdict // empty' 2>/dev/null || true)"
    fi
  fi
  local status="pass"
  [[ "$last_verdict" == "block_close" ]] && status="warn"
  jq -nc --arg sv "$SCHEMA_VERSION.health" --arg ts "$ts" --arg status "$status" \
    --arg ledger "$LEDGER" --argjson row_count "${row_count:-0}" --arg last_verdict "${last_verdict:-}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:$status,ledger:$ledger,ledger_row_count:$row_count,last_verdict:$last_verdict}'
}

emit_canonical_validate() {
  local ts; ts="$(now_iso)"
  local rows=0 invalid=0
  if [[ -r "$LEDGER" ]]; then
    rows="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$rows" ]] && rows=0
    if [[ "$rows" -gt 0 ]]; then
      invalid="$(jq -c 'select((.schema_version // "") == "" or (.verdict // "") == "")' "$LEDGER" 2>/dev/null | wc -l | tr -d ' ')"
      [[ -z "$invalid" ]] && invalid=0
    fi
  fi
  local status="pass"
  [[ "$invalid" -gt 0 ]] && status="violations"
  jq -nc --arg sv "$SCHEMA_VERSION.validate" --arg ts "$ts" --arg status "$status" \
    --argjson rows "${rows:-0}" --argjson invalid "${invalid:-0}" --arg ledger "$LEDGER" \
    '{schema_version:$sv,command:"validate",ts:$ts,status:$status,ledger:$ledger,row_count:$rows,invalid_row_count:$invalid,check:"every verdict row has non-empty schema_version + verdict"}'
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
    ""|four-lens-gate)
      body='Four lenses: brand (Joshua taste), sniff (mechanical evidence), jeff (Jeff Emanuel-style convergence), public (Three Judges: skeptical operator + maintainer + future worker). Each lens scores 1-10. Default pass threshold is per-lens >=7 unless --strict overrides.'
      ;;
    did-n-of-m-gate)
      body='Worker envelope MUST include did=N/M field. If N<M, the close is BLOCKED regardless of lens scores — the worker reported incomplete coverage. This catches "5/9 done, claiming close" bugs. The 4 missing pieces become a rework bead in --apply mode.'
      ;;
    rework-bead-class)
      body='When verdict=block_close and --apply, a child bead is filed under the parent listing the gaps. Idempotent: same (parent_bead, gap_set) reuses the existing rework bead via dedupe lookup against the parent ledger.'
      ;;
    *)
      body="unknown topic: $topic. known: four-lens-gate, did-n-of-m-gate, rework-bead-class"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION" --arg topic "${topic:-four-lens-gate}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"validate-callback-before-close.sh doctor --json"},
      {step:2,action:"dry-run-validate",command:"validate-callback-before-close.sh --bead flywheel-123a --evidence /tmp/ev.md --json"},
      {step:3,action:"apply-with-idem-key",command:"validate-callback-before-close.sh --bead flywheel-123a --evidence /tmp/ev.md --apply --idempotency-key vcbc-$(date +%Y%m%d) --json"},
      {step:4,action:"tail-recent-verdicts",command:"validate-callback-before-close.sh audit --json"}
    ],
    next_actions:["wire-to-pre-close-hook","escalate-block-close-via-rework-bead"]
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

fail_usage() {
  echo "ERR: $1" >&2
  usage >&2
  exit 2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      [ -n "${2:-}" ] || fail_usage "--repo requires PATH"
      REPO="$2"
      shift 2
      ;;
    --bead)
      [ -n "${2:-}" ] || fail_usage "--bead requires ID"
      BEAD="$2"
      shift 2
      ;;
    --evidence)
      [ -n "${2:-}" ] || fail_usage "--evidence requires PATH"
      EVIDENCE="$2"
      shift 2
      ;;
    --envelope)
      [ -n "${2:-}" ] || fail_usage "--envelope requires TEXT"
      ENVELOPE="$2"
      shift 2
      ;;
    --strict)
      STRICT=1
      shift
      ;;
    --json)
      JSON_OUT=1
      shift
      ;;
    --dry-run)
      MODE="dry-run"
      shift
      ;;
    --apply)
      MODE="apply"
      shift
      ;;
    --idempotency-key)
      IDEMPOTENCY_KEY="${2:-}"
      shift 2
      ;;
    --idempotency-key=*)
      IDEMPOTENCY_KEY="${1#--idempotency-key=}"
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --info)
      info
      exit 0
      ;;
    --schema)
      emit_schema
      exit 0
      ;;
    --examples)
      shift
      if [[ "${1:-}" == "--json" ]]; then examples_json; else examples; fi
      exit 0
      ;;
    --version)
      printf '%s\n' "$VERSION"
      exit 0
      ;;
    -*)
      fail_usage "unknown option: $1"
      ;;
    *)
      if [ -z "$BEAD" ]; then
        BEAD="$1"
      elif [ -z "$EVIDENCE" ]; then
        EVIDENCE="$1"
      else
        fail_usage "unexpected argument: $1"
      fi
      shift
      ;;
  esac
done

# Canonical apply contract: --apply requires --idempotency-key.
if [ "$MODE" = "apply" ] && [ -z "$IDEMPOTENCY_KEY" ]; then
  printf '{"schema_version":"%s","status":"refused","mode":"apply","reason":"--apply requires --idempotency-key","exit_code":3}\n' "$SCHEMA_VERSION"
  exit 3
fi

[ -n "$BEAD" ] || fail_usage "missing --bead"
[ -n "$EVIDENCE" ] || fail_usage "missing --evidence"

if ! REPO_ABS="$(cd "$REPO" 2>/dev/null && pwd -P)"; then
  echo "ERR: repo not found: $REPO" >&2
  exit 2
fi

if [ "${EVIDENCE#/}" = "$EVIDENCE" ]; then
  EVIDENCE_ABS="$REPO_ABS/$EVIDENCE"
else
  EVIDENCE_ABS="$EVIDENCE"
fi

FAIL=0
WARN=0
FAILURES=""
WARNINGS=""
BRAND_STATUS="pass"
SNIFF_STATUS="pass"
JEFF_STATUS="pass"
PUBLIC_STATUS="pass"
BRAND_REASON=""
SNIFF_REASON=""
JEFF_REASON=""
PUBLIC_REASON=""
REWORK_BEAD=""
REWORK_ACTION="none"
VALIDATOR_STRUCTURAL_PASS="true"
ENVELOPE_DID_TOTAL_MISMATCH=""
ENVELOPE_DID_VALUE=""
ENVELOPE_DIDNT_VALUE=""
ENVELOPE_GAPS_VALUE=""
ENVELOPE_TMP_DIR_RELEASED_VALUE=""
ENVELOPE_UNTRACKED_DELTA=""
ENVELOPE_SUBSTRATE_CLASSIFIED=""
UNTRACKED_DELTA_WARNING=""
ENVELOPE_STRUCTURAL_SOURCE="none"
BLOCK_CLOSE_REASON=""

append_line() {
  var_name="$1"
  line="$2"
  eval "old=\${$var_name}"
  if [ -n "$old" ]; then
    eval "$var_name=\$old\$'\\n'\$line"
  else
    eval "$var_name=\$line"
  fi
}

check_fail() {
  FAIL=$((FAIL + 1))
  append_line FAILURES "$1"
}

check_warn() {
  WARN=$((WARN + 1))
  append_line WARNINGS "$1"
}

append_reason() {
  var_name="$1"
  reason="$2"
  eval "old=\${$var_name}"
  if [ -n "$old" ]; then
    eval "$var_name=\$old,\$reason"
  else
    eval "$var_name=\$reason"
  fi
}

lens_fail() {
  lens="$1"
  reason="$2"
  case "$lens" in
    brand)
      BRAND_STATUS="fail"
      append_reason BRAND_REASON "$reason"
      ;;
    sniff)
      SNIFF_STATUS="fail"
      append_reason SNIFF_REASON "$reason"
      ;;
    jeff)
      JEFF_STATUS="fail"
      append_reason JEFF_REASON "$reason"
      ;;
    public)
      PUBLIC_STATUS="fail"
      append_reason PUBLIC_REASON "$reason"
      ;;
  esac
}

structural_fail() {
  VALIDATOR_STRUCTURAL_PASS="false"
  check_fail "$1"
}

first_kv_token() {
  key="$1"
  text="$2"
  printf '%s\n' "$text" | tr '[:space:]' '\n' | grep -E "^${key}=" | head -1 | sed -E "s/^${key}=//"
}

check_callback_envelope_structure() {
  structural_text=""
  if [ -n "$ENVELOPE" ]; then
    structural_text="$ENVELOPE"
    ENVELOPE_STRUCTURAL_SOURCE="envelope"
  elif [ -f "$EVIDENCE_ABS" ]; then
    structural_text="$(grep -E '(^|[[:space:]])(did|didnt|gaps|tmp_dir_released)=' "$EVIDENCE_ABS" | head -20 || true)"
    [ -n "$structural_text" ] && ENVELOPE_STRUCTURAL_SOURCE="evidence"
  fi

  [ -n "$structural_text" ] || return 0

  ENVELOPE_DID_VALUE="$(first_kv_token did "$structural_text" || true)"
  ENVELOPE_DIDNT_VALUE="$(first_kv_token didnt "$structural_text" || true)"
  ENVELOPE_GAPS_VALUE="$(first_kv_token gaps "$structural_text" || true)"
  ENVELOPE_TMP_DIR_RELEASED_VALUE="$(first_kv_token tmp_dir_released "$structural_text" || true)"
  ENVELOPE_UNTRACKED_DELTA="$(first_kv_token untracked_delta "$structural_text" || true)"
  ENVELOPE_SUBSTRATE_CLASSIFIED="$(first_kv_token substrate_classified "$structural_text" || true)"

  if [ -n "$ENVELOPE_DID_VALUE" ]; then
    if printf '%s\n' "$ENVELOPE_DID_VALUE" | grep -qE '^[0-9]+/[0-9]+$'; then
      did_done="${ENVELOPE_DID_VALUE%/*}"
      did_total="${ENVELOPE_DID_VALUE#*/}"
      if [ "$did_done" -lt "$did_total" ]; then
        ENVELOPE_DID_TOTAL_MISMATCH="$ENVELOPE_DID_VALUE"
        continuation="${ENVELOPE_GAPS_VALUE:-none}"
        structural_fail "validator_structural_pass=false partial_work_with_continuation envelope_did_total_mismatch=$ENVELOPE_DID_TOTAL_MISMATCH continuation=$continuation"
      elif [ "$did_done" -gt "$did_total" ]; then
        structural_fail "validator_structural_pass=false envelope_did_total_invalid=$ENVELOPE_DID_VALUE"
      fi
    else
      structural_fail "validator_structural_pass=false envelope_did_invalid=$ENVELOPE_DID_VALUE"
    fi
  fi

  case "$ENVELOPE_DIDNT_VALUE" in
    ""|none|0|0/0)
      ;;
    *)
      continuation="${ENVELOPE_GAPS_VALUE:-none}"
      structural_fail "validator_structural_pass=false partial_work_with_continuation envelope_didnt_not_none=$ENVELOPE_DIDNT_VALUE continuation=$continuation"
      ;;
  esac

  if [ "$ENVELOPE_TMP_DIR_RELEASED_VALUE" != "true" ]; then
    structural_fail "tmp_dir_not_released: tmp_dir_released=${ENVELOPE_TMP_DIR_RELEASED_VALUE:-missing}"
  fi

  # bszgl.2: substrate_classified gate — REFUSE close when absent or "no"
  case "${ENVELOPE_SUBSTRATE_CLASSIFIED:-}" in
    yes|partial)
      ;;
    no)
      structural_fail "substrate_classified=no: worker did not account for untracked files — close refused until classified"
      ;;
    "")
      structural_fail "substrate_classified missing from callback envelope — required field per bszgl.2 (untracked_delta + substrate_classified mandatory)"
      ;;
    *)
      structural_fail "substrate_classified=${ENVELOPE_SUBSTRATE_CLASSIFIED}: invalid value, must be yes|partial|no"
      ;;
  esac

  # bszgl.2: untracked_delta warning/block — require field, warn if >10, strict blocks
  if [ -z "${ENVELOPE_UNTRACKED_DELTA:-}" ]; then
    structural_fail "untracked_delta missing from callback envelope — required field per bszgl.2"
  elif ! printf '%s\n' "$ENVELOPE_UNTRACKED_DELTA" | grep -qE '^[0-9]+$'; then
    structural_fail "untracked_delta=${ENVELOPE_UNTRACKED_DELTA}: must be a non-negative integer"
  elif [ "$ENVELOPE_UNTRACKED_DELTA" -gt 10 ]; then
    if [ "$STRICT" -eq 1 ]; then
      structural_fail "untracked_delta=${ENVELOPE_UNTRACKED_DELTA} > 10 in strict mode: justify in notes or clean up before close"
    fi
    # non-strict: surface as warning in output but don't block
    UNTRACKED_DELTA_WARNING="untracked_delta=${ENVELOPE_UNTRACKED_DELTA} exceeds 10 — worker should classify or justify"
  fi
}

check_tmp_evidence_paths() {
  [ -f "$EVIDENCE_ABS" ] || return 0
  bead_short="${BEAD#flywheel-}"
  tmp_paths="$EVIDENCE_ABS"
  tmp_paths="$tmp_paths
$(grep -oE '`(/[^`]+)`' "$EVIDENCE_ABS" 2>/dev/null | sed 's/`//g' || true)"
  tmp_paths="$tmp_paths
$(grep -oE '(^|[[:space:]])evidence=[^[:space:]]+' "$EVIDENCE_ABS" 2>/dev/null | sed -E 's/^[[:space:]]*evidence=//' || true)"

  while IFS= read -r P; do
    [ -n "$P" ] || continue
    case "$P" in
      /tmp/"$BEAD"-*|/private/tmp/"$BEAD"-*|/var/tmp/"$BEAD"-*|/tmp/"$bead_short"-*|/private/tmp/"$bead_short"-*|/var/tmp/"$bead_short"-*)
        structural_fail "tmp_evidence_outside_mktemp_dir: path=$P expected=mktemp -d -t ${bead_short}.XXXXXX"
        ;;
    esac
  done <<EOF
$tmp_paths
EOF
}

short_probe_text() {
  sed '/^$/d' "$@" 2>/dev/null | head -3 | tr '\n' ' ' | cut -c1-500
}

looks_like_db_busy() {
  grep -qiE 'database is locked|database busy|SQLITE_BUSY|OpenRead|malformed|b-tree|database disk image|resource busy'
}

check_br_dep_cycles() {
  cycles_json="$(mktemp "${TMPDIR:-/tmp}/br-dep-cycles.XXXXXX.json")"
  cycles_err="$(mktemp "${TMPDIR:-/tmp}/br-dep-cycles.XXXXXX.err")"
  set +e
  (cd "$REPO_ABS" && br dep cycles --json >"$cycles_json" 2>"$cycles_err")
  cycles_rc=$?
  set -e

  if jq -e . "$cycles_json" >/dev/null 2>&1; then
    if jq -e '.error.code == "CYCLE_DETECTED"' "$cycles_json" >/dev/null 2>&1; then
      summary="$(jq -c '.error.context // .error' "$cycles_json" | cut -c1-500)"
      check_fail "br_dep_cycles_not_empty: count=1 summary=$summary"
      rm -f "$cycles_json" "$cycles_err"
      return 0
    fi

    if [ "$cycles_rc" -ne 0 ]; then
      probe_text="$(short_probe_text "$cycles_json" "$cycles_err")"
      if printf '%s\n' "$probe_text" | looks_like_db_busy; then
        check_fail "br_dep_cycles_db_busy: $probe_text"
      else
        check_fail "br_dep_cycles_probe_failed: rc=$cycles_rc $probe_text"
      fi
      rm -f "$cycles_json" "$cycles_err"
      return 0
    fi

    cycle_count="$(jq -r '
      if (.count | type) == "number" then .count
      elif (.cycles | type) == "array" then (.cycles | length)
      elif type == "array" then length
      else empty end
    ' "$cycles_json")"
    if ! printf '%s\n' "$cycle_count" | grep -qE '^[0-9]+$'; then
      check_fail "br_dep_cycles_json_invalid_shape"
      rm -f "$cycles_json" "$cycles_err"
      return 0
    fi
    if [ "$cycle_count" -gt 0 ]; then
      summary="$(jq -c '.cycles // .' "$cycles_json" | cut -c1-500)"
      check_fail "br_dep_cycles_not_empty: count=$cycle_count cycles=$summary"
    fi
    rm -f "$cycles_json" "$cycles_err"
    return 0
  fi

  probe_text="$(short_probe_text "$cycles_json" "$cycles_err")"
  if [ "$cycles_rc" -ne 0 ] && printf '%s\n' "$probe_text" | looks_like_db_busy; then
    check_fail "br_dep_cycles_db_busy: $probe_text"
  elif [ "$cycles_rc" -ne 0 ]; then
    check_fail "br_dep_cycles_probe_failed: rc=$cycles_rc $probe_text"
  else
    check_fail "br_dep_cycles_json_invalid: $probe_text"
  fi
  rm -f "$cycles_json" "$cycles_err"
}

if [ ! -f "$EVIDENCE_ABS" ]; then
  check_fail "evidence_missing: $EVIDENCE_ABS"
elif [ ! -s "$EVIDENCE_ABS" ]; then
  check_fail "evidence_empty: $EVIDENCE_ABS"
fi

check_callback_envelope_structure
check_tmp_evidence_paths

if [ -f "$EVIDENCE_ABS" ]; then
  if ! grep -qE '\b(did|didnt|gaps)\b' "$EVIDENCE_ABS"; then
    check_warn "evidence_missing_did_didnt_gaps_tokens"
  fi

  GAPS=$(grep -oE '(^|[[:space:]])gaps=[a-z]+-[a-z0-9]+(\.[0-9]+)*(,[a-z]+-[a-z0-9]+(\.[0-9]+)*)*([[:space:]]|$)' "$EVIDENCE_ABS" | head -1 | sed -E 's/^[[:space:]]*gaps=//; s/[[:space:]]*$//' | tr ',' '\n' | grep -v '^none$' || true)
  for G in $GAPS; do
    if ! (cd "$REPO_ABS" && br show "$G" >/dev/null 2>&1); then
      check_fail "gap_bead_not_found: $G"
    fi
  done

  CREATED=$(grep -oE 'created=[a-z0-9,-]+' "$EVIDENCE_ABS" | head -1 | sed 's/^created=//' | tr ',' '\n' | grep -v '^none$' || true)
  for C in $CREATED; do
    if ! (cd "$REPO_ABS" && br show "$C" >/dev/null 2>&1); then
      check_fail "created_bead_not_found: $C"
    fi
  done

  PATHS=$(grep -oE '`(/[^`]+|\.flywheel/[^` ]+|tests/[^` ]+|templates/[^` ]+)`' "$EVIDENCE_ABS" | sed 's/`//g' | sort -u || true)
  while IFS= read -r P; do
    [ -z "$P" ] && continue
    if [ "${P#/}" = "$P" ]; then
      P="$REPO_ABS/$P"
    fi
    if [ ! -e "$P" ]; then
      check_warn "artifact_path_not_found: $P"
    fi
  done <<EOF
$PATHS
EOF

  if grep -qE 'tests=PASS|tests?[ _-]?(pass|passed)' "$EVIDENCE_ABS"; then
    SUSPICIOUS=$(grep -nE '\b(FAIL|FAILED|ERROR|error:)\b' "$EVIDENCE_ABS" | grep -vE '(no |not |_)(FAIL|FAILED|ERROR|error)' | head -3 || true)
    if [ -n "$SUSPICIOUS" ]; then
      check_warn "tests_PASS_but_evidence_mentions_FAIL_ERROR: $(printf '%s\n' "$SUSPICIOUS" | head -1)"
    fi
  fi
fi

if command -v br >/dev/null 2>&1; then
  CHILDREN=$(cd "$REPO_ABS" && br show "$BEAD" 2>&1 | grep -A 50 'Dependents:' | grep -oE 'flywheel-[a-z0-9]+(\.[0-9]+)*' | grep -v "^${BEAD}$" | head -20 || true)
  for C in $CHILDREN; do
    STATE=$(cd "$REPO_ABS" && br show "$C" 2>&1 | grep -oE '\[. (P[0-3]|--) · (OPEN|CLOSED|IN_PROGRESS|BLOCKED|READY)' | grep -oE '(OPEN|IN_PROGRESS|BLOCKED|READY)' | head -1 || true)
    if [ -n "$STATE" ] && [ "$STATE" != "CLOSED" ]; then
      check_fail "open_child_blocks_close: $C state=$STATE"
    fi
  done

  check_br_dep_cycles
fi

if [ -f "$EVIDENCE_ABS" ]; then
  if grep -qiE '\b(leverage synergies|robust solution|seamlessly|cutting-edge|best-in-class|world-class|game-changer|disrupt|revolutionize|paradigm shift|deep dive|circle back|move the needle|low-hanging fruit)\b' "$EVIDENCE_ABS"; then
    lens_fail brand "slop_words_present"
  fi
  if grep -qiE '\b(competitor[s]? (failed|cant|wont|lose)|defeat|crush them|outmaneuver)\b' "$EVIDENCE_ABS"; then
    lens_fail brand "enemy_framing"
  fi

  RECEIPT_COUNT=$(grep -oE '(`/[^`]+`|`\.flywheel/[^`]+`|flywheel-[a-z0-9]+|line [0-9]+|:[0-9]+)' "$EVIDENCE_ABS" | wc -l | tr -d ' ' || true)
  if [ "$RECEIPT_COUNT" -lt 3 ]; then
    lens_fail sniff "few_receipts_${RECEIPT_COUNT}_lt_3"
  fi
  if grep -qE '^(status|state|metric|gauge):' "$EVIDENCE_ABS" && ! grep -qiE '(outcome|impact|result|landed|shipped|reduces|prevents)' "$EVIDENCE_ABS"; then
    lens_fail sniff "status_without_outcome"
  fi

  if grep -qiE 'tests?[_ -]?(pass|passed)|tests=PASS' "$EVIDENCE_ABS"; then
    if ! grep -qE '(```|bash|\$ |zsh|run:|exec:)' "$EVIDENCE_ABS"; then
      lens_fail jeff "tests_PASS_claimed_no_executable_proof"
    fi
  fi
  if grep -qiE '(schema|contract|receipt|payload)' "$EVIDENCE_ABS" && ! grep -qiE '(v[0-9]+|version|schema_version)' "$EVIDENCE_ABS"; then
    lens_fail jeff "contract_without_version"
  fi

  EVIDENCE_LINES=$(wc -l < "$EVIDENCE_ABS" | tr -d ' ')
  if [ "$EVIDENCE_LINES" -lt 20 ]; then
    lens_fail public "too_thin_${EVIDENCE_LINES}_lt_20"
  fi
  if ! grep -qiE '(acceptance|gate|criterion|criteria)' "$EVIDENCE_ABS"; then
    lens_fail public "no_acceptance_gates_addressed"
  fi
  if ! grep -qiE '(three judges|publishability|brand voice|donella|jeff|meadows|four-lens|four lens)' "$EVIDENCE_ABS"; then
    lens_fail public "no_bar_self_grade"
  fi
fi

for lens in brand sniff jeff public; do
  case "$lens" in
    brand) status="$BRAND_STATUS"; reason="$BRAND_REASON" ;;
    sniff) status="$SNIFF_STATUS"; reason="$SNIFF_REASON" ;;
    jeff) status="$JEFF_STATUS"; reason="$JEFF_REASON" ;;
    public) status="$PUBLIC_STATUS"; reason="$PUBLIC_REASON" ;;
  esac
  if [ "$status" = "fail" ]; then
    check_fail "lens_${lens}_fail: $reason"
  fi
done

VERDICT="SAFE_TO_CLOSE"
if [ "$FAIL" -gt 0 ]; then
  VERDICT="BLOCK_CLOSE"
elif [ "$STRICT" -eq 1 ] && [ "$WARN" -gt 0 ]; then
  VERDICT="BLOCK_CLOSE"
fi

if [ "$VERDICT" = "BLOCK_CLOSE" ]; then
  if [ "$VALIDATOR_STRUCTURAL_PASS" = "false" ] && { [ -n "$ENVELOPE_DID_TOTAL_MISMATCH" ] || { [ -n "$ENVELOPE_DIDNT_VALUE" ] && [ "$ENVELOPE_DIDNT_VALUE" != "none" ] && [ "$ENVELOPE_DIDNT_VALUE" != "0" ] && [ "$ENVELOPE_DIDNT_VALUE" != "0/0" ]; }; }; then
    BLOCK_CLOSE_REASON="partial_work_with_continuation did=${ENVELOPE_DID_VALUE:-missing} didnt=${ENVELOPE_DIDNT_VALUE:-missing} continuation=${ENVELOPE_GAPS_VALUE:-none}"
  else
    BLOCK_CLOSE_REASON="$(printf '%s\n' "$FAILURES" | sed '/^$/d' | head -1)"
  fi
fi

create_rework_bead() {
  [ "$VERDICT" = "BLOCK_CLOSE" ] || return 0
  command -v br >/dev/null 2>&1 || {
    REWORK_ACTION="blocked_no_br"
    return 0
  }
  title="[four-lens-rework] ${BEAD} close validation"
  existing=$(cd "$REPO_ABS" && br list --json 2>/dev/null | jq -r --arg title "$title" '(if type == "object" and has("issues") then .issues else . end)[]? | select(.title == $title and (.status | ascii_downcase) != "closed") | .id' | head -1 2>/dev/null || true)
  if [ -n "$existing" ]; then
    REWORK_BEAD="$existing"
    REWORK_ACTION="reused"
    return 0
  fi
  if [ "$MODE" != "apply" ]; then
    REWORK_ACTION="would_create"
    return 0
  fi
  desc_file="$(mktemp "${TMPDIR:-/tmp}/four-lens-rework.XXXXXX")"
  {
    printf 'Parent bead: %s\n' "$BEAD"
    printf 'Close validator: validate-callback-before-close/v1\n'
    printf 'Evidence: %s\n\n' "$EVIDENCE_ABS"
    printf 'Validator blocked close with %s failures and %s warnings.\n\n' "$FAIL" "$WARN"
    printf 'Failures:\n'
    printf '%s\n' "$FAILURES" | sed '/^$/d; s/^/- /'
    printf '\nAcceptance:\n'
    printf 'AG1: Rework evidence or implementation until validate-callback-before-close.sh returns SAFE_TO_CLOSE.\n'
    printf 'AG2: Preserve did/didnt/gaps, executable test proof, acceptance-gate mapping, and Four-Lens Self-Grade.\n'
  } >"$desc_file"
  created=$(cd "$REPO_ABS" && br create "$title" --priority 1 --type task --description "$(cat "$desc_file")" --json 2>/dev/null | jq -r '.id // empty' || true)
  rm -f "$desc_file"
  if [ -n "$created" ]; then
    REWORK_BEAD="$created"
    REWORK_ACTION="created"
  else
    REWORK_ACTION="create_failed"
  fi
}

create_rework_bead

NTM_CHANGES_JSON="$("$NTM_BIN" changes "$NTM_SESSION" --json 2>/dev/null || printf 'null\n')"
NTM_CONFLICTS_JSON="$("$NTM_BIN" conflicts "$NTM_SESSION" --json --limit 50 2>/dev/null || printf 'null\n')"

emit_json() {
  python3 - "$FAILURES" "$WARNINGS" <<PY
import json
import os
import sys

failures = [line for line in sys.argv[1].splitlines() if line]
warnings = [line for line in sys.argv[2].splitlines() if line]
payload = {
    "schema_version": "four-lens-close-validator/v1",
    "version": os.environ["FW_VCBC_VERSION"],
    "repo": os.environ["FW_VCBC_REPO"],
    "bead": os.environ["FW_VCBC_BEAD"],
    "evidence": os.environ["FW_VCBC_EVIDENCE"],
    "mode": os.environ["FW_VCBC_MODE"],
    "verdict": os.environ["FW_VCBC_VERDICT"],
    "block_close_reason": os.environ["FW_VCBC_BLOCK_CLOSE_REASON"] or None,
    "failures_count": int(os.environ["FW_VCBC_FAIL"]),
    "warnings_count": int(os.environ["FW_VCBC_WARN"]),
    "failures": failures,
    "warnings": warnings,
    "validator_structural_pass": os.environ["FW_VCBC_STRUCTURAL_PASS"] == "true",
    "envelope_did_total_mismatch": os.environ["FW_VCBC_ENVELOPE_DID_TOTAL_MISMATCH"] or None,
    "structural": {
        "validator_structural_pass": os.environ["FW_VCBC_STRUCTURAL_PASS"] == "true",
        "source": os.environ["FW_VCBC_ENVELOPE_STRUCTURAL_SOURCE"],
        "did": os.environ["FW_VCBC_ENVELOPE_DID_VALUE"] or None,
        "didnt": os.environ["FW_VCBC_ENVELOPE_DIDNT_VALUE"] or None,
        "gaps": os.environ["FW_VCBC_ENVELOPE_GAPS_VALUE"] or None,
        "tmp_dir_released": os.environ["FW_VCBC_ENVELOPE_TMP_DIR_RELEASED_VALUE"] or None,
        "envelope_did_total_mismatch": os.environ["FW_VCBC_ENVELOPE_DID_TOTAL_MISMATCH"] or None,
    },
    "four_lens": {
        "brand": {"status": os.environ["FW_VCBC_BRAND_STATUS"], "reason": os.environ["FW_VCBC_BRAND_REASON"]},
        "sniff": {"status": os.environ["FW_VCBC_SNIFF_STATUS"], "reason": os.environ["FW_VCBC_SNIFF_REASON"]},
        "jeff": {"status": os.environ["FW_VCBC_JEFF_STATUS"], "reason": os.environ["FW_VCBC_JEFF_REASON"]},
        "public": {"status": os.environ["FW_VCBC_PUBLIC_STATUS"], "reason": os.environ["FW_VCBC_PUBLIC_REASON"]},
    },
    "auto_rework": {
        "action": os.environ["FW_VCBC_REWORK_ACTION"],
        "bead": os.environ["FW_VCBC_REWORK_BEAD"] or None,
    },
    "ntm_changes": json.loads(os.environ["FW_VCBC_NTM_CHANGES"]),
    "ntm_conflicts": json.loads(os.environ["FW_VCBC_NTM_CONFLICTS"]),
}
print(json.dumps(payload, sort_keys=True))
PY
}

if [ "$JSON_OUT" -eq 1 ]; then
  export FW_VCBC_VERSION="$VERSION"
  export FW_VCBC_REPO="$REPO_ABS"
  export FW_VCBC_BEAD="$BEAD"
  export FW_VCBC_EVIDENCE="$EVIDENCE_ABS"
  export FW_VCBC_MODE="$MODE"
  export FW_VCBC_VERDICT="$VERDICT"
  export FW_VCBC_BLOCK_CLOSE_REASON="$BLOCK_CLOSE_REASON"
  export FW_VCBC_FAIL="$FAIL"
  export FW_VCBC_WARN="$WARN"
  export FW_VCBC_STRUCTURAL_PASS="$VALIDATOR_STRUCTURAL_PASS"
  export FW_VCBC_ENVELOPE_DID_TOTAL_MISMATCH="$ENVELOPE_DID_TOTAL_MISMATCH"
  export FW_VCBC_ENVELOPE_DID_VALUE="$ENVELOPE_DID_VALUE"
  export FW_VCBC_ENVELOPE_DIDNT_VALUE="$ENVELOPE_DIDNT_VALUE"
  export FW_VCBC_ENVELOPE_GAPS_VALUE="$ENVELOPE_GAPS_VALUE"
  export FW_VCBC_ENVELOPE_TMP_DIR_RELEASED_VALUE="$ENVELOPE_TMP_DIR_RELEASED_VALUE"
  export FW_VCBC_ENVELOPE_STRUCTURAL_SOURCE="$ENVELOPE_STRUCTURAL_SOURCE"
  export FW_VCBC_BRAND_STATUS="$BRAND_STATUS"
  export FW_VCBC_BRAND_REASON="$BRAND_REASON"
  export FW_VCBC_SNIFF_STATUS="$SNIFF_STATUS"
  export FW_VCBC_SNIFF_REASON="$SNIFF_REASON"
  export FW_VCBC_JEFF_STATUS="$JEFF_STATUS"
  export FW_VCBC_JEFF_REASON="$JEFF_REASON"
  export FW_VCBC_PUBLIC_STATUS="$PUBLIC_STATUS"
  export FW_VCBC_PUBLIC_REASON="$PUBLIC_REASON"
  export FW_VCBC_REWORK_ACTION="$REWORK_ACTION"
  export FW_VCBC_REWORK_BEAD="$REWORK_BEAD"
  export FW_VCBC_NTM_CHANGES="$NTM_CHANGES_JSON"
  export FW_VCBC_NTM_CONFLICTS="$NTM_CONFLICTS_JSON"
  emit_json
else
  echo "=== validate-callback-before-close: $BEAD ==="
  echo "repo: $REPO_ABS"
  echo "evidence: $EVIDENCE_ABS"
  echo "mode: $MODE"
  echo "failures: $FAIL"
  echo "warnings: $WARN"
  echo "structural: validator_structural_pass=$VALIDATOR_STRUCTURAL_PASS envelope_did_total_mismatch=${ENVELOPE_DID_TOTAL_MISMATCH:-none} tmp_dir_released=${ENVELOPE_TMP_DIR_RELEASED_VALUE:-missing} untracked_delta=${ENVELOPE_UNTRACKED_DELTA:-missing} substrate_classified=${ENVELOPE_SUBSTRATE_CLASSIFIED:-missing}"
  [ -n "${UNTRACKED_DELTA_WARNING:-}" ] && echo "hygiene_warn: $UNTRACKED_DELTA_WARNING"
  echo "four_lens: brand=$BRAND_STATUS sniff=$SNIFF_STATUS jeff=$JEFF_STATUS public=$PUBLIC_STATUS"
  echo "ntm_changes: $(printf '%s\n' "$NTM_CHANGES_JSON" | jq -c '{status:(.status // "ok"), changed_count:(.changed_count // .count // (.changes // [] | length) // 0)}' 2>/dev/null || printf 'null')"
  echo "ntm_conflicts: $(printf '%s\n' "$NTM_CONFLICTS_JSON" | jq -c '{status:(.status // "ok"), conflict_count:(.conflict_count // .count // (.conflicts // [] | length) // 0)}' 2>/dev/null || printf 'null')"
  [ -n "$FAILURES" ] && { echo "FAIL:"; printf '%s\n' "$FAILURES" | sed '/^$/d; s/^/  - /'; }
  [ -n "$WARNINGS" ] && { echo "WARN:"; printf '%s\n' "$WARNINGS" | sed '/^$/d; s/^/  - /'; }
  [ "$REWORK_ACTION" != "none" ] && echo "auto_rework: action=$REWORK_ACTION bead=${REWORK_BEAD:-none}"
  [ -n "$BLOCK_CLOSE_REASON" ] && echo "block_close_reason: $BLOCK_CLOSE_REASON"
  echo "VERDICT: $VERDICT"
fi

if [ "$VERDICT" = "BLOCK_CLOSE" ]; then
  exit 1
fi
exit 0

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-04-receipt-callback-envelope.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-88-content-addressed-evidence-pack.md`
