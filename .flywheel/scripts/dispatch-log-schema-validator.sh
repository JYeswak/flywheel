#!/usr/bin/env bash
set -euo pipefail

VERSION="dispatch-log-schema-validator/v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
REPO="$ROOT"
JSON_OUT=0
APPLY=0
EXPLAIN=0
DRY_RUN=1
QUIET=0
COMMAND="scan"
TAIL_N=0
EXPECTED_ANCHOR="${FLYWHEEL_MISSION_ANCHOR:-continuous-orchestrator-uptime-self-sustaining-fleet}"

usage() {
  cat <<'EOF'
usage:
  dispatch-log-schema-validator.sh [--repo PATH] [--dry-run] [--json] [--explain] [--tail N]
  dispatch-log-schema-validator.sh --apply [--repo PATH] [--json] [--tail N]
  dispatch-log-schema-validator.sh --schema|--info|--examples|-h|--help
  dispatch-log-schema-validator.sh doctor|health|validate [--repo PATH] [--json] [--tail N]
  dispatch-log-schema-validator.sh completion [bash|zsh|fish]

flags:
  --tail N    validate only the last N rows of the log (0 = all rows, default)

exit codes: 0=report emitted, 1=doctor/validate found invalid v2 rows, 2=usage or input error
EOF
}

info() {
  jq -nc \
    --arg version "$VERSION" \
    --arg repo "$REPO" \
    --arg schema "$REPO/.flywheel/validation-schema/v1/dispatch-log-entry-v2.schema.json" \
    --arg log "$REPO/.flywheel/dispatch-log.jsonl" \
    '{name:"dispatch-log-schema-validator.sh",version:$version,repo:$repo,mutates:"--apply writes dispatch-log-validation.jsonl atomically",schema:$schema,dispatch_log:$log,default_mode:"dry-run",commands:["doctor","health","validate","repair","audit","why","quickstart","help","completion"],flags:["--dry-run","--apply","--json","--explain","--info","--examples","--schema","--repo PATH","--no-color","--width N"]}'
}

examples() {
  cat <<'EOF'
{"task_id":"valid-v2","ts":"2026-05-07T00:00:00Z","from":"flywheel:1","to":"flywheel-pane-2","pane":2,"session":"flywheel","task_summary":"valid v2","task_file":"/tmp/dispatch_valid_v2.md","agent_type":"codex","pane_state_source":"ntm_health","mission_anchor":"continuous-orchestrator-uptime-self-sustaining-fleet","mission_fitness_claim":"Directly enforces the mission anchor at dispatch time.","mission_fitness_class":"direct","idempotency_token":"valid-v2","callback_received_at":null}
{"task_id":"valid-v1-legacy","callback_received_at":"2026-05-07T00:10:00Z","self_grade":"Y","bead_closed":"yes","validated":"yes"}
{malformed-json
EOF
}

quickstart() {
  cat <<'EOF'
Scan the repo dispatch ledger:
  bash .flywheel/scripts/dispatch-log-schema-validator.sh --repo "$PWD"

Emit machine JSON:
  bash .flywheel/scripts/dispatch-log-schema-validator.sh --repo "$PWD" --json

Write validation sidecar:
  bash .flywheel/scripts/dispatch-log-schema-validator.sh --repo "$PWD" --apply
EOF
}

completion() {
  local shell="${1:-bash}"
  case "$shell" in
    bash|zsh|fish)
      printf '%s\n' '# completion: dispatch-log-schema-validator.sh --repo --dry-run --apply --json --explain --info --examples --schema doctor health validate repair audit why quickstart help completion'
      ;;
    *) printf 'unsupported shell: %s\n' "$shell" >&2; exit 2 ;;
  esac
}

die_usage() {
  printf 'ERR: %s\n' "$1" >&2
  exit 2
}

subcommand="${1:-}"
case "$subcommand" in
  doctor|health|validate)
    COMMAND="$subcommand"
    shift
    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then usage; exit 0; fi
    ;;
  repair)
    shift
    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then usage; exit 0; fi
    if [[ "$JSON_OUT" -eq 1 ]]; then
      jq -nc '{status:"noop",mutated:false,reason:"validator has no autonomous repair; use --apply to write sidecar"}'
    else
      printf '%s\n' 'repair: no autonomous repair; use --apply to write dispatch-log-validation.jsonl'
    fi
    exit 0
    ;;
  audit)
    shift
    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then usage; exit 0; fi
    sidecar="$REPO/.flywheel/dispatch-log-validation.jsonl"
    [[ -f "$sidecar" ]] && tail -n 20 "$sidecar" || printf 'audit: no sidecar found at %s\n' "$sidecar"
    exit 0
    ;;
  why)
    shift
    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then usage; exit 0; fi
    cat <<'EOF'
why: dispatch-log v2 requires mission_fitness_claim and mission_fitness_class so dispatch intent can be audited before callback closeout.
EOF
    exit 0
    ;;
  quickstart)
    quickstart; exit 0
    ;;
  help)
    shift || true
    usage; exit 0
    ;;
  completion)
    shift
    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then usage; exit 0; fi
    completion "${1:-bash}"; exit 0
    ;;
  schema)
    shift
    cat "$REPO/.flywheel/validation-schema/v1/dispatch-log-entry-v2.schema.json"; exit 0
    ;;
esac

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) [[ $# -ge 2 ]] || die_usage "--repo requires PATH"; REPO="$(cd "$2" && pwd -P)"; shift 2 ;;
    --repo=*) REPO="$(cd "${1#*=}" && pwd -P)"; shift ;;
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --json) JSON_OUT=1; shift ;;
    --explain) EXPLAIN=1; shift ;;
    --quiet) QUIET=1; shift ;;
    --no-color) shift ;;
    --width) [[ $# -ge 2 ]] || die_usage "--width requires N"; shift 2 ;;
    --width=*) shift ;;
    --tail) [[ $# -ge 2 ]] || die_usage "--tail requires N"; TAIL_N="$2"; shift 2 ;;
    --tail=*) TAIL_N="${1#*=}"; shift ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --schema) cat "$REPO/.flywheel/validation-schema/v1/dispatch-log-entry-v2.schema.json"; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    --*) die_usage "unknown argument: $1" ;;
    *) die_usage "unexpected argument: $1" ;;
  esac
done

LOG_PATH="$REPO/.flywheel/dispatch-log.jsonl"
SCHEMA_PATH="$REPO/.flywheel/validation-schema/v1/dispatch-log-entry-v2.schema.json"
SIDECAR="$REPO/.flywheel/dispatch-log-validation.jsonl"

[[ -d "$REPO/.flywheel" ]] || die_usage "repo has no .flywheel directory: $REPO"
[[ -r "$SCHEMA_PATH" ]] || die_usage "schema not readable: $SCHEMA_PATH"

TMP="$(mktemp "${TMPDIR:-/tmp}/dispatch-log-schema-validator.XXXXXX")"
TAIL_TMP=""
trap 'rm -f "$TMP" "${SIDE_TMP:-}" "${TAIL_TMP:-}"' EXIT

EFFECTIVE_LOG="$LOG_PATH"
if [[ "$TAIL_N" =~ ^[0-9]+$ ]] && [[ "$TAIL_N" -gt 0 ]] && [[ -f "$LOG_PATH" ]]; then
  TAIL_TMP="$(mktemp "${TMPDIR:-/tmp}/dispatch-log-schema-validator-tail.XXXXXX")"
  tail -n "$TAIL_N" "$LOG_PATH" >"$TAIL_TMP"
  EFFECTIVE_LOG="$TAIL_TMP"
fi

python3 - "$EFFECTIVE_LOG" "$SCHEMA_PATH" "$EXPECTED_ANCHOR" "$VERSION" >"$TMP" <<'PY'
import json
import sys
from collections import Counter
from datetime import datetime
from pathlib import Path

log_path = Path(sys.argv[1])
schema_path = Path(sys.argv[2])
expected_anchor = sys.argv[3]
version = sys.argv[4]

required = [
    "task_id", "ts", "from", "to", "pane", "session", "task_summary",
    "task_file", "agent_type", "pane_state_source", "mission_anchor",
    "mission_fitness_claim", "mission_fitness_class", "idempotency_token",
    "callback_received_at",
]
agent_types = {"codex", "claude", "gemini", "other"}
classes = {"direct", "adjacent", "infrastructure", "drift", "unknown"}
callback_classes = {"direct", "adjacent", "infrastructure", "drift"}
pane_state_sources = {"ntm_health", "ntm_copy", "raw_capture", "none"}

def is_iso8601(value):
    if not isinstance(value, str) or not value:
        return False
    try:
        datetime.fromisoformat(value.replace("Z", "+00:00"))
        return True
    except ValueError:
        return False

def err(code, field, detail):
    return {"code": code, "field": field, "detail": detail}

def validate(row):
    errors = []
    if not isinstance(row, dict):
        return False, "invalid", [err("invalid_type_root", "$", "row must be a JSON object")]

    for field in required:
        if field not in row:
            errors.append(err(f"missing_{field}", field, "required by dispatch-log entry v2"))

    if "ts" in row and not is_iso8601(row.get("ts")):
        errors.append(err("invalid_ts", "ts", "must be ISO8601/date-time"))
    if "callback_received_at" in row and row.get("callback_received_at") is not None and not is_iso8601(row.get("callback_received_at")):
        errors.append(err("invalid_callback_received_at", "callback_received_at", "must be ISO8601/date-time or null"))
    if "pane" in row and (not isinstance(row.get("pane"), int) or isinstance(row.get("pane"), bool)):
        errors.append(err("invalid_pane", "pane", "must be an integer"))
    if "task_summary" in row:
        summary = row.get("task_summary")
        if not isinstance(summary, str) or not summary:
            errors.append(err("invalid_task_summary", "task_summary", "must be a non-empty string"))
        elif len(summary) > 100:
            errors.append(err("task_summary_too_long", "task_summary", "max 100 characters"))
    if "task_file" in row:
        task_file = row.get("task_file")
        if not isinstance(task_file, str) or not task_file.startswith("/"):
            errors.append(err("invalid_task_file", "task_file", "must be an absolute path"))
    if "agent_type" in row and row.get("agent_type") not in agent_types:
        errors.append(err("invalid_agent_type", "agent_type", "must be codex|claude|gemini|other"))
    if "pane_state_source" in row:
        pane_state_source = row.get("pane_state_source")
        if pane_state_source not in pane_state_sources:
            errors.append(err("invalid_pane_state_source", "pane_state_source", "must be ntm_health|ntm_copy|raw_capture|none"))
        if pane_state_source == "raw_capture" and row.get("event") in {"dispatch_sent", "ntm_dispatch_sent", "worker_dispatch"}:
            errors.append(err("raw_capture_dispatch_context", "pane_state_source", "dispatch rows require ntm_health, ntm_copy, or none"))
    if "mission_anchor" in row and row.get("mission_anchor") != expected_anchor:
        errors.append(err("invalid_mission_anchor", "mission_anchor", f"must equal {expected_anchor}"))
    if "mission_fitness_claim" in row:
        claim = row.get("mission_fitness_claim")
        if not isinstance(claim, str) or not claim.strip():
            errors.append(err("invalid_mission_fitness_claim", "mission_fitness_claim", "must be a non-empty string"))
        elif len(claim) > 240:
            errors.append(err("mission_fitness_claim_too_long", "mission_fitness_claim", "max 240 characters"))
    if "mission_fitness_class" in row and row.get("mission_fitness_class") not in classes:
        errors.append(err("invalid_mission_fitness_class", "mission_fitness_class", "must be direct|adjacent|infrastructure|drift|unknown"))
    if "mission_fitness" in row and row.get("mission_fitness") not in callback_classes:
        errors.append(err("invalid_mission_fitness", "mission_fitness", "must be direct|adjacent|infrastructure|drift"))
    for field in ("task_id", "from", "to", "session", "idempotency_token"):
        if field in row and (not isinstance(row.get(field), str) or not row.get(field)):
            errors.append(err(f"invalid_{field}", field, "must be a non-empty string"))
    if "bead_closed" in row and row.get("bead_closed") not in {"yes", "no"}:
        errors.append(err("invalid_bead_closed", "bead_closed", "must be yes|no"))
    if "validated" in row and row.get("validated") not in {"yes", "no"}:
        errors.append(err("invalid_validated", "validated", "must be yes|no"))
    if "backfilled" in row and not isinstance(row.get("backfilled"), bool):
        errors.append(err("invalid_backfilled", "backfilled", "must be boolean"))
    if "mission_fitness_evidence" in row and (not isinstance(row.get("mission_fitness_evidence"), str) or not row.get("mission_fitness_evidence")):
        errors.append(err("invalid_mission_fitness_evidence", "mission_fitness_evidence", "must be a non-empty string"))

    cls = row.get("mission_fitness_class")
    if cls in classes:
        classification = cls
    elif cls is None:
        classification = "missing"
    else:
        classification = "invalid"
    return not errors, classification, errors

schema_id = None
try:
    schema = json.loads(schema_path.read_text(encoding="utf-8"))
    schema_id = schema.get("$id")
except Exception:
    schema_id = None

decisions = []
counts = Counter()
missing_claim = 0
missing_class = 0
malformed = 0

if log_path.exists():
    lines = log_path.read_text(encoding="utf-8", errors="replace").splitlines()
else:
    lines = []

for idx, line in enumerate(lines, 1):
    if not line.strip():
        continue
    try:
        row = json.loads(line)
    except json.JSONDecodeError as exc:
        malformed += 1
        counts["malformed"] += 1
        decisions.append({
            "schema_version": "dispatch-log-validation/v1",
            "validator_version": version,
            "line": idx,
            "valid": False,
            "status": "FAIL",
            "classification": "malformed",
            "task_id": None,
            "errors": [err("malformed_json", "$", str(exc))],
        })
        continue

    valid, classification, errors = validate(row)
    counts[classification] += 1
    if not isinstance(row, dict) or "mission_fitness_claim" not in row:
        missing_claim += 1
    if not isinstance(row, dict) or "mission_fitness_class" not in row:
        missing_class += 1
    decisions.append({
        "schema_version": "dispatch-log-validation/v1",
        "validator_version": version,
        "line": idx,
        "valid": valid,
        "status": "PASS" if valid else "FAIL",
        "classification": classification,
        "task_id": row.get("task_id") if isinstance(row, dict) else None,
        "errors": errors,
    })

total = len(decisions)
valid_count = sum(1 for item in decisions if item["valid"])
summary = {
    "schema_version": "dispatch-log-validator-summary/v1",
    "validator_version": version,
    "schema_id": schema_id,
    "dispatch_log": str(log_path),
    "schema_path": str(schema_path),
    "log_present": log_path.exists(),
    "expected_mission_anchor": expected_anchor,
    "total": total,
    "valid": valid_count,
    "invalid": total - valid_count,
    "malformed_count": malformed,
    "missing_fitness_claim": missing_claim,
    "missing_fitness_class": missing_class,
    "drift_count": counts.get("drift", 0),
    "by_class": {name: counts.get(name, 0) for name in ("direct", "adjacent", "infrastructure", "drift", "unknown", "missing", "invalid", "malformed")},
}
summary["status"] = "PASS" if summary["invalid"] == 0 else "FAIL"
print(json.dumps({"summary": summary, "decisions": decisions}, sort_keys=True))
PY

if [[ "$APPLY" -eq 1 ]]; then
  mkdir -p "$(dirname "$SIDECAR")"
  SIDE_TMP="$(mktemp "${SIDECAR}.XXXXXX")"
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  jq -c --arg ts "$now" '.decisions[] | . + {validated_at:$ts}' "$TMP" >"$SIDE_TMP"
  mv "$SIDE_TMP" "$SIDECAR"
fi

if [[ "$QUIET" -eq 0 ]]; then
  if [[ "$JSON_OUT" -eq 1 ]]; then
    jq '.summary' "$TMP"
  elif [[ "$EXPLAIN" -eq 1 ]]; then
    jq -r '.decisions[] | select(.valid == false) | "row=\(.line) task_id=\(.task_id // "null") class=\(.classification) errors=\([.errors[].code] | join(","))"' "$TMP"
  else
    jq -r '.decisions[] | "row=\(.line) status=\(.status) class=\(.classification) task_id=\(.task_id // "null") errors=\([.errors[].code] | join(","))"' "$TMP"
    jq -r '.summary | "summary total=\(.total) valid=\(.valid) missing_fitness_claim=\(.missing_fitness_claim) missing_fitness_class=\(.missing_fitness_class) drift_count=\(.drift_count)"' "$TMP"
    [[ "$APPLY" -eq 1 ]] && printf 'sidecar=%s\n' "$SIDECAR"
  fi
fi

if [[ "$COMMAND" == "doctor" || "$COMMAND" == "validate" ]]; then
  invalid="$(jq -r '.summary.invalid' "$TMP")"
  [[ "$invalid" == "0" ]] || exit 1
fi
exit 0
