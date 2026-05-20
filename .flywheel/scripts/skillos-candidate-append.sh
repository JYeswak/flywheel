#!/usr/bin/env bash
# Append a candidate to the flywheel -> skillos accretion bridge.
set -euo pipefail

VERSION="2026-05-03"
PENDING_FILE="${SKILLOS_PENDING_PATH:-$HOME/.local/state/flywheel/skillos-pending-candidates.jsonl}"

candidate_class=""
evidence_path=""
rationale=""
source_repo=""
source_session=""
recipient="unknown"
domain="unknown"
joshua_visible="false"
sla_target=""
json=0
dry_run=0
mode="run"

usage() {
  cat <<'EOF'
Usage: skillos-candidate-append.sh --candidate-class <class> --evidence-path <path> --rationale <text> [options]

Required:
  --candidate-class <class>   jsm-changelog | new-skill-suggestion | drift-detected | client-pattern | trauma-class | best-practice-gap
  --evidence-path <path>      /tmp artifact, fuckup-log:<row>, mission-lock:<id>, or equivalent evidence reference
  --rationale <text>          One-line reason this should route to skillos

Options:
  --source-repo <path>        Source repository. Defaults to current real path.
  --source-session <name>     Source NTM session. Defaults to NTM_SESSION, FLYWHEEL_SESSION, or unknown.
  --recipient <target>        existing-skill:<skill-id> | new-skill-suggestion | doctrine-only | unknown
  --domain <name>             Domain hint, e.g. auth, frontend, doctrine, unknown.
  --joshua-visible [bool]     true/false. Defaults false. Bare flag means true.
  --sla-target <iso>          Expected routing-decision deadline. Defaults to UTC now + 24h.
  --dry-run                   Validate and print row without appending.
  --json                      Machine-readable output.
  --info                      Print version, paths, env defaults, and exit codes.
  --examples                  Print usage examples.
  --schema                    Emit the candidate envelope schema.
  --no-color                  Accepted for deterministic logs.
  --no-emoji                  Accepted for deterministic logs.
  --width <n>                 Accepted for deterministic logs.

Exit codes:
  0 success, dry-run, info, examples, or schema
  1 invalid envelope
  2 usage error
EOF
}

examples() {
  cat <<'EOF'
# Trauma class with no matching skill coverage
skillos-candidate-append.sh \
  --candidate-class trauma-class \
  --evidence-path fuckup-log:185 \
  --rationale "3 events of ntm-dispatch-drift; no existing skill coverage" \
  --recipient new-skill-suggestion \
  --domain ntm \
  --joshua-visible true

# Mission-lock skills gap, dry-run JSON
skillos-candidate-append.sh \
  --candidate-class best-practice-gap \
  --evidence-path mission-lock:2026-05-03T02:15Z \
  --rationale "mission-lock needed best-practices for HIPAA auth; library returned 0 matches" \
  --recipient new-skill-suggestion \
  --domain auth \
  --dry-run --json
EOF
}

schema() {
  cat <<'EOF'
{
  "type": "object",
  "required": ["ts", "source_session", "source_repo", "candidate_class", "evidence_path", "recipient", "domain", "rationale", "joshua_visible", "sla_target"],
  "properties": {
    "ts": {"type": "string", "format": "date-time"},
    "source_session": {"type": "string"},
    "source_repo": {"type": "string"},
    "candidate_class": {"enum": ["jsm-changelog", "new-skill-suggestion", "drift-detected", "client-pattern", "trauma-class", "best-practice-gap"]},
    "evidence_path": {"type": "string"},
    "recipient": {"type": "string"},
    "domain": {"type": "string"},
    "rationale": {"type": "string"},
    "joshua_visible": {"type": "boolean"},
    "sla_target": {"type": "string", "format": "date-time"}
  }
}
EOF
}

info() {
  if [ "$json" -eq 1 ]; then
    jq -nc --arg version "$VERSION" --arg pending_file "$PENDING_FILE" \
      '{name:"skillos-candidate-append.sh", version:$version, pending_file:$pending_file, exit_codes:{success:0, invalid_envelope:1, usage:2}}'
  else
    cat <<EOF
skillos-candidate-append.sh $VERSION
pending_file=$PENDING_FILE
env_overrides=SKILLOS_PENDING_PATH,NTM_SESSION,FLYWHEEL_SESSION
exit_codes=0 success/dry-run/info/examples/schema; 1 invalid envelope; 2 usage
EOF
  fi
}

die_usage() {
  echo "ERROR: $1" >&2
  usage >&2
  exit 2
}

die_invalid() {
  echo "ERROR: $1" >&2
  exit 1
}

need_value() {
  if [ "$#" -lt 2 ] || [[ "$2" == --* ]]; then
    die_usage "$1 requires a value"
  fi
}

utc_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

utc_plus_24h() {
  if date -u -v+24H +%Y-%m-%dT%H:%M:%SZ >/dev/null 2>&1; then
    date -u -v+24H +%Y-%m-%dT%H:%M:%SZ
  else
    date -u -d '+24 hours' +%Y-%m-%dT%H:%M:%SZ
  fi
}

normalize_bool() {
  case "${1:-false}" in
    true|TRUE|1|yes|YES) printf 'true' ;;
    false|FALSE|0|no|NO) printf 'false' ;;
    *) die_usage "--joshua-visible must be true or false" ;;
  esac
}

valid_class() {
  case "$1" in
    jsm-changelog|new-skill-suggestion|drift-detected|client-pattern|trauma-class|best-practice-gap) return 0 ;;
    *) return 1 ;;
  esac
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --candidate-class=*) candidate_class="${1#*=}"; shift ;;
    --candidate-class) need_value "$@"; candidate_class="$2"; shift 2 ;;
    --evidence-path=*) evidence_path="${1#*=}"; shift ;;
    --evidence-path) need_value "$@"; evidence_path="$2"; shift 2 ;;
    --rationale=*) rationale="${1#*=}"; shift ;;
    --rationale) need_value "$@"; rationale="$2"; shift 2 ;;
    --source-repo=*) source_repo="${1#*=}"; shift ;;
    --source-repo) need_value "$@"; source_repo="$2"; shift 2 ;;
    --source-session=*) source_session="${1#*=}"; shift ;;
    --source-session) need_value "$@"; source_session="$2"; shift 2 ;;
    --recipient=*) recipient="${1#*=}"; shift ;;
    --recipient) need_value "$@"; recipient="$2"; shift 2 ;;
    --domain=*) domain="${1#*=}"; shift ;;
    --domain) need_value "$@"; domain="$2"; shift 2 ;;
    --joshua-visible=*) joshua_visible="${1#*=}"; shift ;;
    --joshua-visible)
      if [ "$#" -ge 2 ] && [[ "$2" != --* ]]; then
        joshua_visible="$2"
        shift 2
      else
        joshua_visible="true"
        shift
      fi
      ;;
    --sla-target=*) sla_target="${1#*=}"; shift ;;
    --sla-target) need_value "$@"; sla_target="$2"; shift 2 ;;
    --dry-run) dry_run=1; shift ;;
    --json) json=1; shift ;;
    --info) mode="info"; shift ;;
    --examples) mode="examples"; shift ;;
    --schema) mode="schema"; shift ;;
    --no-color|--no-emoji) shift ;;
    --width=*) shift ;;
    --width) need_value "$@"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) die_usage "unknown argument: $1" ;;
  esac
done

if [ "$mode" = "info" ]; then
  if [ "$json" -eq 1 ]; then
    command -v jq >/dev/null 2>&1 || die_usage "jq is required for --json"
  fi
  info
  exit 0
fi
if [ "$mode" = "examples" ]; then
  examples
  exit 0
fi
if [ "$mode" = "schema" ]; then
  schema
  exit 0
fi

command -v jq >/dev/null 2>&1 || die_usage "jq is required"
[ -n "$candidate_class" ] || die_usage "--candidate-class is required"
[ -n "$evidence_path" ] || die_usage "--evidence-path is required"
[ -n "$rationale" ] || die_usage "--rationale is required"
valid_class "$candidate_class" || die_usage "invalid --candidate-class: $candidate_class"

if [ -z "$source_repo" ]; then
  source_repo="$(pwd -P)"
fi
if [ -z "$source_session" ]; then
  source_session="${NTM_SESSION:-${FLYWHEEL_SESSION:-unknown}}"
fi
if [ -z "$sla_target" ]; then
  sla_target="$(utc_plus_24h)"
fi

joshua_visible_json="$(normalize_bool "$joshua_visible")"
ts="$(utc_now)"

row="$(jq -nc \
  --arg ts "$ts" \
  --arg source_session "$source_session" \
  --arg source_repo "$source_repo" \
  --arg candidate_class "$candidate_class" \
  --arg evidence_path "$evidence_path" \
  --arg recipient "$recipient" \
  --arg domain "$domain" \
  --arg rationale "$rationale" \
  --argjson joshua_visible "$joshua_visible_json" \
  --arg sla_target "$sla_target" \
  '{ts:$ts,source_session:$source_session,source_repo:$source_repo,candidate_class:$candidate_class,evidence_path:$evidence_path,recipient:$recipient,domain:$domain,rationale:$rationale,joshua_visible:$joshua_visible,sla_target:$sla_target}')"

printf '%s' "$row" | jq -e '
  (.ts|type=="string" and length>0) and
  (.source_session|type=="string" and length>0) and
  (.source_repo|type=="string" and length>0) and
  (.candidate_class|type=="string" and length>0) and
  (.evidence_path|type=="string" and length>0) and
  (.recipient|type=="string" and length>0) and
  (.domain|type=="string" and length>0) and
  (.rationale|type=="string" and length>0) and
  (.joshua_visible|type=="boolean") and
  (.sla_target|type=="string" and length>0)
' >/dev/null || die_invalid "candidate envelope failed schema validation"

if [ "$dry_run" -eq 1 ]; then
  if [ "$json" -eq 1 ]; then
    jq -nc --arg path "$PENDING_FILE" --argjson row "$row" '{status:"dry_run", would_write:$path, row:$row}'
  else
    printf '%s\n' "$row"
  fi
  exit 0
fi

mkdir -p "$(dirname "$PENDING_FILE")"
printf '%s\n' "$row" >> "$PENDING_FILE"

if [ "$json" -eq 1 ]; then
  jq -nc --arg path "$PENDING_FILE" --argjson row "$row" '{status:"appended", path:$path, row:$row}'
else
  printf 'Appended skillos candidate: %s -> %s\n' "$candidate_class" "$PENDING_FILE"
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-03-agent-ergonomics-rubric.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-58-agent-tool-theory-of-mind.md`
