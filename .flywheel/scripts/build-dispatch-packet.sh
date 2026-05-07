#!/usr/bin/env bash
# build-dispatch-packet.sh — materialize a canonical dispatch packet from a bead.
#
# One-stock-two-flows: BOTH /flywheel:dispatch (operator) AND
# ntm-coordinator-pinned daemon (auto) call this primitive so workers receive
# IDENTICAL packets regardless of dispatch path.
#
# Mission anchor: continuous-orchestrator-uptime-self-sustaining-fleet
# Bead: flywheel-hctfn (T3B)
# Donella: #4 self-organization, #3 goal — one canonical stock for dispatch
#          packets eliminates the 2-stock divergence between operator-fired and
#          coordinator-daemon-fired dispatches.
#
# Canonical-cli-scoping: --dry-run (default) | --apply | --json | --explain
#                        --info | --examples | --schema | --help
#
# Exit codes:
#   0  ok
#   1  bad args / usage
#   2  bead not found / br error
#   3  topology lookup failed
#   4  template missing
#   5  contract validation fail (packet missing required block)

set -euo pipefail

VERSION="0.1.0"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
SHARED_DIR="${HOME}/.claude/commands/flywheel/_shared"
TEMPLATE_FILE="$SHARED_DIR/dispatch-template.md"
TOPOLOGY="${FLYWHEEL_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
JOSH_REQUESTS="${FLYWHEEL_JOSH_REQUESTS:-$HOME/.local/state/flywheel/josh-requests.jsonl}"
IDENTITY_DIR="${FLYWHEEL_IDENTITY_DIR:-$HOME/.local/state/flywheel/orch-worker-identity}"

usage() {
  cat <<EOF
build-dispatch-packet.sh v${VERSION} — materialize canonical dispatch packet

USAGE:
  build-dispatch-packet.sh --bead-id <id> --target-pane <N> --target-session <name> [flags]

REQUIRED:
  --bead-id <id>           Bead ID (e.g. flywheel-abc)
  --target-pane <N>        Target worker pane index
  --target-session <name>  Target session (e.g. flywheel)

OPTIONAL:
  --task-id <id>           Override task id (default: <bead-id>-<short-ts>)
  --dispatch-channel <c>   auto | operator (default: operator)
  --output-dir <path>      Where to write packet (default: /tmp)
  --apply                  Materialize the packet (default: dry-run preview)
  --dry-run                Preview only, no file write (DEFAULT)
  --json                   JSON output (path + sha256 + validation)

INTROSPECTION:
  --explain                Design rationale + Donella + canonical-cli-scoping
  --info                   Version, paths, contract source
  --examples               Worked invocations
  --schema                 JSON output schema
  -h, --help               This help

EXIT CODES:
  0 ok | 1 bad args | 2 bead lookup fail | 3 topology fail | 4 template missing | 5 contract validation fail
EOF
}

explain() {
  cat <<'EOF'
EXPLAIN:
Workers receive dispatch packets from two paths today:
  (A) /flywheel:dispatch — operator-fired, hand-built packet with all 20+
      contract blocks from _shared/dispatch-template.md
  (B) ntm-coordinator-pinned daemon — auto-fired, minimal 16-line template
      pointing at /flywheel:worker-tick

These two stocks diverge. Workers from path (B) miss josh_request_id,
identity_name, skill auto-routes, file discipline, etc. Donella #6 (information
flow) breaks because the same logical work flows differently by accident of
who fired it.

THIS SCRIPT collapses both paths to ONE materialized stock:
- (A) /flywheel:dispatch becomes a thin wrapper: build-dispatch-packet → ntm send
- (B) coordinator daemon's hook builds the packet pre-dispatch; minimal
      template degrades to "Read /tmp/dispatch_<bead>.md"

Donella read: #4 self-organization (system produces correct packet without
operator vs daemon awareness), #3 goal (single canonical packet shape), #6
information flow (workers get the same instructions every time).

Canonical-cli-scoping: dry-run default refuses to mutate; --apply opens the
write path; structured exit codes; --schema for machine integration.
EOF
}

info() {
  cat <<EOF
INFO:
  version          = $VERSION
  template         = $TEMPLATE_FILE
  topology         = $TOPOLOGY
  josh_requests    = $JOSH_REQUESTS
  identity_dir     = $IDENTITY_DIR
  shared_helpers   = $SHARED_DIR
  inject_memory    = $SHARED_DIR/inject-memory-hits.sh
  inject_skills    = $SHARED_DIR/inject-skill-auto-routes.sh
  bead_id_prefix   = (resolved per --target-session via topology)
EOF
}

examples() {
  cat <<'EOF'
EXAMPLES:
  # operator-fired dispatch (default)
  build-dispatch-packet.sh --bead-id flywheel-abc --target-pane 2 --target-session flywheel --apply

  # coordinator-daemon hook (auto channel)
  build-dispatch-packet.sh --bead-id flywheel-abc --target-pane 2 --target-session flywheel \
    --dispatch-channel auto --apply --json

  # preview without writing
  build-dispatch-packet.sh --bead-id flywheel-abc --target-pane 2 --target-session flywheel --dry-run

  # introspect contract
  build-dispatch-packet.sh --schema
EOF
}

schema() {
  cat <<'EOF'
{
  "title": "build-dispatch-packet output (--json)",
  "type": "object",
  "required": ["packet_path", "packet_sha256", "validation_status", "fields_resolved", "schema_version"],
  "properties": {
    "schema_version":  {"const": "build-dispatch-packet.v1"},
    "packet_path":     {"type": "string", "pattern": "^/.+\\.md$"},
    "packet_sha256":   {"type": "string", "pattern": "^[0-9a-f]{64}$"},
    "validation_status": {"enum": ["pass", "fail", "dry-run"]},
    "validation_blocks_present": {"type": "array", "items": {"type": "string"}},
    "validation_blocks_missing": {"type": "array", "items": {"type": "string"}},
    "fields_resolved": {"type": "object",
      "properties": {
        "task_id": {"type": "string"},
        "bead_id": {"type": "string"},
        "target_pane": {"type": "integer"},
        "target_session": {"type": "string"},
        "callback_pane": {"type": "integer"},
        "mission_anchor": {"type": ["string","null"]},
        "mission_fitness_class": {"type": ["string","null"]},
        "josh_request_id": {"type": ["string","null"]},
        "identity_name": {"type": ["string","null"]},
        "dispatch_channel": {"enum": ["auto", "operator"]},
        "memory_hits_count": {"type": "integer"},
        "skill_auto_routes_count": {"type": "integer"}
      }
    }
  }
}
EOF
}

# ─── arg parse ───────────────────────────────────────────────────────────────
BEAD_ID=""
TARGET_PANE=""
TARGET_SESSION=""
TASK_ID=""
DISPATCH_CHANNEL="operator"
OUTPUT_DIR="/tmp"
MODE="dry-run"
JSON_OUT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bead-id) BEAD_ID="$2"; shift 2 ;;
    --target-pane) TARGET_PANE="$2"; shift 2 ;;
    --target-session) TARGET_SESSION="$2"; shift 2 ;;
    --task-id) TASK_ID="$2"; shift 2 ;;
    --dispatch-channel) DISPATCH_CHANNEL="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --apply) MODE="apply"; shift ;;
    --dry-run) MODE="dry-run"; shift ;;
    --json) JSON_OUT=true; shift ;;
    --help|-h) usage; exit 0 ;;
    --explain) explain; exit 0 ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --schema) schema; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage >&2; exit 1 ;;
  esac
done

[[ -z "$BEAD_ID" ]] && { echo "ERROR: --bead-id required" >&2; exit 1; }
[[ -z "$TARGET_PANE" ]] && { echo "ERROR: --target-pane required" >&2; exit 1; }
[[ -z "$TARGET_SESSION" ]] && { echo "ERROR: --target-session required" >&2; exit 1; }
[[ -r "$TEMPLATE_FILE" ]] || { echo "ERROR: template missing: $TEMPLATE_FILE" >&2; exit 4; }

[[ -z "$TASK_ID" ]] && TASK_ID="${BEAD_ID}-$(date -u +%s | shasum | cut -c1-6)"

# ─── resolve dynamic fields ──────────────────────────────────────────────────
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Callback pane from topology (latest-wins)
CALLBACK_PANE=$(jq -sr --arg s "$TARGET_SESSION" '
  map(select(.session == $s))
  | sort_by(.effective_at) | last
  | (.callback_pane // .orchestrator_pane // 1)
' "$TOPOLOGY" 2>/dev/null || echo "1")
[[ "$CALLBACK_PANE" == "null" ]] && CALLBACK_PANE=1

# Mission anchor + fitness from .flywheel/MISSION.md (best-effort)
MISSION_ANCHOR="continuous-orchestrator-uptime-self-sustaining-fleet"
MISSION_FILE="$REPO_ROOT/.flywheel/MISSION.md"
if [[ -r "$MISSION_FILE" ]]; then
  EXTRACTED=$(grep -E "^anchor:|^mission_anchor:|^## Mission Anchor" "$MISSION_FILE" 2>/dev/null | head -1 | sed 's/^[^:]*:[[:space:]]*//' | tr -d '\n' || true)
  if [[ -n "${EXTRACTED:-}" ]]; then MISSION_ANCHOR="$EXTRACTED"; fi
fi
MISSION_FITNESS_CLASS="adjacent"
MISSION_FITNESS_CLAIM="Bead $BEAD_ID advances substrate work supporting the mission anchor."

# Bead body via br show — br emits an array even for single bead
BEAD_JSON=$(br show "$BEAD_ID" --json 2>/dev/null || echo '[]')
BEAD_TITLE=$(echo "$BEAD_JSON" | jq -r 'if type=="array" then .[0].title // "" else .title // "" end' 2>/dev/null || echo "")
BEAD_BODY=$(echo "$BEAD_JSON" | jq -r 'if type=="array" then (.[0].description // .[0].body // "") else (.description // .body // "") end' 2>/dev/null || echo "")
BEAD_PRIORITY=$(echo "$BEAD_JSON" | jq -r 'if type=="array" then (.[0].priority // 99) else (.priority // 99) end' 2>/dev/null || echo 99)
if [[ -z "$BEAD_TITLE" ]]; then echo "ERROR: bead $BEAD_ID not found via br show" >&2; exit 2; fi

# Bead deps
BEAD_DEPS=$(br dep tree "$BEAD_ID" --json 2>/dev/null | jq -r '. | tostring' 2>/dev/null || echo '{}')

# Josh request linkage (lookup; null if none)
JOSH_REQUEST_ID="null"
if [[ -r "$JOSH_REQUESTS" ]]; then
  MATCH=$(jq -sr --arg b "$BEAD_ID" '
    map(select(.linked_bead_ids // [] | index($b)))
    | sort_by(.captured_at) | last
    | (.id // "null")
  ' "$JOSH_REQUESTS" 2>/dev/null || echo "null")
  if [[ -n "${MATCH:-}" && "$MATCH" != "null" ]]; then JOSH_REQUEST_ID="$MATCH"; fi
fi

# Worker identity from manifest
IDENTITY_NAME="null"
IDENTITY_STATUS="needs_registration"
IDENTITY_FILE="$IDENTITY_DIR/${TARGET_SESSION}.json"
if [[ -r "$IDENTITY_FILE" ]]; then
  IDENT_JSON=$(jq -r --argjson p "$TARGET_PANE" '
    .workers[]? | select(.pane == $p) | {name: .fleet_mail_identity, status: .registration_status}
  ' "$IDENTITY_FILE" 2>/dev/null || echo '{}')
  IDENTITY_NAME=$(echo "$IDENT_JSON" | jq -r '.name // "null"')
  IDENTITY_STATUS=$(echo "$IDENT_JSON" | jq -r '.status // "needs_registration"')
fi

# ─── compose packet ──────────────────────────────────────────────────────────
PACKET_FILE="$OUTPUT_DIR/dispatch_${TASK_ID}.md"
TMP_BODY=$(mktemp -t dispatch-body.XXXXXX)
trap 'rm -f "$TMP_BODY"' EXIT

# Write the task body that workers receive
cat > "$TMP_BODY" <<EOF
# DISPATCH PACKET (canonical)
# Task ID: ${TASK_ID}
# Bead: ${BEAD_ID} (P${BEAD_PRIORITY})
# Title: ${BEAD_TITLE}
# Target: ${TARGET_SESSION}:0.${TARGET_PANE}
# Callback pane: ${CALLBACK_PANE}
# Dispatch channel: ${DISPATCH_CHANNEL}
# Identity: ${IDENTITY_NAME} (status=${IDENTITY_STATUS})
# Started: ${NOW}

## CALLBACK CONTRACT

When complete, send EXACTLY ONE of:

\`\`\`
/Users/josh/.local/bin/ntm send ${TARGET_SESSION} --pane=${CALLBACK_PANE} --no-cass-check "DONE ${BEAD_ID} task_id=${TASK_ID} josh_request_id=${JOSH_REQUEST_ID} did=<n>/<total> didnt=<bead-ids-or-none> gaps=<bead-ids-or-none> evidence=<path> tests=PASS|FAIL|SKIPPED mission_fitness=direct|adjacent|infrastructure|drift br_close_executed=yes|failed|not_applicable four_lens=brand:N,sniff:N,jeff:N,public:N callback_delivery_verified=true"
\`\`\`

If blocked: \`BLOCKED ${TASK_ID} reason=<short> need=<short> mission_fitness=<class> josh_request_id=${JOSH_REQUEST_ID}\`
If declining: \`DECLINED ${TASK_ID} reason=<scope-mismatch|capability|risk> mission_fitness=drift josh_request_id=${JOSH_REQUEST_ID}\`

## MISSION FITNESS CLAIM BLOCK

\`\`\`text
mission_anchor=${MISSION_ANCHOR}
mission_fitness_claim=${MISSION_FITNESS_CLAIM}
mission_fitness_class=${MISSION_FITNESS_CLASS}
\`\`\`

Workers MUST echo \`mission_fitness=<direct|adjacent|infrastructure|drift>\` in the DONE callback.

## JOSH REQUEST LINKAGE BLOCK

\`\`\`text
josh_request_id=${JOSH_REQUEST_ID}
\`\`\`

DONE/BLOCKED/DECLINED callbacks MUST include the same field and value verbatim.

## LOCKED WORKER IDENTITY BLOCK

\`\`\`text
identity_name=${IDENTITY_NAME}
identity_source=${IDENTITY_FILE}
worker_identity=${IDENTITY_NAME}
worker_identity_status=${IDENTITY_STATUS}
\`\`\`

If \`worker_identity_status=needs_registration\`, dispatch wrapper triggered registration before this packet was sent.

## SHARED-SURFACE RESERVATION BLOCK (L107)

Before staging shared paths (commit-touched files), reserve:
\`\`\`bash
.flywheel/scripts/shared-surface-reservation-check.sh --reserve <path> --pane=${TARGET_PANE} --task-id=${TASK_ID} --json
\`\`\`
Release after commit. Worker callback MUST include \`shared_surface_reservations_checked=yes shared_surface_reservations_released=yes\`.

## FILE DISCIPLINE (PICOZ_WORKER_FILES)

Edit ONLY files named in this packet's TASK BODY or files explicitly named in the bead body. Other edits require an in-band ntm message asking for scope expansion BEFORE the edit.

## VERIFICATION (pre-DONE)

Run verification commands from bead acceptance section if present. If none, run:
\`\`\`bash
bash -n <any-edited-shell-script>
br show ${BEAD_ID}  # confirm bead state
\`\`\`

## DID / DIDNT / GAPS BLOCK (L80)

Worker DONE callback MUST include:
- \`did=<count>/<total-bead-acceptance-criteria>\`
- \`didnt=<bead-ids-skipped-or-none>\`
- \`gaps=<bead-ids-newly-discovered-or-none>\`

## FOUR-LENS SELF-GRADE BLOCK

Score 1-10 each:
- \`brand\` (zest brand voice consistency)
- \`sniff\` (smell test — does this look right)
- \`jeff\` (Jeff Emanuel substrate alignment)
- \`public\` (would I show this to a stranger)

Echo as \`four_lens=brand:N,sniff:N,jeff:N,public:N\` in DONE callback.

## L61 ECOSYSTEM-TOUCH BLOCK

If this work touches doctrine|INCIDENTS|canonical|L-rule|skill, callback MUST include:
- \`agents_md_updated=yes|no\`
- \`readme_updated=yes|no\`
- \`no_touch_reason=<reason>\` (when either is \`no\`)

## L120 BR-CLOSE-EXECUTED BLOCK

DONE callback MUST include \`br_close_executed=yes|failed|not_applicable\`.
\`yes\` requires \`br close ${BEAD_ID}\` exited 0 BEFORE the ntm send DONE.

## TASK BODY (bead context)

### Title
${BEAD_TITLE}

### Description
${BEAD_BODY}

### Dependencies
\`\`\`json
${BEAD_DEPS}
\`\`\`

### Priority
P${BEAD_PRIORITY}

## EXECUTION

1. Read this entire packet
2. Run \`br show ${BEAD_ID}\` to confirm context
3. Run \`br dep tree ${BEAD_ID}\` to see dependencies
4. Apply socraticode K≥10 if non-trivial code claim involved
5. Reserve any shared paths via L107 script before edits
6. Execute the bead acceptance criteria
7. Run verification
8. \`br close ${BEAD_ID}\` (BEFORE callback per L120)
9. Send DONE callback per CALLBACK CONTRACT above

## METADATA

\`\`\`text
schema_version=dispatch-packet.v1
packet_built_by=build-dispatch-packet.sh@${VERSION}
packet_built_at=${NOW}
dispatch_channel=${DISPATCH_CHANNEL}
\`\`\`
EOF

# ─── inject memory hits + skill auto-routes (if helpers available) ───────────
AUGMENTED_BODY="$TMP_BODY"
if [[ -x "$SHARED_DIR/inject-memory-hits.sh" ]]; then
  MEM_OUT="${TMP_BODY}.mem"
  if "$SHARED_DIR/inject-memory-hits.sh" "$TMP_BODY" "$TASK_ID" "$BEAD_ID" "$REPO_ROOT" > "$MEM_OUT" 2>/dev/null; then
    AUGMENTED_BODY="$MEM_OUT"
  fi
fi
if [[ -x "$SHARED_DIR/inject-skill-auto-routes.sh" ]]; then
  ROUTED_OUT="${AUGMENTED_BODY}.routed"
  if "$SHARED_DIR/inject-skill-auto-routes.sh" "$AUGMENTED_BODY" "$TASK_ID" > "$ROUTED_OUT" 2>/dev/null; then
    AUGMENTED_BODY="$ROUTED_OUT"
  fi
fi

# Memory hit count
MEMORY_HITS=$(grep -c "^- " "$AUGMENTED_BODY" 2>/dev/null | tr -d '\n' || echo 0)
SKILL_ROUTES=$(grep -c "^Skill:" "$AUGMENTED_BODY" 2>/dev/null | tr -d '\n' || echo 0)
[[ -z "$MEMORY_HITS" || ! "$MEMORY_HITS" =~ ^[0-9]+$ ]] && MEMORY_HITS=0
[[ -z "$SKILL_ROUTES" || ! "$SKILL_ROUTES" =~ ^[0-9]+$ ]] && SKILL_ROUTES=0

# ─── validate contract blocks present ───────────────────────────────────────
REQUIRED_BLOCKS=(
  "CALLBACK CONTRACT"
  "MISSION FITNESS CLAIM BLOCK"
  "JOSH REQUEST LINKAGE BLOCK"
  "LOCKED WORKER IDENTITY BLOCK"
  "SHARED-SURFACE RESERVATION BLOCK"
  "FILE DISCIPLINE"
  "VERIFICATION"
  "DID / DIDNT / GAPS BLOCK"
  "FOUR-LENS SELF-GRADE BLOCK"
  "L61 ECOSYSTEM-TOUCH BLOCK"
  "L120 BR-CLOSE-EXECUTED BLOCK"
  "TASK BODY"
  "EXECUTION"
)
PRESENT=()
MISSING=()
for block in "${REQUIRED_BLOCKS[@]}"; do
  if grep -q "^## ${block}" "$AUGMENTED_BODY"; then
    PRESENT+=("$block")
  else
    MISSING+=("$block")
  fi
done

VALIDATION="pass"
[[ ${#MISSING[@]} -gt 0 ]] && VALIDATION="fail"

# ─── write packet ────────────────────────────────────────────────────────────
if [[ "$MODE" == "apply" ]]; then
  cp "$AUGMENTED_BODY" "$PACKET_FILE"
  PACKET_SHA=$(shasum -a 256 "$PACKET_FILE" | awk '{print $1}')
else
  PACKET_SHA=$(shasum -a 256 "$AUGMENTED_BODY" | awk '{print $1}')
  VALIDATION="dry-run"
fi

# ─── output ──────────────────────────────────────────────────────────────────
if $JSON_OUT; then
  jq -nc \
    --arg packet "$PACKET_FILE" \
    --arg sha "$PACKET_SHA" \
    --arg vstatus "$VALIDATION" \
    --arg task "$TASK_ID" \
    --arg bead "$BEAD_ID" \
    --argjson tpane "$TARGET_PANE" \
    --arg tsess "$TARGET_SESSION" \
    --argjson cpane "$CALLBACK_PANE" \
    --arg manchor "$MISSION_ANCHOR" \
    --arg mclass "$MISSION_FITNESS_CLASS" \
    --arg jrid "$JOSH_REQUEST_ID" \
    --arg ident "$IDENTITY_NAME" \
    --arg chan "$DISPATCH_CHANNEL" \
    --argjson memhits "$MEMORY_HITS" \
    --argjson skillroutes "$SKILL_ROUTES" \
    --argjson present "$(printf '%s\n' "${PRESENT[@]}" | jq -R . | jq -s .)" \
    --argjson missing "$(printf '%s\n' "${MISSING[@]}" | jq -R . | jq -s .)" \
    '{
      schema_version: "build-dispatch-packet.v1",
      packet_path: $packet,
      packet_sha256: $sha,
      validation_status: $vstatus,
      validation_blocks_present: $present,
      validation_blocks_missing: $missing,
      fields_resolved: {
        task_id: $task,
        bead_id: $bead,
        target_pane: $tpane,
        target_session: $tsess,
        callback_pane: $cpane,
        mission_anchor: $manchor,
        mission_fitness_class: $mclass,
        josh_request_id: (if $jrid == "null" then null else $jrid end),
        identity_name: (if $ident == "null" then null else $ident end),
        dispatch_channel: $chan,
        memory_hits_count: $memhits,
        skill_auto_routes_count: $skillroutes
      }
    }'
else
  echo "packet:    $PACKET_FILE"
  echo "sha256:    $PACKET_SHA"
  echo "validation: $VALIDATION (${#PRESENT[@]}/${#REQUIRED_BLOCKS[@]} blocks present)"
  [[ ${#MISSING[@]} -gt 0 ]] && echo "missing:   ${MISSING[*]}"
  echo "channel:   $DISPATCH_CHANNEL"
  echo "task_id:   $TASK_ID"
  echo "bead_id:   $BEAD_ID"
  echo "target:    ${TARGET_SESSION}:0.${TARGET_PANE} (callback=${CALLBACK_PANE})"
  echo "identity:  $IDENTITY_NAME ($IDENTITY_STATUS)"
fi

[[ "$VALIDATION" == "fail" ]] && exit 5
exit 0
