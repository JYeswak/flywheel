#!/usr/bin/env bash
# flywheel-cli-surface: true
# canonical-cli-scoping: passing (info/schema/examples + emit/check/doctor/health)
#
# trauma-claim-emitter.sh — emit trauma-claim rows for novel fuckup-log classes.
#
# Closes P2 of ZESTSTREAM SUBSTRATE-COMPOUNDING GOAL v2 (FCLA Wave 1):
# fire structured trauma-claim rows to .flywheel/evidence/trauma-candidates.jsonl
# whenever the fuckup-log surfaces a class not already absorbed into
# INCIDENTS.md or ~/.claude/skills/flywheel-recovery/SKILL.md.
#
# Schema: flywheel.trauma_candidate.v0
#         (.flywheel/validation-schema/v1/trauma-candidate.schema.json)
#
# Output: appends to .flywheel/evidence/trauma-candidates.jsonl (tracked path).
# Disable via env: FLYWHEEL_TRAUMA_EMITTER=0
#
# Exit codes:
#   0  ran successfully (rows emitted or no candidates found)
#   1  I/O or schema error
#   2  usage error
#   3  emitter disabled via env

set -euo pipefail

VERSION="trauma-claim-emitter.v0.1.0"
SCHEMA_VERSION="flywheel.trauma_candidate.v0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO_ROOT="${TRAUMA_EMITTER_REPO:-$REPO_DEFAULT}"
FUCKUP_LOG="${TRAUMA_EMITTER_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
INCIDENTS_PATH="${TRAUMA_EMITTER_INCIDENTS:-$REPO_ROOT/INCIDENTS.md}"
RECOVERY_SKILL="${TRAUMA_EMITTER_RECOVERY_SKILL:-$HOME/.claude/skills/flywheel-recovery/SKILL.md}"
OUT_PATH="${TRAUMA_EMITTER_OUT:-$REPO_ROOT/.flywheel/evidence/trauma-candidates.jsonl}"
LIMIT="${TRAUMA_EMITTER_LIMIT:-200}"

if [[ "${FLYWHEEL_TRAUMA_EMITTER:-1}" == "0" ]]; then
  printf '{"status":"disabled","reason":"FLYWHEEL_TRAUMA_EMITTER=0"}\n'
  exit 3
fi

usage() {
  cat <<EOF
usage:
  trauma-claim-emitter.sh emit [--limit N] [--dry-run] [--json]
  trauma-claim-emitter.sh check [--json]
  trauma-claim-emitter.sh --info|--schema|--examples [--json]
  trauma-claim-emitter.sh doctor|health [--json]
  trauma-claim-emitter.sh --help|-h

Emits trauma-candidate rows for fuckup-log classes not in INCIDENTS.md or
~/.claude/skills/flywheel-recovery/SKILL.md. Appends to:
  $OUT_PATH

Env overrides:
  TRAUMA_EMITTER_FUCKUP_LOG   default $HOME/.local/state/flywheel/fuckup-log.jsonl
  TRAUMA_EMITTER_INCIDENTS    default <repo>/INCIDENTS.md
  TRAUMA_EMITTER_RECOVERY_SKILL  default ~/.claude/skills/flywheel-recovery/SKILL.md
  TRAUMA_EMITTER_OUT          default <repo>/.flywheel/evidence/trauma-candidates.jsonl
  TRAUMA_EMITTER_LIMIT        default 200 (recent rows scanned)
  FLYWHEEL_TRAUMA_EMITTER=0   disable entirely
EOF
}

emit_info() {
  cat <<JSON
{
  "name": "trauma-claim-emitter",
  "version": "$VERSION",
  "schema_version": "$SCHEMA_VERSION",
  "purpose": "Emit structured trauma-claim rows for novel fuckup-log classes (FCLA W1)",
  "subcommands": ["emit", "check", "doctor", "health"],
  "canonical_cli_flags": ["--info", "--schema", "--examples", "--json", "--help"],
  "mutates_state": "appends to $OUT_PATH",
  "env_overrides": [
    "TRAUMA_EMITTER_FUCKUP_LOG",
    "TRAUMA_EMITTER_INCIDENTS",
    "TRAUMA_EMITTER_RECOVERY_SKILL",
    "TRAUMA_EMITTER_OUT",
    "TRAUMA_EMITTER_LIMIT",
    "FLYWHEEL_TRAUMA_EMITTER"
  ]
}
JSON
}

emit_schema() {
  cat <<JSON
{
  "schema_version": "$SCHEMA_VERSION",
  "row_schema_path": ".flywheel/validation-schema/v1/trauma-candidate.schema.json",
  "input_schema": {
    "fuckup_log_jsonl": "$HOME/.local/state/flywheel/fuckup-log.jsonl",
    "filter": "rows with .class field where class is not in INCIDENTS.md or flywheel-recovery SKILL.md"
  },
  "output_schema": {
    "jsonl_path": "$OUT_PATH",
    "row_shape": "flywheel.trauma_candidate.v0 (see validation-schema)"
  }
}
JSON
}

emit_examples() {
  cat <<JSON
{
  "examples": [
    {
      "name": "scan recent fuckup-log and emit candidates",
      "command": ".flywheel/scripts/trauma-claim-emitter.sh emit --json"
    },
    {
      "name": "dry-run (no write)",
      "command": ".flywheel/scripts/trauma-claim-emitter.sh emit --dry-run --json"
    },
    {
      "name": "check what candidates exist without writing",
      "command": ".flywheel/scripts/trauma-claim-emitter.sh check --json"
    }
  ]
}
JSON
}

emit_doctor() {
  local checks=()
  local status="ok"
  if [[ -f "$FUCKUP_LOG" ]]; then
    checks+=("$(printf '{"check":"fuckup_log_exists","ok":true,"path":"%s"}' "$FUCKUP_LOG")")
  else
    checks+=("$(printf '{"check":"fuckup_log_exists","ok":false,"path":"%s"}' "$FUCKUP_LOG")")
    status="fail"
  fi
  if [[ -f "$INCIDENTS_PATH" ]]; then
    checks+=("$(printf '{"check":"incidents_exists","ok":true,"path":"%s"}' "$INCIDENTS_PATH")")
  else
    checks+=("$(printf '{"check":"incidents_exists","ok":false,"path":"%s"}' "$INCIDENTS_PATH")")
  fi
  if [[ -f "$RECOVERY_SKILL" ]]; then
    checks+=("$(printf '{"check":"recovery_skill_exists","ok":true,"path":"%s"}' "$RECOVERY_SKILL")")
  else
    checks+=("$(printf '{"check":"recovery_skill_exists","ok":false,"path":"%s"}' "$RECOVERY_SKILL")")
  fi
  if command -v jq >/dev/null 2>&1; then
    checks+=('{"check":"jq_available","ok":true}')
  else
    checks+=('{"check":"jq_available","ok":false}')
    status="fail"
  fi
  printf '{"command":"doctor","status":"%s","checks":[%s]}\n' "$status" "$(IFS=,; echo "${checks[*]}")"
  [[ "$status" == "fail" ]] && return 1 || return 0
}

scan_candidates() {
  # Extract unique classes from recent fuckup-log rows
  # For each, check against INCIDENTS.md and flywheel-recovery SKILL.md
  # Emit JSONL rows for novel classes
  tail -n "$LIMIT" "$FUCKUP_LOG" \
    | jq -c 'select((.class // .trauma_class // null) != null) | {class: (.class // .trauma_class), ts: .ts, session: .session, severity: .severity, what_happened: .what_happened, line_ts: .ts}' \
    | python3 -c "
import json, sys, hashlib
from pathlib import Path
from datetime import datetime, timezone

incidents = ''
if Path('$INCIDENTS_PATH').exists():
    incidents = Path('$INCIDENTS_PATH').read_text()
recovery = ''
if Path('$RECOVERY_SKILL').exists():
    recovery = Path('$RECOVERY_SKILL').read_text()

seen_classes = set()
candidates = []
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        row = json.loads(line)
    except json.JSONDecodeError:
        continue
    cls = row.get('class')
    if not cls or cls.startswith('test-') or cls == '?':
        continue
    if cls in seen_classes:
        continue
    seen_classes.add(cls)

    # Check absorption
    if cls in incidents:
        disposition = 'known'
    elif cls in recovery:
        disposition = 'known'
    else:
        disposition = 'new'

    # Default loop routing: 4 (trauma accretor) for trauma-class, 2 (worker-finding) for behavior
    loop = 4

    candidate = {
        'schema_version': '$SCHEMA_VERSION',
        'ts': datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ'),
        'class': cls,
        'fuckup_log_ref': '$FUCKUP_LOG:ts=' + (row.get('line_ts') or 'unknown'),
        'dispatch_log_task_id': None,
        'proposed_disposition': disposition,
        'recommended_skillos_loop': loop,
        'evidence_excerpt': (row.get('what_happened') or '')[:500],
        'session': row.get('session') or 'unknown',
        'severity': row.get('severity') or 'medium',
        'skillos_handoff_message_id': None,
    }
    candidates.append(candidate)

for c in candidates:
    print(json.dumps(c))
"
}

cmd_emit() {
  local dry_run=0 json_out=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) dry_run=1; shift ;;
      --json) json_out=1; shift ;;
      --limit) LIMIT="$2"; shift 2 ;;
      *) printf 'unknown arg: %s\n' "$1" >&2; return 2 ;;
    esac
  done

  if [[ ! -f "$FUCKUP_LOG" ]]; then
    printf '{"status":"error","reason":"fuckup_log_not_found","path":"%s"}\n' "$FUCKUP_LOG" >&2
    return 1
  fi

  local candidates
  candidates="$(scan_candidates)"
  local count
  count="$(echo "$candidates" | grep -c '^{' || echo 0)"

  if [[ "$dry_run" -eq 1 ]]; then
    if [[ "$json_out" -eq 1 ]]; then
      printf '{"status":"dry_run","candidate_count":%d,"would_write":"%s"}\n' "$count" "$OUT_PATH"
      [[ "$count" -gt 0 ]] && echo "$candidates" | jq -s '.'
    else
      printf 'DRY-RUN: %d candidates would be written to %s\n' "$count" "$OUT_PATH"
      [[ "$count" -gt 0 ]] && echo "$candidates"
    fi
    return 0
  fi

  mkdir -p "$(dirname "$OUT_PATH")"
  if [[ "$count" -gt 0 ]]; then
    echo "$candidates" >>"$OUT_PATH"
  fi
  if [[ "$json_out" -eq 1 ]]; then
    printf '{"status":"emitted","candidate_count":%d,"path":"%s"}\n' "$count" "$OUT_PATH"
  else
    printf 'EMITTED %d candidate(s) → %s\n' "$count" "$OUT_PATH"
  fi
}

cmd_check() {
  local json_out=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json) json_out=1; shift ;;
      *) printf 'unknown arg: %s\n' "$1" >&2; return 2 ;;
    esac
  done
  cmd_emit --dry-run $([[ "$json_out" -eq 1 ]] && echo "--json")
}

main() {
  case "${1:-}" in
    --info) shift; emit_info ;;
    --schema) shift; emit_schema ;;
    --examples) shift; emit_examples ;;
    --help|-h|"") usage ;;
    emit) shift; cmd_emit "$@" ;;
    check) shift; cmd_check "$@" ;;
    doctor|health) shift; emit_doctor ;;
    *) printf 'unknown subcommand: %s\n' "$1" >&2; usage >&2; return 2 ;;
  esac
}

main "$@"
