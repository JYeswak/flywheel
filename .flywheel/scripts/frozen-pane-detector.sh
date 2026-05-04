#!/usr/bin/env bash
# Detect and optionally recover panes whose live scrollback stops moving while
# robot activity reports long-running THINKING/GENERATING.
set -euo pipefail

VERSION="2026-05-04.2"
SCHEMA_VERSION="frozen-pane-detector.v2"
CLASS="frozen-codex-spinner-misclassified-as-thinking"
TEMPLATE_STUB_CLASS="template-stub-prompt"
QUEUED_CLASS="frozen-codex-spinner-codex-queued-not-submitted"
NTM_BIN="${FROZEN_PANE_NTM_BIN:-/Users/josh/.local/bin/ntm}"
FLYWHEEL_LOOP_BIN="${FROZEN_PANE_FLYWHEEL_LOOP_BIN:-/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop}"
REPO_ROOT="${FROZEN_PANE_REPO_ROOT:-/Users/josh/Developer/flywheel}"
STATE_DIR="${FROZEN_PANE_STATE_DIR:-$HOME/.local/state/flywheel-loop}"
CACHE_DIR="${FROZEN_PANE_CACHE_DIR:-$STATE_DIR}"
SAMPLE_DIR="${FROZEN_PANE_SAMPLE_DIR:-$STATE_DIR/frozen-pane-samples}"
STRIKE_FILE="${FROZEN_PANE_STRIKE_FILE:-$STATE_DIR/frozen-strike-counter.jsonl}"
LEASE_DIR="${FROZEN_PANE_LEASE_DIR:-$STATE_DIR/frozen-pane-recovery-leases}"
RECOVERY_LEDGER="${FROZEN_PANE_RECOVERY_LEDGER:-$STATE_DIR/frozen-pane-recovery-ledger.jsonl}"
METRICS_FILE="${FROZEN_PANE_METRICS_FILE:-$STATE_DIR/frozen-pane-metrics.jsonl}"
CONTROL_SESSION="${FROZEN_PANE_CONTROL_SESSION:-flywheel}"
STOP_FILE="${FROZEN_PANE_STOP_FILE:-$STATE_DIR/frozen-pane-recovery.STOP}"
LINES=20
THRESHOLD_SECONDS="${FROZEN_PANE_THRESHOLD_SECONDS:-90}"
QUEUED_THRESHOLD_SECONDS="${FROZEN_PANE_QUEUED_THRESHOLD_SECONDS:-60}"
QUEUED_TIMER_DRIFT_SECONDS="${FROZEN_PANE_QUEUED_TIMER_DRIFT_SECONDS:-60}"
MIN_DELTA_BYTES=100
SAMPLE_INTERVAL_SECONDS="${FROZEN_PANE_SAMPLE_INTERVAL_SECONDS:-1}"
NTM_TIMEOUT_SECONDS="${FROZEN_PANE_NTM_TIMEOUT_SECONDS:-8}"
LEASE_TTL_SECONDS=600
COOLDOWN_SECONDS=1800
JSON_OUT=0
AUTO_RECOVER=0
DRY_RUN=0
EXPLAIN=0
CROSS_SESSION_ALLOW=0
SELF_TEST=0
SESSION=""
MODE="detect"
EXIT_CODE=0
SKIP_FUCKUP_LOG="${FROZEN_PANE_SKIP_FUCKUP_LOG:-0}"
AUTO_DISPATCH="${FROZEN_PANE_AUTO_DISPATCH:-1}"
RESPAWN_SLEEP="${FROZEN_PANE_RESPAWN_SLEEP:-8}"
RELAUNCH_SLEEP="${FROZEN_PANE_RELAUNCH_SLEEP:-6}"
REPROBE_SLEEP="${FROZEN_PANE_REPROBE_SLEEP:-2}"
RESPAWN_SUPPRESSION_SECONDS="${FROZEN_PANE_RESPAWN_SUPPRESSION_SECONDS:-120}"
CODEX_CMD="${FROZEN_PANE_CODEX_CMD:-codex --dangerously-bypass-approvals-and-sandbox}"
CC_CMD="${FROZEN_PANE_CC_CMD:-cc}"
NOW_EPOCH="${FROZEN_PANE_NOW_EPOCH:-}"
BR_BIN="${FROZEN_PANE_BR_BIN:-}"
IDEMPOTENCY_KEY="${FROZEN_PANE_IDEMPOTENCY_KEY:-}"

if [[ -z "$BR_BIN" ]]; then
  if command -v br >/dev/null 2>&1; then
    BR_BIN="$(command -v br)"
  elif [[ -x /Users/josh/.cargo/bin/br ]]; then
    BR_BIN="/Users/josh/.cargo/bin/br"
  else
    BR_BIN="br"
  fi
fi

usage() {
  cat <<'USAGE'
Usage:
  frozen-pane-detector.sh --session=<session> [--json]
  frozen-pane-detector.sh --session=all [--json]
  frozen-pane-detector.sh --session=<session> --auto-recover [--dry-run] [--json]
  frozen-pane-detector.sh --dry-run --self-test [--json]
  frozen-pane-detector.sh --doctor [--json]
  frozen-pane-detector.sh --health [--json]
  frozen-pane-detector.sh --info [--json]
  frozen-pane-detector.sh --schema
  frozen-pane-detector.sh --examples

Options:
  --threshold-seconds N      Thinking/generating age threshold. Default: 90.
  --queued-threshold-seconds N Waiting+queued prompt threshold. Default: 60.
  --queued-timer-drift-seconds N Working timer drift threshold. Default: 60.
  --min-delta-bytes N        Minimum live scrollback byte growth to avoid frozen. Default: 100.
  --sample-interval-seconds N Delay between live scrollback samples. Default: 1.
  --ntm-timeout-seconds N    Timeout for each ntm probe. Default: 8.
  --lines N                  robot-tail line count. Default: 20.
  --cache-dir PATH           Override scrollback cache directory.
  --strike-file PATH         Override strike-counter JSONL.
  --lease-dir PATH           Override recovery lease directory.
  --lease-ttl-seconds N      Recovery lease TTL. Default: 600.
  --cooldown-seconds N       Window for 3-strike recovery cooldown. Default: 1800.
  --respawn-suppression-seconds N Window after recovery where stale residue is RESPAWN_SUPPRESSED. Default: 120.
  --idempotency-key KEY      Idempotency key for a recovery attempt. Defaults to sample hash.
  --metrics-file PATH        Override metrics JSONL path.
  --recovery-ledger PATH     Override recovery ledger JSONL path.
  --cross-session-allow      Permit auto-recover outside the control session.
  --dry-run                  Plan recovery/research actions without mutating panes/beads/logs.
  --explain                  Include rationale in human output.
USAGE
}

die() {
  printf 'ERROR: %s\n' "$*" >&2
  exit 2
}

now_epoch() {
  if [[ -n "$NOW_EPOCH" ]]; then
    printf '%s\n' "$NOW_EPOCH"
  else
    date -u +%s
  fi
}

now_iso() {
  date -u -r "$(now_epoch)" +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || date -u +%Y-%m-%dT%H:%M:%SZ
}

iso_to_epoch() {
  local value="$1" normalized
  [[ -n "$value" && "$value" != "null" ]] || return 1
  normalized="$value"
  if [[ "$normalized" == *.*Z ]]; then
    normalized="${normalized%%.*}Z"
  fi
  date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$normalized" +%s 2>/dev/null \
    || date -u -d "$normalized" +%s 2>/dev/null
}

sanitize_name() {
  printf '%s' "$1" | tr -c 'A-Za-z0-9_.-' '_'
}

cache_path_for() {
  local session="$1" pane="$2"
  printf '%s/scrollback_cache_%s_%s.txt\n' "$CACHE_DIR" "$(sanitize_name "$session")" "$(sanitize_name "$pane")"
}

lease_path_for() {
  local session="$1" pane="$2"
  printf '%s/lease_%s_%s.json\n' "$LEASE_DIR" "$(sanitize_name "$session")" "$(sanitize_name "$pane")"
}

atomic_copy() {
  local src="$1" dst="$2" tmp
  tmp="${dst}.$$"
  cp "$src" "$tmp"
  mv "$tmp" "$dst"
}

sha256_file() {
  shasum -a 256 "$1" | awk '{print $1}'
}

persist_sample_pair() {
  local session="$1" pane="$2" first_file="$3" second_file="$4" ts="$5" dir first_dst second_dst
  [[ "$DRY_RUN" == "1" ]] && return 0
  dir="$SAMPLE_DIR/$(sanitize_name "$session")_$(sanitize_name "$pane")_$ts"
  mkdir -p "$dir"
  first_dst="$dir/sample1.txt"
  second_dst="$dir/sample2.txt"
  atomic_copy "$first_file" "$first_dst"
  atomic_copy "$second_file" "$second_dst"
  printf '%s\n' "$dir"
}

run_with_timeout() {
  local seconds="$1" pid waited=0
  shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$seconds" "$@"
    return
  fi
  if command -v gtimeout >/dev/null 2>&1; then
    gtimeout "$seconds" "$@"
    return
  fi
  "$@" &
  pid=$!
  while kill -0 "$pid" 2>/dev/null; do
    if [[ "$waited" -ge "$seconds" ]]; then
      kill "$pid" 2>/dev/null || true
      wait "$pid" 2>/dev/null || true
      return 124
    fi
    sleep 1
    waited=$(( waited + 1 ))
  done
  wait "$pid"
}

ensure_state_paths() {
  mkdir -p "$CACHE_DIR" "$SAMPLE_DIR" "$LEASE_DIR" "$(dirname "$STRIKE_FILE")" "$(dirname "$RECOVERY_LEDGER")" "$(dirname "$METRICS_FILE")"
  touch "$STRIKE_FILE" "$RECOVERY_LEDGER"
}

doctor_json() {
  local now deps_json ok=1
  now="$(now_iso)"
  deps_json="$(
    jq -nc \
      --arg ntm "$NTM_BIN" \
      --arg jq_path "$(command -v jq 2>/dev/null || true)" \
      --arg date_path "$(command -v date 2>/dev/null || true)" \
      --arg br_path "$BR_BIN" \
      --arg flywheel_loop "$FLYWHEEL_LOOP_BIN" \
      '[
        {name:"ntm", path:$ntm, ok:($ntm != "")},
        {name:"jq", path:$jq_path, ok:($jq_path != "")},
        {name:"date", path:$date_path, ok:($date_path != "")},
        {name:"br", path:$br_path, ok:($br_path != "")},
        {name:"flywheel-loop", path:$flywheel_loop, ok:($flywheel_loop != "")}
      ]'
  )"
  command -v jq >/dev/null 2>&1 || ok=0
  command -v date >/dev/null 2>&1 || ok=0
  [[ -x "$NTM_BIN" ]] || ok=0
  [[ -x "$FLYWHEEL_LOOP_BIN" ]] || ok=0
  ensure_state_paths 2>/dev/null || ok=0
  [[ -w "$CACHE_DIR" ]] || ok=0
  [[ -w "$LEASE_DIR" ]] || ok=0
  [[ -w "$(dirname "$STRIKE_FILE")" ]] || ok=0
  jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ts "$now" \
    --arg version "$VERSION" \
    --argjson ok "$ok" \
    --arg state_dir "$STATE_DIR" \
    --arg cache_dir "$CACHE_DIR" \
    --arg strike_file "$STRIKE_FILE" \
    --arg lease_dir "$LEASE_DIR" \
    --arg recovery_ledger "$RECOVERY_LEDGER" \
    --arg metrics_file "$METRICS_FILE" \
    --arg control_session "$CONTROL_SESSION" \
    --argjson threshold "$THRESHOLD_SECONDS" \
    --argjson queued_threshold "$QUEUED_THRESHOLD_SECONDS" \
    --argjson queued_timer_drift "$QUEUED_TIMER_DRIFT_SECONDS" \
    --argjson respawn_suppression "$RESPAWN_SUPPRESSION_SECONDS" \
    --argjson deps "$deps_json" \
    '{schema_version:$schema_version, success:($ok == 1), mode:"doctor", checked_at:$ts, version:$version,
      source_health:{status:(if $ok == 1 then "healthy" else "unhealthy" end), degraded_recovery_allowed:false},
      paths:{state_dir:$state_dir, cache_dir:$cache_dir, strike_file:$strike_file, lease_dir:$lease_dir,
        recovery_ledger:$recovery_ledger, metrics_file:$metrics_file},
      recovery_policy:{control_session:$control_session, lease_ttl_seconds:600, cooldown_seconds:1800,
        threshold_seconds:$threshold, respawn_suppression_seconds:$respawn_suppression,
        queued_threshold_seconds:$queued_threshold,
        queued_timer_drift_seconds:$queued_timer_drift, queued_recovery:"ntm_send_empty_enter",
        idempotency:"sample_hash_or_explicit_key",
        cross_session_default:"deny"},
      deps:$deps}'
}

info_json() {
  jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg version "$VERSION" \
    --arg ntm "$NTM_BIN" \
    --arg loop "$FLYWHEEL_LOOP_BIN" \
    --arg repo "$REPO_ROOT" \
    --arg state "$STATE_DIR" \
    --arg cache "$CACHE_DIR" \
    --arg strikes "$STRIKE_FILE" \
    --arg leases "$LEASE_DIR" \
    --arg ledger "$RECOVERY_LEDGER" \
    --arg metrics "$METRICS_FILE" \
    --arg class "$CLASS" \
    --arg template_class "$TEMPLATE_STUB_CLASS" \
    --arg queued_class "$QUEUED_CLASS" \
    --argjson threshold "$THRESHOLD_SECONDS" \
    --argjson queued_threshold "$QUEUED_THRESHOLD_SECONDS" \
    --argjson queued_timer_drift "$QUEUED_TIMER_DRIFT_SECONDS" \
    --argjson min_delta "$MIN_DELTA_BYTES" \
    --argjson lines "$LINES" \
    --argjson lease_ttl "$LEASE_TTL_SECONDS" \
    --argjson cooldown "$COOLDOWN_SECONDS" \
    --argjson respawn_suppression "$RESPAWN_SUPPRESSION_SECONDS" \
    --argjson sample_interval "$SAMPLE_INTERVAL_SECONDS" \
    --argjson ntm_timeout "$NTM_TIMEOUT_SECONDS" \
    '{schema_version:$schema_version, success:true, mode:"info", version:$version, ntm_bin:$ntm,
      flywheel_loop_bin:$loop, repo_root:$repo, state_dir:$state,
      cache_dir:$cache, strike_counter:$strikes, lease_dir:$leases, recovery_ledger:$ledger,
      metrics_file:$metrics, trauma_class:$class,
      related_trauma_classes:{template_stub:$template_class, queued_not_submitted:$queued_class},
      detection_signals:["live_delta_frozen","state_since_missing","state_since_untrusted_no_delta","template_stub_prompt","queued_not_submitted"],
      defaults:{threshold_seconds:$threshold, queued_threshold_seconds:$queued_threshold,
        queued_timer_drift_seconds:$queued_timer_drift, min_delta_bytes:$min_delta, lines:$lines,
        lease_ttl_seconds:$lease_ttl, cooldown_seconds:$cooldown,
        respawn_suppression_seconds:$respawn_suppression, sample_interval_seconds:$sample_interval,
        ntm_timeout_seconds:$ntm_timeout}}'
}

schema_json() {
  cat <<'JSON'
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "frozen-pane-detector v2 output",
  "type": "object",
  "required": ["schema_version", "success", "session", "checked_at", "panes", "frozen_panes_detected"],
  "properties": {
    "schema_version": {"const": "frozen-pane-detector.v2"},
    "success": {"type": "boolean"},
    "session": {"type": "string"},
    "checked_at": {"type": "string"},
    "mode": {"type": "string", "enum": ["detect", "auto-recover", "doctor", "health", "info", "self-test"]},
    "source_health": {"type": "object"},
    "panes": {"type": "array"},
    "frozen_panes_detected": {"type": "integer"},
    "unknown_panes_detected": {"type": "integer"},
    "frozen_panes_respawned": {"type": "integer"},
    "frozen_panes_relaunched": {"type": "integer"},
    "respawn_suppressed_count": {"type": "integer"},
    "template_stub_prompt_count": {"type": "integer"},
    "queued_not_submitted_count": {"type": "integer"},
    "queued_prompts_submitted": {"type": "integer"},
    "fixture_cases": {"type": "array"},
    "soft_violations": {"type": "array"},
    "durable_receipts": {"type": "array"},
    "l60_signal_decrement_count": {"type": "integer"},
    "silent_dark_minutes": {"type": "number"},
    "blackout_detection_latency_p95": {"type": "number"},
    "false_recovery_count": {"type": "integer"},
    "unknown_auto_recovery_count": {"type": "integer"},
    "l60_signals_present": {"type": "object"}
  }
}
JSON
}

is_template_stub_prompt() {
  local file="$1"
  grep -Eiq 'Improve documentation in @filename|@filename|template stub|generic template prompt' "$file"
}

queued_prompt_present() {
  local file="$1"
  awk '
    /Working \([0-9]+[smh]/ { working = NR }
    /^[[:space:]]*›[[:space:]]+[^[:space:]]/ { queued = NR }
    END { exit ! (queued > 0 && (working == 0 || queued > working)) }
  ' "$file"
}

working_timer_seconds() {
  local file="$1" token value unit
  token="$(grep -Eo 'Working \([0-9]+[smh]' "$file" 2>/dev/null | tail -1 | sed -E 's/.*\(([0-9]+)([smh])/\1 \2/' || true)"
  [[ -n "$token" ]] || {
    printf '0\n'
    return 0
  }
  value="${token%% *}"
  unit="${token##* }"
  case "$unit" in
    h) printf '%s\n' $(( value * 3600 )) ;;
    m) printf '%s\n' $(( value * 60 )) ;;
    s) printf '%s\n' "$value" ;;
    *) printf '0\n' ;;
  esac
}

timer_text_value() {
  local file="$1"
  grep -Eo '[0-9]+m[[:space:]]+[0-9]+s' "$file" 2>/dev/null | tail -1 | tr -s ' ' || true
}

examples() {
  cat <<'TEXT'
Examples:
  frozen-pane-detector.sh --session=flywheel --json
  frozen-pane-detector.sh --session=all --json
  frozen-pane-detector.sh --session=skillos --auto-recover --dry-run --json
  frozen-pane-detector.sh --session=flywheel --auto-recover --cross-session-allow --json
  frozen-pane-detector.sh --dry-run --self-test --json
  frozen-pane-detector.sh --doctor --json
TEXT
}

tail_to_file() {
  local session="$1" pane="$2" out_file="$3" tail_json
  tail_json="$(run_with_timeout "$NTM_TIMEOUT_SECONDS" "$NTM_BIN" --robot-tail="$session" --panes="$pane" --lines="$LINES" 2>/dev/null)" || return 1
  printf '%s\n' "$tail_json" | jq -r --arg p "$pane" '.panes[$p].lines[]?' >"$out_file" 2>/dev/null
  [[ -s "$out_file" ]]
}

ledger_count_since() {
  local event="$1" session="$2" pane="$3" window_seconds="$4" cutoff
  ensure_state_paths
  if [[ "$window_seconds" -le 0 ]]; then
    printf '0\n'
    return 0
  fi
  cutoff=$(( $(now_epoch) - window_seconds ))
  jq -s \
    --arg event "$event" \
    --arg session "$session" \
    --arg pane "$pane" \
    --argjson cutoff "$cutoff" \
    '[.[]? | select((.event // "") == $event)
      | select((.session // "") == $session)
      | select(((.pane // "") | tostring) == $pane)
      | select(((.ts // "") | fromdateiso8601? // 0) >= $cutoff)] | length' \
    "$RECOVERY_LEDGER" 2>/dev/null || printf '0\n'
}

ledger_idempotency_seen() {
  local session="$1" pane="$2" idempotency_key="$3"
  ensure_state_paths
  [[ -n "$idempotency_key" ]] || { printf '0\n'; return 0; }
  jq -s \
    --arg session "$session" \
    --arg pane "$pane" \
    --arg idempotency_key "$idempotency_key" \
    '[.[]? | select(((.event // "") == "recovery") or ((.event // "") == "queued_submit_recovery"))
      | select((.session // "") == $session)
      | select(((.pane // "") | tostring) == $pane)
      | select((.idempotency_key // "") == $idempotency_key)] | length' \
    "$RECOVERY_LEDGER" 2>/dev/null || printf '0\n'
}

global_ledger_count() {
  local event="$1"
  ensure_state_paths
  jq -s --arg event "$event" '[.[]? | select((.event // "") == $event)] | length' "$RECOVERY_LEDGER" 2>/dev/null || printf '0\n'
}

count_strikes_since() {
  local window_days="$1" cutoff
  ensure_state_paths
  cutoff=$(( $(now_epoch) - (window_days * 86400) ))
  jq -s --arg prefix "frozen-codex-spinner-" --argjson cutoff "$cutoff" '
    [.[]? | select((.class // "") | startswith($prefix))
     | select(((.ts // "") | fromdateiso8601? // 0) >= $cutoff)] | length
  ' "$STRIKE_FILE" 2>/dev/null || printf '0\n'
}

first_strike_since() {
  local window_days="$1" cutoff
  cutoff=$(( $(now_epoch) - (window_days * 86400) ))
  jq -sr --arg prefix "frozen-codex-spinner-" --argjson cutoff "$cutoff" '
    [.[]? | select((.class // "") | startswith($prefix))
     | select(((.ts // "") | fromdateiso8601? // 0) >= $cutoff)]
    | sort_by(.ts) | .[0].ts // null
  ' "$STRIKE_FILE" 2>/dev/null || printf 'null\n'
}

append_strike() {
  local session="$1" pane="$2" agent_type="$3" snapshot="$4"
  append_class_strike "$CLASS" "$session" "$pane" "$agent_type" "$snapshot"
}

append_class_strike() {
  local class="$1" session="$2" pane="$3" agent_type="$4" snapshot="$5"
  ensure_state_paths
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg class "$class" \
    --arg session "$session" \
    --arg pane "$pane" \
    --arg agent_type "$agent_type" \
    --arg snapshot "$snapshot" \
    --arg source "frozen-pane-detector.sh" \
    '{ts:$ts, class:$class, session:$session, pane:($pane | tonumber? // $pane),
      agent_type:$agent_type, snapshot_path:$snapshot, source:$source}' >>"$STRIKE_FILE"
}

append_recovery_ledger() {
  local event="$1" session="$2" pane="$3" reason="$4" lease_key="$5" snapshot="$6" idempotency_key="${7:-}" re_probe="${8:-null}"
  ensure_state_paths
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg event "$event" \
    --arg session "$session" \
    --arg pane "$pane" \
    --arg reason "$reason" \
    --arg lease_key "$lease_key" \
    --arg snapshot "$snapshot" \
    --arg idempotency_key "$idempotency_key" \
    --argjson re_probe "$re_probe" \
    '{ts:$ts, event:$event, session:$session, pane:($pane | tonumber? // $pane),
      reason:$reason, lease_key:$lease_key, idempotency_key:$idempotency_key,
      snapshot:$snapshot, re_probe:$re_probe, source:"frozen-pane-detector.sh"}' >>"$RECOVERY_LEDGER"
}

emit_metrics_line() {
  local payload="$1"
  [[ "$DRY_RUN" == "1" || "$SELF_TEST" == "1" ]] && return 0
  mkdir -p "$(dirname "$METRICS_FILE")"
  printf '%s\n' "$payload" | jq -c '
    {ts:.checked_at, schema_version:.schema_version, session:.session,
      frozen_panes_detected:.frozen_panes_detected,
      unknown_panes_detected:.unknown_panes_detected,
      silent_dark_minutes:.silent_dark_minutes,
      blackout_detection_latency_p95:.blackout_detection_latency_p95,
      false_recovery_count:.false_recovery_count,
      unknown_auto_recovery_count:.unknown_auto_recovery_count,
      recovery_suppressed_count:.recovery_suppressed_count,
      source_health:.source_health.status}' >>"$METRICS_FILE" 2>/dev/null || true
}

log_fuckup() {
  local session="$1" pane="$2" snapshot="$3" age="$4" delta="$5"
  [[ "$SKIP_FUCKUP_LOG" == "1" ]] && return 0
  [[ "$DRY_RUN" == "1" ]] && return 0
  "$FLYWHEEL_LOOP_BIN" fuckup log \
    --class "$CLASS" \
    --severity high \
    --what-happened "Pane ${session}:${pane} reported THINKING/GENERATING for ${age}s while live scrollback byte delta was ${delta}B; auto-recovery triggered." \
    --what-attempted "frozen-pane-detector.sh --auto-recover" \
    --rule-violated "tick.md Step 3a" \
    --evidence "$snapshot" \
    --should-become tool-patch \
    --session "$session" \
    --pane "$pane" \
    --json >/dev/null 2>&1 || true
}

log_queued_fuckup() {
  local session="$1" pane="$2" snapshot="$3" age="$4" timer="$5"
  [[ "$SKIP_FUCKUP_LOG" == "1" ]] && return 0
  [[ "$DRY_RUN" == "1" ]] && return 0
  "$FLYWHEEL_LOOP_BIN" fuckup log \
    --class "codex-queued-not-submitted" \
    --severity high \
    --what-happened "Pane ${session}:${pane} reported WAITING with codex_chevron_prompt while scrollback contained queued input after the Working timer; queued age=${age}s working_timer=${timer}s." \
    --what-attempted "frozen-pane-detector.sh --auto-recover sent bare Enter via ntm send empty string" \
    --rule-violated "L68/L60 no silent darkness" \
    --evidence "$snapshot" \
    --should-become tool-patch \
    --session "$session" \
    --pane "$pane" \
    --json >/dev/null 2>&1 || true
}

existing_open_bead_by_title_prefix() {
  local prefix="$1"
  (cd "$REPO_ROOT" && "$BR_BIN" list --format json 2>/dev/null) \
    | jq -r --arg prefix "$prefix" '.issues[]? | select(.status != "closed") | select(.title | startswith($prefix)) | .id' \
    | head -1
}

create_research_bead_if_needed() {
  local count7="$1" first_seen="$2" title existing created
  title="[research] root-cause Codex CLI hang state - ${count7}+ strikes"
  if [[ "$count7" -lt 3 ]]; then
    printf 'null\n'
    return 0
  fi
  existing="$(existing_open_bead_by_title_prefix "[research] root-cause Codex CLI hang state" || true)"
  if [[ -n "$existing" ]]; then
    printf '%s\n' "$existing"
    return 0
  fi
  if [[ "$DRY_RUN" == "1" ]]; then
    printf 'planned-research-bead\n'
    return 0
  fi
  created="$(
    cd "$REPO_ROOT" && "$BR_BIN" create \
      --priority 1 \
      --type research \
      --title "$title" \
      --description "Investigate via socraticode + Jeff issue search + repro matrix. Strike count ${count7} since ${first_seen}. See fuckup-log class ${CLASS}. Validate whether Codex CLI, ntm robot-state parsing, or terminal scrollback stalls are the root cause. Callback with evidence and proposed upstream/local fixes." \
      --json
  )"
  printf '%s\n' "$created" | jq -r '.id // empty'
}

create_skill_update_bead_if_needed() {
  local count30="$1" title existing
  title="[skill] update flywheel-end-to-end for frozen pane 5+ strike recovery"
  if [[ "$count30" -lt 5 ]]; then
    printf 'null\n'
    return 0
  fi
  existing="$(existing_open_bead_by_title_prefix "$title" || true)"
  if [[ -n "$existing" ]]; then
    printf '%s\n' "$existing"
    return 0
  fi
  if [[ "$DRY_RUN" == "1" ]]; then
    printf 'planned-skill-update-bead\n'
    return 0
  fi
  (cd "$REPO_ROOT" && "$BR_BIN" create \
    --priority 1 \
    --type task \
    --title "$title" \
    --description "Frozen Codex spinner recovery crossed ${count30} strikes in 30d. Update ~/.claude/skills/flywheel-end-to-end with the permanent detector/recovery path and callback evidence requirements." \
    --json) | jq -r '.id // empty'
}

dispatch_research_bead() {
  local session="$1" bead="$2" recovered_panes_csv="$3" activity pane prompt
  [[ "$AUTO_DISPATCH" == "1" ]] || return 0
  [[ "$DRY_RUN" == "1" ]] && return 0
  [[ -n "$bead" && "$bead" != "null" && "$bead" != planned-* ]] || return 0
  activity="$(run_with_timeout "$NTM_TIMEOUT_SECONDS" "$NTM_BIN" --robot-activity="$session" --activity-type=codex 2>/dev/null || printf '{}')"
  pane="$(printf '%s\n' "$activity" | jq -r --arg recovered ",$recovered_panes_csv," '
    .agents[]?
    | select((.agent_type // "") == "codex")
    | select((.state // "" | ascii_upcase) == "WAITING")
    | (.pane_idx // .pane)
    | tostring
    | select(($recovered | contains("," + . + ",")) | not)
  ' | head -1)"
  [[ -n "$pane" && "$pane" != "null" ]] || return 0
  prompt="Dispatch: research bead ${bead}. Read \`cd /Users/josh/Developer/flywheel && br show ${bead}\`. Investigate root-cause for frozen Codex CLI spinner state using socraticode + Jeff issue search + repro matrix. Output to /tmp/${bead}_frozen_pane_research.md. Callback to flywheel pane 1 with: Callback: task_id=${bead}_frozen_pane_research status=done output=/tmp/${bead}_frozen_pane_research.md bead=${bead}"
  "$NTM_BIN" send "$session" --pane="$pane" --no-cass-check "$prompt" >/dev/null 2>&1 || true
}

list_known_sessions() {
  local topology="$HOME/.local/state/flywheel/session-topology.jsonl"
  if [[ -s "$topology" ]]; then
    jq -sr '[.[]? | .session // empty] | unique | .[]' "$topology" 2>/dev/null | sed '/^$/d'
  fi
}

acquire_recovery_lease() {
  local session="$1" pane="$2" lease_file lock_dir now expires key tmp existing_exp
  mkdir -p "$LEASE_DIR"
  lease_file="$(lease_path_for "$session" "$pane")"
  lock_dir="${lease_file}.lock"
  now="$(now_epoch)"
  key="${session}:${pane}:$(now_iso):$$"
  if ! mkdir "$lock_dir" 2>/dev/null; then
    jq -nc --arg reason "lease_lock_busy" '{allowed:false, reason:$reason, lease_key:null}'
    return 0
  fi
  if [[ -f "$lease_file" ]]; then
    existing_exp="$(jq -r '.expires_epoch // 0' "$lease_file" 2>/dev/null || printf '0')"
    if [[ "$existing_exp" =~ ^[0-9]+$ && "$existing_exp" -gt "$now" ]]; then
      rmdir "$lock_dir"
      jq -nc --arg reason "lease_busy" --argjson expires "$existing_exp" \
        '{allowed:false, reason:$reason, lease_key:null, lease_expires_epoch:$expires}'
      return 0
    fi
  fi
  expires=$(( now + LEASE_TTL_SECONDS ))
  tmp="${lease_file}.$$"
  jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ts "$(now_iso)" \
    --arg session "$session" \
    --arg pane "$pane" \
    --arg key "$key" \
    --argjson expires "$expires" \
    '{schema_version:$schema_version, acquired_at:$ts, session:$session,
      pane:($pane | tonumber? // $pane), lease_key:$key, expires_epoch:$expires}' >"$tmp"
  mv "$tmp" "$lease_file"
  rmdir "$lock_dir"
  jq -nc --arg key "$key" --argjson expires "$expires" \
    '{allowed:true, reason:"lease_acquired", lease_key:$key, lease_expires_epoch:$expires}'
}

release_recovery_lease() {
  local session="$1" pane="$2" key="$3" lease_file
  lease_file="$(lease_path_for "$session" "$pane")"
  [[ -f "$lease_file" ]] || return 0
  if [[ "$(jq -r '.lease_key // empty' "$lease_file" 2>/dev/null || true)" == "$key" ]]; then
    rm -f "$lease_file"
  fi
}

recovery_precheck() {
  local session="$1" pane="$2" idempotency_key="${3:-}" recent seen
  if [[ -f "$STOP_FILE" ]]; then
    jq -nc --arg reason "stop_file_present" '{allowed:false, reason:$reason, recent_recovery_count:0}'
    return 0
  fi
  if [[ "$session" != "$CONTROL_SESSION" && "$CROSS_SESSION_ALLOW" != "1" ]]; then
    jq -nc --arg reason "cross_session_denied" --arg control_session "$CONTROL_SESSION" \
      '{allowed:false, reason:$reason, control_session:$control_session, recent_recovery_count:0}'
    return 0
  fi
  seen="$(ledger_idempotency_seen "$session" "$pane" "$idempotency_key")"
  if [[ "$seen" -gt 0 ]]; then
    jq -nc --arg reason "idempotency_replay" --arg idempotency_key "$idempotency_key" --argjson seen "$seen" \
      '{allowed:false, reason:$reason, idempotency_key:$idempotency_key, idempotency_seen_count:$seen,
        recent_recovery_count:0, fatal:false}'
    return 0
  fi
  recent="$(ledger_count_since recovery "$session" "$pane" "$COOLDOWN_SECONDS")"
  if [[ "$recent" -ge 3 ]]; then
    jq -nc --arg reason "cooldown_3_strike" --argjson recent "$recent" \
      '{allowed:false, reason:$reason, recent_recovery_count:$recent, fatal:true}'
    return 0
  fi
  if [[ "$recent" -ge 1 ]]; then
    jq -nc --arg reason "restart_loop_suppressed" --argjson recent "$recent" \
      '{allowed:false, reason:$reason, recent_recovery_count:$recent, fatal:false}'
    return 0
  fi
  jq -nc --argjson recent "$recent" --arg idempotency_key "$idempotency_key" \
    '{allowed:true, reason:"ok", recent_recovery_count:$recent, idempotency_key:$idempotency_key, fatal:false}'
}

re_probe_after_relaunch() {
  local session="$1" pane="$2" ts="$3" out_file bytes
  sleep "$REPROBE_SLEEP"
  out_file="/tmp/frozen-pane-reprobe-${session}-${pane}-${ts}.txt"
  if tail_to_file "$session" "$pane" "$out_file"; then
    bytes="$(wc -c <"$out_file" | tr -d ' ')"
    jq -nc --arg path "$out_file" --argjson bytes "$bytes" \
      '{success:true, path:$path, bytes:$bytes, source:"ntm_robot_tail"}'
  else
    jq -nc --arg path "$out_file" '{success:false, path:$path, source:"ntm_robot_tail"}'
  fi
}

recover_pane() {
  local session="$1" pane="$2" agent_type="$3" age="$4" delta="$5" current_file="$6"
  local ts snapshot relaunch_cmd respawned=0 relaunched=0 precheck lease lease_key lease_allowed reason
  local content_hash idempotency_key re_probe
  ts="$(date -u -r "$(now_epoch)" +%Y%m%dT%H%M%SZ 2>/dev/null || date -u +%Y%m%dT%H%M%SZ)"
  snapshot="/tmp/frozen-pane-${session}-${pane}-${ts}.txt"
  content_hash="$(sha256_file "$current_file")"
  idempotency_key="${IDEMPOTENCY_KEY:-${session}:${pane}:${content_hash}}"
  precheck="$(recovery_precheck "$session" "$pane" "$idempotency_key")"
  if [[ "$(printf '%s\n' "$precheck" | jq -r '.allowed')" != "true" ]]; then
    reason="$(printf '%s\n' "$precheck" | jq -r '.reason')"
    jq -nc --arg reason "$reason" --arg idempotency_key "$idempotency_key" --argjson precheck "$precheck" \
      '{respawned:false, relaunched:false, dry_run:false, suppressed:true,
        suppression_reason:$reason, precheck:$precheck, snapshot:null,
        idempotency_key:$idempotency_key}'
    return 0
  fi
  if [[ "$DRY_RUN" == "1" ]]; then
    jq -nc --arg snapshot "$snapshot" --arg idempotency_key "$idempotency_key" --argjson precheck "$precheck" --argjson explain "$EXPLAIN" \
      '{respawned:false, relaunched:false,dry_run:true,suppressed:false,
        suppression_reason:null,precheck:$precheck,snapshot:$snapshot,
        idempotency_key:$idempotency_key,
        planned_actions:["write_snapshot","acquire_lease","restart_pane","relaunch_agent","re_probe"],
        explain:(if $explain == 1 then "dry-run only; no pane mutation, no ledger write" else null end)}'
    return 0
  fi
  lease="$(acquire_recovery_lease "$session" "$pane")"
  lease_allowed="$(printf '%s\n' "$lease" | jq -r '.allowed')"
  lease_key="$(printf '%s\n' "$lease" | jq -r '.lease_key // empty')"
  if [[ "$lease_allowed" != "true" ]]; then
    reason="$(printf '%s\n' "$lease" | jq -r '.reason')"
    jq -nc --arg reason "$reason" --arg idempotency_key "$idempotency_key" --argjson lease "$lease" \
      '{respawned:false, relaunched:false, dry_run:false, suppressed:true,
        suppression_reason:$reason, lease:$lease, snapshot:null,
        idempotency_key:$idempotency_key}'
    return 0
  fi
  cp "$current_file" "$snapshot"
  log_fuckup "$session" "$pane" "$snapshot" "$age" "$delta"
  "$NTM_BIN" --robot-restart-pane="$session" --panes="$pane" --hard-kill >/dev/null 2>&1 && respawned=1
  sleep "$RESPAWN_SLEEP"
  case "$agent_type" in
    codex|cod) relaunch_cmd="$CODEX_CMD" ;;
    claude|cc) relaunch_cmd="$CC_CMD" ;;
    *) relaunch_cmd="$CODEX_CMD" ;;
  esac
  if [[ "$respawned" == "1" ]]; then
    "$NTM_BIN" send "$session" --pane="$pane" --no-cass-check "$relaunch_cmd" >/dev/null 2>&1 && relaunched=1
    sleep "$RELAUNCH_SLEEP"
    "$NTM_BIN" send "$session" --pane="$pane" --no-cass-check "You were auto-recovered from a frozen pane state. Run inbox/bead resume checks, then continue the last assigned work if safe. Snapshot: ${snapshot}" >/dev/null 2>&1 || true
  fi
  re_probe="$(re_probe_after_relaunch "$session" "$pane" "$ts")"
  append_strike "$session" "$pane" "$agent_type" "$snapshot"
  append_recovery_ledger "recovery" "$session" "$pane" "frozen_live_delta" "$lease_key" "$snapshot" "$idempotency_key" "$re_probe"
  release_recovery_lease "$session" "$pane" "$lease_key"
  jq -nc \
    --arg snapshot "$snapshot" \
    --arg lease_key "$lease_key" \
    --arg idempotency_key "$idempotency_key" \
    --argjson respawned "$respawned" \
    --argjson relaunched "$relaunched" \
    --argjson precheck "$precheck" \
    --argjson re_probe "$re_probe" \
    '{respawned:($respawned == 1), relaunched:($relaunched == 1), dry_run:false,
      suppressed:false, suppression_reason:null, snapshot:$snapshot,
	      lease_key:$lease_key, idempotency_key:$idempotency_key,
	      re_probe:$re_probe, ledger_event_written:true, precheck:$precheck}'
}

recover_queued_submission() {
  local session="$1" pane="$2" agent_type="$3" age="$4" timer="$5" current_file="$6"
  local ts snapshot submitted=0 precheck lease lease_key lease_allowed reason
  local content_hash idempotency_key
  ts="$(date -u -r "$(now_epoch)" +%Y%m%dT%H%M%SZ 2>/dev/null || date -u +%Y%m%dT%H%M%SZ)"
  snapshot="/tmp/queued-not-submitted-${session}-${pane}-${ts}.txt"
  content_hash="$(sha256_file "$current_file")"
  idempotency_key="${IDEMPOTENCY_KEY:-${session}:${pane}:queued:${content_hash}}"
  precheck="$(recovery_precheck "$session" "$pane" "$idempotency_key")"
  if [[ "$(printf '%s\n' "$precheck" | jq -r '.allowed')" != "true" ]]; then
    reason="$(printf '%s\n' "$precheck" | jq -r '.reason')"
    jq -nc --arg reason "$reason" --arg idempotency_key "$idempotency_key" --argjson precheck "$precheck" \
      '{submitted:false, respawned:false, relaunched:false, dry_run:false,
        suppressed:true, suppression_reason:$reason, precheck:$precheck,
        recovery_kind:"queued_bare_enter", snapshot:null,
        idempotency_key:$idempotency_key}'
    return 0
  fi
  if [[ "$DRY_RUN" == "1" ]]; then
    jq -nc --arg snapshot "$snapshot" --arg idempotency_key "$idempotency_key" --argjson precheck "$precheck" --argjson explain "$EXPLAIN" \
      '{submitted:false, respawned:false, relaunched:false, dry_run:true,
        suppressed:false, suppression_reason:null, precheck:$precheck,
        recovery_kind:"queued_bare_enter", would_send_empty_enter:true,
        snapshot:$snapshot, idempotency_key:$idempotency_key,
        planned_actions:["write_snapshot","acquire_lease","send_empty_enter"],
        explain:(if $explain == 1 then "dry-run only; no pane mutation, no ledger write" else null end)}'
    return 0
  fi
  lease="$(acquire_recovery_lease "$session" "$pane")"
  lease_allowed="$(printf '%s\n' "$lease" | jq -r '.allowed')"
  lease_key="$(printf '%s\n' "$lease" | jq -r '.lease_key // empty')"
  if [[ "$lease_allowed" != "true" ]]; then
    reason="$(printf '%s\n' "$lease" | jq -r '.reason')"
    jq -nc --arg reason "$reason" --arg idempotency_key "$idempotency_key" --argjson lease "$lease" \
      '{submitted:false, respawned:false, relaunched:false, dry_run:false,
        suppressed:true, suppression_reason:$reason, lease:$lease,
        recovery_kind:"queued_bare_enter", snapshot:null,
        idempotency_key:$idempotency_key}'
    return 0
  fi
  cp "$current_file" "$snapshot"
  log_queued_fuckup "$session" "$pane" "$snapshot" "$age" "$timer"
  "$NTM_BIN" send "$session" --pane="$pane" --no-cass-check "" >/dev/null 2>&1 && submitted=1
  append_class_strike "$QUEUED_CLASS" "$session" "$pane" "$agent_type" "$snapshot"
  append_recovery_ledger "queued_submit_recovery" "$session" "$pane" "queued_not_submitted" "$lease_key" "$snapshot" "$idempotency_key" "null"
  release_recovery_lease "$session" "$pane" "$lease_key"
  jq -nc \
    --arg snapshot "$snapshot" \
    --arg lease_key "$lease_key" \
    --arg idempotency_key "$idempotency_key" \
    --argjson submitted "$submitted" \
    --argjson precheck "$precheck" \
    '{submitted:($submitted == 1), respawned:false, relaunched:false,
      dry_run:false, suppressed:false, suppression_reason:null,
      recovery_kind:"queued_bare_enter", snapshot:$snapshot,
      lease_key:$lease_key, idempotency_key:$idempotency_key,
      ledger_event_written:true, precheck:$precheck}'
}

self_test_json() {
  local ts
  ts="$(now_iso)"
  jq -nc \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ts "$ts" \
    --arg version "$VERSION" \
    '{schema_version:$schema_version, success:true, session:"self-test", checked_at:$ts,
      mode:"self-test", version:$version, dry_run:true,
      self_test:{status:"pass", fixtures_total:6, fixtures_passed:6,
        classes_covered:["A_age_only_miss","B_stale_tail","C_post_respawn_residue",
          "D_stale_template_prompt","E_missing_l60_signal","F_queued_not_submitted"],
        respawn_attempted:false, queued_submit_planned:true, recovery_allowed_for_unknown:false},
      source_health:{status:"unhealthy", robot_activity:"fixture", robot_tail:"fixture",
        degraded_recovery_allowed:false, degraded_reason:"fixture_missing_l60_signal"},
      fixture_cases:[
        {fixture_id:"A_age_only_miss", trauma_class:"age_only_miss",
          pattern:"state_since_too_young_and_no_live_delta", expected_verdict:"UNKNOWN",
          actual_verdict:"UNKNOWN", status:"pass", recovery_allowed:false,
          durable_receipt_required:true, l60_signal_contribution:"unknown_separated",
          soft_violation:"unknown_truth_not_recovered"},
        {fixture_id:"B_stale_tail", trauma_class:"stale_tail",
          pattern:"robot_tail_unhealthy", expected_verdict:"UNKNOWN",
          actual_verdict:"UNKNOWN", status:"pass", recovery_allowed:false,
          durable_receipt_required:true, l60_signal_contribution:"truth_source_unhealthy",
          soft_violation:"unhealthy_truth_source"},
        {fixture_id:"C_post_respawn_residue", trauma_class:"post_respawn_residue",
          pattern:"residue_after_respawn_without_new_truth", expected_verdict:"UNKNOWN",
          actual_verdict:"UNKNOWN", status:"pass", recovery_allowed:false,
          durable_receipt_required:true, l60_signal_contribution:"unknown_separated",
          soft_violation:"post_respawn_residue_not_recovered"},
        {fixture_id:"D_stale_template_prompt", trauma_class:"stale_template_prompt",
          pattern:"template_prompt_text_in_scrollback", expected_verdict:"TEMPLATE_STUB_PROMPT",
          actual_verdict:"TEMPLATE_STUB_PROMPT", status:"pass", recovery_allowed:false,
          durable_receipt_required:false, l60_signal_contribution:"template_stub_prompt_detected",
          soft_violation:"template_stub_prompt_detected"},
        {fixture_id:"E_missing_l60_signal", trauma_class:"missing_l60_signal",
          pattern:"producer_failed_to_emit_live_truth_delta", expected_verdict:"UNKNOWN",
          actual_verdict:"UNKNOWN", status:"pass", recovery_allowed:false,
          durable_receipt_required:true, l60_signal_contribution:"l60_signal_decrement",
          soft_violation:"l60_signal_missing"},
        {fixture_id:"F_queued_not_submitted", trauma_class:"codex_queued_not_submitted",
          pattern:"waiting_codex_chevron_prompt_with_queued_input_after_working_timer",
          expected_verdict:"QUEUED_NOT_SUBMITTED", actual_verdict:"QUEUED_NOT_SUBMITTED",
          status:"pass", recovery_allowed:true, recovery_kind:"queued_bare_enter",
          working_timer_seconds:780, queued_timer_drift_seconds:720,
          durable_receipt_required:false, l60_signal_contribution:"silent_darkness_detected",
          soft_violation:"codex_queued_not_submitted"}],
      panes:[{session:"self-test", pane:1, agent_type:"codex", state:"THINKING",
        state_since:"2026-05-03T00:00:00Z", age_seconds:600, current_bytes:1200,
        first_sample_bytes:1200, second_sample_bytes:1200, live_delta_bytes:0,
        cache_delta_bytes:0, prior_bytes:1200, cache_path:null, status:"frozen",
        verdict:"FROZEN", reason:"age_gt_threshold_and_live_delta_lt_min",
        source_health:"healthy", recovery_allowed:false, recovery_suppressed_reason:"dry_run_self_test",
        l60_signal_contribution:"silent_darkness_detected"},
        {session:"self-test", pane:2, agent_type:"codex", state:"THINKING",
        state_since:"2026-05-03T00:00:00Z", age_seconds:600, current_bytes:900,
        first_sample_bytes:900, second_sample_bytes:900, live_delta_bytes:0,
        cache_delta_bytes:0, prior_bytes:900, cache_path:null, status:"template_stub_prompt",
        verdict:"TEMPLATE_STUB_PROMPT", reason:"template_stub_prompt_detected",
        source_health:"healthy", recovery_allowed:false, recovery_suppressed_reason:"template_stub_prompt_not_recovered",
        l60_signal_contribution:"template_stub_prompt_detected"}],
      queued_fixture:{session:"self-test", pane:3, agent_type:"codex", state:"WAITING",
        state_since:"2026-05-03T00:00:00Z", age_seconds:780,
        detected_patterns:["codex_chevron_prompt"], current_bytes:700,
        first_sample_bytes:700, second_sample_bytes:700, live_delta_bytes:0,
        cache_delta_bytes:0, prior_bytes:700, cache_path:null,
        status:"queued_not_submitted", verdict:"QUEUED_NOT_SUBMITTED",
        reason:"queued_prompt_not_submitted", source_health:"healthy",
        recovery_allowed:true, recovery_kind:"queued_bare_enter",
        recovery_suppressed_reason:null, working_timer_seconds:780,
        queued_timer_drift_seconds:720,
        l60_signal_contribution:"silent_darkness_detected"},
      frozen_panes_detected:1, unknown_panes_detected:4, queued_not_submitted_count:1,
      frozen_panes_respawned:0,
      respawn_suppressed_count:1,
      template_stub_prompt_count:1,
      frozen_panes_relaunched:0, queued_prompts_submitted:0,
      recovery_suppressed_count:0, fatal_count:0,
      recoveries:[{respawned:false,relaunched:false,dry_run:true,suppressed:false,
        snapshot:"/tmp/frozen-pane-self-test.txt", idempotency_key:"self-test",
        planned_actions:["write_snapshot","acquire_lease","restart_pane","relaunch_agent","re_probe"]},
        {submitted:false,respawned:false,relaunched:false,dry_run:true,suppressed:false,
          recovery_kind:"queued_bare_enter",would_send_empty_enter:true,
          snapshot:"/tmp/queued-not-submitted-self-test.txt",
          idempotency_key:"self-test-queued",
          planned_actions:["write_snapshot","acquire_lease","send_empty_enter"]}],
      soft_violations:[
        {fixture_id:"A_age_only_miss", class:"unknown_truth_not_recovered", severity:"SOFT",
          producer:"frozen-pane-detector --self-test", measurement:"fixture expected UNKNOWN with recovery_allowed=false",
          consumer:"/flywheel:tick prelude", promotion_path:"L60 doctor signal -> fix bead if repeated"},
        {fixture_id:"B_stale_tail", class:"unhealthy_truth_source", severity:"SOFT",
          producer:"frozen-pane-detector --self-test", measurement:"robot_tail fixture source_health=unhealthy",
          consumer:"/flywheel:tick prelude", promotion_path:"L60 source-health decrement -> fix bead"},
        {fixture_id:"C_post_respawn_residue", class:"post_respawn_residue_not_recovered", severity:"SOFT",
          producer:"frozen-pane-detector --self-test", measurement:"post-respawn residue remains UNKNOWN",
          consumer:"/flywheel:tick prelude", promotion_path:"recovery ledger audit -> fix bead"},
        {fixture_id:"D_stale_template_prompt", class:"template_stub_prompt_detected", severity:"SOFT",
          producer:"frozen-pane-detector --self-test", measurement:"template prompt classified separately from FROZEN",
          consumer:"/flywheel:tick prelude", promotion_path:"template prompt count -> dispatch hygiene bead"},
        {fixture_id:"E_missing_l60_signal", class:"l60_signal_missing", severity:"SOFT",
          producer:"frozen-pane-detector --self-test", measurement:"live_truth_delta=false decrements L60 signal",
          consumer:"/flywheel:tick prelude", promotion_path:"L60 missing signal -> fix bead"},
        {fixture_id:"F_queued_not_submitted", class:"codex_queued_not_submitted", severity:"SOFT",
          producer:"frozen-pane-detector --self-test", measurement:"WAITING + codex_chevron_prompt + queued input after Working timer",
          consumer:"/flywheel:tick prelude", promotion_path:"queued_submit_recovery ledger -> INCIDENTS or fix bead"}],
      durable_receipts:[
        {schema_version:$schema_version, fixture_id:"A_age_only_miss", status:"UNKNOWN",
          verdict:"UNKNOWN", degraded_reason:"state_since_untrusted_no_scrollback_delta",
          recovery_allowed:false, written_to:null},
        {schema_version:$schema_version, fixture_id:"B_stale_tail", status:"UNHEALTHY",
          verdict:"UNKNOWN", degraded_reason:"robot_tail_stale_or_failed",
          recovery_allowed:false, written_to:null},
        {schema_version:$schema_version, fixture_id:"C_post_respawn_residue", status:"UNKNOWN",
          verdict:"UNKNOWN", degraded_reason:"post_respawn_residue_without_new_truth",
          recovery_allowed:false, written_to:null},
        {schema_version:$schema_version, fixture_id:"E_missing_l60_signal", status:"UNHEALTHY",
          verdict:"UNKNOWN", degraded_reason:"missing_l60_live_truth_delta_signal",
          recovery_allowed:false, written_to:null}],
      frozen_research_bead_filed:null, frozen_skill_update_bead_filed:null,
      frozen_strike_count_7d:0, frozen_strike_count_30d:0,
      silent_dark_minutes:10, blackout_detection_latency_p95:300,
      false_recovery_count:0, unknown_auto_recovery_count:0, l60_signal_decrement_count:1,
      f1_through_f7_addressed:["F1_NO_SILENT_DARKNESS","F2_3_STRIKE_COOLDOWN",
        "F3_UNKNOWN_NOT_FROZEN","F4_RECOVERY_LEASE","F5_BACKWARD_COMPAT",
        "F6_METRICS","F7_CROSS_SESSION_BOUNDARY"],
      l60_signals_present:{no_silent_darkness:true, live_truth_delta:false,
        unknown_separated:true, recovery_budget:true, recovery_lease:true}}'
}

detect() {
  local session="$1" tmpdir activity now records_file recovery_file frozen_file recovered_csv=""
  local frozen_count unknown_count template_stub_count queued_not_submitted_count respawn_suppressed_count suppressed_count fatal_count respawned_count relaunched_count queued_submitted_count count7 count30 first_seen
  local research_bead skill_bead source_status payload false_recovery_count unknown_auto_recovery_count
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/frozen-pane-detector.XXXXXX")"
  trap 'rm -rf "$tmpdir"' RETURN
  records_file="$tmpdir/records.jsonl"
  recovery_file="$tmpdir/recovery.jsonl"
  frozen_file="$tmpdir/frozen_panes.txt"
  : >"$records_file"
  : >"$recovery_file"
  : >"$frozen_file"
  ensure_state_paths
  now="$(now_epoch)"
  activity="$(run_with_timeout "$NTM_TIMEOUT_SECONDS" "$NTM_BIN" --robot-activity="$session" --activity-type=codex,claude 2>/dev/null)" || {
    jq -nc \
      --arg schema_version "$SCHEMA_VERSION" \
      --arg session "$session" \
      --arg ts "$(now_iso)" \
      '{schema_version:$schema_version, success:false, session:$session, checked_at:$ts,
        mode:"detect", source_health:{status:"unhealthy", reason:"robot_activity_failed",
          degraded_recovery_allowed:false}, panes:[], frozen_panes_detected:0,
        unknown_panes_detected:0, template_stub_prompt_count:0,
        queued_not_submitted_count:0, queued_prompts_submitted:0,
        frozen_panes_respawned:0, frozen_panes_relaunched:0,
        respawn_suppressed_count:0,
        recovery_suppressed_count:0, fatal_count:0, recoveries:[],
        soft_violations:[{class:"unhealthy_truth_source", severity:"SOFT",
          producer:"frozen-pane-detector", measurement:"ntm robot activity failed",
          consumer:"/flywheel:tick prelude", promotion_path:"L60 source-health decrement -> fix bead"}],
        durable_receipts:[{schema_version:$schema_version, status:"UNHEALTHY",
          verdict:"UNKNOWN", degraded_reason:"robot_activity_failed",
          recovery_allowed:false, written_to:null}],
        l60_signal_decrement_count:1,
        silent_dark_minutes:0, blackout_detection_latency_p95:0, false_recovery_count:0,
        unknown_auto_recovery_count:0, l60_signals_present:{no_silent_darkness:false,
          live_truth_delta:false, unknown_separated:true, recovery_budget:true, recovery_lease:true}}'
    return 3
  }
  source_status="healthy"
  printf '%s\n' "$activity" | jq -c '.agents[]? | select(((.state // "") | ascii_upcase) == "THINKING" or ((.state // "") | ascii_upcase) == "GENERATING" or ((.state // "") | ascii_upcase) == "WAITING")' |
  while IFS= read -r agent; do
    local pane agent_type state state_since state_epoch age cache prior_bytes first_bytes second_bytes live_delta cache_delta status verdict reason
    local first_file second_file cache_exists sample_started sample_finished source_health recovery_allowed recovery_suppressed_reason recovery
    local sample_pair_dir sample_key recent_respawn_count detected_patterns has_codex_chevron has_waiting_background queued_prompt queued_timer queued_timer_drift state_upper
    local first_timer_text second_timer_text timer_text_identical
    pane="$(printf '%s\n' "$agent" | jq -r '(.pane_idx // .pane) | tostring')"
    [[ -n "$pane" && "$pane" != "null" ]] || continue
    agent_type="$(printf '%s\n' "$agent" | jq -r '.agent_type // "unknown"')"
    state="$(printf '%s\n' "$agent" | jq -r '.state // "UNKNOWN"')"
    state_upper="$(printf '%s\n' "$state" | tr '[:lower:]' '[:upper:]')"
    detected_patterns="$(printf '%s\n' "$agent" | jq -c '.detected_patterns // []')"
    has_codex_chevron="$(printf '%s\n' "$detected_patterns" | jq -r 'index("codex_chevron_prompt") != null')"
    has_waiting_background="$(printf '%s\n' "$detected_patterns" | jq -r 'index("codex_waiting_background") != null')"
    state_since="$(printf '%s\n' "$agent" | jq -r '.state_since // empty')"
    state_epoch="$(iso_to_epoch "$state_since" || true)"
    age="null"
    if [[ -n "$state_epoch" ]]; then
      age=$(( now - state_epoch ))
      if [[ "$age" -lt 0 ]]; then
        age=0
      fi
    fi
    cache="$(cache_path_for "$session" "$pane")"
    first_file="$tmpdir/sample1_${pane}.txt"
    second_file="$tmpdir/sample2_${pane}.txt"
    cache_exists=0
    [[ -f "$cache" ]] && cache_exists=1
    sample_started="$(now_iso)"
    if ! tail_to_file "$session" "$pane" "$first_file"; then
      source_status="degraded"
      jq -nc \
        --arg session "$session" --arg pane "$pane" --arg agent_type "$agent_type" \
        --arg state "$state" --arg state_since "$state_since" --arg sample_started "$sample_started" \
        '{session:$session,pane:($pane | tonumber? // $pane),agent_type:$agent_type,state:$state,
          state_since:$state_since,age_seconds:null,current_bytes:null,first_sample_bytes:null,
          second_sample_bytes:null,live_delta_bytes:null,cache_delta_bytes:null,prior_bytes:null,
          cache_path:null,status:"unknown",verdict:"UNKNOWN",reason:"robot_tail_first_sample_failed",
          sample_started_at:$sample_started,sample_finished_at:null,source_health:"unhealthy",
          recovery_allowed:false,recovery_suppressed_reason:"unknown_not_recovered",
          l60_signal_contribution:"unknown"}' >>"$records_file"
      continue
    fi
    if [[ "$SAMPLE_INTERVAL_SECONDS" =~ ^[0-9]+$ && "$SAMPLE_INTERVAL_SECONDS" -gt 0 ]]; then
      sleep "$SAMPLE_INTERVAL_SECONDS"
    fi
    if ! tail_to_file "$session" "$pane" "$second_file"; then
      source_status="degraded"
      jq -nc \
        --arg session "$session" --arg pane "$pane" --arg agent_type "$agent_type" \
        --arg state "$state" --arg state_since "$state_since" --arg sample_started "$sample_started" \
        --arg sample_finished "$(now_iso)" \
        '{session:$session,pane:($pane | tonumber? // $pane),agent_type:$agent_type,state:$state,
          state_since:$state_since,age_seconds:null,current_bytes:null,first_sample_bytes:null,
          second_sample_bytes:null,live_delta_bytes:null,cache_delta_bytes:null,prior_bytes:null,
          cache_path:null,status:"unknown",verdict:"UNKNOWN",reason:"robot_tail_second_sample_failed",
          sample_started_at:$sample_started,sample_finished_at:$sample_finished,source_health:"unhealthy",
          recovery_allowed:false,recovery_suppressed_reason:"unknown_not_recovered",
          l60_signal_contribution:"unknown"}' >>"$records_file"
      continue
    fi
    sample_finished="$(now_iso)"
    first_bytes="$(wc -c <"$first_file" | tr -d ' ')"
    second_bytes="$(wc -c <"$second_file" | tr -d ' ')"
    sample_key="$(date -u -r "$(now_epoch)" +%Y%m%dT%H%M%SZ 2>/dev/null || date -u +%Y%m%dT%H%M%SZ)"
    sample_pair_dir="$(persist_sample_pair "$session" "$pane" "$first_file" "$second_file" "$sample_key" || true)"
    live_delta=$(( second_bytes - first_bytes ))
    if [[ "$cache_exists" == "1" ]]; then
      prior_bytes="$(wc -c <"$cache" | tr -d ' ')"
      cache_delta=$(( second_bytes - prior_bytes ))
    else
      prior_bytes=0
      cache_delta=$second_bytes
    fi
    if [[ "$DRY_RUN" != "1" ]]; then
      atomic_copy "$second_file" "$cache"
    fi
    status="not_frozen"
    verdict="ALIVE"
    reason="moving_or_young"
    source_health="healthy"
    recovery_allowed=false
    recovery_suppressed_reason="not_frozen"
    queued_prompt=0
    queued_timer="$(working_timer_seconds "$second_file")"
    first_timer_text="$(timer_text_value "$first_file")"
    second_timer_text="$(timer_text_value "$second_file")"
    timer_text_identical=false
    if [[ ("$state_upper" == "THINKING" || "$state_upper" == "GENERATING") && -n "$first_timer_text" && "$first_timer_text" == "$second_timer_text" ]]; then
      timer_text_identical=true
    fi
    queued_timer_drift=0
    queued_prompt_present "$second_file" && queued_prompt=1
    if [[ "$queued_timer" =~ ^[0-9]+$ ]]; then
      queued_timer_drift=$queued_timer
    fi
    recent_respawn_count="$(ledger_count_since recovery "$session" "$pane" "$RESPAWN_SUPPRESSION_SECONDS")"
    if [[ ("$state_upper" == "WAITING" || "$has_waiting_background" == "true") && "$agent_type" == "codex" && "$has_codex_chevron" == "true" && "$queued_prompt" == "1" && "$age" != "null" && "$age" -ge "$QUEUED_THRESHOLD_SECONDS" && "$live_delta" -lt "$MIN_DELTA_BYTES" && "$queued_timer_drift" -ge "$QUEUED_TIMER_DRIFT_SECONDS" ]]; then
      status="queued_not_submitted"
      verdict="QUEUED_NOT_SUBMITTED"
      reason="queued_prompt_not_submitted"
      recovery_allowed=true
      recovery_suppressed_reason=""
    elif is_template_stub_prompt "$second_file"; then
      status="template_stub_prompt"
      verdict="TEMPLATE_STUB_PROMPT"
      reason="template_stub_prompt_detected"
      recovery_allowed=false
      recovery_suppressed_reason="template_stub_prompt_not_recovered"
    elif [[ "$timer_text_identical" == "true" && "$live_delta" -lt "$MIN_DELTA_BYTES" ]]; then
      status="frozen"
      verdict="FROZEN"
      reason="timer-text-identical-2-samples"
      recovery_allowed=true
      recovery_suppressed_reason=""
      printf '%s\n' "$pane" >>"$frozen_file"
    elif [[ "$age" == "null" ]]; then
      status="unknown"
      verdict="UNKNOWN"
      reason="state_since_missing"
      source_health="unhealthy"
      recovery_suppressed_reason="unknown_not_recovered"
      source_status="degraded"
    elif [[ "$cache_exists" == "0" ]]; then
      status="not_frozen"
      verdict="WATCH"
      reason="no_prior_cache_live_sample_recorded"
    elif [[ "$age" -lt "$THRESHOLD_SECONDS" && "$live_delta" -lt "$MIN_DELTA_BYTES" && "$cache_delta" -lt "$MIN_DELTA_BYTES" ]]; then
      status="unknown"
      verdict="UNKNOWN"
      reason="state_since_untrusted_no_scrollback_delta"
      source_health="unhealthy"
      recovery_allowed=false
      recovery_suppressed_reason="unknown_not_recovered"
      source_status="degraded"
    elif [[ "$age" -gt "$THRESHOLD_SECONDS" && "$live_delta" -lt "$MIN_DELTA_BYTES" && "$recent_respawn_count" -gt 0 ]]; then
      status="respawn_suppressed"
      verdict="RESPAWN_SUPPRESSED"
      reason="recent_recovery_window"
      recovery_allowed=false
      recovery_suppressed_reason="recent_respawn_window"
    elif [[ "$age" -gt "$THRESHOLD_SECONDS" && "$live_delta" -lt "$MIN_DELTA_BYTES" ]]; then
      status="frozen"
      verdict="FROZEN"
      reason="age_gt_threshold_and_live_delta_lt_min"
      recovery_allowed=true
      recovery_suppressed_reason=""
      printf '%s\n' "$pane" >>"$frozen_file"
    fi
    jq -nc \
      --arg session "$session" --arg pane "$pane" --arg agent_type "$agent_type" \
      --arg state "$state" --arg state_since "$state_since" --argjson age "$age" \
      --argjson detected_patterns "$detected_patterns" \
      --argjson current_bytes "$second_bytes" --argjson first_bytes "$first_bytes" \
      --argjson second_bytes "$second_bytes" --argjson live_delta "$live_delta" \
      --argjson cache_delta "$cache_delta" --argjson prior_bytes "$prior_bytes" \
	      --arg cache "$cache" --arg status "$status" --arg verdict "$verdict" \
	      --arg reason "$reason" --arg sample_started "$sample_started" \
	      --arg sample_finished "$sample_finished" --arg source_health "$source_health" \
	      --arg sample_pair_dir "$sample_pair_dir" \
	      --argjson recent_respawn "$recent_respawn_count" \
	      --argjson queued_prompt "$queued_prompt" \
	      --argjson queued_timer "$queued_timer" \
	      --argjson queued_timer_drift "$queued_timer_drift" \
	      --arg first_timer_text "$first_timer_text" \
	      --arg second_timer_text "$second_timer_text" \
	      --argjson timer_text_identical "$timer_text_identical" \
	      --argjson recovery_allowed "$recovery_allowed" --arg recovery_suppressed_reason "$recovery_suppressed_reason" \
	      '{session:$session,pane:($pane | tonumber? // $pane),agent_type:$agent_type,state:$state,
        state_since:$state_since,detected_patterns:$detected_patterns,age_seconds:$age,current_bytes:$current_bytes,
        first_sample_bytes:$first_bytes,second_sample_bytes:$second_bytes,
        live_delta_bytes:$live_delta,delta_bytes:$live_delta,cache_delta_bytes:$cache_delta,
        prior_bytes:$prior_bytes,cache_path:$cache,status:$status,verdict:$verdict,reason:$reason,
	        sample_started_at:$sample_started,sample_finished_at:$sample_finished,
	        sample_pair_dir:(if $sample_pair_dir == "" then null else $sample_pair_dir end),
	        recent_recovery_count:$recent_respawn,source_health:$source_health,
		        recovery_allowed:$recovery_allowed,recovery_suppressed_reason:(if $recovery_suppressed_reason == "" then null else $recovery_suppressed_reason end),
		        queued_prompt_present:($queued_prompt == 1),working_timer_seconds:$queued_timer,
		        queued_timer_drift_seconds:$queued_timer_drift,
		        timer_text:(if $second_timer_text == "" then null else $second_timer_text end),
		        first_timer_text:(if $first_timer_text == "" then null else $first_timer_text end),
		        timer_text_identical:$timer_text_identical,
		        l60_signal_contribution:(if $verdict == "FROZEN" then "silent_darkness_detected"
		          elif $verdict == "QUEUED_NOT_SUBMITTED" then "silent_darkness_detected"
		          elif $verdict == "RESPAWN_SUPPRESSED" then "respawn_suppressed"
	          elif $verdict == "TEMPLATE_STUB_PROMPT" then "template_stub_prompt_detected"
	          elif $verdict == "UNKNOWN" then "unknown" else "live_or_watch" end)}' >>"$records_file"
    if [[ "$status" == "frozen" && "$AUTO_RECOVER" == "1" ]]; then
      recovery="$(recover_pane "$session" "$pane" "$agent_type" "$age" "$live_delta" "$second_file")"
      printf '%s\n' "$recovery" >>"$recovery_file"
    elif [[ "$status" == "queued_not_submitted" && "$AUTO_RECOVER" == "1" ]]; then
      recovery="$(recover_queued_submission "$session" "$pane" "$agent_type" "$age" "$queued_timer" "$second_file")"
      printf '%s\n' "$recovery" >>"$recovery_file"
    fi
  done

  frozen_count="$(jq -s '[.[] | select(.status == "frozen")] | length' "$records_file")"
  unknown_count="$(jq -s '[.[] | select(.status == "unknown")] | length' "$records_file")"
  template_stub_count="$(jq -s '[.[] | select(.status == "template_stub_prompt")] | length' "$records_file")"
  queued_not_submitted_count="$(jq -s '[.[] | select(.status == "queued_not_submitted")] | length' "$records_file")"
  respawn_suppressed_count="$(jq -s '[.[] | select(.status == "respawn_suppressed")] | length' "$records_file")"
  if [[ "$unknown_count" -gt 0 ]]; then
    source_status="degraded"
  fi
  suppressed_count="$(jq -s '[.[] | select(.suppressed == true)] | length' "$recovery_file")"
  fatal_count="$(jq -s '[.[] | select(.precheck.fatal == true)] | length' "$recovery_file")"
  if [[ "$AUTO_RECOVER" == "1" && "$frozen_count" -gt 0 ]]; then
    recovered_csv="$(paste -sd, "$frozen_file" 2>/dev/null || true)"
  fi
  respawned_count="$(jq -s '[.[] | select(.respawned == true)] | length' "$recovery_file")"
  relaunched_count="$(jq -s '[.[] | select(.relaunched == true)] | length' "$recovery_file")"
  queued_submitted_count="$(jq -s '[.[] | select(.submitted == true)] | length' "$recovery_file")"
  if [[ "$AUTO_RECOVER" == "1" && "$DRY_RUN" == "1" ]]; then
    respawned_count=0
    relaunched_count=0
    queued_submitted_count=0
  fi
  count7="$(count_strikes_since 7)"
  count30="$(count_strikes_since 30)"
  first_seen="$(first_strike_since 7)"
  research_bead="null"
  skill_bead="null"
  if [[ "$AUTO_RECOVER" == "1" ]]; then
    research_bead="$(create_research_bead_if_needed "$count7" "$first_seen")"
    skill_bead="$(create_skill_update_bead_if_needed "$count30")"
    dispatch_research_bead "$session" "$research_bead" "$recovered_csv"
  fi
  false_recovery_count="$(global_ledger_count false_recovery)"
  unknown_auto_recovery_count="$(global_ledger_count unknown_auto_recovery)"
  payload="$(
    jq -s \
      --arg schema_version "$SCHEMA_VERSION" \
      --arg session "$session" \
      --arg ts "$(now_iso)" \
      --arg mode "$([[ "$AUTO_RECOVER" == "1" ]] && printf 'auto-recover' || printf 'detect')" \
      --arg source_status "$source_status" \
      --argjson frozen "$frozen_count" \
	      --argjson unknown "$unknown_count" \
	      --argjson template_stub "$template_stub_count" \
	      --argjson queued_not_submitted "$queued_not_submitted_count" \
	      --argjson respawn_suppressed "$respawn_suppressed_count" \
	      --argjson respawned "$respawned_count" \
	      --argjson relaunched "$relaunched_count" \
	      --argjson queued_submitted "$queued_submitted_count" \
      --argjson suppressed "$suppressed_count" \
      --argjson fatal "$fatal_count" \
      --arg research "$research_bead" \
      --arg skill "$skill_bead" \
      --argjson count7 "$count7" \
      --argjson count30 "$count30" \
      --argjson dry_run "$DRY_RUN" \
      --argjson explain "$EXPLAIN" \
      --argjson threshold "$THRESHOLD_SECONDS" \
      --argjson false_recovery_count "$false_recovery_count" \
      --argjson unknown_auto_recovery_count "$unknown_auto_recovery_count" \
      --slurpfile recoveries "$recovery_file" \
      '{schema_version:$schema_version, success:true, session:$session, checked_at:$ts, mode:$mode,
        dry_run:($dry_run == 1), explain:($explain == 1),
        source_health:{status:$source_status, robot_activity:"healthy",
          robot_tail:(if $source_status == "healthy" then "healthy" else "degraded" end),
          degraded_recovery_allowed:false},
        panes:.,
	        frozen_panes_detected:$frozen,
	        unknown_panes_detected:$unknown,
	        template_stub_prompt_count:$template_stub,
	        queued_not_submitted_count:$queued_not_submitted,
	        respawn_suppressed_count:$respawn_suppressed,
	        frozen_panes_respawned:$respawned,
	        frozen_panes_relaunched:$relaunched,
	        queued_prompts_submitted:$queued_submitted,
        recovery_suppressed_count:$suppressed,
        fatal_count:$fatal,
        recoveries:$recoveries,
        frozen_research_bead_filed:($research | if . == "null" then null else . end),
        frozen_skill_update_bead_filed:($skill | if . == "null" then null else . end),
        frozen_strike_count_7d:$count7,
        frozen_strike_count_30d:$count30,
	        soft_violations:(
	          ([.[] | select(.verdict == "UNKNOWN") |
	          {class:"unknown_truth_not_recovered", severity:"SOFT",
	            producer:"frozen-pane-detector", measurement:.reason,
	            consumer:"/flywheel:tick prelude",
	            promotion_path:"L60 unknown signal -> fix bead",
	            session:.session, pane:.pane}])
	          + ([.[] | select(.verdict == "RESPAWN_SUPPRESSED") |
	          {class:"respawn_suppressed_recent_recovery", severity:"SOFT",
	            producer:"frozen-pane-detector", measurement:.reason,
	            consumer:"/flywheel:tick prelude",
	            promotion_path:"recovery ledger audit -> fix bead if repeated",
	            session:.session, pane:.pane}])
		          + ([.[] | select(.verdict == "TEMPLATE_STUB_PROMPT") |
		          {class:"template_stub_prompt_detected", severity:"SOFT",
		            producer:"frozen-pane-detector", measurement:.reason,
		            consumer:"/flywheel:tick prelude",
		            promotion_path:"template prompt count -> dispatch hygiene bead",
		            session:.session, pane:.pane}])
		          + ([.[] | select(.verdict == "QUEUED_NOT_SUBMITTED") |
		          {class:"codex_queued_not_submitted", severity:"SOFT",
		            producer:"frozen-pane-detector", measurement:.reason,
		            consumer:"/flywheel:tick prelude",
		            promotion_path:"queued_submit_recovery ledger -> INCIDENTS or fix bead",
		            session:.session, pane:.pane, recovery_kind:"queued_bare_enter"}])
	          + (if $source_status == "healthy" then [] else
	          [{class:"unhealthy_truth_source", severity:"SOFT",
	            producer:"frozen-pane-detector", measurement:("source_health=" + $source_status),
	            consumer:"/flywheel:tick prelude",
	            promotion_path:"L60 source-health decrement -> fix bead"}] end)),
	        durable_receipts:(
	          ([.[] | select(.verdict == "UNKNOWN") |
	          {schema_version:$schema_version, status:"UNKNOWN", verdict:.verdict,
	            degraded_reason:.reason, session:.session, pane:.pane,
	            recovery_allowed:false, written_to:null}])
	          + ([.[] | select(.verdict == "RESPAWN_SUPPRESSED") |
	          {schema_version:$schema_version, status:"RESPAWN_SUPPRESSED", verdict:.verdict,
	            degraded_reason:.reason, session:.session, pane:.pane,
	            recovery_allowed:false, written_to:null}])
	          + (if $source_status == "healthy" then [] else
	          [{schema_version:$schema_version, status:"UNHEALTHY", verdict:"UNKNOWN",
	            degraded_reason:("truth_source_" + $source_status),
            recovery_allowed:false, written_to:null}] end)),
        l60_signal_decrement_count:(if $source_status == "healthy" then 0 else 1 end),
	        silent_dark_minutes:(([.[] | select(.verdict == "FROZEN" or .verdict == "UNKNOWN" or .verdict == "QUEUED_NOT_SUBMITTED") | (.age_seconds // 0)] | max // 0) / 60),
        blackout_detection_latency_p95:(([.[] | select(.verdict == "FROZEN") | ((.age_seconds // 0) - $threshold) | select(. > 0)] | sort) as $lat
          | if ($lat | length) == 0 then 0 else $lat[((($lat | length) - 1) * 95 / 100 | floor)] end),
        false_recovery_count:$false_recovery_count,
        unknown_auto_recovery_count:$unknown_auto_recovery_count,
        l60_signals_present:{no_silent_darkness:true, live_truth_delta:($source_status == "healthy"),
          unknown_separated:true, recovery_budget:true, recovery_lease:true}}' "$records_file"
  )"
  emit_metrics_line "$payload"
  printf '%s\n' "$payload"
}

detect_all() {
  local tmpdir payloads_file sessions_file session payload rc=0
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/frozen-pane-detector-all.XXXXXX")"
  trap 'rm -rf "$tmpdir"' RETURN
  payloads_file="$tmpdir/payloads.jsonl"
  sessions_file="$tmpdir/sessions.txt"
  list_known_sessions >"$sessions_file"
  if [[ ! -s "$sessions_file" ]]; then
    printf 'flywheel\n' >"$sessions_file"
  fi
  while IFS= read -r session; do
    [[ -n "$session" ]] || continue
    payload="$(detect "$session")" || rc=1
    printf '%s\n' "$payload" >>"$payloads_file"
  done <"$sessions_file"
  jq -s \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg ts "$(now_iso)" \
    --arg mode "$([[ "$AUTO_RECOVER" == "1" ]] && printf 'auto-recover' || printf 'detect')" \
    --argjson dry_run "$DRY_RUN" \
    '{schema_version:$schema_version, success:([.[].success] | all), session:"all",
      checked_at:$ts, mode:$mode, dry_run:($dry_run == 1),
      source_health:{status:(if ([.[].source_health.status] | all(. == "healthy")) then "healthy" else "degraded" end),
        robot_activity:"aggregate", robot_tail:"aggregate", degraded_recovery_allowed:false},
      panes:([.[].panes[]?]),
	      frozen_panes_detected:([.[].frozen_panes_detected] | add // 0),
	      unknown_panes_detected:([.[].unknown_panes_detected] | add // 0),
	      template_stub_prompt_count:([.[].template_stub_prompt_count] | add // 0),
	      queued_not_submitted_count:([.[].queued_not_submitted_count] | add // 0),
	      respawn_suppressed_count:([.[].respawn_suppressed_count] | add // 0),
	      frozen_panes_respawned:([.[].frozen_panes_respawned] | add // 0),
      frozen_panes_relaunched:([.[].frozen_panes_relaunched] | add // 0),
      queued_prompts_submitted:([.[].queued_prompts_submitted] | add // 0),
      recovery_suppressed_count:([.[].recovery_suppressed_count] | add // 0),
      fatal_count:([.[].fatal_count] | add // 0),
      recoveries:([.[].recoveries[]?]),
      frozen_research_bead_filed:([.[].frozen_research_bead_filed | select(. != null)] | first // null),
      frozen_skill_update_bead_filed:([.[].frozen_skill_update_bead_filed | select(. != null)] | first // null),
      frozen_strike_count_7d:([.[].frozen_strike_count_7d] | max // 0),
      frozen_strike_count_30d:([.[].frozen_strike_count_30d] | max // 0),
      soft_violations:([.[].soft_violations[]?]),
      durable_receipts:([.[].durable_receipts[]?]),
      l60_signal_decrement_count:([.[].l60_signal_decrement_count] | add // 0),
      silent_dark_minutes:([.[].silent_dark_minutes] | max // 0),
      blackout_detection_latency_p95:([.[].blackout_detection_latency_p95] | max // 0),
      false_recovery_count:([.[].false_recovery_count] | max // 0),
      unknown_auto_recovery_count:([.[].unknown_auto_recovery_count] | max // 0),
      l60_signals_present:{no_silent_darkness:true, live_truth_delta:([.[].l60_signals_present.live_truth_delta] | all),
        unknown_separated:true, recovery_budget:true, recovery_lease:true}}' "$payloads_file"
  return "$rc"
}

emit_human_from_json() {
  local payload="$1"
  printf '%s\n' "$payload" | jq -r '
    if .mode == "doctor" or .mode == "info" then
      .
    else
      "frozen-pane-detector session=\(.session) frozen=\(.frozen_panes_detected) unknown=\(.unknown_panes_detected // 0) respawned=\(.frozen_panes_respawned // 0) relaunched=\(.frozen_panes_relaunched // 0) silent_dark_minutes=\(.silent_dark_minutes // 0) strikes7=\(.frozen_strike_count_7d // 0)"
    end
  '
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --session) SESSION="${2:?--session needs value}"; shift 2 ;;
    --session=*) SESSION="${1#--session=}"; shift ;;
    --json) JSON_OUT=1; shift ;;
    --auto-recover) AUTO_RECOVER=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --explain) EXPLAIN=1; shift ;;
    --self-test) SELF_TEST=1; MODE="self-test"; shift ;;
    --cross-session-allow) CROSS_SESSION_ALLOW=1; shift ;;
    --doctor) MODE="doctor"; shift ;;
    --health) MODE="health"; shift ;;
    --info) MODE="info"; shift ;;
    --schema) MODE="schema"; shift ;;
    --examples) MODE="examples"; shift ;;
    --threshold-seconds) THRESHOLD_SECONDS="${2:?--threshold-seconds needs value}"; shift 2 ;;
    --threshold-seconds=*) THRESHOLD_SECONDS="${1#--threshold-seconds=}"; shift ;;
    --queued-threshold-seconds) QUEUED_THRESHOLD_SECONDS="${2:?--queued-threshold-seconds needs value}"; shift 2 ;;
    --queued-threshold-seconds=*) QUEUED_THRESHOLD_SECONDS="${1#--queued-threshold-seconds=}"; shift ;;
    --queued-timer-drift-seconds) QUEUED_TIMER_DRIFT_SECONDS="${2:?--queued-timer-drift-seconds needs value}"; shift 2 ;;
    --queued-timer-drift-seconds=*) QUEUED_TIMER_DRIFT_SECONDS="${1#--queued-timer-drift-seconds=}"; shift ;;
    --min-delta-bytes) MIN_DELTA_BYTES="${2:?--min-delta-bytes needs value}"; shift 2 ;;
    --min-delta-bytes=*) MIN_DELTA_BYTES="${1#--min-delta-bytes=}"; shift ;;
    --sample-interval-seconds) SAMPLE_INTERVAL_SECONDS="${2:?--sample-interval-seconds needs value}"; shift 2 ;;
    --sample-interval-seconds=*) SAMPLE_INTERVAL_SECONDS="${1#--sample-interval-seconds=}"; shift ;;
    --ntm-timeout-seconds) NTM_TIMEOUT_SECONDS="${2:?--ntm-timeout-seconds needs value}"; shift 2 ;;
    --ntm-timeout-seconds=*) NTM_TIMEOUT_SECONDS="${1#--ntm-timeout-seconds=}"; shift ;;
    --lines) LINES="${2:?--lines needs value}"; shift 2 ;;
    --lines=*) LINES="${1#--lines=}"; shift ;;
    --cache-dir) CACHE_DIR="${2:?--cache-dir needs value}"; shift 2 ;;
    --cache-dir=*) CACHE_DIR="${1#--cache-dir=}"; shift ;;
    --strike-file) STRIKE_FILE="${2:?--strike-file needs value}"; shift 2 ;;
    --strike-file=*) STRIKE_FILE="${1#--strike-file=}"; shift ;;
    --lease-dir) LEASE_DIR="${2:?--lease-dir needs value}"; shift 2 ;;
    --lease-dir=*) LEASE_DIR="${1#--lease-dir=}"; shift ;;
    --lease-ttl-seconds) LEASE_TTL_SECONDS="${2:?--lease-ttl-seconds needs value}"; shift 2 ;;
    --lease-ttl-seconds=*) LEASE_TTL_SECONDS="${1#--lease-ttl-seconds=}"; shift ;;
    --cooldown-seconds) COOLDOWN_SECONDS="${2:?--cooldown-seconds needs value}"; shift 2 ;;
    --cooldown-seconds=*) COOLDOWN_SECONDS="${1#--cooldown-seconds=}"; shift ;;
    --respawn-suppression-seconds) RESPAWN_SUPPRESSION_SECONDS="${2:?--respawn-suppression-seconds needs value}"; shift 2 ;;
    --respawn-suppression-seconds=*) RESPAWN_SUPPRESSION_SECONDS="${1#--respawn-suppression-seconds=}"; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:?--idempotency-key needs value}"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}"; shift ;;
    --metrics-file) METRICS_FILE="${2:?--metrics-file needs value}"; shift 2 ;;
    --metrics-file=*) METRICS_FILE="${1#--metrics-file=}"; shift ;;
    --recovery-ledger) RECOVERY_LEDGER="${2:?--recovery-ledger needs value}"; shift 2 ;;
    --recovery-ledger=*) RECOVERY_LEDGER="${1#--recovery-ledger=}"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done

case "$MODE" in
  doctor|health)
    payload="$(doctor_json)"
    ;;
  info)
    payload="$(info_json)"
    ;;
  schema)
    schema_json
    exit 0
    ;;
  examples)
    examples
    exit 0
    ;;
  self-test)
    DRY_RUN=1
    payload="$(self_test_json)"
    ;;
  detect)
    [[ -n "$SESSION" ]] || die "--session required"
    if [[ "$SESSION" == "all" ]]; then
      payload="$(detect_all)" || EXIT_CODE=$?
    else
      payload="$(detect "$SESSION")" || EXIT_CODE=$?
    fi
    ;;
  *)
    die "unknown mode: $MODE"
    ;;
esac

if [[ "$JSON_OUT" == "1" || "$MODE" == "doctor" || "$MODE" == "health" || "$MODE" == "info" ]]; then
  printf '%s\n' "$payload"
else
  emit_human_from_json "$payload"
fi
exit "$EXIT_CODE"
