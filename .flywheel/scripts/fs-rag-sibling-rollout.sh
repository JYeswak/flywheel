#!/usr/bin/env bash
# fs-rag-sibling-rollout.sh — install fs-rag-discipline across sibling repos
# via flywheel-adopt.sh --apply-fs-rag, gating on `.flywheel/ subtree clean`
# rather than tree-wide clean.
#
# Refinement of flywheel-hi4e6's original tree-wide gate (Meadows #5: gate on
# the actual safety property, not the proxy). The rollout only mutates inside
# .flywheel/ + .git/hooks/, so .flywheel/ subtree clean is the precise gate.
#
# Stable exit codes: 0 ok | 1 rollout had refusals or failures | 64 usage
# Default --dry-run. Mutate via --apply.
#
# Owns: bead flywheel-uwqf0 (follow-up to flywheel-hi4e6).
# Doctrine: .flywheel/audit/flywheel-fs-rag-portable/apply-spec.md AG3.

set -euo pipefail

VERSION="fs-rag-sibling-rollout/v1"
DEV_ROOT="${DEV_ROOT:-/Users/josh/Developer}"
DEFAULT_SIBLINGS=(alpsinsurance mobile-eats skillos vrtx picoz zesttube)
ADOPT_SCRIPT="${FS_RAG_ADOPT_SCRIPT:-/Users/josh/Developer/flywheel/.flywheel/scripts/flywheel-adopt.sh}"
OUT_DIR="${FS_RAG_OUT_DIR:-/Users/josh/Developer/flywheel/.flywheel/audit/flywheel-fs-rag-portable}"
APPLY=0
JSON_OUT=1
IDEMPOTENCY_KEY=""
SIBLINGS=()

usage() {
  cat <<USAGE
Usage:
  fs-rag-sibling-rollout.sh [--apply] [--idempotency-key KEY]
                            [--sibling NAME ...] [--out-dir PATH] [--json]

Default --dry-run. Per repo: probe \`.flywheel/ subtree\` dirty count;
if clean, invoke flywheel-adopt.sh --apply-fs-rag. Aggregates per-repo
rows into \$OUT_DIR/sibling-rollout-<rollout-date>.json.

Gating refinement vs flywheel-hi4e6: the original rollout used
\`git status --porcelain\` (tree-wide). This script uses
\`git status --porcelain .flywheel/\` because that is the precise
mutation surface (Meadows #5).

Exit codes:
  0  rollout succeeded (or dry-run completed)
  1  at least one repo skipped or failed
  64 usage error
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply) APPLY=1; shift ;;
    --dry-run) APPLY=0; shift ;;
    --idempotency-key) IDEMPOTENCY_KEY="${2:?--idempotency-key requires a value}"; shift 2 ;;
    --idempotency-key=*) IDEMPOTENCY_KEY="${1#*=}"; shift ;;
    --sibling) SIBLINGS+=("${2:?--sibling requires a NAME}"); shift 2 ;;
    --out-dir) OUT_DIR="${2:?--out-dir requires a PATH}"; shift 2 ;;
    --json) JSON_OUT=1; shift ;;
    --help|-h) usage; exit 0 ;;
    *) printf 'ERR: unknown argument: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

if [[ "$APPLY" -eq 1 && -z "$IDEMPOTENCY_KEY" ]]; then
  printf 'ERR: --apply requires --idempotency-key\n' >&2
  exit 64
fi

if [[ ! -x "$ADOPT_SCRIPT" ]]; then
  printf 'ERR: flywheel-adopt.sh not executable at %s\n' "$ADOPT_SCRIPT" >&2
  exit 64
fi

if [[ "${#SIBLINGS[@]}" -eq 0 ]]; then
  SIBLINGS=("${DEFAULT_SIBLINGS[@]}")
fi

mkdir -p "$OUT_DIR"
rollout_date="$(date -u +%Y-%m-%d)"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
mode="dry_run"
[[ "$APPLY" -eq 1 ]] && mode="apply"
receipt_path="$OUT_DIR/sibling-rollout-$rollout_date.json"

rows=()
installed=0
skipped=0
failed=0
total=0

for repo in "${SIBLINGS[@]}"; do
  total=$((total + 1))
  path="$DEV_ROOT/$repo"
  reason=""
  status=""
  subtree_dirty_count=0
  baseline_path=""
  violations_total=0

  if [[ ! -d "$path" ]]; then
    status="skipped"; reason="repo_not_found"
    skipped=$((skipped + 1))
  elif ! git -C "$path" rev-parse --show-toplevel >/dev/null 2>&1; then
    status="skipped"; reason="not_a_git_repo"
    skipped=$((skipped + 1))
  elif [[ ! -d "$path/.flywheel" ]]; then
    status="skipped"; reason="flywheel_not_installed"
    skipped=$((skipped + 1))
  else
    # Meadows-refined gate: .flywheel/ subtree only (precise mutation surface).
    subtree_dirty_count="$(git -C "$path" status --porcelain .flywheel/ 2>/dev/null | wc -l | tr -d ' ' || echo 0)"
    if (( subtree_dirty_count > 0 )); then
      status="skipped"; reason="flywheel_subtree_dirty"
      skipped=$((skipped + 1))
    elif [[ "$APPLY" -eq 0 ]]; then
      status="dry_run_ready"; reason="would_apply_on_--apply"
      installed=$((installed + 1))
    else
      # Apply fs-rag substrate via flywheel-adopt.
      set +e
      adopt_out="$("$ADOPT_SCRIPT" --repo "$path" --apply --apply-fs-rag \
        --idempotency-key "$IDEMPOTENCY_KEY" --json 2>&1)"
      adopt_rc=$?
      set -e
      if [[ "$adopt_rc" -eq 0 ]]; then
        status="installed"
        baseline_path="$(jq -r '.fs_rag.baseline_path // empty' <<<"$adopt_out" 2>/dev/null || true)"
        violations_total="$(jq -r '.fs_rag.violations_total // 0' <<<"$adopt_out" 2>/dev/null || echo 0)"
        installed=$((installed + 1))
      else
        status="failed"; reason="adopt_rc_$adopt_rc"
        failed=$((failed + 1))
      fi
    fi
  fi

  rows+=("$(jq -nc \
    --arg repo "$repo" \
    --arg path "$path" \
    --arg status "$status" \
    --arg reason "$reason" \
    --argjson subtree "$subtree_dirty_count" \
    --arg baseline "$baseline_path" \
    --argjson violations "$violations_total" \
    '{
      repo:$repo, path:$path, status:$status,
      reason:(if $reason == "" then null else $reason end),
      flywheel_subtree_dirty_count:$subtree,
      gate:"flywheel_subtree_clean",
      gate_refinement_vs_hi4e6:"tree-wide → .flywheel/-subtree (Meadows #5)",
      baseline_path:(if $baseline == "" then null else $baseline end),
      violations_total:$violations
    }')")
done

rows_json="$(printf '%s\n' "${rows[@]}" | jq -s .)"
jq -nc \
  --arg schema_version "$VERSION" \
  --arg ts "$ts" \
  --arg rollout_date "$rollout_date" \
  --arg mode "$mode" \
  --arg key "$IDEMPOTENCY_KEY" \
  --argjson siblings "$total" \
  --argjson installed "$installed" \
  --argjson skipped "$skipped" \
  --argjson failed "$failed" \
  --argjson rows "$rows_json" \
  '{
    schema_version:$schema_version, ts:$ts, rollout_date:$rollout_date,
    mode:$mode, idempotency_key:(if $key == "" then null else $key end),
    gate:"flywheel_subtree_clean",
    gate_refinement_vs_hi4e6:"tree-wide → .flywheel/-subtree (Meadows #5: gate on actual safety property, not proxy)",
    siblings:$siblings, installed:$installed, skipped:$skipped, failed:$failed,
    rows:$rows
  }' > "$receipt_path"

if [[ "$JSON_OUT" -eq 1 ]]; then
  cat "$receipt_path"
fi

# rc=1 if any repo skipped or failed (signals operator: dirty subtrees or other blockers remain).
if (( skipped > 0 || failed > 0 )); then
  exit 1
fi
exit 0

# Meta-Learning Cross-References (2026-05-19)
# Batch-16 comment backfill; citations are documentation-only and do not alter runtime behavior.
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-19-flywheel-engagement-protocol.md`
# Related: `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-61-agent-first-operator-surface.md`
