#!/usr/bin/env bash
# verify-bead-authority.sh — pre-mutation guard for hooks. Refuses to operate
# when bead resolution would walk up to a global vault, satisfies bead-isolation
# Phase 4 Change 4.4 (hook bead-authority verification) without patching ntm or
# beads_rust upstream.
#
# Exit codes:
#   0  authority OK — local .beads, no cross-tree symlink, BEADS_STRICT_LOCAL=1 honored
#   1  authority refused — would resolve via walk-up or cross-tree symlink
#   2  config error
#
# Hooks should call this BEFORE any mutating br invocation:
#   if /Users/josh/Developer/flywheel/.flywheel/scripts/verify-bead-authority.sh \
#       --target-dir "$PROJECT_DIR" --json >/dev/null; then
#     BEADS_STRICT_LOCAL=1 br ...
#   else
#     echo "bead-authority refused (cross-tree or walk-up resolution)" >&2
#     exit 1
#   fi
set -euo pipefail

SCHEMA_VERSION="verify-bead-authority.v1"
PROBE="${VERIFY_BEAD_AUTHORITY_PROBE:-/Users/josh/Developer/flywheel/.flywheel/scripts/br-authority-probe.sh}"

TARGET_DIR="${VERIFY_BEAD_AUTHORITY_TARGET_DIR:-$PWD}"
ALLOW_GLOBAL=0
JSON_OUT=0
MODE=verify

usage() {
  cat <<'USAGE'
usage: verify-bead-authority.sh [--target-dir PATH] [--allow-global] [--json]
       verify-bead-authority.sh --doctor|--health|--info|--schema [--json]

Refuses if br would resolve via walk-up or cross-tree symlink.

Flags:
  --target-dir PATH    directory to verify (default: $PWD)
  --allow-global       permit walk-up resolution (escape hatch; default deny)
  --json               JSON receipt + exit code; otherwise short text + exit code

Exit codes:
  0  authority OK
  1  refused (walk-up or cross-tree symlink)
  2  config error
USAGE
}

doctor() {
  jq -nc --arg schema "$SCHEMA_VERSION" --arg probe "$PROBE" \
    '{schema_version:$schema, success:true, mode:"doctor",
      probe_present:($probe | test("br-authority-probe\\.sh$")),
      enforces:["walk-up refusal","cross-tree symlink refusal"]}'
}

info() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema, success:true, mode:"info",
      verdict_classes:["ok","refused-walk-up","refused-cross-tree","refused-no-db"]}'
}

schema() {
  jq -nc --arg schema "$SCHEMA_VERSION" \
    '{schema_version:$schema,
      properties:{
        verdict:{type:"string", enum:["ok","refused-walk-up","refused-cross-tree","refused-no-db"]},
        target_dir:{type:"string"},
        discovery_method:{type:"string"},
        cross_tree:{type:"boolean"},
        allow_global:{type:"boolean"},
        reason:{type:["string","null"]}}}'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-dir) TARGET_DIR="${2:?--target-dir requires PATH}"; shift 2;;
    --allow-global) ALLOW_GLOBAL=1; shift;;
    --json) JSON_OUT=1; shift;;
    --doctor|--health) MODE=doctor; shift;;
    --info) MODE=info; shift;;
    --schema) MODE=schema; shift;;
    -h|--help) usage; exit 0;;
    *) echo "ERR: unknown arg $1" >&2; usage >&2; exit 2;;
  esac
done

case "$MODE" in
  doctor) doctor; exit 0;;
  info) info; exit 0;;
  schema) schema; exit 0;;
esac

[[ -x "$PROBE" ]] || { echo "ERR: probe not executable: $PROBE" >&2; exit 2; }

PROBE_OUT="$("$PROBE" --target-dir "$TARGET_DIR" --json 2>/dev/null)" || {
  echo "ERR: probe failed against $TARGET_DIR" >&2; exit 2; }

DISCOVERY="$(jq -r '.discovery_method' <<<"$PROBE_OUT")"
CROSS_TREE="$(jq -r '.cross_tree' <<<"$PROBE_OUT")"
DB_PATH="$(jq -r '.db_path' <<<"$PROBE_OUT")"
TARGET_ABS="$(jq -r '.target_dir' <<<"$PROBE_OUT")"

VERDICT="ok"
REASON=""
EXIT_CODE=0

if [[ "$DB_PATH" == "null" || -z "$DB_PATH" ]]; then
  VERDICT="refused-no-db"
  REASON="no .beads found from target dir"
  EXIT_CODE=1
elif [[ "$CROSS_TREE" == "true" ]]; then
  VERDICT="refused-cross-tree"
  REASON="resolved .beads is a cross-tree symlink"
  EXIT_CODE=1
elif [[ "$DISCOVERY" == "walk-up" && "$ALLOW_GLOBAL" != "1" ]]; then
  VERDICT="refused-walk-up"
  REASON="resolution walked up to a parent .beads (use --allow-global to override)"
  EXIT_CODE=1
fi

PAYLOAD="$(jq -nc \
  --arg schema "$SCHEMA_VERSION" \
  --arg verdict "$VERDICT" \
  --arg target "$TARGET_ABS" \
  --arg discovery "$DISCOVERY" \
  --argjson cross "$CROSS_TREE" \
  --argjson allow "$ALLOW_GLOBAL" \
  --arg reason "$REASON" \
  '{schema_version:$schema, success:($verdict == "ok"),
    mode:"verify", verdict:$verdict, target_dir:$target,
    discovery_method:$discovery, cross_tree:$cross,
    allow_global:($allow == 1),
    reason:(if $reason == "" then null else $reason end)}')"

if [[ "$JSON_OUT" == 1 ]]; then
  printf '%s\n' "$PAYLOAD"
else
  jq -r '"verify-bead-authority verdict=\(.verdict) target=\(.target_dir) discovery=\(.discovery_method) cross_tree=\(.cross_tree)\(if .reason then " reason=\"" + .reason + "\"" else "" end)"' <<<"$PAYLOAD"
fi

exit "$EXIT_CODE"

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-100-contention-shaped-state-owner.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-53-idempotent-delivery-replay.md`
