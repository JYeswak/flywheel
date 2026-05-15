#!/usr/bin/env bash
# ntm-send-with-josh-req-capture.sh — Codex-runtime parity wrapper for the
# Joshua-request capture substrate.
#
# The Claude UserPromptSubmit hook (~/.claude/hooks/josh-request-capture.sh)
# captures Joshua's prompts into ~/.local/state/flywheel/josh-requests.jsonl
# at write-time. Codex CLI has no equivalent hook surface, so when an
# orchestrator dispatches a Joshua-originated prompt to a Codex-runtime
# worker pane, the request is invisible to that JSONL.
#
# This wrapper is the Codex parity surface (track
# `secondary_ntm_send_wrapper_capture` in
# `.flywheel/scripts/orch-capture-parity-probe.py`). It passes every flag
# through to `ntm send`, but if the message is request-shaped (same regex
# as the Claude hook) it ALSO appends a schema-v2-compatible row with
# `captured_via=ntm_send` provenance. Dedup uses `request_text_hash`.
#
# Owns: bead flywheel-xap2 (closes the runtime-parity-EPIC flywheel-2p25
# gap left open by flywheel-d62z Gate 5).
#
# Stable exit codes:
#   0  — `ntm send` succeeded (capture is best-effort, never fails the
#        forward call); --capture-only also returns 0 on capture success
#   non-zero — exits with `ntm send`'s exit code
#  64  — usage error
#
# Usage:
#   ntm-send-with-josh-req-capture.sh send <session> [ntm-flags...] "<message>"
#   ntm-send-with-josh-req-capture.sh --capture-only --session <s> --pane <p> [--from <id>] "<message>"
#   ntm-send-with-josh-req-capture.sh --doctor [--json]
#   ntm-send-with-josh-req-capture.sh --info [--json]
#   ntm-send-with-josh-req-capture.sh --schema [--json]
#   ntm-send-with-josh-req-capture.sh --help
#
# Discovered shape (autocomplete vibe):
#   send is the canonical subcommand: it forwards to `ntm send`.
#   --capture-only suppresses the forward and is intended for tests +
#     out-of-band captures (e.g. orchestrator pre-dispatch ledger).
#   --no-capture suppresses the JSONL append (forward-only mode).

set -uo pipefail

VERSION="ntm-send-with-josh-req-capture.v1"
SCRIPT_VERSION="2026-05-09.1"

NTM_BIN="${NTM_BIN:-/Users/josh/.local/bin/ntm}"
STATE_DIR="${JOSH_REQUEST_STATE_DIR:-$HOME/.local/state/flywheel}"
STATE_FILE="${JOSH_REQUEST_STATE_FILE:-$STATE_DIR/josh-requests.jsonl}"
DEDUP_LOOKBACK="${JOSH_REQUEST_DEDUP_LOOKBACK:-100}"
ERROR_LOG="${JOSH_REQUEST_ERROR_LOG:-$STATE_DIR/josh-request-capture-errors.log}"
CLAUDE_HOOK="${JOSH_REQUEST_CLAUDE_HOOK:-$HOME/.claude/hooks/josh-request-capture.sh}"

JSON=0
MODE="forward"          # forward | capture-only | doctor | info | schema
NO_CAPTURE=0
CAPTURE_SOURCE="${JOSH_REQUEST_CAPTURE_VIA:-ntm_send}"
CAPTURE_RUNTIME="${JOSH_REQUEST_RUNTIME:-codex}"
CAPTURE_SESSION=""
CAPTURE_PANE=""
CAPTURE_FROM=""
DRY_RUN=0
NTM_ARGS=()
MESSAGE=""
EXPLICIT_MESSAGE=0

usage() {
  cat <<'USAGE'
Usage:
  ntm-send-with-josh-req-capture.sh send <session> [--pane=N] [--no-cass-check] "<message>"
  ntm-send-with-josh-req-capture.sh --capture-only --session <s> --pane <p> "<message>"
  ntm-send-with-josh-req-capture.sh --doctor [--json]
  ntm-send-with-josh-req-capture.sh --info [--json]
  ntm-send-with-josh-req-capture.sh --schema [--json]
  ntm-send-with-josh-req-capture.sh --help

Codex-runtime parity wrapper for the Joshua-request capture substrate.
Forwards to `ntm send` and side-effects a schema-v2 JSONL row when the
message is request-shaped. Dedup via request_text_hash.
USAGE
}

# --- arg parsing ---------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON=1; shift ;;
    --doctor) MODE="doctor"; shift ;;
    --info) MODE="info"; shift ;;
    --schema) MODE="schema"; shift ;;
    --capture-only) MODE="capture-only"; shift ;;
    --no-capture) NO_CAPTURE=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --session) CAPTURE_SESSION="${2:-}"; shift 2 ;;
    --session=*) CAPTURE_SESSION="${1#*=}"; shift ;;
    --pane) CAPTURE_PANE="${2:-}"; shift 2 ;;
    --pane=*) CAPTURE_PANE="${1#*=}"; shift ;;
    --from) CAPTURE_FROM="${2:-}"; shift 2 ;;
    --from=*) CAPTURE_FROM="${1#*=}"; shift ;;
    --captured-via) CAPTURE_SOURCE="${2:-}"; shift 2 ;;
    --captured-via=*) CAPTURE_SOURCE="${1#*=}"; shift ;;
    --runtime) CAPTURE_RUNTIME="${2:-}"; shift 2 ;;
    --runtime=*) CAPTURE_RUNTIME="${1#*=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    send)
      shift
      # Next positional is session; remaining ntm flags + message are passthrough.
      if [[ $# -gt 0 ]]; then
        CAPTURE_SESSION="${CAPTURE_SESSION:-$1}"
        NTM_ARGS+=("$1")
        shift
      fi
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --pane=*) CAPTURE_PANE="${CAPTURE_PANE:-${1#*=}}"; NTM_ARGS+=("$1"); shift ;;
          --pane) CAPTURE_PANE="${CAPTURE_PANE:-$2}"; NTM_ARGS+=("$1" "$2"); shift 2 ;;
          --from=*) CAPTURE_FROM="${CAPTURE_FROM:-${1#*=}}"; NTM_ARGS+=("$1"); shift ;;
          --from) CAPTURE_FROM="${CAPTURE_FROM:-$2}"; NTM_ARGS+=("$1" "$2"); shift 2 ;;
          --no-cass-check|--no-cass) NTM_ARGS+=("$1"); shift ;;
          --) shift; break ;;
          -*) NTM_ARGS+=("$1"); shift ;;
          *)
            if [[ $EXPLICIT_MESSAGE -eq 0 ]]; then
              MESSAGE="$1"; EXPLICIT_MESSAGE=1
            else
              # Multiple positionals — concatenate (rare).
              MESSAGE="$MESSAGE $1"
            fi
            shift
            ;;
        esac
      done
      ;;
    *)
      if [[ $MODE == "capture-only" && $EXPLICIT_MESSAGE -eq 0 ]]; then
        MESSAGE="$1"; EXPLICIT_MESSAGE=1
        shift
      else
        echo "ntm-send-with-josh-req-capture.sh: unknown arg: $1" >&2
        usage >&2
        exit 64
      fi
      ;;
  esac
done

log_error() {
  local msg="$1"
  mkdir -p "$(dirname "$ERROR_LOG")" 2>/dev/null || true
  printf '[%s] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$msg" >> "$ERROR_LOG" 2>/dev/null || true
}

emit_payload() {
  local payload="$1"
  if [[ $JSON -eq 1 || $MODE == "info" || $MODE == "schema" || $MODE == "doctor" ]]; then
    printf '%s\n' "$payload"
  fi
}

info_payload() {
  jq -n \
    --arg version "$VERSION" \
    --arg script_version "$SCRIPT_VERSION" \
    --arg ntm_bin "$NTM_BIN" \
    --arg state_file "$STATE_FILE" \
    --arg claude_hook "$CLAUDE_HOOK" \
    --argjson dedup_lookback "$DEDUP_LOOKBACK" \
    '{
      version: $version,
      script_version: $script_version,
      schema_version: "ntm-send-with-josh-req-capture/v1",
      mode: "info",
      ntm_bin: $ntm_bin,
      state_file: $state_file,
      claude_hook: $claude_hook,
      dedup_lookback_rows: $dedup_lookback,
      modes: ["forward","capture-only","doctor","info","schema"],
      forwards_to: "ntm send",
      captured_via_default: "ntm_send",
      runtime_default: "codex",
      owns: "flywheel-xap2",
      parity_track: "secondary_ntm_send_wrapper_capture",
      status: "ok"
    }'
}

schema_payload() {
  jq -n '{
    schema_version: "ntm-send-with-josh-req-capture/v1",
    row_required_fields: [
      "schema_version","id","captured_at","source_session","source_pane",
      "transcript_path","source_message_id","prompt_hash","request_text_hash",
      "sanitized_excerpt","inferred_action","state","owner","priority","scope",
      "last_updated_at","closure_actor","linked_bead_ids","duplicate_of",
      "supersedes","stale_after","closure_evidence","captured_via","runtime",
      "target_pane"
    ],
    captured_via_enum: ["ntm_send","hook","agent_context_callback","manual"],
    runtime_enum: ["codex","claude","unknown"],
    dedup_key: "request_text_hash",
    dedup_lookback_rows: 100,
    exit_codes: {"0":"forward+capture ok or capture-only ok","64":"usage","other":"ntm send exit code"},
    mode: "schema",
    status: "ok"
  }'
}

doctor_payload() {
  local issues=()
  [[ -x "$NTM_BIN" ]] || issues+=("ntm_bin_missing=$NTM_BIN")
  [[ -d "$STATE_DIR" ]] || issues+=("state_dir_missing=$STATE_DIR")
  [[ -w "$STATE_DIR" ]] || issues+=("state_dir_not_writable=$STATE_DIR")
  command -v jq >/dev/null 2>&1 || issues+=("jq_missing")
  command -v shasum >/dev/null 2>&1 || issues+=("shasum_missing")
  command -v perl >/dev/null 2>&1 || issues+=("perl_missing")
  local issues_json
  if [[ ${#issues[@]} -gt 0 ]]; then
    issues_json=$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)
  else
    issues_json='[]'
  fi
  jq -n \
    --arg version "$VERSION" \
    --arg ntm_bin "$NTM_BIN" \
    --arg state_file "$STATE_FILE" \
    --argjson issues "$issues_json" \
    '{
      version: $version,
      schema_version: "ntm-send-with-josh-req-capture/v1",
      mode: "doctor",
      ntm_bin: $ntm_bin,
      state_file: $state_file,
      issues: $issues,
      status: (if ($issues|length)==0 then "ok" else "degraded" end)
    }'
}

scrub_secrets() {
  perl -0pe '
    s/Authorization:\s*Bearer\s+[^\s]+/[SCRUBBED:bearer_authz]/g;
    s/Bearer\s+[A-Za-z0-9._~+\/=-]+/[SCRUBBED:bearer_token]/g;
    s/-----BEGIN[A-Z ]*PRIVATE KEY-----[\s\S]*?-----END[A-Z ]*PRIVATE KEY-----/[SCRUBBED:private_key_block]/g;
    s/registration_token[":=\s]+[A-Za-z0-9_-]{20,}/[SCRUBBED:agent_mail_registration]/g;
    s/sender_token[":=\s]+[A-Za-z0-9_-]{20,}/[SCRUBBED:agent_mail_sender]/g;
    s/github_pat_[A-Za-z0-9_]+/[SCRUBBED:github_fine_grained_pat]/g;
    s/ghp_[A-Za-z0-9]+/[SCRUBBED:github_personal_token]/g;
    s/gho_[A-Za-z0-9]+/[SCRUBBED:github_oauth_token]/g;
    s/ghu_[A-Za-z0-9]+/[SCRUBBED:github_user_token]/g;
    s/ghs_[A-Za-z0-9]+/[SCRUBBED:github_server_token]/g;
    s/ghr_[A-Za-z0-9]+/[SCRUBBED:github_refresh_token]/g;
    s/sk-ant-[A-Za-z0-9_-]+/[SCRUBBED:anthropic_key]/g;
    s/sk-proj-[A-Za-z0-9_-]+/[SCRUBBED:openai_project_key]/g;
    s/sk_(?:test|live)_[A-Za-z0-9_-]+/[SCRUBBED:stripe_key]/g;
    s/sk-[A-Za-z0-9_-]{20,}/[SCRUBBED:openai_key]/g;
    s/AKIA[0-9A-Z]{16}/[SCRUBBED:aws_access_key]/g;
    s/ASIA[0-9A-Z]{16}/[SCRUBBED:aws_session_key]/g;
    s/AIza[A-Za-z0-9_-]{35}/[SCRUBBED:google_api_key]/g;
    s/xoxb-[A-Za-z0-9-]+/[SCRUBBED:slack_bot_token]/g;
    s/xoxa-[A-Za-z0-9-]+/[SCRUBBED:slack_app_token]/g;
    s/xoxp-[A-Za-z0-9-]+/[SCRUBBED:slack_user_token]/g;
    s/eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/[SCRUBBED:jwt_token]/g;
    s/xai-[A-Za-z0-9_-]+/[SCRUBBED:xai_key]/g;
    s/\b(token|secret|key|password|authorization|api_key|access_key)([\s:="]+)([A-Za-z0-9+\/_-]{32,})/${1}${2}[SCRUBBED:context_secret]/gi;
  '
}

is_request_shape() {
  local lc="$1"
  printf '%s' "$lc" | grep -Eq \
    "(^|[[:space:]])(dispatch|review|implement|build|fix|ship|close|create|update|wire|add|investigate|verify|validate|write|make|run|set up|surface|capture|register|reserve|callback|follow up|check|continue|deploy|stop|do you|need to|we need|please|can you|could you|let'?s|todo|task|bead|p0|p1)([[:space:][:punct:]]|$)"
}

dedup_request_text_hash_present() {
  local target="$1"
  [[ -f "$STATE_FILE" ]] || return 1
  tail -n "$DEDUP_LOOKBACK" "$STATE_FILE" 2>/dev/null \
    | grep -F "\"request_text_hash\":\"$target\"" \
    | head -1 >/dev/null
}

# --- capture --------------------------------------------------------------------
capture_one() {
  local message="$1"
  local session="${CAPTURE_SESSION:-unknown}"
  local pane="${CAPTURE_PANE:-null}"
  local from="${CAPTURE_FROM:-null}"
  local runtime="$CAPTURE_RUNTIME"
  local captured_via="$CAPTURE_SOURCE"

  if [[ $NO_CAPTURE -eq 1 ]]; then
    emit_payload '{"capture":"skipped","reason":"--no-capture"}'
    return 0
  fi

  if [[ -z "$message" ]]; then
    emit_payload '{"capture":"skipped","reason":"empty_message"}'
    return 0
  fi

  if ! is_request_shape "$(printf '%s' "$message" | tr '[:upper:]' '[:lower:]')"; then
    emit_payload '{"capture":"skipped","reason":"non_request_shape"}'
    return 0
  fi

  local scrubbed prompt_hash request_text_hash excerpt ts epoch suffix id row
  scrubbed="$(printf '%s' "$message" | scrub_secrets 2>/dev/null || printf '%s' "$message")"
  prompt_hash="$(printf '%s' "$message" | shasum -a 256 2>/dev/null | awk '{print "sha256:" $1}')"
  request_text_hash="$(printf '%s' "$scrubbed" | shasum -a 256 2>/dev/null | awk '{print "sha256:" $1}')"
  [[ -n "$prompt_hash" ]] || prompt_hash="sha256:hash_unavailable"
  [[ -n "$request_text_hash" ]] || request_text_hash="sha256:hash_unavailable"
  excerpt="$(printf '%s' "$scrubbed" | tr '\r\n\t' '   ' | tr -s ' ' | cut -c 1-500)"

  if dedup_request_text_hash_present "$request_text_hash"; then
    emit_payload "$(jq -nc --arg h "$request_text_hash" '{capture:"deduped",reason:"request_text_hash_present_in_lookback",request_text_hash:$h}')"
    return 0
  fi

  ts="${JOSH_REQUEST_NOW:-$(date -u '+%Y-%m-%dT%H:%M:%SZ')}"
  epoch="$(date -u -j -f '%Y-%m-%dT%H:%M:%SZ' "$ts" '+%s' 2>/dev/null || date -u '+%s')"
  suffix="$(printf '%03d' "$(( epoch % 1000 ))" 2>/dev/null || printf '000')"
  id="jr-$(printf '%s' "$ts" | sed 's/://g')-$suffix"

  row="$(jq -cn \
    --arg id "$id" \
    --arg captured_at "$ts" \
    --arg session "$session" \
    --arg pane "$pane" \
    --arg from "$from" \
    --arg prompt_hash "$prompt_hash" \
    --arg request_text_hash "$request_text_hash" \
    --arg excerpt "$excerpt" \
    --arg captured_via "$captured_via" \
    --arg runtime "$runtime" \
    '{
      schema_version:2,
      id:$id,
      captured_at:$captured_at,
      source_session:$session,
      source_pane:(if $pane=="null" then null else ($pane|tonumber? // null) end),
      transcript_path:null,
      source_message_id:(if $from=="null" then null else $from end),
      prompt_hash:$prompt_hash,
      request_text_hash:$request_text_hash,
      sanitized_excerpt:$excerpt,
      inferred_action:null,
      state:"needs_triage",
      owner:"unassigned",
      priority:"P1",
      scope:"single-repo",
      last_updated_at:$captured_at,
      closure_actor:null,
      linked_bead_ids:[],
      duplicate_of:null,
      supersedes:null,
      stale_after:24,
      closure_evidence:null,
      captured_via:$captured_via,
      runtime:$runtime,
      target_pane:(if $pane=="null" then null else ($pane|tonumber? // null) end)
    }')"

  if [[ -z "$row" ]]; then
    log_error "failed to build JSON row for $session pane=$pane"
    emit_payload '{"capture":"error","reason":"row_build_failed"}'
    return 0
  fi

  if [[ $DRY_RUN -eq 0 ]]; then
    mkdir -p "$STATE_DIR" 2>/dev/null || true
    printf '%s\n' "$row" >> "$STATE_FILE" 2>/dev/null || {
      log_error "append failed: $STATE_FILE"
      emit_payload '{"capture":"error","reason":"append_failed"}'
      return 0
    }
  fi

  emit_payload "$(jq -nc --arg id "$id" --arg h "$request_text_hash" --argjson dry "$DRY_RUN" '{capture:"captured",id:$id,request_text_hash:$h,dry_run:($dry==1)}')"
  return 0
}

# --- mode dispatch -------------------------------------------------------------
case "$MODE" in
  info) emit_payload "$(info_payload)"; exit 0 ;;
  schema) emit_payload "$(schema_payload)"; exit 0 ;;
  doctor)
    payload="$(doctor_payload)"
    emit_payload "$payload"
    [[ "$(printf '%s' "$payload" | jq -r '.status')" == "ok" ]] && exit 0 || exit 1
    ;;
esac

if [[ $MODE == "capture-only" ]]; then
  if [[ -z "$MESSAGE" ]]; then
    echo "ntm-send-with-josh-req-capture.sh: --capture-only requires a message argument" >&2
    exit 64
  fi
  capture_one "$MESSAGE"
  exit 0
fi

# Forward mode: capture (best-effort), then exec ntm send.
if [[ ${#NTM_ARGS[@]} -eq 0 ]]; then
  echo "ntm-send-with-josh-req-capture.sh: forward mode requires 'send <session> ... \"<message>\"' arguments" >&2
  exit 64
fi

if [[ -z "$MESSAGE" ]]; then
  # Pull the last positional out of NTM_ARGS as message — the dispatch
  # contract puts the message last.
  MESSAGE="${NTM_ARGS[-1]}"
  unset 'NTM_ARGS[-1]'
fi

capture_one "$MESSAGE" || true

if [[ $DRY_RUN -eq 1 ]]; then
  emit_payload "$(jq -nc --arg cmd "ntm send ${NTM_ARGS[*]} <message>" '{forward:"dry_run_skipped",cmd:$cmd}')"
  exit 0
fi

exec "$NTM_BIN" send "${NTM_ARGS[@]}" "$MESSAGE"
