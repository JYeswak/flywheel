#!/usr/bin/env bash
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

set -uo pipefail

VERSION="jeffrey-comment-watchtower.v1"
SCRIPT_VERSION="2026-05-09.1"

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

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --reseed) MODE="reseed"; shift ;;
    --doctor) MODE="doctor"; shift ;;
    --info) MODE="info"; shift ;;
    --schema) MODE="schema"; shift ;;
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
      owns: "flywheel-d6tz0",
      sla_hours: 4,
      cadence_minutes: 15,
      status: "ok"
    }'
}

schema_payload() {
  jq -nc '{
    schema_version: "jeffrey-comment-watchtower/v1",
    ledger_row_fields: [
      "schema_version","ts","repo","issue","comment_id","comment_url",
      "author","created_at","comment_excerpt","action_required",
      "dispatched","dispatched_ts"
    ],
    signal_line: "JEFFREY_COMMENT_NEW repo=<r> issue=#<n> comment_id=<id> excerpt=\"<excerpt>\" action=reply-required",
    heartbeat_row_fields: ["schema_version","ts","mode","run_id","new_count","poll_count","status","error"],
    exit_codes: {"0":"ok","1":"non-fatal poll error logged as heartbeat","64":"usage","77":"missing dep"},
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
    --argjson issues "$issues_json" \
    '{
      version: $version,
      schema_version: "jeffrey-comment-watchtower/v1",
      mode: "doctor",
      ledger: $ledger,
      issues: $issues,
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
