#!/usr/bin/env bash
# dispatch-trigger-gated-precheck.sh
# Pre-check for trigger-gated beads. Consults the named watchtower BEFORE
# build-dispatch-packet.sh emits a packet, so a worker round-trip is not
# wasted probing the trigger only to return BLOCKED.
#
# A bead is trigger-gated when its body declares an external trigger via:
#   external_trigger_watchtower=<name>      (canonical, structured)
#
# Prose-only signals ("Operational trigger is ...", "Depends on ... release
# announcement") are detected as a WARNING that nags the bead author to add
# the structured field. They do not refuse dispatch.
#
# The pre-check runs the watchtower once and reads
#   .watchlists.<name>.status
# A status of `release_available`, `released`, `target_released`, or
# `newer_than_target` means the trigger has fired. Anything else
# (`public_no_release`, `not_found`, `hold_target_not_released`, `unknown`,
# missing) means the bead must wait.
#
# Doctrine: .flywheel/doctrine/trigger-gated-bead-precheck.md
# Sister: flywheel-g6xaw, flywheel-ubrb5 (watchtower author).
#
# CLI matrix per canonical-cli-scoping:
#   doctor / health / repair triad: doctor (operator view), health (single status), repair (--dry-run|--apply)
#   validate / audit / why subsidiary: validate (one bead), audit (jsonl), why (one bead, verbose)
#   schema / examples / info / completion: standard introspection

set -euo pipefail

VERSION="dispatch-trigger-gated-precheck.v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
WATCHTOWER_BIN="${WATCHTOWER_BIN:-$SCRIPT_DIR/jeff-binary-version-watchtower.sh}"
BR_BIN="${BR_BIN:-br}"

# Statuses that count as "trigger has fired" / release_available.
RELEASE_AVAILABLE_STATUSES=(release_available released target_released newer_than_target)

usage() {
  cat <<EOF
$VERSION - dispatch-time pre-check for trigger-gated beads

USAGE
  dispatch-trigger-gated-precheck.sh <command> [flags]

COMMANDS
  validate --bead-id <id>                  Probe one bead. Exit 0 ok, 6 trigger not yet fired.
  validate --bead-body-file <path>         Probe a bead-body file (no br lookup).
  why     --bead-id <id> [--json]          Verbose explain output.
  doctor  [--bead-id <id>] [--json]        Operator view; health summary plus row.
  health  [--bead-id <id>] [--json]        Single status: ok | trigger_not_yet_fired | not_trigger_gated.
  repair  --bead-id <id> --dry-run|--apply Suggest re-disposition (no auto-mutation).
  schema                                   JSON output schema.
  examples                                 Minimal example commands.
  info                                     Surface name and supported watchlists.
  completion                               Shell completion text.
  help                                     This message.

FLAGS
  --watchtower-fixture <path>          Use fixture for FRANKENTERM_RELEASE_FIXTURE.
  --watchtower-bin <path>              Override watchtower binary.
  --watchtower-json-fixture <path>     Inline pre-computed watchtower --json output.
  --br-bin <path>                      Override br binary.
  --json                               Emit JSON output (default for validate).
  --explain                            Equivalent to validate --json with verbose narrative.

EXIT CODES
  0  ok (not trigger-gated, OR trigger has fired)
  1  bad args / usage
  2  bead lookup failed
  3  watchtower probe failed
  5  watchtower output malformed
  6  trigger-gated bead, watchtower not yet at release_available
EOF
}

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

# --- introspection ---
info() { jq -nc --arg v "$VERSION" '{command:"dispatch-trigger-gated-precheck",version:$v,canonical_field:"external_trigger_watchtower",supported_watchlists:["frankenterm_release","codex_release"],release_available_statuses:["release_available","released","target_released","newer_than_target"]}'; }
examples() {
  cat <<EOF
EXAMPLES:
  dispatch-trigger-gated-precheck.sh validate --bead-id flywheel-g6xaw
  dispatch-trigger-gated-precheck.sh validate --bead-body-file /tmp/bead.txt --watchtower-json-fixture /tmp/watch.json
  dispatch-trigger-gated-precheck.sh why --bead-id flywheel-g6xaw --json
  dispatch-trigger-gated-precheck.sh doctor --json
EOF
}
schema() {
  cat <<'EOF'
{"title":"dispatch-trigger-gated-precheck output (--json)","type":"object","required":["schema_version","status","trigger_gated","reason_code"],"properties":{"schema_version":{"const":"dispatch-trigger-gated-precheck.v1"},"status":{"enum":["ok","trigger_not_yet_fired","not_trigger_gated","watchtower_unreachable","malformed"]},"trigger_gated":{"type":"boolean"},"watchtower":{"type":"string"},"watchtower_status":{"type":["string","null"]},"reason_code":{"type":"string"},"warnings":{"type":"array","items":{"type":"string"}},"prose_signals":{"type":"array","items":{"type":"string"}}}}
EOF
}
completion() { printf '%s\n' 'complete -W "validate why doctor health repair schema examples info completion help --bead-id --bead-body-file --watchtower-fixture --watchtower-bin --watchtower-json-fixture --br-bin --json --explain --dry-run --apply" dispatch-trigger-gated-precheck.sh'; }

# --- argument parsing ---
COMMAND=""
BEAD_ID=""
BEAD_BODY_FILE=""
WATCHTOWER_FIXTURE=""
WATCHTOWER_JSON_FIXTURE=""
JSON_OUT=0
EXPLAIN=0
REPAIR_MODE=""

if [[ $# -eq 0 ]]; then usage >&2; exit 1; fi

case "${1:-}" in
  -h|--help|help) usage; exit 0 ;;
  schema) schema; exit 0 ;;
  examples|--examples) examples; exit 0 ;;
  info|--info) info; exit 0 ;;
  completion) completion; exit 0 ;;
esac

COMMAND="$1"
shift
case "$COMMAND" in
  validate|why|doctor|health|repair) ;;
  *) usage >&2; die "unknown command: $COMMAND" 1 ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bead-id) BEAD_ID="$2"; shift 2 ;;
    --bead-body-file) BEAD_BODY_FILE="$2"; shift 2 ;;
    --watchtower-fixture) WATCHTOWER_FIXTURE="$2"; shift 2 ;;
    --watchtower-bin) WATCHTOWER_BIN="$2"; shift 2 ;;
    --watchtower-json-fixture) WATCHTOWER_JSON_FIXTURE="$2"; shift 2 ;;
    --br-bin) BR_BIN="$2"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --explain) EXPLAIN=1; JSON_OUT=1; shift ;;
    --dry-run) REPAIR_MODE="dry-run"; shift ;;
    --apply) REPAIR_MODE="apply"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "unknown flag: $1" 1 ;;
  esac
done

# --- helpers ---
load_bead_body() {
  if [[ -n "$BEAD_BODY_FILE" ]]; then
    [[ -r "$BEAD_BODY_FILE" ]] || die "bead-body-file unreadable: $BEAD_BODY_FILE" 2
    cat "$BEAD_BODY_FILE"
    return 0
  fi
  [[ -n "$BEAD_ID" ]] || die "either --bead-id or --bead-body-file required" 1
  local raw
  raw="$("$BR_BIN" show "$BEAD_ID" --json 2>/dev/null || true)"
  [[ -n "$raw" ]] || die "br show $BEAD_ID failed" 2
  echo "$raw" | jq -r 'if type=="array" then (.[0].description // .[0].body // "") else (.description // .body // "") end' 2>/dev/null
}

# Parse bead body for the structured field. Returns watchtower name on stdout (empty if absent).
parse_external_trigger() {
  local body="$1"
  printf '%s\n' "$body" \
    | grep -Eo 'external_trigger_watchtower=[A-Za-z0-9_]+' \
    | head -1 \
    | sed -E 's/^external_trigger_watchtower=//' \
    || true
}

# Detect prose-only signals. Emits one signal-name per line.
parse_prose_signals() {
  local body="$1"
  {
    grep -iEo 'operational trigger[^.]*' <<<"$body" 2>/dev/null || true
    grep -iEo 'depends on[^.]*release announcement[^.]*' <<<"$body" 2>/dev/null || true
    grep -iEo 'await(s|ing)?[^.]*release[^.]*' <<<"$body" 2>/dev/null || true
    grep -iEo 'gated on[^.]*release[^.]*' <<<"$body" 2>/dev/null || true
  } | sed -E 's/[[:space:]]+/ /g; s/^ //; s/ $//' | grep -v '^$' | head -3 || true
}

# Run watchtower or use fixture, return JSON on stdout.
load_watchtower_json() {
  if [[ -n "$WATCHTOWER_JSON_FIXTURE" ]]; then
    [[ -r "$WATCHTOWER_JSON_FIXTURE" ]] || die "watchtower-json-fixture unreadable: $WATCHTOWER_JSON_FIXTURE" 3
    cat "$WATCHTOWER_JSON_FIXTURE"
    return 0
  fi
  [[ -x "$WATCHTOWER_BIN" ]] || die "watchtower not executable: $WATCHTOWER_BIN" 3
  local args=(--json)
  [[ -n "$WATCHTOWER_FIXTURE" ]] && args+=(--frankenterm-release-fixture "$WATCHTOWER_FIXTURE")
  "$WATCHTOWER_BIN" "${args[@]}" 2>/dev/null || die "watchtower probe failed" 3
}

# Lookup .watchlists.<name>.status from watchtower JSON.
lookup_status() {
  local watchtower_json="$1" name="$2"
  echo "$watchtower_json" | jq -r --arg n "$name" '.watchlists[$n].status // "missing"' 2>/dev/null
}

is_release_available() {
  local status="$1" s
  for s in "${RELEASE_AVAILABLE_STATUSES[@]}"; do
    [[ "$status" == "$s" ]] && return 0
  done
  return 1
}

# --- evaluation core ---
evaluate() {
  local body watchtower_name prose_signals_text watchtower_json status reason warnings
  body="$(load_bead_body)"
  watchtower_name="$(parse_external_trigger "$body")"
  prose_signals_text="$(parse_prose_signals "$body")"
  warnings=()

  if [[ -z "$watchtower_name" ]]; then
    if [[ -n "$prose_signals_text" ]]; then
      warnings+=("prose-trigger-detected-but-no-external_trigger_watchtower-field")
    fi
    local warnings_json="[]"
    if [[ ${#warnings[@]} -gt 0 ]]; then
      warnings_json="$(printf '%s\n' "${warnings[@]}" | jq -R . | jq -s .)"
    fi
    jq -nc \
      --arg sv "$VERSION" \
      --argjson tg false \
      --arg name "" \
      --arg status "" \
      --arg reason "no_external_trigger_watchtower_field" \
      --arg signals "$prose_signals_text" \
      --argjson warnings "$warnings_json" \
      '{schema_version:$sv,status:"not_trigger_gated",trigger_gated:$tg,watchtower:$name,watchtower_status:null,reason_code:$reason,warnings:$warnings,prose_signals:($signals | split("\n") | map(select(length>0)))}'
    return 0
  fi

  watchtower_json="$(load_watchtower_json)"
  if ! echo "$watchtower_json" | jq -e . >/dev/null 2>&1; then
    jq -nc --arg sv "$VERSION" --arg name "$watchtower_name" \
      '{schema_version:$sv,status:"malformed",trigger_gated:true,watchtower:$name,watchtower_status:null,reason_code:"watchtower_json_malformed",warnings:["watchtower output is not valid JSON"]}'
    return 5
  fi

  status="$(lookup_status "$watchtower_json" "$watchtower_name")"
  if [[ "$status" == "missing" || -z "$status" || "$status" == "null" ]]; then
    jq -nc --arg sv "$VERSION" --arg name "$watchtower_name" \
      '{schema_version:$sv,status:"watchtower_unreachable",trigger_gated:true,watchtower:$name,watchtower_status:null,reason_code:"watchlist_not_present",warnings:[("watchlist " + $name + " not found in watchtower output")]}'
    return 3
  fi

  if is_release_available "$status"; then
    reason="trigger_has_fired"
    jq -nc --arg sv "$VERSION" --arg name "$watchtower_name" --arg status "$status" --arg reason "$reason" \
      '{schema_version:$sv,status:"ok",trigger_gated:true,watchtower:$name,watchtower_status:$status,reason_code:$reason,warnings:[]}'
    return 0
  fi

  reason="trigger_not_yet_fired"
  jq -nc --arg sv "$VERSION" --arg name "$watchtower_name" --arg status "$status" --arg reason "$reason" \
    '{schema_version:$sv,status:"trigger_not_yet_fired",trigger_gated:true,watchtower:$name,watchtower_status:$status,reason_code:$reason,warnings:[("watchtower says " + $name + ".status=" + $status + " — wait for release_available before dispatch")]}'
  return 6
}

# --- command dispatch ---
case "$COMMAND" in
  validate|why)
    set +e
    out="$(evaluate)"
    rc=$?
    set -e
    if [[ "$JSON_OUT" -eq 1 || "$COMMAND" == "why" ]]; then
      printf '%s\n' "$out"
    else
      jq -r '"status=\(.status) trigger_gated=\(.trigger_gated) watchtower=\(.watchtower) watchtower_status=\(.watchtower_status) reason=\(.reason_code)"' <<<"$out"
    fi
    exit "$rc"
    ;;
  doctor|health)
    if [[ -n "$BEAD_ID" || -n "$BEAD_BODY_FILE" ]]; then
      set +e
      out="$(evaluate)"
      rc=$?
      set -e
      if [[ "$COMMAND" == "health" ]]; then
        if [[ "$JSON_OUT" -eq 1 ]]; then
          printf '%s\n' "$out"
        else
          jq -r '"health=\(.status)"' <<<"$out"
        fi
      else
        if [[ "$JSON_OUT" -eq 1 ]]; then
          printf '%s\n' "$out"
        else
          jq -r '"doctor: status=\(.status) reason=\(.reason_code) wt=\(.watchtower) wt_status=\(.watchtower_status)"' <<<"$out"
        fi
      fi
      exit "$rc"
    fi
    if [[ "$JSON_OUT" -eq 1 ]]; then
      jq -nc --arg v "$VERSION" '{schema_version:$v,status:"ok",ready:true,note:"no bead probed; surface healthy"}'
    else
      printf 'doctor: surface healthy (no bead probed)\n'
    fi
    exit 0
    ;;
  repair)
    [[ -n "$BEAD_ID" ]] || die "repair requires --bead-id" 1
    [[ "$REPAIR_MODE" == "dry-run" || "$REPAIR_MODE" == "apply" ]] || die "repair requires --dry-run or --apply" 1
    set +e
    out="$(evaluate)"
    rc=$?
    set -e
    case "$rc" in
      0) suggestion="no_change_needed" ;;
      6) suggestion="hold_dispatch_until_watchtower_flip" ;;
      3) suggestion="probe_watchtower_health" ;;
      5) suggestion="fix_watchtower_emit_or_fixture" ;;
      *) suggestion="see_validate_output" ;;
    esac
    if [[ "$JSON_OUT" -eq 1 ]]; then
      jq -nc --arg v "$VERSION" --arg s "$suggestion" --arg mode "$REPAIR_MODE" --argjson o "$out" '{schema_version:$v,mode:$mode,suggestion:$s,probe:$o,mutation_invoked:false}'
    else
      printf 'repair: suggestion=%s mode=%s (no mutation)\n' "$suggestion" "$REPAIR_MODE"
    fi
    exit 0
    ;;
esac

usage >&2
exit 1
