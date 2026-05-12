#!/usr/bin/env bash
set -euo pipefail

# canonical-cli-drift-detector.sh
# Cross-orch P2 drift detector — bilateral parity with skillos's node impl.
# Schema: cross-orch-canonical-cli-drift-run/v1
#
# Behavior:
# 1. Scan receipts at ~/.local/state/canonical-cli-scoping/receipts/*/
# 2. Group by surface name
# 3. For each surface with >1 orch's receipt, compare scores + per-dim verdicts
# 4. Emit findings per disagreement; aggregate JSON output
#
# Cross-orch ratified protocol P2 (cross-orch-anti-divergence-v1.0.0).
# Exit 0 = ran successfully; non-zero = invocation error.
# Drift presence is a finding, not an error.

RECEIPTS_DIR="${HOME}/.local/state/canonical-cli-scoping/receipts"
DRIFT_DIR="${HOME}/.local/state/canonical-cli-scoping/drift-runs"
ORCH="${1:-flywheel:1}"
TS="$(date -u +%Y%m%dT%H%M%SZ)"
OUTPUT_PATH="${DRIFT_DIR}/${TS}-${ORCH}.json"

mkdir -p "$DRIFT_DIR"

if [[ ! -d "$RECEIPTS_DIR" ]]; then
  jq -nc --arg sv "cross-orch-canonical-cli-drift-run/v1" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg orch "$ORCH" \
    '{schema_version:$sv, ts:$ts, orch_running:$orch, status:"no_receipts_dir", receipts_scanned:0, surfaces_total:0, shared_surfaces:0, drift_detected:false, findings_count:0, findings:[]}' \
    | tee "$OUTPUT_PATH"
  exit 0
fi

ALL_RECEIPTS=$(find "$RECEIPTS_DIR" -name '*.json' -type f 2>/dev/null | sort)
RECEIPT_COUNT=$(echo "$ALL_RECEIPTS" | grep -cv '^$' || echo 0)

if [[ "$RECEIPT_COUNT" -eq 0 ]]; then
  jq -nc --arg sv "cross-orch-canonical-cli-drift-run/v1" --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" --arg orch "$ORCH" \
    '{schema_version:$sv, ts:$ts, orch_running:$orch, status:"empty_receipts", receipts_scanned:0, surfaces_total:0, shared_surfaces:0, drift_detected:false, findings_count:0, findings:[]}' \
    | tee "$OUTPUT_PATH"
  exit 0
fi

# Build per-surface map: surface_name -> [{orch, score, dimensions, ts, path}]
SURFACE_MAP="{}"
while IFS= read -r RECEIPT; do
  [[ -z "$RECEIPT" ]] && continue
  SURFACE=$(jq -r '.surface // empty' "$RECEIPT" 2>/dev/null || echo "")
  RECEIPT_ORCH=$(jq -r '.orch // empty' "$RECEIPT" 2>/dev/null || echo "")
  SCORE=$(jq -r '.score // 0' "$RECEIPT" 2>/dev/null || echo 0)
  if [[ -n "$SURFACE" && -n "$RECEIPT_ORCH" ]]; then
    ENTRY=$(jq -nc --arg orch "$RECEIPT_ORCH" --argjson score "$SCORE" --slurpfile dims <(jq -c '.dimensions // {}' "$RECEIPT") --arg ts "$(jq -r '.ts // ""' "$RECEIPT")" --arg path "$RECEIPT" \
      '{orch:$orch, score:$score, dimensions:$dims[0], ts:$ts, path:$path}')
    SURFACE_MAP=$(echo "$SURFACE_MAP" | jq --arg surface "$SURFACE" --argjson entry "$ENTRY" '.[$surface] = ((.[$surface] // []) + [$entry])')
  fi
done <<< "$ALL_RECEIPTS"

SURFACES_TOTAL=$(echo "$SURFACE_MAP" | jq 'keys | length')
SHARED_SURFACES=$(echo "$SURFACE_MAP" | jq '[. | to_entries[] | select(.value | length > 1) | select(.value | map(.orch) | unique | length > 1)] | length')

# For each shared surface (multiple orchs), compute findings
FINDINGS="[]"
while IFS= read -r SURFACE; do
  [[ -z "$SURFACE" ]] && continue
  ENTRIES=$(echo "$SURFACE_MAP" | jq -c --arg s "$SURFACE" '.[$s]')
  ORCH_COUNT=$(echo "$ENTRIES" | jq '[.[].orch] | unique | length')
  if [[ "$ORCH_COUNT" -gt 1 ]]; then
    # Score divergence
    SCORES=$(echo "$ENTRIES" | jq '[.[].score] | unique | length')
    if [[ "$SCORES" -gt 1 ]]; then
      FINDING=$(echo "$ENTRIES" | jq --arg surface "$SURFACE" '{class:"score_divergence", surface:$surface, entries:.}')
      FINDINGS=$(echo "$FINDINGS" | jq --argjson f "$FINDING" '. + [$f]')
    fi
    # Per-dim divergence
    DIMS=$(echo "$ENTRIES" | jq '[.[].dimensions | keys[]] | unique')
    while IFS= read -r DIM; do
      [[ -z "$DIM" || "$DIM" == "null" ]] && continue
      DIM_VERDICTS=$(echo "$ENTRIES" | jq --arg d "$DIM" '[.[].dimensions[$d] // "MISSING"] | unique | length')
      if [[ "$DIM_VERDICTS" -gt 1 ]]; then
        DIM_FINDING=$(echo "$ENTRIES" | jq --arg surface "$SURFACE" --arg dim "$DIM" '{class:"per_dim_divergence", surface:$surface, dimension:$dim, verdicts:[.[] | {orch:.orch, verdict:(.dimensions[$dim] // "MISSING")}]}')
        FINDINGS=$(echo "$FINDINGS" | jq --argjson f "$DIM_FINDING" '. + [$f]')
      fi
    done < <(echo "$DIMS" | jq -r '.[]')
  fi
done < <(echo "$SURFACE_MAP" | jq -r 'keys[]')

FINDINGS_COUNT=$(echo "$FINDINGS" | jq 'length')
DRIFT_DETECTED=$([[ "$FINDINGS_COUNT" -gt 0 ]] && echo true || echo false)

DISJOINT_SURFACES=$((SURFACES_TOTAL - SHARED_SURFACES))

jq -nc \
  --arg sv "cross-orch-canonical-cli-drift-run/v1" \
  --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg orch "$ORCH" \
  --argjson scanned "$RECEIPT_COUNT" \
  --argjson surfaces "$SURFACES_TOTAL" \
  --argjson shared "$SHARED_SURFACES" \
  --argjson disjoint "$DISJOINT_SURFACES" \
  --argjson detected "$DRIFT_DETECTED" \
  --argjson count "$FINDINGS_COUNT" \
  --argjson findings "$FINDINGS" \
  '{
    schema_version: $sv,
    ts: $ts,
    orch_running: $orch,
    status: "complete",
    receipts_scanned: $scanned,
    surfaces_total: $surfaces,
    shared_surfaces: $shared,
    disjoint_surfaces: $disjoint,
    drift_detected: $detected,
    findings_count: $count,
    findings: $findings,
    receipts_dir: env.HOME + "/.local/state/canonical-cli-scoping/receipts"
  }' \
  | tee "$OUTPUT_PATH"
