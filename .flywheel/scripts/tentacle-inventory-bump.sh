#!/usr/bin/env bash
# .flywheel/scripts/tentacle-inventory-bump.sh
# Bead flywheel-fjw [D4] — atomic INVENTORY.md trailer update on
# tentacle drift sweep.
#
# Bumps a "Last Drift Sweep" trailer block at the END of
# dicklesworthstone-stack/references/INVENTORY.md whenever a
# tentacle-drift-sweep summary (or per-repo row JSONL) supplies
# fresh drift data. The curated table (Verdict / Rationale columns,
# all 177 repo rows) is intentionally NOT touched — those carry
# Joshua's human judgment and the GitHub API's authoritative metadata.
#
# Atomicity: the trailer block is rewritten in-place via tempfile
# rename so a partial write cannot leave a torn INVENTORY.md.
# Idempotent: identical input ts → no-op (no diff).
#
# Tracking bead: flywheel-fjw  Origin: 00-MASTER-PLAN.md §IV.6
set -euo pipefail

VERSION="tentacle-inventory-bump.v1"

INVENTORY_DEFAULT="$HOME/.claude/skills/dicklesworthstone-stack/references/INVENTORY.md"
INVENTORY="${INVENTORY:-$INVENTORY_DEFAULT}"
SUMMARY_PATH=""
NOW="${TENTACLE_INVENTORY_BUMP_NOW:-}"
MODE="dry-run"
JSON_OUT=0
TRAILER_BEGIN="<!-- BEGIN-TENTACLE-DRIFT-TRAILER -->"
TRAILER_END="<!-- END-TENTACLE-DRIFT-TRAILER -->"

usage() {
  cat <<'USAGE'
Usage:
  tentacle-inventory-bump.sh --summary PATH [--inventory PATH] [--apply|--dry-run] [--json]
  tentacle-inventory-bump.sh doctor|--doctor [--inventory PATH] [--summary PATH] [--json]
  tentacle-inventory-bump.sh --info|--schema|--examples|--help [--json]

Reads a tentacle-drift-sweep summary (JSON, schema_version
"tentacle-drift-sweep/v1") and bumps the "Last Drift Sweep" trailer
block in INVENTORY.md. Default mode is --dry-run; --apply rewrites
INVENTORY.md atomically via tempfile rename.

Exit codes:
  0  bump applied (apply) or preview emitted (dry-run)
  1  bump failed (summary unparseable, INVENTORY.md missing,
     atomic rename failed)
  2  usage error
  3  prerequisite missing (jq, INVENTORY.md path inaccessible)

Trailer block shape (preserves curated table):
  <!-- BEGIN-TENTACLE-DRIFT-TRAILER -->
  ## Last Drift Sweep
  - sweep_ts: <iso>
  - schema_version: <summary.schema_version>
  - repo_count: <n>
  - alert_count: <n>
  - max_commits_behind: <n>
  - status: <pass|warn|fail>
  - sweep_ledger: <path>
  - alert_ledger: <path>
  <!-- END-TENTACLE-DRIFT-TRAILER -->
USAGE
}

now_iso() {
  if [[ -n "$NOW" ]]; then printf '%s\n' "$NOW"; else date -u +%Y-%m-%dT%H:%M:%SZ; fi
}

info_json() {
  jq -nc \
    --arg name "tentacle-inventory-bump.sh" \
    --arg version "$VERSION" \
    --arg inventory_default "$INVENTORY_DEFAULT" \
    --arg trailer_begin "$TRAILER_BEGIN" \
    --arg trailer_end "$TRAILER_END" \
    --argjson exit_codes '{"0":"bump applied or preview emitted","1":"bump failed","2":"usage error","3":"prerequisite missing"}' \
    --argjson modes '["dry-run","apply"]' \
    --argjson flags '["--summary","--inventory","--apply","--dry-run","--json","doctor","--doctor","--info","--schema","--examples","--help"]' \
    --argjson env_vars '["INVENTORY","TENTACLE_INVENTORY_BUMP_NOW"]' \
    '{
      schema_version: "tool-info/v1",
      name: $name,
      version: $version,
      inventory_default: $inventory_default,
      trailer_begin: $trailer_begin,
      trailer_end: $trailer_end,
      modes: $modes,
      default_mode: "dry-run",
      flags: $flags,
      env_vars: $env_vars,
      mutates: true,
      mutation_requires: ["--apply"],
      doctor_schema: "tentacle-inventory-bump.doctor.v1",
      curated_table_modified: false,
      atomicity: "tempfile-rename-only",
      idempotent: true,
      exit_codes: $exit_codes,
      receipt_schema: "tentacle-inventory-bump-receipt/v1",
      consumes_schema: "tentacle-drift-sweep/v1",
      tracking_bead: "flywheel-fjw"
    }'
}

schema_json() {
  jq -nc '{
    "$schema": "http://json-schema.org/draft-07/schema#",
    schema_version: "tentacle-inventory-bump-receipt/v1",
    type: "object",
    required: ["ts","mode","inventory","summary","trailer_status","atomicity"],
    properties: {
      ts: {type:"string"},
      mode: {type:"string", enum:["dry-run","apply"]},
      inventory: {type:"string"},
      summary: {type:"object"},
      trailer_status: {type:"string", enum:["unchanged","updated","inserted"]},
      atomicity: {type:"string", const:"tempfile-rename-only"},
      diff_lines_added: {type:"integer"},
      diff_lines_removed: {type:"integer"},
      curated_table_modified: {type:"boolean", const:false}
    }
  }'
}

examples() {
  cat <<'EXAMPLES'
Examples:
  # Read-only doctor (no trailer rewrite)
  .flywheel/scripts/tentacle-inventory-bump.sh doctor | jq .

  # Dry-run preview against the default INVENTORY (no mutation)
  echo '{"schema_version":"tentacle-drift-sweep/v1","status":"warn","ts":"2026-05-10T01:00:00Z","repo_count":177,"alert_count":11,"max_commits_behind":5780,"ledger_path":"/x/sweep.jsonl","alert_ledger_path":"/x/alerts.jsonl"}' \
    > /tmp/sweep.json
  .flywheel/scripts/tentacle-inventory-bump.sh --summary /tmp/sweep.json

  # Apply the bump (rewrites INVENTORY.md trailer)
  .flywheel/scripts/tentacle-inventory-bump.sh --summary /tmp/sweep.json --apply

  # Pipe in via stdin (use --summary -)
  cat /tmp/sweep.json | .flywheel/scripts/tentacle-inventory-bump.sh --summary - --apply

  # Custom INVENTORY path (fixture testing)
  INVENTORY=/tmp/fixture-inventory.md .flywheel/scripts/tentacle-inventory-bump.sh \
    --summary /tmp/sweep.json --apply --json
EXAMPLES
}

doctor_json() {
  local jq_status inventory_status inventory_parent_status summary_status markers_status overall
  local inventory_parent
  overall="pass"
  if command -v jq >/dev/null 2>&1; then
    jq_status="pass"
  else
    jq_status="fail"
    overall="fail"
  fi
  if [[ -f "$INVENTORY" && -r "$INVENTORY" ]]; then
    inventory_status="pass"
  else
    inventory_status="fail"
    overall="fail"
  fi
  inventory_parent="$(dirname "$INVENTORY")"
  if [[ -d "$inventory_parent" && -w "$inventory_parent" ]]; then
    inventory_parent_status="pass"
  else
    inventory_parent_status="warn"
    [[ "$overall" == "fail" ]] || overall="warn"
  fi
  if [[ -z "$SUMMARY_PATH" ]]; then
    summary_status="warn"
    [[ "$overall" == "fail" ]] || overall="warn"
  elif [[ "$SUMMARY_PATH" == "-" ]]; then
    summary_status="warn"
    [[ "$overall" == "fail" ]] || overall="warn"
  elif [[ -f "$SUMMARY_PATH" && -r "$SUMMARY_PATH" ]]; then
    if jq -e '.schema_version | test("^tentacle-drift-sweep/")' "$SUMMARY_PATH" >/dev/null 2>&1; then
      summary_status="pass"
    else
      summary_status="fail"
      overall="fail"
    fi
  else
    summary_status="fail"
    overall="fail"
  fi
  if [[ -n "$TRAILER_BEGIN" && -n "$TRAILER_END" && "$TRAILER_BEGIN" != "$TRAILER_END" ]]; then
    markers_status="pass"
  else
    markers_status="fail"
    overall="fail"
  fi
  jq -nc \
    --arg status "$overall" \
    --arg version "$VERSION" \
    --arg inventory "$INVENTORY" \
    --arg inventory_parent "$inventory_parent" \
    --arg summary_path "$SUMMARY_PATH" \
    --arg jq_status "$jq_status" \
    --arg inventory_status "$inventory_status" \
    --arg inventory_parent_status "$inventory_parent_status" \
    --arg summary_status "$summary_status" \
    --arg markers_status "$markers_status" \
    --arg trailer_begin "$TRAILER_BEGIN" \
    --arg trailer_end "$TRAILER_END" \
    '{
      schema_version: "tentacle-inventory-bump.doctor.v1",
      command: "doctor",
      status: $status,
      mode: "read_only",
      mutates: false,
      version: $version,
      inventory: $inventory,
      summary_path: $summary_path,
      trailer_begin: $trailer_begin,
      trailer_end: $trailer_end,
      checks: [
        {name:"jq_available", status:$jq_status},
        {name:"inventory_readable", status:$inventory_status},
        {name:"inventory_parent_writable", status:$inventory_parent_status, path:$inventory_parent},
        {name:"summary_readable_when_supplied", status:$summary_status},
        {name:"trailer_markers_configured", status:$markers_status}
      ]
    }'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --info)     info_json; exit 0 ;;
    --schema)   schema_json; exit 0 ;;
    --examples) examples; exit 0 ;;
    -h|--help)  usage; exit 0 ;;
    doctor|--doctor) MODE="doctor"; shift ;;
    --apply)    MODE="apply"; shift ;;
    --dry-run)  MODE="dry-run"; shift ;;
    --json)     JSON_OUT=1; shift ;;
    --summary)  SUMMARY_PATH="${2:-}"; shift 2 ;;
    --inventory)INVENTORY="${2:-}"; shift 2 ;;
    --*)        printf 'unknown flag: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    *)          printf 'unexpected arg: %s\n' "$1" >&2; exit 2 ;;
  esac
done

if [[ "$MODE" == "doctor" ]]; then
  doctor_json
  exit 0
fi

if [[ -z "$SUMMARY_PATH" ]]; then
  printf 'error: --summary PATH required\n' >&2
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  printf 'error: jq required\n' >&2
  exit 3
fi

# Read summary (file path or stdin via "-")
if [[ "$SUMMARY_PATH" == "-" ]]; then
  SUMMARY_JSON="$(cat)"
elif [[ -f "$SUMMARY_PATH" ]]; then
  SUMMARY_JSON="$(cat "$SUMMARY_PATH")"
else
  printf 'error: summary file not found: %s\n' "$SUMMARY_PATH" >&2
  exit 1
fi

if ! jq -e '.schema_version | test("^tentacle-drift-sweep/")' >/dev/null 2>&1 <<<"$SUMMARY_JSON"; then
  printf 'error: summary lacks tentacle-drift-sweep/* schema_version\n' >&2
  exit 1
fi

if [[ ! -f "$INVENTORY" ]]; then
  printf 'error: INVENTORY missing: %s\n' "$INVENTORY" >&2
  exit 3
fi

SWEEP_TS="$(jq -r '.ts // empty' <<<"$SUMMARY_JSON")"
SWEEP_SCHEMA="$(jq -r '.schema_version' <<<"$SUMMARY_JSON")"
SWEEP_REPO_COUNT="$(jq -r '.repo_count // 0' <<<"$SUMMARY_JSON")"
SWEEP_ALERT_COUNT="$(jq -r '.alert_count // 0' <<<"$SUMMARY_JSON")"
SWEEP_MAX_BEHIND="$(jq -r '.max_commits_behind // 0' <<<"$SUMMARY_JSON")"
SWEEP_STATUS="$(jq -r '.status // "unknown"' <<<"$SUMMARY_JSON")"
SWEEP_LEDGER="$(jq -r '.ledger_path // ""' <<<"$SUMMARY_JSON")"
SWEEP_ALERT_LEDGER="$(jq -r '.alert_ledger_path // ""' <<<"$SUMMARY_JSON")"
[[ -n "$SWEEP_TS" ]] || SWEEP_TS="$(now_iso)"

trailer_block() {
  cat <<EOF
$TRAILER_BEGIN
## Last Drift Sweep
- sweep_ts: $SWEEP_TS
- schema_version: $SWEEP_SCHEMA
- repo_count: $SWEEP_REPO_COUNT
- alert_count: $SWEEP_ALERT_COUNT
- max_commits_behind: $SWEEP_MAX_BEHIND
- status: $SWEEP_STATUS
- sweep_ledger: $SWEEP_LEDGER
- alert_ledger: $SWEEP_ALERT_LEDGER
$TRAILER_END
EOF
}

# Build the proposed new INVENTORY content via awk: drop existing
# trailer block (between markers) if present, append fresh block.
TMPFILE="$(mktemp -t tentacle-inventory-bump.XXXXXX)"
trap 'rm -f "$TMPFILE"' EXIT

awk -v begin="$TRAILER_BEGIN" -v end="$TRAILER_END" '
  $0 == begin { in_block = 1; next }
  $0 == end   { in_block = 0; next }
  !in_block   { print }
' "$INVENTORY" >"$TMPFILE"

# Trim trailing blank lines from body (so trailer placement is canonical)
# then append fresh trailer.
# Use sed to strip trailing blank lines.
awk 'NF { last = NR; lines[NR] = $0; next } { lines[NR] = $0 } END { for (i = 1; i <= last; i++) print lines[i] }' "$TMPFILE" > "$TMPFILE.body"
mv "$TMPFILE.body" "$TMPFILE"
printf '\n' >>"$TMPFILE"
trailer_block >>"$TMPFILE"

# Diff-stat between old and new. `diff` returns 1 when files differ;
# wrap with `|| true` so set -e + pipefail don't abort the script.
DIFF_OUT="$(diff -u "$INVENTORY" "$TMPFILE" 2>/dev/null || true)"
DIFF_ADDED="$(awk '/^\+/ && !/^\+\+\+/ {n++} END {print n+0}' <<<"$DIFF_OUT")"
DIFF_REMOVED="$(awk '/^-/ && !/^---/ {n++} END {print n+0}' <<<"$DIFF_OUT")"

# Detect if a curated-table row changed. Curated rows match the table
# header (`| Rank |`) or the data rows (`| <int> |`). The trailer
# lives AFTER `## Clone And Index Notes`, so these regions are
# mutually exclusive.
CURATED_DIFF="$(awk '
  BEGIN { in_diff = 0 }
  /^@@/ { in_diff = 1; next }
  in_diff && /^[+-][^+-]/ {
    if ($0 ~ /\| Rank \|/ || $0 ~ /^[+-]\|[ ]?[0-9]+[ ]?\|/) print "TABLE_ROW_CHANGED"
  }
' <<<"$DIFF_OUT" | head -1)"

if [[ -n "$CURATED_DIFF" ]]; then
  printf 'error: curated-table row would be modified — refusing to bump\n' >&2
  exit 1
fi

# Determine trailer_status
if grep -qF "$TRAILER_BEGIN" "$INVENTORY"; then
  if diff -q "$INVENTORY" "$TMPFILE" >/dev/null 2>&1; then
    TRAILER_STATUS="unchanged"
  else
    TRAILER_STATUS="updated"
  fi
else
  TRAILER_STATUS="inserted"
fi

emit_receipt() {
  jq -nc \
    --arg ts "$(now_iso)" \
    --arg mode "$MODE" \
    --arg inventory "$INVENTORY" \
    --argjson summary "$SUMMARY_JSON" \
    --arg trailer_status "$TRAILER_STATUS" \
    --argjson diff_added "${DIFF_ADDED:-0}" \
    --argjson diff_removed "${DIFF_REMOVED:-0}" \
    '{
      schema_version: "tentacle-inventory-bump-receipt/v1",
      ts: $ts,
      mode: $mode,
      inventory: $inventory,
      summary: $summary,
      trailer_status: $trailer_status,
      atomicity: "tempfile-rename-only",
      diff_lines_added: $diff_added,
      diff_lines_removed: $diff_removed,
      curated_table_modified: false
    }'
}

if [[ "$MODE" == "dry-run" ]]; then
  receipt="$(emit_receipt)"
  if [[ "$JSON_OUT" -eq 1 ]]; then
    printf '%s\n' "$receipt"
  else
    printf 'DRY-RUN: would update %s trailer (status=%s diff +%s/-%s)\n' "$INVENTORY" "$TRAILER_STATUS" "${DIFF_ADDED:-0}" "${DIFF_REMOVED:-0}"
    printf '%s\n' "$receipt" >&2
  fi
  exit 0
fi

# Apply: atomic rename
if [[ "$TRAILER_STATUS" == "unchanged" ]]; then
  receipt="$(emit_receipt)"
else
  mv "$TMPFILE" "$INVENTORY" || { printf 'error: rename failed\n' >&2; exit 1; }
  trap - EXIT
  receipt="$(emit_receipt)"
fi

if [[ "$JSON_OUT" -eq 1 ]]; then
  printf '%s\n' "$receipt"
else
  printf 'APPLIED: %s trailer status=%s (diff +%s/-%s)\n' "$INVENTORY" "$TRAILER_STATUS" "${DIFF_ADDED:-0}" "${DIFF_REMOVED:-0}"
fi

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
