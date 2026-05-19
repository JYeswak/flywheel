#!/usr/bin/env bash
# public-artifact-pipeline-probe.sh — smallest recurring measurement
# for value-gap dimension `public-artifact-pipeline` (#10 of 10 in
# `.flywheel/scripts/value-gap-probe.sh:DIMENSIONS[]`).
#
# Owns: bead flywheel-1rmp.11. Sisters: flywheel-1rmp.5
# (cost-telemetry-token-burn), flywheel-1rmp.7
# (mobile-eats-end-user-health), flywheel-1rmp.9
# (cross-time-synthesis) — same shape: proxy + no-surface receipt.
#
# What this measures (proxy):
#   - publishable_audits_count    (audit packs with four_lens public >= MIN)
#   - publishable_audits_recent   (within last N hours, default 168=7d)
#   - newest_publishable_audit    (path + four_lens scores)
#   - audits_total                (any evidence.md under .flywheel/audit/)
#   - publishable_ratio           (publishable_count / audits_total)
#   - public_channel_state        ("no_pipeline_yet" — no canonical
#                                   "publish to ZestStream blog/X/site"
#                                   surface in flywheel today)
#
# Step 4o anti-pattern guardrail: SURFACES the gap; does NOT
# auto-publish or auto-create showcase beads.
#
# Stable exit codes: 0 ok | 1 domain | 64 usage
# Triad: doctor / info / schema; --json default for robot consumers.

set -uo pipefail

VERSION="public-artifact-pipeline-probe.v1"
SCRIPT_VERSION="2026-05-09.1"

REPO="${PUBLIC_ARTIFACT_REPO:-/Users/josh/Developer/flywheel}"
AUDIT_DIR="${PUBLIC_ARTIFACT_AUDIT_DIR:-$REPO/.flywheel/audit}"
LEDGER="${PUBLIC_ARTIFACT_LEDGER:-$HOME/.local/state/flywheel/public-artifact-pipeline.jsonl}"
RECENT_HOURS="${PUBLIC_ARTIFACT_RECENT_HOURS:-168}"
PUBLIC_MIN_SCORE="${PUBLIC_ARTIFACT_MIN_SCORE:-8}"

JSON_OUT=0
MODE="run"
APPLY=0
DRY_RUN=0

usage() {
  cat <<'USAGE'
Usage:
  public-artifact-pipeline-probe.sh [--apply|--dry-run] [--min-score N] [--json]
  public-artifact-pipeline-probe.sh --doctor [--json]
  public-artifact-pipeline-probe.sh --info [--json]
  public-artifact-pipeline-probe.sh --schema [--json]
  public-artifact-pipeline-probe.sh --help

Smallest recurring measurement for the value-gap-hunter dimension
"public-artifact-pipeline" (Meadows #8 information flow). Counts
audit evidence packs scoring four_lens public >= MIN as publishable
candidates; emits explicit no_pipeline_yet receipt because flywheel
lacks a canonical "publish-to-public-channel" surface today.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) JSON_OUT=1; shift ;;
    --apply) APPLY=1; DRY_RUN=0; shift ;;
    --dry-run) DRY_RUN=1; APPLY=0; shift ;;
    --min-score) PUBLIC_MIN_SCORE="${2:?}"; shift 2 ;;
    --recent-hours) RECENT_HOURS="${2:?}"; shift 2 ;;
    --audit-dir) AUDIT_DIR="${2:?}"; shift 2 ;;
    --ledger) LEDGER="${2:?}"; shift 2 ;;
    --doctor) MODE="doctor"; shift ;;
    --info) MODE="info"; shift ;;
    --schema) MODE="schema"; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "public-artifact-pipeline-probe.sh: unknown arg: $1" >&2; usage >&2; exit 64 ;;
  esac
done

if [[ $MODE == "run" && $APPLY -eq 0 && $DRY_RUN -eq 0 ]]; then
  DRY_RUN=1
fi

now_iso() { date -u +%Y-%m-%dT%H:%M:%SZ; }
emit() {
  if [[ $JSON_OUT -eq 1 || $MODE == "info" || $MODE == "schema" || $MODE == "doctor" ]]; then
    printf '%s\n' "$1"
  fi
}

info_payload() {
  jq -nc \
    --arg version "$VERSION" \
    --arg script_version "$SCRIPT_VERSION" \
    --arg repo "$REPO" \
    --arg audit_dir "$AUDIT_DIR" \
    --arg ledger "$LEDGER" \
    --argjson recent_hours "$RECENT_HOURS" \
    --argjson min_score "$PUBLIC_MIN_SCORE" \
    '{
      version: $version,
      script_version: $script_version,
      schema_version: "public-artifact-pipeline/v1",
      mode: "info",
      repo: $repo,
      audit_dir: $audit_dir,
      ledger: $ledger,
      recent_hours: $recent_hours,
      public_min_score: $min_score,
      modes: ["run","doctor","info","schema"],
      owns: "flywheel-1rmp.11",
      parent: "flywheel-1rmp",
      value_gap_dimension: "public-artifact-pipeline",
      meadows_tier: "#8 information flow",
      public_channel_state: "no_pipeline_yet",
      public_no_pipeline_reason: "Flywheel has no canonical surface for routing showcase-worthy artifacts to public channels (ZestStream blog/X/website/product). Internal evidence packs are graded via four_lens (brand/sniff/jeff/public) but no producer-side wiring exists to lift `public >= 8` artifacts into a public publication queue. Smallest recurring measurement is publishable-candidate inventory until a public-channel surface lands.",
      step_4o_anti_pattern_guardrail: "this probe surfaces; it does NOT auto-publish or auto-file showcase beads",
      status: "ok"
    }'
}

schema_payload() {
  jq -nc '{
    schema_version: "public-artifact-pipeline/v1",
    ledger_row_required_fields: [
      "schema_version","ts","audit_dir","public_min_score",
      "audits_total","publishable_audits_count","publishable_audits_recent",
      "publishable_ratio","newest_publishable_audit",
      "newest_publishable_audit_path","newest_publishable_audit_age_hours",
      "public_channel_state","public_no_pipeline_reason",
      "publishable_recent_paths"
    ],
    proxy_metrics: [
      {"name":"audits_total","describes":"any evidence.md under .flywheel/audit/"},
      {"name":"publishable_audits_count","describes":"audit packs with four_lens public >= public_min_score"},
      {"name":"publishable_audits_recent","describes":"publishable_audits_count whose mtime is within recent_hours"},
      {"name":"publishable_ratio","describes":"publishable_count / audits_total (0..1)"},
      {"name":"newest_publishable_audit","describes":"basename of newest mtime among publishable audits"}
    ],
    public_channel_state_enum: ["no_pipeline_yet","draft_queue","wired"],
    surfaced_via: ["ledger:~/.local/state/flywheel/public-artifact-pipeline.jsonl","cli:public-artifact-pipeline-probe.sh","value-gap-probe parent ledger"],
    exit_codes: {"0":"ok","1":"domain","64":"usage"},
    mode: "schema",
    status: "ok"
  }'
}

doctor_payload() {
  local issues=()
  command -v jq >/dev/null 2>&1 || issues+=("jq_missing")
  [[ -d "$AUDIT_DIR" ]] || issues+=("audit_dir_missing=$AUDIT_DIR")
  mkdir -p "$(dirname "$LEDGER")" 2>/dev/null
  [[ -w "$(dirname "$LEDGER")" ]] || issues+=("ledger_dir_not_writable=$(dirname "$LEDGER")")
  local issues_json
  if [[ ${#issues[@]} -gt 0 ]]; then
    issues_json=$(printf '%s\n' "${issues[@]}" | jq -R . | jq -s .)
  else
    issues_json='[]'
  fi
  jq -nc \
    --arg version "$VERSION" \
    --argjson issues "$issues_json" \
    '{
      version: $version,
      schema_version: "public-artifact-pipeline/v1",
      mode: "doctor",
      issues: $issues,
      status: (if ($issues|length)==0 then "ok" else "degraded" end)
    }'
}

mtime_iso() { stat -f '%Sm' -t '%Y-%m-%dT%H:%M:%SZ' "$1" 2>/dev/null; }
mtime_epoch() { stat -f '%m' "$1" 2>/dev/null; }

run_pass() {
  local mode_label="$1"
  local now_epoch
  now_epoch=$(date -u +%s)

  local audits_total=0 publishable=0 publishable_recent=0
  local newest_epoch=0 newest_path="" newest_iso=""
  local recent_paths_json='[]'

  local f
  while IFS= read -r f; do
    [[ -z "$f" ]] && continue
    audits_total=$((audits_total+1))
    if grep -qE "public:(8|9|10|9\.|8\.)" "$f" 2>/dev/null; then
      publishable=$((publishable+1))
      local ep iso age
      ep=$(mtime_epoch "$f")
      iso=$(mtime_iso "$f")
      [[ -z "$ep" ]] && continue
      age=$(( (now_epoch - ep) / 3600 ))
      if (( age <= RECENT_HOURS )); then
        publishable_recent=$((publishable_recent+1))
        recent_paths_json=$(jq -c \
          --arg p "$f" --arg mt "$iso" --argjson age "$age" \
          '. + [{path: $p, mtime: $mt, age_hours: $age}]' <<<"$recent_paths_json")
      fi
      if (( ep > newest_epoch )); then
        newest_epoch=$ep
        newest_path="$f"
        newest_iso="$iso"
      fi
    fi
  done < <(find "$AUDIT_DIR" -mindepth 2 -maxdepth 2 -name 'evidence.md' -type f 2>/dev/null)

  local ratio='0'
  if (( audits_total > 0 )); then
    ratio=$(python3 -c "print(round($publishable / $audits_total, 4))" 2>/dev/null || echo "0")
  fi
  local newest_age=999999
  if (( newest_epoch > 0 )); then
    newest_age=$(( (now_epoch - newest_epoch) / 3600 ))
  fi

  local row
  row=$(jq -nc \
    --arg ts "$(now_iso)" \
    --arg dir "$AUDIT_DIR" \
    --argjson min "$PUBLIC_MIN_SCORE" \
    --argjson total "$audits_total" \
    --argjson pub "$publishable" \
    --argjson recent "$publishable_recent" \
    --arg ratio "$ratio" \
    --arg newest_path "$newest_path" \
    --arg newest_iso "$newest_iso" \
    --argjson newest_age "$newest_age" \
    --argjson recent_paths "$recent_paths_json" \
    '{
      schema_version: "public-artifact-pipeline/v1",
      ts: $ts,
      audit_dir: $dir,
      public_min_score: $min,
      audits_total: $total,
      publishable_audits_count: $pub,
      publishable_audits_recent: $recent,
      publishable_ratio: ($ratio | tonumber? // 0),
      newest_publishable_audit: (if $newest_path == "" then null else ($newest_path | sub(".*/audit/"; "")) end),
      newest_publishable_audit_path: (if $newest_path == "" then null else $newest_path end),
      newest_publishable_audit_age_hours: $newest_age,
      public_channel_state: "no_pipeline_yet",
      public_no_pipeline_reason: "Flywheel has no canonical publish-to-public surface (ZestStream blog/X/website/product). Internal evidence packs are graded but no producer-side wiring exists to lift public>=8 artifacts to a public queue. Future bead: route flywheel-1rmp publication-pipeline followup once Joshua names the target channel.",
      publishable_recent_paths: $recent_paths
    }')

  if [[ "$mode_label" == "apply" ]]; then
    mkdir -p "$(dirname "$LEDGER")" 2>/dev/null
    printf '%s\n' "$row" >> "$LEDGER" 2>/dev/null
  fi

  emit "$(printf '%s' "$row" | jq -c \
    --arg mode "$mode_label" --arg ledger "$LEDGER" \
    '{mode:$mode, ledger:$ledger} + .')"
  return 0
}

case "$MODE" in
  info)   emit "$(info_payload)"; exit 0 ;;
  schema) emit "$(schema_payload)"; exit 0 ;;
  doctor)
    payload="$(doctor_payload)"
    emit "$payload"
    [[ "$(printf '%s' "$payload" | jq -r .status)" == "ok" ]] && exit 0 || exit 1
    ;;
esac

if [[ $DRY_RUN -eq 1 ]]; then
  run_pass dry-run
  exit $?
fi
run_pass apply
exit $?

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-02-conformance-fixtures.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-68-schema-executable-validator-pair.md`
