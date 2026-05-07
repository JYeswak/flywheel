#!/usr/bin/env bash
set -euo pipefail

VERSION="0.2.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
SHARED_DIR="${HOME}/.claude/commands/flywheel/_shared"
TEMPLATE_FILE="$SHARED_DIR/dispatch-template.md"
TOPOLOGY="${FLYWHEEL_TOPOLOGY:-$HOME/.local/state/flywheel/session-topology.jsonl}"
JOSH_REQUESTS="${FLYWHEEL_JOSH_REQUESTS:-$HOME/.local/state/flywheel/josh-requests.jsonl}"
IDENTITY_DIR="${FLYWHEEL_IDENTITY_DIR:-$HOME/.local/state/flywheel/orch-worker-identity}"
NTM_BIN="${FLYWHEEL_NTM_BIN:-/Users/josh/.local/bin/ntm}"

usage() {
  cat <<EOF
build-dispatch-packet.sh v${VERSION} - materialize canonical dispatch packet

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
  --apply                  Materialize packet (default: dry-run preview)
  --dry-run                Preview only, no file write (default)
  --json                   JSON output

INTROSPECTION:
  --explain | --info | --examples | --schema | -h, --help

EXIT CODES:
  0 ok | 1 bad args | 2 bead lookup fail | 3 ntm/context/topology fail | 4 template missing | 5 contract validation fail
EOF
}

explain() { printf '%s\n' "EXPLAIN:" "Single materializer for operator and daemon dispatch. Flywheel doctrine blocks stay local; task context/template mechanics come from NTM JSON: context build --json and template show marching_orders --body --json. Dry-run default, --apply mutation gate, --json schema, and stable exit codes remain per canonical-cli-scoping."; }
info() { printf 'INFO:\n  version        = %s\n  ntm_bin        = %s\n  ntm_context    = ntm context build --json\n  ntm_template   = ntm template show marching_orders --body --json\n  contract_ref   = %s\n  topology       = %s\n  josh_requests  = %s\n  identity_dir   = %s\n' "$VERSION" "$NTM_BIN" "$TEMPLATE_FILE" "$TOPOLOGY" "$JOSH_REQUESTS" "$IDENTITY_DIR"; }
examples() { printf '%s\n' "EXAMPLES:" "  build-dispatch-packet.sh --bead-id flywheel-abc --target-pane 2 --target-session flywheel --apply" "  build-dispatch-packet.sh --bead-id flywheel-abc --target-pane 2 --target-session flywheel --dispatch-channel auto --apply --json" "  build-dispatch-packet.sh --bead-id flywheel-abc --target-pane 2 --target-session flywheel --dry-run" "  build-dispatch-packet.sh --schema"; }
schema() { printf '%s\n' '{"title":"build-dispatch-packet output (--json)","type":"object","required":["packet_path","packet_sha256","validation_status","fields_resolved","schema_version"],"properties":{"schema_version":{"const":"build-dispatch-packet.v1"},"packet_path":{"type":"string"},"packet_sha256":{"type":"string","pattern":"^[0-9a-f]{64}$"},"validation_status":{"enum":["pass","fail","dry-run"]},"validation_blocks_present":{"type":"array","items":{"type":"string"}},"validation_blocks_missing":{"type":"array","items":{"type":"string"}},"fields_resolved":{"type":"object"}}}'; }

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }
jq_get() { jq -r "$1 // \"\"" 2>/dev/null; }
json_array() {
  if [[ "$#" -eq 0 ]]; then echo "[]"; else printf '%s\n' "$@" | jq -R . | jq -s .; fi
}

BEAD_ID="" TARGET_PANE="" TARGET_SESSION="" TASK_ID=""
DISPATCH_CHANNEL="operator" OUTPUT_DIR="/tmp" MODE="dry-run" JSON_OUT=false
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
    --explain) explain; exit 0 ;;
    --info) info; exit 0 ;;
    --examples) examples; exit 0 ;;
    --schema) schema; exit 0 ;;
    --help|-h) usage; exit 0 ;;
    *) usage >&2; die "unknown arg: $1" 1 ;;
  esac
done

[[ -n "$BEAD_ID" ]] || die "--bead-id required" 1
[[ -n "$TARGET_PANE" ]] || die "--target-pane required" 1
[[ -n "$TARGET_SESSION" ]] || die "--target-session required" 1
[[ -r "$TEMPLATE_FILE" ]] || die "template missing: $TEMPLATE_FILE" 4
[[ -x "$NTM_BIN" ]] || die "ntm not executable: $NTM_BIN" 3
[[ -z "$TASK_ID" ]] && TASK_ID="${BEAD_ID}-$(date -u +%s | shasum | cut -c1-6)"
NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

CALLBACK_PANE="$(jq -sr --arg s "$TARGET_SESSION" 'map(select(.session == $s)) | sort_by(.effective_at) | last | (.callback_pane // .orchestrator_pane // 1)' "$TOPOLOGY" 2>/dev/null || echo 1)"
[[ "$CALLBACK_PANE" == "null" || -z "$CALLBACK_PANE" ]] && CALLBACK_PANE=1

MISSION_ANCHOR="continuous-orchestrator-uptime-self-sustaining-fleet"
MISSION_FILE="$REPO_ROOT/.flywheel/MISSION.md"
if [[ -r "$MISSION_FILE" ]]; then
  EXTRACTED="$(grep -E '^anchor:|^mission_anchor:' "$MISSION_FILE" 2>/dev/null | head -1 | sed 's/^[^:]*:[[:space:]]*//' || true)"
  [[ -n "${EXTRACTED:-}" ]] && MISSION_ANCHOR="$EXTRACTED"
fi
MISSION_FITNESS_CLASS="adjacent"
MISSION_FITNESS_CLAIM="Bead $BEAD_ID advances substrate work supporting the mission anchor."

BEAD_JSON="$(br show "$BEAD_ID" --json 2>/dev/null || echo '[]')"
BEAD_TITLE="$(echo "$BEAD_JSON" | jq_get 'if type=="array" then .[0].title else .title end')"
BEAD_BODY="$(echo "$BEAD_JSON" | jq_get 'if type=="array" then (.[0].description // .[0].body) else (.description // .body) end')"
BEAD_PRIORITY="$(echo "$BEAD_JSON" | jq_get 'if type=="array" then (.[0].priority // 99) else (.priority // 99) end')"
[[ -n "$BEAD_TITLE" ]] || die "bead $BEAD_ID not found via br show" 2
BEAD_DEPS="$(br dep tree "$BEAD_ID" --json 2>/dev/null | jq -r '. | tostring' 2>/dev/null || echo '{}')"

NTM_CONTEXT_JSON="$("$NTM_BIN" context build --bead "$BEAD_ID" --task "$BEAD_TITLE" --files "$SCRIPT_DIR/build-dispatch-packet.sh" --agent cod --json 2>/dev/null || true)"
echo "$NTM_CONTEXT_JSON" | jq -e . >/dev/null 2>&1 || die "ntm context build --json failed" 3
NTM_TEMPLATE_JSON="$("$NTM_BIN" template show marching_orders --body --json 2>/dev/null || true)"
echo "$NTM_TEMPLATE_JSON" | jq -e . >/dev/null 2>&1 || die "ntm template show --json failed" 4
NTM_CONTEXT_ID="$(echo "$NTM_CONTEXT_JSON" | jq_get '.id')"
NTM_CONTEXT_REV="$(echo "$NTM_CONTEXT_JSON" | jq_get '.repo_rev')"
NTM_CONTEXT_TOKENS="$(echo "$NTM_CONTEXT_JSON" | jq_get '.token_count')"
NTM_TEMPLATE_NAME="$(echo "$NTM_TEMPLATE_JSON" | jq_get '.name')"
NTM_TEMPLATE_SOURCE="$(echo "$NTM_TEMPLATE_JSON" | jq_get '.source')"

JOSH_REQUEST_ID="null"
if [[ -r "$JOSH_REQUESTS" ]]; then
  MATCH="$(jq -sr --arg b "$BEAD_ID" 'map(select(.linked_bead_ids // [] | index($b))) | sort_by(.captured_at) | last | (.id // "null")' "$JOSH_REQUESTS" 2>/dev/null || echo null)"
  [[ -n "$MATCH" && "$MATCH" != "null" ]] && JOSH_REQUEST_ID="$MATCH"
fi

IDENTITY_NAME="null" IDENTITY_STATUS="needs_registration"
IDENTITY_FILE="$IDENTITY_DIR/${TARGET_SESSION}.json"
if [[ -r "$IDENTITY_FILE" ]]; then
  IDENT_JSON="$(jq -r --argjson p "$TARGET_PANE" '.workers[]? | select(.pane == $p) | {name:.fleet_mail_identity,status:.registration_status}' "$IDENTITY_FILE" 2>/dev/null || echo '{}')"
  IDENTITY_NAME="$(echo "$IDENT_JSON" | jq_get '.name')"; [[ -z "$IDENTITY_NAME" ]] && IDENTITY_NAME="null"
  IDENTITY_STATUS="$(echo "$IDENT_JSON" | jq_get '.status')"; [[ -z "$IDENTITY_STATUS" ]] && IDENTITY_STATUS="needs_registration"
fi

PACKET_FILE="$OUTPUT_DIR/dispatch_${TASK_ID}.md"
TMP_BODY="$(mktemp -t dispatch-body.XXXXXX)"
trap 'rm -f "$TMP_BODY" "${TMP_BODY}.mem" "${TMP_BODY}.mem.routed" "${TMP_BODY}.routed"' EXIT

{
  printf '# DISPATCH PACKET (canonical)\n# Task ID: %s\n# Bead: %s (P%s)\n# Title: %s\n# Target: %s:0.%s\n# Callback pane: %s\n# Dispatch channel: %s\n# Identity: %s (status=%s)\n# Started: %s\n\n' "$TASK_ID" "$BEAD_ID" "$BEAD_PRIORITY" "$BEAD_TITLE" "$TARGET_SESSION" "$TARGET_PANE" "$CALLBACK_PANE" "$DISPATCH_CHANNEL" "$IDENTITY_NAME" "$IDENTITY_STATUS" "$NOW"
  printf '## CALLBACK CONTRACT\n\nWhen complete, send EXACTLY ONE of:\n\n```\n/Users/josh/.local/bin/ntm send %s --pane=%s --no-cass-check "DONE %s task_id=%s josh_request_id=%s did=<n>/<total> didnt=<bead-ids-or-none> gaps=<bead-ids-or-none> evidence=<path> tests=PASS|FAIL|SKIPPED mission_fitness=direct|adjacent|infrastructure|drift br_close_executed=yes|failed|not_applicable four_lens=brand:N,sniff:N,jeff:N,public:N callback_delivery_verified=true"\n```\n\nIf blocked: `BLOCKED %s reason=<short> need=<short> mission_fitness=<class> josh_request_id=%s`\nIf declining: `DECLINED %s reason=<scope-mismatch|capability|risk> mission_fitness=drift josh_request_id=%s`\n\n' "$TARGET_SESSION" "$CALLBACK_PANE" "$BEAD_ID" "$TASK_ID" "$JOSH_REQUEST_ID" "$TASK_ID" "$JOSH_REQUEST_ID" "$TASK_ID" "$JOSH_REQUEST_ID"
  printf '## MISSION FITNESS CLAIM BLOCK\n\n```text\nmission_anchor=%s\nmission_fitness_claim=%s\nmission_fitness_class=%s\n```\n\nWorkers MUST echo `mission_fitness=<direct|adjacent|infrastructure|drift>` in the DONE callback.\n\n' "$MISSION_ANCHOR" "$MISSION_FITNESS_CLAIM" "$MISSION_FITNESS_CLASS"
  printf '## JOSH REQUEST LINKAGE BLOCK\n\n```text\njosh_request_id=%s\n```\n\nDONE/BLOCKED/DECLINED callbacks MUST include the same field and value verbatim.\n\n## LOCKED WORKER IDENTITY BLOCK\n\n```text\nidentity_name=%s\nidentity_source=%s\nworker_identity=%s\nworker_identity_status=%s\n```\n\nIf `worker_identity_status=needs_registration`, dispatch wrapper triggered registration before this packet was sent.\n\n' "$JOSH_REQUEST_ID" "$IDENTITY_NAME" "$IDENTITY_FILE" "$IDENTITY_NAME" "$IDENTITY_STATUS"
  printf '## SHARED-SURFACE RESERVATION BLOCK (L107)\n\nBefore staging shared paths (commit-touched files), reserve:\n```bash\n.flywheel/scripts/shared-surface-reservation-check.sh --reserve <path> --pane=%s --task-id=%s --json\n```\nRelease after commit. Worker callback MUST include `shared_surface_reservations_checked=yes shared_surface_reservations_released=yes`.\n\n## FILE DISCIPLINE (PICOZ_WORKER_FILES)\n\nEdit ONLY files named in this packet TASK BODY or files explicitly named in the bead body. Other edits require an in-band ntm message asking for scope expansion BEFORE the edit.\n\n' "$TARGET_PANE" "$TASK_ID"
  printf '## VERIFICATION (pre-DONE)\n\nRun verification commands from bead acceptance section if present. If none, run:\n```bash\nbash -n <any-edited-shell-script>\nbr show %s  # confirm bead state\n```\n\n## DID / DIDNT / GAPS BLOCK (L80)\n\nWorker DONE callback MUST include:\n- `did=<count>/<total-bead-acceptance-criteria>`\n- `didnt=<bead-ids-skipped-or-none>`\n- `gaps=<bead-ids-newly-discovered-or-none>`\n\n' "$BEAD_ID"
  printf '## FOUR-LENS SELF-GRADE BLOCK\n\nScore 1-10 each:\n- `brand` (zest brand voice consistency)\n- `sniff` (smell test; does this look right)\n- `jeff` (Jeff Emanuel substrate alignment)\n- `public` (would I show this to a stranger)\n\nEcho as `four_lens=brand:N,sniff:N,jeff:N,public:N` in DONE callback.\n\n## L61 ECOSYSTEM-TOUCH BLOCK\n\nIf this work touches doctrine|INCIDENTS|canonical|L-rule|skill, callback MUST include:\n- `agents_md_updated=yes|no`\n- `readme_updated=yes|no`\n- `no_touch_reason=<reason>` (when either is `no`)\n\n'
  printf '## L120 BR-CLOSE-EXECUTED BLOCK\n\nDONE callback MUST include `br_close_executed=yes|failed|not_applicable`.\n`yes` requires `br close %s` exited 0 BEFORE the ntm send DONE.\n\n## TASK BODY (bead context)\n\n### Title\n%s\n\n### Description\n' "$BEAD_ID" "$BEAD_TITLE"
  printf '%s\n\n' "$BEAD_BODY"
  printf '### Dependencies\n```json\n%s\n```\n\n### Priority\nP%s\n\n### NTM Context And Template\n```text\nntm_context_id=%s\nntm_context_repo_rev=%s\nntm_context_token_count=%s\nntm_template_name=%s\nntm_template_source=%s\n```\n\n' "$BEAD_DEPS" "$BEAD_PRIORITY" "$NTM_CONTEXT_ID" "$NTM_CONTEXT_REV" "$NTM_CONTEXT_TOKENS" "$NTM_TEMPLATE_NAME" "$NTM_TEMPLATE_SOURCE"
  printf '## EXECUTION\n\n1. Read this entire packet\n2. Run `br show %s` to confirm context\n3. Run `br dep tree %s` to see dependencies\n4. Apply socraticode K>=10 if non-trivial code claim involved\n5. Reserve any shared paths via L107 script before edits\n6. Execute the bead acceptance criteria\n7. Run verification\n8. `br close %s` (BEFORE callback per L120)\n9. Send DONE callback per CALLBACK CONTRACT above\n\n## METADATA\n\n```text\nschema_version=dispatch-packet.v1\npacket_built_by=build-dispatch-packet.sh@%s\npacket_built_at=%s\ndispatch_channel=%s\nntm_context_source=context build --json\nntm_template_source=template show %s --body --json\n```\n' "$BEAD_ID" "$BEAD_ID" "$BEAD_ID" "$VERSION" "$NOW" "$DISPATCH_CHANNEL" "$NTM_TEMPLATE_NAME"
} >"$TMP_BODY"

AUGMENTED_BODY="$TMP_BODY"
if [[ -x "$SHARED_DIR/inject-memory-hits.sh" ]] && "$SHARED_DIR/inject-memory-hits.sh" "$TMP_BODY" "$TASK_ID" "$BEAD_ID" "$REPO_ROOT" >"${TMP_BODY}.mem" 2>/dev/null; then
  AUGMENTED_BODY="${TMP_BODY}.mem"
fi
if [[ -x "$SHARED_DIR/inject-skill-auto-routes.sh" ]] && "$SHARED_DIR/inject-skill-auto-routes.sh" "$AUGMENTED_BODY" "$TASK_ID" >"${AUGMENTED_BODY}.routed" 2>/dev/null; then
  AUGMENTED_BODY="${AUGMENTED_BODY}.routed"
fi

MEMORY_HITS="$(grep -c '^- ' "$AUGMENTED_BODY" 2>/dev/null | tr -d '\n' || echo 0)"
SKILL_ROUTES="$(grep -Ec '^skill_auto_routes=[0-9]+' "$AUGMENTED_BODY" 2>/dev/null | tr -d '\n' || echo 0)"
[[ "$MEMORY_HITS" =~ ^[0-9]+$ ]] || MEMORY_HITS=0
[[ "$SKILL_ROUTES" =~ ^[0-9]+$ ]] || SKILL_ROUTES=0

REQUIRED_BLOCKS=("CALLBACK CONTRACT" "MISSION FITNESS CLAIM BLOCK" "JOSH REQUEST LINKAGE BLOCK" "LOCKED WORKER IDENTITY BLOCK" "SHARED-SURFACE RESERVATION BLOCK" "FILE DISCIPLINE" "VERIFICATION" "DID / DIDNT / GAPS BLOCK" "FOUR-LENS SELF-GRADE BLOCK" "L61 ECOSYSTEM-TOUCH BLOCK" "L120 BR-CLOSE-EXECUTED BLOCK" "TASK BODY" "EXECUTION")
declare -a PRESENT=()
declare -a MISSING=()
for block in "${REQUIRED_BLOCKS[@]}"; do
  if grep -q "^## ${block}" "$AUGMENTED_BODY"; then PRESENT+=("$block"); else MISSING+=("$block"); fi
done
VALIDATION="pass"; [[ ${#MISSING[@]} -gt 0 ]] && VALIDATION="fail"

if [[ "$MODE" == "apply" ]]; then
  cp "$AUGMENTED_BODY" "$PACKET_FILE"
  PACKET_SHA="$(shasum -a 256 "$PACKET_FILE" | awk '{print $1}')"
else
  PACKET_SHA="$(shasum -a 256 "$AUGMENTED_BODY" | awk '{print $1}')"
  VALIDATION="dry-run"
fi
if [[ ${#PRESENT[@]} -eq 0 ]]; then PRESENT_JSON="[]"; else PRESENT_JSON="$(json_array "${PRESENT[@]}")"; fi
if [[ ${#MISSING[@]} -eq 0 ]]; then MISSING_JSON="[]"; else MISSING_JSON="$(json_array "${MISSING[@]}")"; fi

if $JSON_OUT; then
  jq -nc --arg packet "$PACKET_FILE" --arg sha "$PACKET_SHA" --arg vstatus "$VALIDATION" \
    --arg task "$TASK_ID" --arg bead "$BEAD_ID" --argjson tpane "$TARGET_PANE" --arg tsess "$TARGET_SESSION" \
    --argjson cpane "$CALLBACK_PANE" --arg manchor "$MISSION_ANCHOR" --arg mclass "$MISSION_FITNESS_CLASS" \
    --arg jrid "$JOSH_REQUEST_ID" --arg ident "$IDENTITY_NAME" --arg chan "$DISPATCH_CHANNEL" \
    --arg context_id "$NTM_CONTEXT_ID" --arg template "$NTM_TEMPLATE_NAME" \
    --argjson memhits "$MEMORY_HITS" --argjson skillroutes "$SKILL_ROUTES" --argjson present "$PRESENT_JSON" --argjson missing "$MISSING_JSON" \
    '{schema_version:"build-dispatch-packet.v1",packet_path:$packet,packet_sha256:$sha,validation_status:$vstatus,validation_blocks_present:$present,validation_blocks_missing:$missing,fields_resolved:{task_id:$task,bead_id:$bead,target_pane:$tpane,target_session:$tsess,callback_pane:$cpane,mission_anchor:$manchor,mission_fitness_class:$mclass,josh_request_id:(if $jrid=="null" then null else $jrid end),identity_name:(if $ident=="null" then null else $ident end),dispatch_channel:$chan,memory_hits_count:$memhits,skill_auto_routes_count:$skillroutes,ntm_context_id:$context_id,ntm_template_name:$template}}'
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
  echo "ntm:       context=$NTM_CONTEXT_ID template=$NTM_TEMPLATE_NAME"
fi

[[ "$VALIDATION" == "fail" ]] && exit 5
exit 0
