#!/usr/bin/env bash
set -euo pipefail

SCHEMA_VERSION="ntm-serve-eventstream-bridge.v1"
MISSION_ANCHOR="continuous-orchestrator-uptime-self-sustaining-fleet"
NATIVE_SURFACE="ntm serve eventstream"
WRAPPER_SURFACE="flywheel serve eventstream bridge"
L112="OK_ntm_migrate_W1S"
DEFAULT_HOST="127.0.0.1"
DEFAULT_PORT="8765"
DEFAULT_ENDPOINT="/events"
TTL_NATIVE="eventstream_connection_lifetime"
TTL_WRAPPER="serve_bridge_receipt_15m"
TTL_DECISION="revalidate_metrics_per_event_and_drop_receipt_after_disconnect"
NATIVE_WRAPPER_DELTA="native_ntm_serve_owns_eventstream_transport_when_available;wrapper_owns_loopback_bind_redacted_metrics_payload_and_file_receipt_fallback"
AUTHORIZED_OPERATIONS="metrics_doctor_read,eventstream_emit,loopback_bind,payload_redaction,serve_readiness_receipt"
FORBIDDEN_OPERATIONS="non_loopback_default,payload_secret_leak,credential_read,credential_rotation,dispatch_mutation,pane_mutation,metrics_state_mutation"
ROLLBACK="stop_serve_process_and_fall_back_to_file_receipts_doctor_snapshots"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SELF="$ROOT/.flywheel/scripts/ntm-serve-eventstream-bridge.sh"
metrics_probe="$ROOT/.flywheel/scripts/ntm-metrics-doctor-probe.sh"
fixture=""
session="flywheel"
host="$DEFAULT_HOST"
port="$DEFAULT_PORT"
endpoint="$DEFAULT_ENDPOINT"
event_id="1"
retry_ms="5000"
interval_seconds="5"
max_events="1"
max_requests="0"
ready_file=""
reason="overview"
json=false
command="doctor"

usage() {
  cat <<'EOF'
usage: ntm-serve-eventstream-bridge.sh [doctor|health|repair|validate|audit|why|event-json|event|serve|schema|quickstart] [options]

Bridge W1M metrics doctor receipts into redacted server-sent events.

Options:
  --session NAME              NTM session to label/read (default: flywheel)
  --metrics-probe PATH        W1M metrics doctor probe path
  --fixture PATH              Read metrics doctor JSON from fixture instead of probe
  --host HOST                 Bind host for serve (default: 127.0.0.1)
  --port PORT                 Bind port for serve (default: 8765)
  --endpoint PATH             Eventstream endpoint (default: /events)
  --event-id ID               Event id for one-shot event output
  --retry-ms N                SSE retry value (default: 5000)
  --interval-seconds N        Delay between served events (default: 5)
  --max-events N              Events per request for serve/event (default: 1)
  --max-requests N            Requests before serve exits (default: 0, unlimited)
  --ready-file PATH           Write bound host/port JSON after server starts
  --reason NAME               Explanation topic for why
  --json                      Emit JSON for JSON-capable commands
  --dry-run                   Accepted; serve reports planned bind instead of listening
  --apply                     Refused; bridge never mutates state
  --info | --examples | --schema Self-documenting surfaces
EOF
}

now_utc() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

emit_json() {
  jq -cn \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg mission_anchor "$MISSION_ANCHOR" \
    --arg native_surface "$NATIVE_SURFACE" \
    --arg wrapper_surface "$WRAPPER_SURFACE" \
    --arg l112 "$L112" \
    --arg default_host "$DEFAULT_HOST" \
    --arg default_port "$DEFAULT_PORT" \
    --arg endpoint "$endpoint" \
    --arg ttl_native "$TTL_NATIVE" \
    --arg ttl_wrapper "$TTL_WRAPPER" \
    --arg ttl_decision "$TTL_DECISION" \
    --arg native_wrapper_delta "$NATIVE_WRAPPER_DELTA" \
    --arg authorized_operations "$AUTHORIZED_OPERATIONS" \
    --arg forbidden_operations "$FORBIDDEN_OPERATIONS" \
    --arg rollback "$ROLLBACK" \
    "$1"
}

info_json() {
  emit_json '{
    schema_version:$schema_version,
    name:"ntm-serve-eventstream-bridge",
    mission_anchor:$mission_anchor,
    native_surface:$native_surface,
    wrapper_surface:$wrapper_surface,
    default_bind_host:$default_host,
    default_port:($default_port | tonumber),
    endpoint:$endpoint,
    l112_observed:$l112,
    canonical_cli:{
      doctor:true, health:true, repair:true, validate:true, audit:true, why:true,
      schema:true, examples:true, json:true, dry_run:true, apply_refused:true
    },
    authorized_operations:($authorized_operations | split(",")),
    forbidden_operations:($forbidden_operations | split(",")),
    ttl_native:$ttl_native,
    ttl_wrapper:$ttl_wrapper,
    ttl_decision:$ttl_decision,
    native_wrapper_delta:$native_wrapper_delta,
    rollback:$rollback
  }'
}

examples_json() {
  emit_json '{
    schema_version:$schema_version,
    examples:[
      ".flywheel/scripts/ntm-serve-eventstream-bridge.sh validate --fixture /tmp/metrics.json --json",
      ".flywheel/scripts/ntm-serve-eventstream-bridge.sh event --fixture /tmp/metrics.json",
      ".flywheel/scripts/ntm-serve-eventstream-bridge.sh serve --host 127.0.0.1 --port 8765",
      ".flywheel/scripts/ntm-serve-eventstream-bridge.sh serve --dry-run --json"
    ]
  }'
}

schema_json() {
  emit_json '{
    schema_version:$schema_version,
    required:["schema_version","status","scope","checked_at","event","data","payload_redacted","l112_observed","native_wrapper_delta"],
    event_required:["id","event","retry_ms","content_type","endpoint"],
    default_bind_host:$default_host,
    content_type:"text/event-stream",
    mutation_requires:"not_supported",
    default_mode:"read_only"
  }'
}

fail_json() {
  local rc="$1" reason_text="$2"
  jq -cn \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg checked_at "$(now_utc)" \
    --arg session "$session" \
    --arg host "$host" \
    --arg port "$port" \
    --arg endpoint "$endpoint" \
    --arg reason "$reason_text" \
    --arg l112 "$L112" \
    --arg native_wrapper_delta "$NATIVE_WRAPPER_DELTA" \
    --arg rollback "$ROLLBACK" \
    '{schema_version:$schema_version,status:"fail",scope:{session:$session,host:$host,port:($port|tonumber),endpoint:$endpoint},checked_at:$checked_at,findings:[{severity:"error",reason:$reason}],event:null,data:null,payload_redacted:true,l112_observed:$l112,native_wrapper_delta:$native_wrapper_delta,rollback:$rollback,dispatch_mutation_performed:false,secret_values_observed:0}'
  exit "$rc"
}

validate_host() {
  case "$host" in
    127.0.0.1|localhost|::1) ;;
    *) fail_json 3 "non_loopback_bind_refused" ;;
  esac
}

validate_numbers() {
  case "$port" in
    ''|*[!0-9]*) fail_json 3 "invalid_port" ;;
  esac
  case "$retry_ms" in
    ''|*[!0-9]*) fail_json 3 "invalid_retry_ms" ;;
  esac
  case "$interval_seconds" in
    ''|*[!0-9]*) fail_json 3 "invalid_interval_seconds" ;;
  esac
  case "$max_events" in
    ''|*[!0-9]*) fail_json 3 "invalid_max_events" ;;
  esac
  case "$max_requests" in
    ''|*[!0-9]*) fail_json 3 "invalid_max_requests" ;;
  esac
}

read_metrics_receipt() {
  if [[ -n "$fixture" ]]; then
    cat "$fixture"
    return
  fi
  if [[ ! -x "$metrics_probe" ]]; then
    fail_json 2 "metrics_probe_missing_or_not_executable"
  fi
  "$metrics_probe" validate --session "$session" --json
}

redact_json() {
  jq -c '
    def scrub:
      if type == "object" then
        with_entries(
          if (.key | test("(?i)(token|secret|password|credential|authorization|bearer|registration|private[_-]?key|api[_-]?key)")) then
            .value = "[SCRUBBED:secret_field]"
          else
            .value |= scrub
          end
        )
      elif type == "array" then map(scrub)
      elif type == "string" then
        gsub("Bearer [A-Za-z0-9._-]+";"Bearer [SCRUBBED:bearer_token]")
        | gsub("sk-[A-Za-z0-9]{20,}";"[SCRUBBED:openai_key]")
        | gsub("ghp_[A-Za-z0-9]+";"[SCRUBBED:github_token]")
        | gsub("gh_pat_[A-Za-z0-9_]+";"[SCRUBBED:github_token]")
        | gsub("xox[baprs]-[A-Za-z0-9-]+";"[SCRUBBED:slack_token]")
        | gsub("eyJ[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+";"[SCRUBBED:jwt]")
      else .
      end;
    scrub'
}

event_payload() {
  local raw redacted status
  if ! raw="$(read_metrics_receipt)"; then
    fail_json 2 "metrics_probe_failed"
  fi
  if ! jq empty >/dev/null 2>&1 <<<"$raw"; then
    fail_json 2 "metrics_probe_non_json"
  fi
  redacted="$(redact_json <<<"$raw")"
  status="$(jq -r '.status // "warn"' <<<"$redacted")"

  local payload
  payload="$(jq -cn \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg status "$status" \
    --arg checked_at "$(now_utc)" \
    --arg session "$session" \
    --arg host "$host" \
    --arg port "$port" \
    --arg endpoint "$endpoint" \
    --arg event_id "$event_id" \
    --arg retry_ms "$retry_ms" \
    --arg l112 "$L112" \
    --arg mission_anchor "$MISSION_ANCHOR" \
    --arg native_surface "$NATIVE_SURFACE" \
    --arg wrapper_surface "$WRAPPER_SURFACE" \
    --arg ttl_native "$TTL_NATIVE" \
    --arg ttl_wrapper "$TTL_WRAPPER" \
    --arg ttl_decision "$TTL_DECISION" \
    --arg native_wrapper_delta "$NATIVE_WRAPPER_DELTA" \
    --arg authorized_operations "$AUTHORIZED_OPERATIONS" \
    --arg forbidden_operations "$FORBIDDEN_OPERATIONS" \
    --arg rollback "$ROLLBACK" \
    --argjson data "$redacted" \
    '{
      schema_version:$schema_version,
      status:$status,
      mission_anchor:$mission_anchor,
      checked_at:$checked_at,
      scope:{session:$session,host:$host,port:($port|tonumber),endpoint:$endpoint},
      native_surface:$native_surface,
      wrapper_surface:$wrapper_surface,
      event:{id:$event_id,event:"ntm_metrics",retry_ms:($retry_ms|tonumber),content_type:"text/event-stream",endpoint:$endpoint},
      data:$data,
      payload_redacted:true,
      redaction:{applied:true,policy:"secret_keys_and_token_like_values",replacement_prefix:"[SCRUBBED:"},
      eventstream_ready:($status != "fail"),
      dispatch_mutation_performed:false,
      l112_observed:$l112,
      rollback:$rollback,
      authorized_operations:($authorized_operations | split(",")),
      forbidden_operations:($forbidden_operations | split(",")),
      ttl_native:$ttl_native,
      ttl_wrapper:$ttl_wrapper,
      ttl_decision:$ttl_decision,
      native_wrapper_delta:$native_wrapper_delta,
      secret_values_observed:0
    }')"
  printf '%s\n' "$payload"
  [[ "$status" != "fail" ]]
}

emit_sse_event() {
  local payload
  payload="$(event_payload)"
  printf 'event: ntm_metrics\n'
  printf 'id: %s\n' "$event_id"
  printf 'retry: %s\n' "$retry_ms"
  printf 'data: %s\n\n' "$payload"
}

run_json_command() {
  local mode="$1"
  local payload rc
  set +e
  payload="$(event_payload)"
  rc=$?
  set -e
  if [[ "$mode" == "audit" ]]; then
    payload="$(jq -c '. + {audit:{default_bind_host:"127.0.0.1",redaction_applied:.payload_redacted,event_type:.event.event,content_type:.event.content_type,data_keys:(.data | keys)}}' <<<"$payload")"
  fi
  printf '%s\n' "$payload"
  exit "$rc"
}

repair_json() {
  jq -cn \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg checked_at "$(now_utc)" \
    --arg l112 "$L112" \
    --arg rollback "$ROLLBACK" \
    --arg authorized_operations "$AUTHORIZED_OPERATIONS" \
    --arg forbidden_operations "$FORBIDDEN_OPERATIONS" \
    '{
      schema_version:$schema_version,
      status:"ok",
      checked_at:$checked_at,
      repair_mode:"dry_run",
      mutation_performed:false,
      planned_actions:["stop serve process if running","fall back to file receipts","rerun metrics doctor snapshot"],
      rollback:$rollback,
      authorized_operations:($authorized_operations | split(",")),
      forbidden_operations:($forbidden_operations | split(",")),
      l112_observed:$l112
    }'
}

why_json() {
  jq -cn \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg reason "$reason" \
    --arg checked_at "$(now_utc)" \
    --arg l112 "$L112" \
    '{
      schema_version:$schema_version,
      status:"ok",
      checked_at:$checked_at,
      reason:$reason,
      explanations:{
        overview:"W1S exposes W1M metrics as redacted server-sent events without mutating dispatch state.",
        loopback_default:"The bridge binds 127.0.0.1 by default and refuses non-loopback hosts.",
        redaction:"Payloads pass through key-name and token-shape redaction before SSE emission.",
        rollback:"Stop the serve process and fall back to file receipts or metrics doctor snapshots."
      },
      l112_observed:$l112
    }'
}

serve_dry_run_json() {
  validate_host
  jq -cn \
    --arg schema_version "$SCHEMA_VERSION" \
    --arg checked_at "$(now_utc)" \
    --arg session "$session" \
    --arg host "$host" \
    --arg port "$port" \
    --arg endpoint "$endpoint" \
    --arg l112 "$L112" \
    '{schema_version:$schema_version,status:"ok",checked_at:$checked_at,serve:{session:$session,host:$host,port:($port|tonumber),endpoint:$endpoint,dry_run:true,would_bind:true,content_type:"text/event-stream"},l112_observed:$l112,mutation_performed:false}'
}

serve_http() {
  validate_host
  python3 - "$SELF" "$session" "$host" "$port" "$endpoint" "$metrics_probe" "$fixture" "$retry_ms" "$interval_seconds" "$max_events" "$max_requests" "$ready_file" <<'PY'
import http.server
import json
import subprocess
import sys
import threading
import time
from pathlib import Path

script, session, host, port, endpoint, metrics_probe, fixture, retry_ms, interval_s, max_events, max_requests, ready_file = sys.argv[1:]
port = int(port)
interval_s = int(interval_s)
max_events = int(max_events)
max_requests = int(max_requests)
state = {"requests": 0}

class Handler(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        return

    def do_GET(self):
        if self.path.split("?", 1)[0] != endpoint:
            self.send_response(404)
            self.end_headers()
            return
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("X-Accel-Buffering", "no")
        self.end_headers()
        count = max_events if max_events > 0 else 1_000_000
        for i in range(count):
            cmd = [script, "event-json", "--session", session, "--host", host, "--port", str(self.server.server_port), "--endpoint", endpoint, "--metrics-probe", metrics_probe, "--event-id", str(i + 1), "--retry-ms", retry_ms, "--json"]
            if fixture:
                cmd.extend(["--fixture", fixture])
            payload = subprocess.check_output(cmd, text=True).strip()
            self.wfile.write(b"event: ntm_metrics\n")
            self.wfile.write(f"id: {i + 1}\n".encode())
            self.wfile.write(f"retry: {retry_ms}\n".encode())
            self.wfile.write(f"data: {payload}\n\n".encode())
            self.wfile.flush()
            if i + 1 < count:
                time.sleep(interval_s)
        state["requests"] += 1
        if max_requests > 0 and state["requests"] >= max_requests:
            threading.Thread(target=self.server.shutdown, daemon=True).start()

server = http.server.ThreadingHTTPServer((host, port), Handler)
if ready_file:
    Path(ready_file).write_text(json.dumps({"status": "ready", "host": host, "port": server.server_port, "endpoint": endpoint}, sort_keys=True) + "\n")
try:
    server.serve_forever()
finally:
    server.server_close()
PY
}

dry_run=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    doctor|health|repair|validate|audit|why|event-json|event|serve|schema|quickstart) command="$1"; shift ;;
    --session) session="$2"; shift 2 ;;
    --metrics-probe) metrics_probe="$2"; shift 2 ;;
    --fixture) fixture="$2"; shift 2 ;;
    --host) host="$2"; shift 2 ;;
    --port) port="$2"; shift 2 ;;
    --endpoint) endpoint="$2"; shift 2 ;;
    --event-id) event_id="$2"; shift 2 ;;
    --retry-ms) retry_ms="$2"; shift 2 ;;
    --interval-seconds) interval_seconds="$2"; shift 2 ;;
    --max-events) max_events="$2"; shift 2 ;;
    --max-requests) max_requests="$2"; shift 2 ;;
    --ready-file) ready_file="$2"; shift 2 ;;
    --reason) reason="$2"; shift 2 ;;
    --json) json=true; shift ;;
    --dry-run) dry_run=true; shift ;;
    --apply) fail_json 3 "apply_not_supported_read_only_bridge" ;;
    --explain) command="why"; shift ;;
    --info) info_json; exit 0 ;;
    --examples|examples) examples_json; exit 0 ;;
    --schema) schema_json; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) fail_json 3 "unknown_argument:$1" ;;
  esac
done

validate_numbers

case "$command" in
  schema) schema_json ;;
  quickstart) jq -cn --arg schema_version "$SCHEMA_VERSION" '{schema_version:$schema_version,status:"ok",steps:["run --info --json","run --schema --json","run validate --fixture /tmp/metrics.json --json","run event --fixture /tmp/metrics.json","run serve --host 127.0.0.1 --port 8765"]}' ;;
  doctor|health|validate) run_json_command "$command" ;;
  audit) run_json_command "audit" ;;
  repair) repair_json ;;
  why) why_json ;;
  event-json) event_payload ;;
  event) emit_sse_event ;;
  serve)
    if [[ "$dry_run" == "true" ]]; then
      serve_dry_run_json
    else
      serve_http
    fi
    ;;
esac
