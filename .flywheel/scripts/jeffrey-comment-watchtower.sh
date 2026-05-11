#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (partial -> passing per bead flywheel-k8gcv.21)
# jeffrey-comment-watchtower.sh — auto-detect new Jeffrey Emanuel comments
# on our open issues at github.com/Dicklesworthstone and dispatch a
# JEFFREY_COMMENT_NEW signal to the flywheel orchestrator pane within
# the polling interval.
#
# Owns: bead flywheel-d6tz0. Mission anchor: continuous-orchestrator-uptime.
# SLA: reply within 4 hours of Jeffrey's comment landing (waking-hour budget).
# Companion canonical: AGENTS.md L70 ORCH-NO-PUNT and the new
# `.flywheel/rules/L102-L151-jeffrey-comment-response-sla.md` ratifying
# the watchtower-driven response loop.
#
# Stable exit codes:
#   0  — run completed cleanly (with or without new comments)
#   1  — non-fatal poll failure recorded as heartbeat row
#  64  — usage error
#  77  — required dependency missing (gh / jq / ntm)
#
# Triad: doctor / info / schema modes; --json default for robot consumers.

set -euo pipefail

VERSION="jeffrey-comment-watchtower.v1.1.0"
SCHEMA_VERSION="jeffrey-comment-watchtower/v1"
SCRIPT_VERSION="2026-05-11.1"
IDEMPOTENCY_KEY=""

# --- defaults -----------------------------------------------------------------
JEFFREY_LOGIN="${JEFFREY_LOGIN:-Dicklesworthstone}"
OUR_LOGIN="${JEFFREY_WATCHTOWER_AUTHOR:-JYeswak}"
OWNER="${JEFFREY_WATCHTOWER_OWNER:-Dicklesworthstone}"
SEARCH_LIMIT="${JEFFREY_WATCHTOWER_SEARCH_LIMIT:-50}"
STATE_DIR="${JEFFREY_WATCHTOWER_STATE_DIR:-$HOME/.local/state/flywheel}"
LEDGER="${JEFFREY_WATCHTOWER_LEDGER:-$STATE_DIR/jeffrey-comment-watchtower.jsonl}"
LOG_FILE="${JEFFREY_WATCHTOWER_LOG:-$HOME/.local/logs/jeffrey-comment-watchtower.jsonl}"
NTM_BIN="${NTM_BIN:-$HOME/.local/bin/ntm}"
CALLBACK_SESSION="${JEFFREY_WATCHTOWER_CALLBACK_SESSION:-flywheel}"
CALLBACK_PANE="${JEFFREY_WATCHTOWER_CALLBACK_PANE:-1}"
EXCERPT_LEN="${JEFFREY_WATCHTOWER_EXCERPT_LEN:-150}"

MODE="run"
JSON_OUT=0
QUIET=0
DRY_RUN=0
APPLY=0
EXPLICIT_APPLY=0
RESEED=0
ONCE=1            # default to one pass — launchd schedules cadence

# --- arg parsing --------------------------------------------------------------
usage() {
  cat <<'USAGE'
Usage:
  jeffrey-comment-watchtower.sh [--apply|--dry-run] [--json] [--quiet]
  jeffrey-comment-watchtower.sh --doctor [--json]
  jeffrey-comment-watchtower.sh --info [--json]
  jeffrey-comment-watchtower.sh --schema [--json]
  jeffrey-comment-watchtower.sh --reseed [--apply]
  jeffrey-comment-watchtower.sh --help

Detect new Jeffrey Emanuel comments on our open issues at
github.com/Dicklesworthstone, append schema-versioned ledger rows, and
dispatch JEFFREY_COMMENT_NEW signals to the flywheel orchestrator pane.

Modes:
  --apply       writes ledger + dispatches signal (default if neither set)
  --dry-run     all probes run; ledger NOT written; no signal dispatched
  --reseed      mark every existing Jeffrey comment as 'seen' without
                dispatching (initial bootstrap; idempotent)
  --doctor      check dependencies + ledger writability + ntm reachability
  --info        emit static metadata (paths, version, owner)
  --schema      emit ledger + signal field shape
USAGE
}

now_iso_top() { date -u +%Y-%m-%dT%H:%M:%SZ; }

emit_canonical_doctor() {
  local ts; ts="$(now_iso_top)"
  local gh_status="pass"; command -v gh >/dev/null 2>&1 || gh_status="fail"
  local jq_status="pass"; command -v jq >/dev/null 2>&1 || jq_status="fail"
  local perl_status="pass"; command -v perl >/dev/null 2>&1 || perl_status="fail"
  local ntm_status="pass"; [[ -x "$NTM_BIN" ]] || ntm_status="fail"
  local state_status="pass"
  [[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR" 2>/dev/null
  [[ -w "$STATE_DIR" ]] || state_status="fail"
  local gh_auth_status="pass"
  if command -v gh >/dev/null 2>&1; then
    gh auth status >/dev/null 2>&1 || gh_auth_status="warn"
  else
    gh_auth_status="warn"
  fi
  local overall="pass"
  for s in "$gh_status" "$jq_status" "$perl_status" "$ntm_status" "$state_status" "$gh_auth_status"; do
    case "$s" in
      fail) overall="fail" ;;
      warn) [[ "$overall" == "pass" ]] && overall="warn" ;;
    esac
  done
  jq -nc --arg sv "$SCHEMA_VERSION.doctor" --arg ts "$ts" --arg overall "$overall" \
    --arg gh_s "$gh_status" --arg jq_s "$jq_status" --arg perl_s "$perl_status" \
    --arg ntm_s "$ntm_status" --arg ntm "$NTM_BIN" \
    --arg state_s "$state_status" --arg state "$STATE_DIR" \
    --arg gh_auth_s "$gh_auth_status" \
    '{
      schema_version:$sv,
      command:"doctor",
      ts:$ts,
      status:$overall,
      checks:[
        {name:"gh",status:$gh_s,detail:"gh CLI required for GitHub comment search"},
        {name:"jq",status:$jq_s,detail:"jq required for envelope emission"},
        {name:"perl",status:$perl_s,detail:"perl required for excerpt trimming"},
        {name:"ntm_bin",status:$ntm_s,path:$ntm,detail:"ntm binary required for JEFFREY_COMMENT_NEW signal dispatch"},
        {name:"state_dir_writable",status:$state_s,path:$state,detail:"state directory for ledger writes"},
        {name:"gh_auth",status:$gh_auth_s,detail:"gh auth status configured (warn if not authed — read-only paths still work)"}
      ]
    }'
}

emit_examples_text() {
  cat <<'EOF'
examples:
  jeffrey-comment-watchtower.sh --dry-run --json
  jeffrey-comment-watchtower.sh --apply --idempotency-key jcw-2026-05-11 --json
  jeffrey-comment-watchtower.sh --reseed --apply --idempotency-key jcw-bootstrap --json
  jeffrey-comment-watchtower.sh doctor --json
  jeffrey-comment-watchtower.sh audit --json
EOF
}

emit_examples_json() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"examples",
    examples:[
      {name:"dry-run-poll",invocation:"jeffrey-comment-watchtower.sh --dry-run --json",purpose:"probe GitHub without writing ledger or dispatching signal"},
      {name:"apply-with-idem-key",invocation:"jeffrey-comment-watchtower.sh --apply --idempotency-key jcw-2026-05-11 --json",purpose:"apply mode: write ledger + dispatch JEFFREY_COMMENT_NEW signal; requires --idempotency-key"},
      {name:"reseed-bootstrap",invocation:"jeffrey-comment-watchtower.sh --reseed --apply --idempotency-key jcw-bootstrap --json",purpose:"mark every existing Jeffrey comment as seen without dispatching (initial bootstrap)"},
      {name:"doctor",invocation:"jeffrey-comment-watchtower.sh doctor --json",purpose:"canonical doctor envelope: gh, jq, perl, ntm_bin, state_dir, gh_auth checks"},
      {name:"audit",invocation:"jeffrey-comment-watchtower.sh audit --json",purpose:"tail recent comment-ledger rows"}
    ]
  }'
}

emit_health() {
  local ts; ts="$(now_iso_top)"
  local row_count=0
  local last_action=""
  if [[ -r "$LEDGER" ]]; then
    row_count="$(wc -l <"$LEDGER" 2>/dev/null | tr -d ' ')"
    [[ -z "$row_count" ]] && row_count=0
    if [[ "$row_count" -gt 0 ]]; then
      last_action="$(tail -n 1 "$LEDGER" 2>/dev/null | jq -r '.action_required // .mode // empty' 2>/dev/null || true)"
    fi
  fi
  jq -nc --arg sv "$SCHEMA_VERSION.health" --arg ts "$ts" \
    --arg ledger "$LEDGER" --argjson row_count "${row_count:-0}" --arg last_action "${last_action:-}" \
    '{schema_version:$sv,command:"health",ts:$ts,status:"pass",ledger:$ledger,ledger_row_count:$row_count,last_action_required:$last_action}'
}

emit_canonical_validate() {
  local ts; ts="$(now_iso_top)"
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
    '{schema_version:$sv,command:"validate",ts:$ts,status:$status,ledger:$ledger,row_count:$rows,invalid_row_count:$invalid,check:"every comment row has non-empty schema_version"}'
}

emit_audit() {
  local limit="${1:-20}"
  local ts; ts="$(now_iso_top)"
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
    ""|sla-4h-cadence-15min)
      body='Joshua axiom: reply to Jeffrey Emanuel within 4 hours of his comment landing on our open issues. Watchtower polls GitHub every 15 minutes (launchd cadence). Detection→signal→reply chain budget: <4h waking hours. Failure to respond within SLA is a fleet incident class.'
      ;;
    jeffrey-comment-new-signal)
      body='Signal format: `JEFFREY_COMMENT_NEW repo=<r> issue=#<n> comment_id=<id> excerpt="<excerpt>" action=reply-required`. Dispatched to flywheel:1 via ntm send. Orchestrator must surface to operator + open a tracking bead within the SLA window.'
      ;;
    reseed-bootstrap)
      body='--reseed mode walks every open issue authored by OUR_LOGIN, finds every existing Jeffrey comment, and marks them as "seen" in the ledger WITHOUT dispatching signals. Used once at initial deployment to avoid alert-storm on backlog comments. Idempotent: re-running --reseed adds no new ledger rows.'
      ;;
    *)
      body="unknown topic: $topic. known: sla-4h-cadence-15min, jeffrey-comment-new-signal, reseed-bootstrap"
      ;;
  esac
  jq -nc --arg sv "$SCHEMA_VERSION" --arg topic "${topic:-sla-4h-cadence-15min}" --arg body "$body" \
    '{schema_version:$sv,command:"why",topic:$topic,body:$body}'
}

emit_quickstart() {
  jq -nc --arg sv "$SCHEMA_VERSION" '{
    schema_version:$sv,
    command:"quickstart",
    status:"ok",
    steps:[
      {step:1,action:"check-doctor",command:"jeffrey-comment-watchtower.sh doctor --json"},
      {step:2,action:"reseed-bootstrap-once",command:"jeffrey-comment-watchtower.sh --reseed --apply --idempotency-key jcw-bootstrap --json"},
      {step:3,action:"install-launchd-15min-cadence",command:"launchctl load ~/Library/LaunchAgents/ai.zeststream.flywheel-jeffrey-comment-watchtower.plist"},
      {step:4,action:"tail-recent",command:"jeffrey-comment-watchtower.sh audit --json"}
    ],
    next_actions:["wire-launchd-cadence","verify-jeffrey-comment-new-signal-routing"]
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
  local ts; ts="$(now_iso_top)"
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
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --apply) APPLY=1; DRY_RUN=0; EXPLICIT_APPLY=1; shift ;;
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:?}"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}"; shift ;;
    --reseed) MODE="reseed"; shift ;;
    --doctor) MODE="doctor"; shift ;;
    --info) MODE="info"; shift ;;
    --schema) MODE="schema"; shift ;;
    --examples)
      shift
      if [[ "${1:-}" == "--json" ]]; then emit_examples_json; else emit_examples_text; fi
      exit 0
      ;;
    --once) ONCE=1; shift ;;     # explicit alias; default is already once
    --owner) OWNER="${2:?}"; shift 2 ;;
    --owner=*) OWNER="${1#*=}"; shift ;;
    --author) OUR_LOGIN="${2:?}"; shift 2 ;;
    --author=*) OUR_LOGIN="${1#*=}"; shift ;;
    --jeffrey) JEFFREY_LOGIN="${2:?}"; shift 2 ;;
    --jeffrey=*) JEFFREY_LOGIN="${1#*=}"; shift ;;
    --ledger) LEDGER="${2:?}"; shift 2 ;;
    --ledger=*) LEDGER="${1#*=}"; shift ;;
    --log) LOG_FILE="${2:?}"; shift 2 ;;
    --log=*) LOG_FILE="${1#*=}"; shift ;;
    --callback-session) CALLBACK_SESSION="${2:?}"; shift 2 ;;
    --callback-pane) CALLBACK_PANE="${2:?}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "jeffrey-comment-watchtower.sh: unknown arg: $1" >&2; usage >&2; exit 64 ;;
  esac
done

# --apply is default when no mode flag set and not dry-run
if [[ $MODE == "run" && $APPLY -eq 0 && $DRY_RUN -eq 0 ]]; then
  APPLY=1
fi

# Canonical apply contract: --apply (explicit) requires --idempotency-key.
# Note: default-apply (no --apply or --dry-run) still works without key per
# launchd-cadence ergonomics. Only EXPLICIT --apply triggers the gate.
if [[ "${EXPLICIT_APPLY:-0}" -eq 1 && -z "$IDEMPOTENCY_KEY" ]]; then
  printf '{"schema_version":"%s","status":"refused","mode":"apply","reason":"--apply requires --idempotency-key (default-apply for launchd-cadence is exempt)","exit_code":3}\n' "$SCHEMA_VERSION"
  exit 3
fi

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# --- helpers ------------------------------------------------------------------
require() {
  command -v "$1" >/dev/null 2>&1 || { echo "missing dependency: $1" >&2; exit 77; }
}

emit() {
  local payload="$1"
  if [[ $JSON_OUT -eq 1 || $MODE == "info" || $MODE == "schema" || $MODE == "doctor" ]]; then
    printf '%s\n' "$payload"
  fi
}

log_heartbeat() {
  local row="$1"
  mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || return 0
  printf '%s\n' "$row" >> "$LOG_FILE" 2>/dev/null || true
}

scrub_excerpt() {
  # Defensive single-line scrub for tokens. We never echo raw comment
  # bodies into the dispatch line — only sanitized excerpts.
  perl -0pe '
    s/[\r\n\t]/ /g;
    s/\s+/ /g;
    s/Bearer\s+[A-Za-z0-9._~+\/=-]+/[SCRUB:bearer]/g;
    s/sk-ant-[A-Za-z0-9_-]+/[SCRUB:anthropic]/g;
    s/ghp_[A-Za-z0-9]+/[SCRUB:gh_pat]/g;
    s/gho_[A-Za-z0-9]+/[SCRUB:gh_oauth]/g;
    s/AKIA[0-9A-Z]{16}/[SCRUB:aws]/g;
    s/eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/[SCRUB:jwt]/g;
  '
}

ledger_seen() {
  local repo="$1" issue="$2" comment_id="$3"
  [[ -f "$LEDGER" ]] || return 1
  grep -F "\"comment_id\":\"$comment_id\"" "$LEDGER" 2>/dev/null \
    | grep -F "\"repo\":\"$repo\"" \
    | grep -F "\"issue\":$issue" >/dev/null
}

# --- modes --------------------------------------------------------------------
info_payload() {
  jq -nc \
    --arg version "$VERSION" \
    --arg script_version "$SCRIPT_VERSION" \
    --arg jeffrey "$JEFFREY_LOGIN" \
    --arg author "$OUR_LOGIN" \
    --arg owner "$OWNER" \
    --arg ledger "$LEDGER" \
    --arg log "$LOG_FILE" \
    --arg ntm "$NTM_BIN" \
    --arg session "$CALLBACK_SESSION" \
    --argjson pane "$CALLBACK_PANE" \
    --argjson limit "$SEARCH_LIMIT" \
    '{
      name: "jeffrey-comment-watchtower.sh",
      command: "info",
      version: $version,
      script_version: $script_version,
      schema_version: "jeffrey-comment-watchtower/v1",
      mode: "info",
      jeffrey_login: $jeffrey,
      our_login: $author,
      owner: $owner,
      search_limit: $limit,
      ledger: $ledger,
      log_file: $log,
      ntm_bin: $ntm,
      callback_session: $session,
      callback_pane: $pane,
      modes: ["run","reseed","doctor","info","schema"],
      subcommands: ["doctor","health","validate","audit","why","repair","quickstart"],
      canonical_flags: ["--info","--schema","--examples","--json","--apply","--dry-run","--idempotency-key","--quiet","--reseed","--doctor","--owner","--author","--jeffrey","--ledger","--log","--callback-session","--callback-pane"],
      capabilities: [
        "github-comment-poll-via-gh-search",
        "jeffrey-emanuel-author-filtering",
        "schema-versioned-ledger-append",
        "ntm-dispatch-of-jeffrey-comment-new-signal",
        "reseed-bootstrap-mode-idempotent",
        "heartbeat-row-on-poll-failure",
        "4h-sla-with-15min-cadence"
      ],
      apply_supported: true,
      dry_run_supported: true,
      idempotency_key_required_for_apply: true,
      mutates_state: true,
      env_vars: ["JEFFREY_LOGIN","JEFFREY_WATCHTOWER_AUTHOR","JEFFREY_WATCHTOWER_OWNER","JEFFREY_WATCHTOWER_SEARCH_LIMIT","JEFFREY_WATCHTOWER_STATE_DIR","JEFFREY_WATCHTOWER_LEDGER","JEFFREY_WATCHTOWER_LOG","NTM_BIN","JEFFREY_WATCHTOWER_CALLBACK_SESSION","JEFFREY_WATCHTOWER_CALLBACK_PANE","JEFFREY_WATCHTOWER_EXCERPT_LEN"],
      exit_codes: {"0":"ok","1":"non-fatal poll error","3":"refused-apply-without-idempotency-key","64":"usage","77":"missing dep"},
      owns: "flywheel-d6tz0",
      sla_hours: 4,
      cadence_minutes: 15,
      status: "ok"
    }'
}

schema_payload() {
  jq -nc '{
    schema_version: "jeffrey-comment-watchtower/v1",
    command: "schema",
    input_schema: {
      type: "object",
      properties: {
        apply: {type:"boolean"},
        dry_run: {type:"boolean"},
        idempotency_key: {type:"string",description:"required with --apply"},
        quiet: {type:"boolean"},
        reseed: {type:"boolean"},
        owner: {type:"string",description:"GitHub owner to scan (default Dicklesworthstone)"},
        author: {type:"string",description:"our login to filter our authored issues"},
        jeffrey: {type:"string",description:"Jeffrey GitHub login"},
        ledger: {type:"string"},
        log: {type:"string"},
        callback_session: {type:"string"},
        callback_pane: {type:"integer"}
      }
    },
    output_schema: {
      type: "object",
      properties: {
        schema_version: {const:"jeffrey-comment-watchtower/v1"},
        ts: {type:"string",format:"date-time"},
        mode: {enum:["run","reseed","doctor","info","schema","health","validate","audit","why","repair","quickstart"]},
        new_count: {type:"integer",minimum:0},
        poll_count: {type:"integer",minimum:0},
        status: {enum:["ok","error","degraded","pass","fail"]}
      }
    },
    ledger_row_fields: [
      "schema_version","ts","repo","issue","comment_id","comment_url",
      "author","created_at","comment_excerpt","action_required",
      "dispatched","dispatched_ts"
    ],
    signal_line: "JEFFREY_COMMENT_NEW repo=<r> issue=#<n> comment_id=<id> excerpt=\"<excerpt>\" action=reply-required",
    heartbeat_row_fields: ["schema_version","ts","mode","run_id","new_count","poll_count","status","error"],
    exit_codes: {"0":"ok","1":"non-fatal poll error logged as heartbeat","3":"refused-apply-without-idempotency-key","64":"usage","77":"missing dep"},
    mode: "schema",
    status: "ok"
  }'
}

doctor_payload() {
  local issues=()
  command -v gh >/dev/null 2>&1 || issues+=("gh_missing")
  command -v jq >/dev/null 2>&1 || issues+=("jq_missing")
  command -v perl >/dev/null 2>&1 || issues+=("perl_missing")
  [[ -x "$NTM_BIN" ]] || issues+=("ntm_bin_missing=$NTM_BIN")
  [[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR" 2>/dev/null
  [[ -w "$STATE_DIR" ]] || issues+=("state_dir_not_writable=$STATE_DIR")
  if command -v gh >/dev/null 2>&1; then
    if ! gh auth status >/dev/null 2>&1; then
      issues+=("gh_auth_unconfigured")
    fi
  fi
  local issues_json
  if [[ ${#issues[@]} -gt 0 ]]; then
    issues_json=$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)
  else
    issues_json='[]'
  fi
  jq -nc \
    --arg version "$VERSION" \
    --arg ledger "$LEDGER" \
    --arg ntm "$NTM_BIN" \
    --arg state_dir "$STATE_DIR" \
    --argjson issues "$issues_json" \
    '{
      version: $version,
      schema_version: "jeffrey-comment-watchtower/v1",
      command: "doctor",
      mode: "doctor",
      ledger: $ledger,
      issues: $issues,
      checks: [
        {name:"gh",status:(if ($issues | any(.=="gh_missing")) then "fail" else "pass" end),detail:"gh CLI required for GitHub comment search"},
        {name:"jq",status:(if ($issues | any(.=="jq_missing")) then "fail" else "pass" end),detail:"jq required for envelope emission"},
        {name:"perl",status:(if ($issues | any(.=="perl_missing")) then "fail" else "pass" end),detail:"perl required for excerpt trimming"},
        {name:"ntm_bin",status:(if ($issues | any(. | tostring | startswith("ntm_bin_missing"))) then "fail" else "pass" end),path:$ntm,detail:"ntm binary required for JEFFREY_COMMENT_NEW signal dispatch"},
        {name:"state_dir_writable",status:(if ($issues | any(. | tostring | startswith("state_dir_not_writable"))) then "fail" else "pass" end),path:$state_dir,detail:"state directory for ledger writes"},
        {name:"gh_auth",status:(if ($issues | any(.=="gh_auth_unconfigured")) then "warn" else "pass" end),detail:"gh auth status configured"}
      ],
      status: (if ($issues|length)==0 then "ok" else "degraded" end)
    }'
}

# --- core run loop ------------------------------------------------------------
run_one_pass() {
  local mode_label="$1"   # "apply" | "dry-run" | "reseed"
  local run_id new_count poll_count status err
  run_id="run-$(date -u +%Y%m%dT%H%M%SZ)-$$"
  new_count=0
  poll_count=0
  status="ok"
  err=""

  require gh
  require jq
  require perl

  local search_json
  if ! search_json="$(gh search issues "author:$OUR_LOGIN" "owner:$OWNER" \
       --state open --limit "$SEARCH_LIMIT" \
       --json number,repository,title,createdAt,updatedAt 2>/dev/null)"; then
    status="fail"
    err="gh_search_failed"
    log_heartbeat "$(jq -nc \
      --arg ts "$(now_iso)" \
      --arg mode "$mode_label" \
      --arg run_id "$run_id" \
      --argjson new_count 0 \
      --argjson poll_count 0 \
      --arg status "$status" \
      --arg error "$err" \
      '{schema_version:"jeffrey-comment-watchtower/v1", ts:$ts, mode:$mode,
        run_id:$run_id, new_count:$new_count, poll_count:$poll_count,
        status:$status, error:$error}')"
    emit "$(jq -nc --arg s "$status" --arg e "$err" --arg id "$run_id" \
      '{run_id:$id, status:$s, error:$e, new_count:0, poll_count:0}')"
    return 1
  fi

  local issue_count
  issue_count=$(printf '%s' "$search_json" | jq 'length')
  poll_count=$issue_count

  local new_signals='[]'
  local i=0
  while [[ $i -lt $issue_count ]]; do
    local repo issue title
    repo=$(printf '%s' "$search_json" | jq -r ".[$i].repository.nameWithOwner // empty")
    issue=$(printf '%s' "$search_json" | jq -r ".[$i].number // empty")
    title=$(printf '%s' "$search_json" | jq -r ".[$i].title // empty")
    i=$((i+1))
    [[ -n "$repo" && -n "$issue" ]] || continue

    local comments_json
    if ! comments_json="$(gh issue view "$issue" --repo "$repo" --json comments 2>/dev/null)"; then
      err="gh_view_failed_${repo//\//_}#${issue}"
      continue
    fi

    local jc=0
    local jeffrey_count
    jeffrey_count=$(printf '%s' "$comments_json" | jq -r --arg j "$JEFFREY_LOGIN" \
      '[.comments[] | select(.author.login == $j)] | length')
    while [[ $jc -lt $jeffrey_count ]]; do
      local cid created body
      cid=$(printf '%s' "$comments_json" | jq -r --arg j "$JEFFREY_LOGIN" \
        "[.comments[] | select(.author.login == \$j)][$jc].id // empty")
      created=$(printf '%s' "$comments_json" | jq -r --arg j "$JEFFREY_LOGIN" \
        "[.comments[] | select(.author.login == \$j)][$jc].createdAt // empty")
      body=$(printf '%s' "$comments_json" | jq -r --arg j "$JEFFREY_LOGIN" \
        "[.comments[] | select(.author.login == \$j)][$jc].body // \"\"")
      jc=$((jc+1))
      [[ -n "$cid" ]] || continue

      if ledger_seen "$repo" "$issue" "$cid"; then
        continue
      fi

      local excerpt
      excerpt=$(printf '%s' "$body" | scrub_excerpt | cut -c "1-$EXCERPT_LEN")

      local row
      row=$(jq -nc \
        --arg ts "$(now_iso)" \
        --arg repo "$repo" \
        --argjson issue "$issue" \
        --arg comment_id "$cid" \
        --arg comment_url "https://github.com/$repo/issues/$issue#issuecomment-$cid" \
        --arg author "$JEFFREY_LOGIN" \
        --arg created_at "$created" \
        --arg excerpt "$excerpt" \
        --arg dispatched_ts "$(now_iso)" \
        --argjson dispatched $([[ $mode_label == "apply" ]] && echo true || echo false) \
        --argjson action_required $([[ $mode_label == "reseed" ]] && echo false || echo true) \
        '{schema_version:"jeffrey-comment-watchtower/v1",
          ts:$ts, repo:$repo, issue:$issue, comment_id:$comment_id,
          comment_url:$comment_url, author:$author,
          created_at:$created_at, comment_excerpt:$excerpt,
          action_required:$action_required, dispatched:$dispatched,
          dispatched_ts:$dispatched_ts}')

      if [[ $mode_label == "apply" || $mode_label == "reseed" ]]; then
        mkdir -p "$(dirname "$LEDGER")" 2>/dev/null || true
        printf '%s\n' "$row" >> "$LEDGER" 2>/dev/null || true
      fi

      if [[ $mode_label == "apply" ]]; then
        local signal
        signal="JEFFREY_COMMENT_NEW repo=$repo issue=#$issue comment_id=$cid excerpt=\"$excerpt\" action=reply-required"
        if [[ -x "$NTM_BIN" ]]; then
          "$NTM_BIN" send "$CALLBACK_SESSION" "--pane=$CALLBACK_PANE" --no-cass-check "$signal" >/dev/null 2>&1 || true
        fi
        new_count=$((new_count+1))
      elif [[ $mode_label == "dry-run" ]]; then
        new_count=$((new_count+1))
      fi

      new_signals=$(jq -c --argjson r "$row" '. + [$r]' <<<"$new_signals")
    done
  done

  log_heartbeat "$(jq -nc \
    --arg ts "$(now_iso)" \
    --arg mode "$mode_label" \
    --arg run_id "$run_id" \
    --argjson new_count "$new_count" \
    --argjson poll_count "$poll_count" \
    --arg status "$status" \
    --arg error "$err" \
    '{schema_version:"jeffrey-comment-watchtower/v1", ts:$ts, mode:$mode,
      run_id:$run_id, new_count:$new_count, poll_count:$poll_count,
      status:$status, error:$error}')"

  emit "$(jq -nc \
    --arg id "$run_id" \
    --arg s "$status" \
    --argjson nc "$new_count" \
    --argjson pc "$poll_count" \
    --argjson signals "$new_signals" \
    '{run_id:$id, status:$s, new_count:$nc, poll_count:$pc,
      signals:$signals}')"
}

# --- mode dispatch ------------------------------------------------------------
case "$MODE" in
  info)   emit "$(info_payload)"; exit 0 ;;
  schema) emit "$(schema_payload)"; exit 0 ;;
  doctor)
    payload="$(doctor_payload)"
    emit "$payload"
    [[ "$(printf '%s' "$payload" | jq -r '.status')" == "ok" ]] && exit 0 || exit 1
    ;;
  reseed)
    run_one_pass reseed
    exit $?
    ;;
  run)
    if [[ $DRY_RUN -eq 1 ]]; then
      run_one_pass dry-run
    else
      run_one_pass apply
    fi
    exit $?
    ;;
esac
