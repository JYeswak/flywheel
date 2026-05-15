#!/usr/bin/env bash
# .flywheel/scripts/jeff-bead-285-divergence-capture.sh
#
# Capture harness for Dicklesworthstone/beads_rust issue #285 evidence
# request. Jeffrey asked for two artifacts on a fresh br_close
# divergence:
#   1. RUST_LOG=br::storage::sqlite=trace,br::cli::commands::close=trace
#      br --lock-timeout 10000 close <id>      → stderr trace
#   2. br doctor --json IMMEDIATELY after divergence is observed → packet
#
# Both must be captured in the same run, on the SAME divergence event.
# This script wraps both calls + bundles the artifacts under a
# timestamped capture directory so the evidence is upload-ready.
#
# Usage:
#   jeff-bead-285-divergence-capture.sh <bead-id> [--apply|--dry-run]
#   jeff-bead-285-divergence-capture.sh doctor|--doctor
#   jeff-bead-285-divergence-capture.sh --info|--schema|--examples|--help
#
# Default mode is --dry-run (prints what would run; does NOT execute the
# br close trace because that mutates state). Use --apply on a SAFE
# bead-id (e.g., a sandbox or test-fixture bead, never a production
# closure).
#
# Tracking bead: flywheel-f23ix
# Upstream:      https://github.com/Dicklesworthstone/beads_rust/issues/285
set -euo pipefail

VERSION="jeff-bead-285-divergence-capture.v1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
CAPTURE_ROOT_DEFAULT="$REPO_ROOT/.flywheel/audit/flywheel-f23ix/captures"
BR_BIN="${BR_BIN:-br}"
DEFAULT_LOCK_TIMEOUT_MS="${DEFAULT_LOCK_TIMEOUT_MS:-10000}"

BEAD_ID=""
MODE="dry-run"
IDEMPOTENCY_KEY=""
JSON_OUT=0
AUDIT_LOG="${JEFF_285_AUDIT_LOG:-$HOME/.local/state/flywheel/jeff-bead-285-divergence-capture-runs.jsonl}"

usage() {
  cat <<'EOF'
usage:
  jeff-bead-285-divergence-capture.sh <bead-id> [--apply --idempotency-key KEY | --dry-run] [--json]
  jeff-bead-285-divergence-capture.sh doctor|--doctor [--json]
  jeff-bead-285-divergence-capture.sh --info|--schema|--examples|--help [--json]

Captures the two artifacts Jeffrey requested on
beads_rust#285 (br close trace + br doctor --json) on a live
br_close divergence. Mutating; default mode is --dry-run.

Exit codes:
  0  capture complete (apply) or dry-run preview emitted
  1  capture failed (br close errored, doctor json invalid, or trace
     file missing)
  2  usage error (missing bead-id, unknown flag)
  3  prerequisite missing (br binary, capture root unwritable)
EOF
}

info_json() {
  jq -nc \
    --arg name "jeff-bead-285-divergence-capture.sh" \
    --arg version "$VERSION" \
    --arg upstream "https://github.com/Dicklesworthstone/beads_rust/issues/285" \
    --arg tracking_bead "flywheel-f23ix" \
    --arg br_bin "$BR_BIN" \
    --arg capture_root_default "$CAPTURE_ROOT_DEFAULT" \
    --argjson default_lock_timeout_ms "$DEFAULT_LOCK_TIMEOUT_MS" \
    --arg audit_log "$AUDIT_LOG" \
    --argjson exit_codes '{"0":"capture complete, replay-no-op, or dry-run preview emitted","1":"capture failed","2":"usage error","3":"prerequisite missing or --apply without --idempotency-key (canonical refusal)"}' \
    --argjson trace_targets '["br::storage::sqlite=trace","br::cli::commands::close=trace"]' \
    '{
      schema_version: "tool-info/v1",
      name: $name,
      version: $version,
      upstream_issue: $upstream,
      tracking_bead: $tracking_bead,
      br_bin: $br_bin,
      capture_root_default: $capture_root_default,
      default_lock_timeout_ms: $default_lock_timeout_ms,
      modes: ["dry-run", "apply"],
      default_mode: "dry-run",
      flags: ["--apply", "--dry-run", "--idempotency-key", "--json", "doctor", "--doctor", "--info", "--schema", "--examples", "--help"],
      env_vars: ["BR_BIN", "DEFAULT_LOCK_TIMEOUT_MS", "CAPTURE_ROOT", "RUST_LOG", "JEFF_285_AUDIT_LOG"],
      mutates: true,
      mutation_requires: ["--apply", "--idempotency-key"],
      apply_requires: "--idempotency-key",
      doctor_schema: "jeff-bead-285-divergence-capture.doctor.v1",
      audit_log: $audit_log,
      rust_log_targets: $trace_targets,
      exit_codes: $exit_codes,
      receipt_schema: "jeff-bead-285-capture-receipt/v1",
      capture_artifacts: ["close-trace.log", "doctor-pre.json", "doctor-post.json", "manifest.json"]
    }'
}

schema_json() {
  jq -nc '{
    "$schema": "http://json-schema.org/draft-07/schema#",
    schema_version: "jeff-bead-285-capture-receipt/v1",
    type: "object",
    required: ["ts", "mode", "bead_id", "capture_dir", "artifacts", "br_version", "lock_timeout_ms"],
    properties: {
      ts: {type:"string", description:"ISO8601 capture start time"},
      mode: {type:"string", enum:["dry-run","apply"]},
      bead_id: {type:"string"},
      capture_dir: {type:"string"},
      artifacts: {
        type: "object",
        properties: {
          close_trace: {type:"string", description:"path to close-trace.log"},
          doctor_pre: {type:"string"},
          doctor_post: {type:"string"},
          manifest: {type:"string"}
        }
      },
      br_version: {type:"string"},
      lock_timeout_ms: {type:"integer"},
      close_exit_code: {type:["integer","null"]},
      doctor_pre_status: {type:["string","null"]},
      doctor_post_status: {type:["string","null"]},
      divergence_observed: {type:"boolean"}
    }
  }'
}

examples() {
  cat <<'EOF'
Examples:
  # Inspect the tool (no execution)
  .flywheel/scripts/jeff-bead-285-divergence-capture.sh --info | jq .

  # Read-only doctor (no bead close, no capture directory creation)
  .flywheel/scripts/jeff-bead-285-divergence-capture.sh doctor | jq .

  # Dry-run preview against a sandbox bead-id
  .flywheel/scripts/jeff-bead-285-divergence-capture.sh sandbox-fixture-001

  # Live capture (mutating; only use on safe bead-ids)
  .flywheel/scripts/jeff-bead-285-divergence-capture.sh sandbox-fixture-001 --apply --idempotency-key=capture-001

  # Override the capture root
  CAPTURE_ROOT=/tmp/jeff-285 .flywheel/scripts/jeff-bead-285-divergence-capture.sh \
    sandbox-fixture-001 --apply

  # Override lock timeout (matches Jeffrey's --lock-timeout 10000 ask)
  DEFAULT_LOCK_TIMEOUT_MS=10000 .flywheel/scripts/jeff-bead-285-divergence-capture.sh \
    sandbox-fixture-001 --apply
EOF
}

doctor_json() {
  local br_status capture_parent_status audit_parent_status timeout_status overall timeout_json
  local capture_root capture_parent audit_parent
  overall="pass"
  if command -v "$BR_BIN" >/dev/null 2>&1; then
    br_status="pass"
  else
    br_status="fail"
    overall="fail"
  fi
  capture_root="${CAPTURE_ROOT:-$CAPTURE_ROOT_DEFAULT}"
  capture_parent="$(dirname "$capture_root")"
  if [[ -d "$capture_parent" && -w "$capture_parent" ]]; then
    capture_parent_status="pass"
  else
    capture_parent_status="warn"
    [[ "$overall" == "fail" ]] || overall="warn"
  fi
  audit_parent="$(dirname "$AUDIT_LOG")"
  if [[ -d "$audit_parent" && -w "$audit_parent" ]]; then
    audit_parent_status="pass"
  else
    audit_parent_status="warn"
    [[ "$overall" == "fail" ]] || overall="warn"
  fi
  if [[ "$DEFAULT_LOCK_TIMEOUT_MS" =~ ^[0-9]+$ && "$DEFAULT_LOCK_TIMEOUT_MS" -gt 0 ]]; then
    timeout_status="pass"
    timeout_json="$DEFAULT_LOCK_TIMEOUT_MS"
  else
    timeout_status="fail"
    timeout_json="0"
    overall="fail"
  fi
  jq -nc \
    --arg status "$overall" \
    --arg version "$VERSION" \
    --arg br_bin "$BR_BIN" \
    --arg capture_root "$capture_root" \
    --arg capture_parent "$capture_parent" \
    --arg audit_log "$AUDIT_LOG" \
    --arg audit_parent "$audit_parent" \
    --arg br_status "$br_status" \
    --arg capture_parent_status "$capture_parent_status" \
    --arg audit_parent_status "$audit_parent_status" \
    --arg timeout_status "$timeout_status" \
    --argjson default_lock_timeout_ms "$timeout_json" \
    '{
      schema_version: "jeff-bead-285-divergence-capture.doctor.v1",
      command: "doctor",
      status: $status,
      mode: "read_only",
      mutates: false,
      version: $version,
      br_bin: $br_bin,
      capture_root: $capture_root,
      audit_log: $audit_log,
      default_lock_timeout_ms: $default_lock_timeout_ms,
      checks: [
        {name:"br_available", status:$br_status},
        {name:"capture_root_parent_writable", status:$capture_parent_status, path:$capture_parent},
        {name:"audit_log_parent_writable", status:$audit_parent_status, path:$audit_parent},
        {name:"lock_timeout_positive_integer", status:$timeout_status}
      ]
    }'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info)     info_json; exit 0 ;;
    --schema)   schema_json; exit 0 ;;
    --examples) examples; exit 0 ;;
    -h|--help)  usage; exit 0 ;;
    doctor|--doctor) doctor_json; exit 0 ;;
    --apply)    MODE="apply"; shift ;;
    --dry-run)  MODE="dry-run"; shift ;;
    --idempotency-key) [[ -n "${2:-}" ]] || { printf 'error: --idempotency-key requires VALUE\n' >&2; exit 2; }; IDEMPOTENCY_KEY="$2"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#--idempotency-key=}"; [[ -n "$IDEMPOTENCY_KEY" ]] || { printf 'error: --idempotency-key requires VALUE\n' >&2; exit 2; }; shift ;;
    --json)     JSON_OUT=1; shift ;;
    --*)        printf 'unknown flag: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *)
      if [[ -z "$BEAD_ID" ]]; then
        BEAD_ID="$1"
      else
        printf 'unexpected positional: %s\n' "$1" >&2
        usage >&2
        exit 2
      fi
      shift
      ;;
  esac
done

if [[ -z "$BEAD_ID" ]]; then
  printf 'error: bead-id required (got none)\n' >&2
  usage >&2
  exit 2
fi

if ! command -v "$BR_BIN" >/dev/null 2>&1; then
  printf 'error: br binary not found at %s\n' "$BR_BIN" >&2
  exit 3
fi

CAPTURE_ROOT="${CAPTURE_ROOT:-$CAPTURE_ROOT_DEFAULT}"
TS="$(date -u +%Y-%m-%dT%H%M%SZ)"
CAPTURE_DIR="$CAPTURE_ROOT/$TS-$BEAD_ID"
CLOSE_TRACE="$CAPTURE_DIR/close-trace.log"
DOCTOR_PRE="$CAPTURE_DIR/doctor-pre.json"
DOCTOR_POST="$CAPTURE_DIR/doctor-post.json"
MANIFEST="$CAPTURE_DIR/manifest.json"

emit_receipt() {
  local mode="$1" close_rc="${2-null}" pre_status="${3-null}" post_status="${4-null}" divergence_observed="${5-false}"
  jq -nc \
    --arg ts "$TS" \
    --arg mode "$mode" \
    --arg bead_id "$BEAD_ID" \
    --arg capture_dir "$CAPTURE_DIR" \
    --arg close_trace "$CLOSE_TRACE" \
    --arg doctor_pre "$DOCTOR_PRE" \
    --arg doctor_post "$DOCTOR_POST" \
    --arg manifest "$MANIFEST" \
    --arg br_version "$("$BR_BIN" --version 2>/dev/null | head -1 || echo unknown)" \
    --argjson lock_timeout_ms "$DEFAULT_LOCK_TIMEOUT_MS" \
    --argjson close_exit_code "${close_rc/null/null}" \
    --arg pre_status "${pre_status:-}" \
    --arg post_status "${post_status:-}" \
    --argjson divergence_observed "$divergence_observed" \
    '{
      schema_version: "jeff-bead-285-capture-receipt/v1",
      ts: $ts,
      mode: $mode,
      bead_id: $bead_id,
      capture_dir: $capture_dir,
      artifacts: {
        close_trace: $close_trace,
        doctor_pre: $doctor_pre,
        doctor_post: $doctor_post,
        manifest: $manifest
      },
      br_version: $br_version,
      lock_timeout_ms: $lock_timeout_ms,
      close_exit_code: ($close_exit_code // null),
      doctor_pre_status: (if $pre_status == "" then null else $pre_status end),
      doctor_post_status: (if $post_status == "" then null else $post_status end),
      divergence_observed: $divergence_observed
    }'
}

if [[ "$MODE" == "dry-run" ]]; then
  receipt="$(emit_receipt "dry-run" "null" "" "" "false")"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$receipt"
  else
    printf 'DRY-RUN: would capture bead-id=%s into %s\n' "$BEAD_ID" "$CAPTURE_DIR"
    printf '  pre-doctor:  %s doctor --json > %s\n' "$BR_BIN" "$DOCTOR_PRE"
    printf '  close-trace: RUST_LOG=br::storage::sqlite=trace,br::cli::commands::close=trace %s --lock-timeout %s close %s 2> %s\n' \
      "$BR_BIN" "$DEFAULT_LOCK_TIMEOUT_MS" "$BEAD_ID" "$CLOSE_TRACE"
    printf '  post-doctor: %s doctor --json > %s\n' "$BR_BIN" "$DOCTOR_POST"
    printf '  manifest:    %s\n' "$MANIFEST"
    printf '\nUse --apply to execute. Only use on a SAFE bead-id (sandbox / test fixture).\n'
    printf '%s\n' "$receipt" >&2
  fi
  exit 0
fi

# Mutation gate (7axmt P3 fix, sister j0xpa per-target-scope variant). Scope=bead_id.
# Fires BEFORE the destructive br close trace creates the capture dir (hoqq8 invariant).
if [[ -z "$IDEMPOTENCY_KEY" ]]; then
  jq -nc \
    --arg sv "jeff-bead-285-capture-receipt/v1" \
    --arg bead_id "$BEAD_ID" \
    '{schema_version:$sv,command:"jeff-bead-285-divergence-capture",status:"refused",mode:"apply",bead_id:$bead_id,reason:"--apply requires --idempotency-key"}' >&2
  exit 3
fi

# Replay-check (tolerant-parse per sister 8sx9w skill discovery). Match on
# (idempotency_key, bead_id) tuple — same key + same bead_id → no-op. Different
# bead_ids under the same key apply (per-target scope).
replay_prior_capture() {
  if [[ -z "$IDEMPOTENCY_KEY" || ! -r "$AUDIT_LOG" ]]; then
    printf ''
    return 0
  fi
  jq -Rc --arg k "$IDEMPOTENCY_KEY" --arg b "$BEAD_ID" \
    'fromjson? | select((.idempotency_key // "") == $k and (.bead_id // "") == $b and ((.status // "") | IN("captured","replay")))' \
    "$AUDIT_LOG" 2>/dev/null | tail -n 1 || true
}

audit_append_capture() {
  local row="$1"
  mkdir -p "$(dirname "$AUDIT_LOG")" 2>/dev/null || true
  printf '%s\n' "$row" >>"$AUDIT_LOG"
}

REPLAY_ROW="$(replay_prior_capture)"
if [[ -n "$REPLAY_ROW" ]]; then
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq -c --arg k "$IDEMPOTENCY_KEY" '. + {replay:true,replay_for_idempotency_key:$k,status:"replay"}' <<<"$REPLAY_ROW"
  else
    printf 'jeff-bead-285-divergence-capture: replay idempotency_key=%s bead_id=%s — prior capture found, no-op\n' "$IDEMPOTENCY_KEY" "$BEAD_ID"
  fi
  exit 0
fi

mkdir -p "$CAPTURE_DIR" || { printf 'error: cannot create %s\n' "$CAPTURE_DIR" >&2; exit 3; }

# 1. Pre-close doctor snapshot (baseline)
if ! "$BR_BIN" doctor --json >"$DOCTOR_PRE" 2>"$CAPTURE_DIR/doctor-pre.stderr"; then
  printf 'WARN: br doctor --json (pre) returned non-zero; output captured at %s\n' "$DOCTOR_PRE" >&2
fi
PRE_STATUS="$(jq -r '.workspace_health // "unknown"' <"$DOCTOR_PRE" 2>/dev/null || echo "unparseable")"

# 2. The trace-instrumented close (Jeffrey's exact ask)
RUST_LOG="br::storage::sqlite=trace,br::cli::commands::close=trace" \
  "$BR_BIN" --lock-timeout "$DEFAULT_LOCK_TIMEOUT_MS" close "$BEAD_ID" 2>"$CLOSE_TRACE" >"$CAPTURE_DIR/close-stdout.log" || CLOSE_RC=$? && CLOSE_RC="${CLOSE_RC:-0}"

# 3. Post-close doctor snapshot (divergence detection)
if ! "$BR_BIN" doctor --json >"$DOCTOR_POST" 2>"$CAPTURE_DIR/doctor-post.stderr"; then
  printf 'WARN: br doctor --json (post) returned non-zero; output captured at %s\n' "$DOCTOR_POST" >&2
fi
POST_STATUS="$(jq -r '.workspace_health // "unknown"' <"$DOCTOR_POST" 2>/dev/null || echo "unparseable")"

# 4. Detect divergence: pre was healthy, post is degraded/unrecoverable
DIVERGENCE_OBSERVED="false"
if [[ "$PRE_STATUS" == "healthy" || "$PRE_STATUS" == "recoverable" ]] \
  && [[ "$POST_STATUS" == "degraded" || "$POST_STATUS" == "unrecoverable" ]]; then
  DIVERGENCE_OBSERVED="true"
fi

# 5. Manifest with all metadata
emit_receipt "apply" "$CLOSE_RC" "$PRE_STATUS" "$POST_STATUS" "$DIVERGENCE_OBSERVED" >"$MANIFEST"

# 6. Audit-log row carrying per-(key, bead_id) provenance for sister-pattern replay.
audit_append_capture "$(jq -nc \
  --arg sv "jeff-bead-285-capture-receipt/v1" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg status "captured" \
  --arg bead_id "$BEAD_ID" \
  --arg idempotency_key "$IDEMPOTENCY_KEY" \
  --arg capture_dir "$CAPTURE_DIR" \
  --arg manifest "$MANIFEST" \
  --arg pre_status "$PRE_STATUS" \
  --arg post_status "$POST_STATUS" \
  --argjson close_exit_code "${CLOSE_RC:-null}" \
  --argjson divergence_observed "$DIVERGENCE_OBSERVED" \
  '{schema_version:$sv,ts:$ts,status:$status,bead_id:$bead_id,idempotency_key:$idempotency_key,capture_dir:$capture_dir,manifest:$manifest,close_exit_code:$close_exit_code,pre_status:$pre_status,post_status:$post_status,divergence_observed:$divergence_observed}')"

if [[ "$JSON_OUT" -eq 1 ]]; then
  cat "$MANIFEST"
else
  printf 'CAPTURE: bead=%s mode=apply close_rc=%s pre=%s post=%s divergence=%s\n' \
    "$BEAD_ID" "$CLOSE_RC" "$PRE_STATUS" "$POST_STATUS" "$DIVERGENCE_OBSERVED"
  printf '  artifacts at: %s\n' "$CAPTURE_DIR"
  printf '  files: %s\n' "$(find "$CAPTURE_DIR" -maxdepth 1 -type f -exec basename {} \; 2>/dev/null | tr '\n' ' ')"
  if [[ "$DIVERGENCE_OBSERVED" == "true" ]]; then
    printf '  DIVERGENCE OBSERVED — bundle ready for upstream issue #285\n'
  fi
fi
