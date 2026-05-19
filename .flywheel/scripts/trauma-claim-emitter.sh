#!/usr/bin/env bash
# Meta-pattern Adoption stance:
# Embodies MP-08-trauma-class-promotion.md and MP-74-assertion-control-evidence-chain.md.
# Source: /Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/
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

VERSION="trauma-claim-emitter.v0.2.0"
SCHEMA_VERSION="flywheel.trauma_candidate.v0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DEFAULT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
REPO_ROOT="${TRAUMA_EMITTER_REPO:-$REPO_DEFAULT}"
FUCKUP_LOG="${TRAUMA_EMITTER_FUCKUP_LOG:-$HOME/.local/state/flywheel/fuckup-log.jsonl}"
INCIDENTS_PATH="${TRAUMA_EMITTER_INCIDENTS:-$REPO_ROOT/INCIDENTS.md}"
RECOVERY_SKILL="${TRAUMA_EMITTER_RECOVERY_SKILL:-$HOME/.claude/skills/flywheel-recovery/SKILL.md}"
OUT_PATH="${TRAUMA_EMITTER_OUT:-$REPO_ROOT/.flywheel/evidence/trauma-candidates.jsonl}"
LIMIT="${TRAUMA_EMITTER_LIMIT:-200}"
WINDOW_HOURS="${TRAUMA_EMITTER_WINDOW_HOURS:-24}"
SATURATION_THRESHOLD_DEFAULT="${TRAUMA_EMITTER_SATURATION_THRESHOLD:-3}"
SECRETS_CLASS_THRESHOLD="${TRAUMA_EMITTER_SECRETS_THRESHOLD:-1}"

if [[ "${FLYWHEEL_TRAUMA_EMITTER:-1}" == "0" ]]; then
  printf '{"status":"disabled","reason":"FLYWHEEL_TRAUMA_EMITTER=0"}\n'
  exit 3
fi

usage() {
  cat <<EOF
usage:
  trauma-claim-emitter.sh emit [--limit N] [--dry-run] [--json]
  trauma-claim-emitter.sh check [--json]
  trauma-claim-emitter.sh stale-check [--json]
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
  TRAUMA_EMITTER_WINDOW_HOURS default 24 (rolling saturation window)
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
  "subcommands": ["emit", "check", "stale-check", "doctor", "health"],
  "canonical_cli_flags": ["--info", "--schema", "--examples", "--json", "--help"],
  "mutates_state": "appends to $OUT_PATH",
  "env_overrides": [
    "TRAUMA_EMITTER_FUCKUP_LOG",
    "TRAUMA_EMITTER_INCIDENTS",
    "TRAUMA_EMITTER_RECOVERY_SKILL",
    "TRAUMA_EMITTER_OUT",
    "TRAUMA_EMITTER_LIMIT",
    "TRAUMA_EMITTER_WINDOW_HOURS",
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
    },
    {
      "name": "warn on saturated classes missing trauma-candidates row",
      "command": ".flywheel/scripts/trauma-claim-emitter.sh stale-check --json"
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
  # Two-pass saturation scan:
  # 1. collect recent rows per class over a rolling window
  # 2. emit only classes that satisfy the class-family threshold
  tail -n "$LIMIT" "$FUCKUP_LOG" \
    | python3 -c "
import json, sys, hashlib
import os, re
from collections import defaultdict
from pathlib import Path
from datetime import datetime, timezone, timedelta

incidents = ''
if Path('$INCIDENTS_PATH').exists():
    incidents = Path('$INCIDENTS_PATH').read_text()
recovery = ''
if Path('$RECOVERY_SKILL').exists():
    recovery = Path('$RECOVERY_SKILL').read_text()

WORKER_DISCIPLINE_CLASSES = {
    'worker_low_socraticode_K',
    'worker_skipped_skill_lookup',
    'worker_skipped_ubs_on_critical_surface',
    'worker_unreserved_edit',
    'worker_tick_missing_evidence',
    'worker_optimized_without_profile',
}
CROSS_TRACK_CLASSES = {
    'cross_track_dispatch_collision',
}
SECRETS_CLASS_PATTERNS = (
    'secret', 'credential', 'token', 'key_leak', 'token_leak', 'pii_', 'cf_access',
)

def parse_ts(value):
    if not value:
        return None
    for candidate in (str(value), str(value).replace('Z', '+00:00')):
        try:
            parsed = datetime.fromisoformat(candidate)
            if parsed.tzinfo is None:
                parsed = parsed.replace(tzinfo=timezone.utc)
            return parsed.astimezone(timezone.utc)
        except ValueError:
            pass
    return None

def slug_class(cls):
    return re.sub(r'[^a-z0-9_]+', '_', cls.lower().replace('-', '_')).strip('_') or 'unknown'

now_raw = os.environ.get('TRAUMA_EMITTER_NOW')
now = parse_ts(now_raw) if now_raw else datetime.now(timezone.utc)
cutoff = now - timedelta(hours=int('$WINDOW_HOURS'))
class_data = {}
candidates = []
for line in sys.stdin:
    line = line.strip()
    if not line: continue
    try:
        row = json.loads(line)
    except json.JSONDecodeError:
        continue
    cls = row.get('class') or row.get('trauma_class')
    if not cls or cls.startswith('test-') or cls == '?':
        continue
    row_ts = parse_ts(row.get('ts'))
    if row_ts is None or row_ts < cutoff:
        continue
    data = class_data.setdefault(cls, {
        'count': 0,
        'first_seen': row.get('ts'),
        'last_seen': row.get('ts'),
        'samples': [],
        'severity': row.get('severity') or 'medium',
        'session': row.get('session') or 'unknown',
        'excerpt': row.get('what_happened') or '',
    })
    data['count'] += 1
    if row.get('ts') and (not data['first_seen'] or row.get('ts') < data['first_seen']):
        data['first_seen'] = row.get('ts')
    if row.get('ts') and (not data['last_seen'] or row.get('ts') > data['last_seen']):
        data['last_seen'] = row.get('ts')
    if len(data['samples']) < 3:
        data['samples'].append({
            'ts': row.get('ts'),
            'session': row.get('session') or 'unknown',
            'severity': row.get('severity') or 'medium',
            'what_happened': (row.get('what_happened') or '')[:200],
        })

for cls, data in sorted(class_data.items()):
    # Check absorption
    if cls in incidents:
        disposition = 'known'
    elif cls in recovery:
        disposition = 'known'
    else:
        disposition = 'new'

    lowered = cls.lower()
    is_secrets = any(pattern in lowered for pattern in SECRETS_CLASS_PATTERNS)
    is_worker = cls in WORKER_DISCIPLINE_CLASSES
    is_cross_track = cls in CROSS_TRACK_CLASSES
    threshold = int('$SECRETS_CLASS_THRESHOLD') if (is_secrets or is_cross_track) else int('$SATURATION_THRESHOLD_DEFAULT')
    if data['count'] < threshold:
        continue

    # Default loop routing: 4 (trauma accretor) for trauma-class, 2 (worker-finding) for behavior
    loop = 4

    candidate = {
        'schema_version': '$SCHEMA_VERSION',
        'ts': now.strftime('%Y-%m-%dT%H:%M:%SZ'),
        'class': cls,
        'N': data['count'],
        'count_in_window': data['count'],
        'window_hours': int('$WINDOW_HOURS'),
        'saturation_threshold': threshold,
        'class_family': 'cross_track_dispatch_collision' if is_cross_track else ('worker_discipline' if is_worker else ('secrets' if is_secrets else 'general')),
        'first_seen': data['first_seen'],
        'last_seen': data['last_seen'],
        'sample_rows': data['samples'],
        'proposed_memory_path': 'feedback_' + slug_class(cls) + '.md',
        'fuckup_log_ref': '$FUCKUP_LOG:ts=' + (data['first_seen'] or 'unknown') + '..' + (data['last_seen'] or 'unknown'),
        'dispatch_log_task_id': None,
        'proposed_disposition': disposition,
        'recommended_skillos_loop': loop,
        'evidence_excerpt': data['excerpt'][:500],
        'session': data['session'],
        'severity': data['severity'] if data['severity'] in {'low','medium','high','critical'} else 'medium',
        'skillos_handoff_message_id': None,
    }
    candidates.append(candidate)

for c in candidates:
    print(json.dumps(c))
"
}

cmd_stale_check() {
  local json_out=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --json) json_out=1; shift ;;
      *) printf 'unknown arg: %s\n' "$1" >&2; return 2 ;;
    esac
  done
  if [[ ! -f "$FUCKUP_LOG" ]]; then
    printf '{"status":"error","reason":"fuckup_log_not_found","path":"%s"}\n' "$FUCKUP_LOG" >&2
    return 1
  fi
  local saturated promoted stale_json stale_count status
  saturated="$(scan_candidates)"
  promoted="$(mktemp "${TMPDIR:-/tmp}/trauma-promoted.XXXXXX")"
  if [[ -f "$OUT_PATH" ]]; then
    TRAUMA_EMITTER_NOW="${TRAUMA_EMITTER_NOW:-}" python3 - "$OUT_PATH" "$WINDOW_HOURS" >"$promoted" <<'PY' || true
import json
import os
import sys
from datetime import datetime, timezone, timedelta

path, window_hours = sys.argv[1], int(sys.argv[2])

def parse_ts(value):
    if not value:
        return None
    for candidate in (str(value), str(value).replace("Z", "+00:00")):
        try:
            parsed = datetime.fromisoformat(candidate)
            if parsed.tzinfo is None:
                parsed = parsed.replace(tzinfo=timezone.utc)
            return parsed.astimezone(timezone.utc)
        except ValueError:
            pass
    return None

now = parse_ts(os.environ.get("TRAUMA_EMITTER_NOW")) or datetime.now(timezone.utc)
cutoff = now - timedelta(hours=window_hours)
classes = set()
with open(path, encoding="utf-8", errors="replace") as handle:
    for line in handle:
        try:
            row = json.loads(line)
        except Exception:
            continue
        cls = row.get("class")
        ts = parse_ts(row.get("ts"))
        if cls and ts and ts >= cutoff:
            classes.add(str(cls))
for cls in sorted(classes):
    print(cls)
PY
  else
    : >"$promoted"
  fi
  stale_json="$(echo "$saturated" | jq -cs --rawfile promoted "$promoted" '
    ($promoted | split("\n") | map(select(length > 0))) as $p
    | [ .[] | select((.class as $c | $p | index($c) | not)) | {class,N,first_seen,last_seen,proposed_memory_path} ]
  ')"
  rm -f "$promoted"
  stale_count="$(echo "$stale_json" | jq 'length')"
  if [[ "$stale_count" -gt 0 ]]; then status="warn"; else status="ok"; fi
  if [[ "$json_out" -eq 1 ]]; then
    jq -nc --arg status "$status" --argjson count "$stale_count" --argjson stale "$stale_json" --arg out "$OUT_PATH" \
      '{status:$status,stale_saturated_class_count:$count,trauma_candidates_path:$out,stale_classes:$stale}'
  else
    printf '%s: %s saturated class(es) lack trauma-candidates row\n' "$status" "$stale_count"
  fi
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
  local args=(--dry-run)
  [[ "$json_out" -eq 1 ]] && args+=(--json)
  cmd_emit "${args[@]}"
}

main() {
  case "${1:-}" in
    --info) shift; emit_info ;;
    --schema) shift; emit_schema ;;
    --examples) shift; emit_examples ;;
    --help|-h|"") usage ;;
    emit) shift; cmd_emit "$@" ;;
    check) shift; cmd_check "$@" ;;
    stale-check) shift; cmd_stale_check "$@" ;;
    doctor|health) shift; emit_doctor ;;
    *) printf 'unknown subcommand: %s\n' "$1" >&2; usage >&2; return 2 ;;
  esac
}

main "$@"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
