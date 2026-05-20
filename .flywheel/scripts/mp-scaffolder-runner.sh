#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
SCAFFOLDER_DIR="$ROOT/.flywheel/scripts/mp-scaffolders"
DEFAULT_RESULTS="$ROOT/.flywheel/audits/fleet-conformance-2026-05-19-v2/results.jsonl"
SCHEMA_VERSION="mp-scaffolder-runner/v1"
MPS="MP-90 MP-91 MP-89 MP-82 MP-97"

usage() {
  cat <<'USAGE'
usage: .flywheel/scripts/mp-scaffolder-runner.sh [--dry-run|--apply] [--target-list PATH] [--limit-per-mp N] [--confirm MP-XX=apply] [--json]

Dry-run is default. Without --target-list, the runner uses the v2
fleet-conformance results as the materialized T1+T2 applicable filter and
selects FAIL rows for MP-90, MP-91, MP-89, MP-82, and MP-97.

--apply requires one --confirm MP-XX=apply flag for every scaffolder that may
mutate targets. This sprint is author-and-test only; do not apply to real fleet
surfaces without Joshua's future gate.
USAGE
}

scaffolder_for_mp() {
  case "$1" in
    MP-90) printf '%s\n' "$SCAFFOLDER_DIR/MP-90-adjacent-skill-boundary-router-scaffold.sh" ;;
    MP-91) printf '%s\n' "$SCAFFOLDER_DIR/MP-91-progress-counter-forced-motion-loop-scaffold.sh" ;;
    MP-89) printf '%s\n' "$SCAFFOLDER_DIR/MP-89-mode-scoped-phase-workspace-scaffold.sh" ;;
    MP-82) printf '%s\n' "$SCAFFOLDER_DIR/MP-82-hook-lifecycle-guardrail-chain-scaffold.sh" ;;
    MP-97) printf '%s\n' "$SCAFFOLDER_DIR/MP-97-federated-retrieval-parity-provenance-scaffold.sh" ;;
    *) return 1 ;;
  esac
}

confirmed() {
  case " $CONFIRMS " in
    *" $1=apply "*) return 0 ;;
    *) return 1 ;;
  esac
}

target_from_json() {
  jq -r '
    if (.target // "") != "" then .target
    elif ((.repo_path // "") != "" and (.path // "") != "") then (.repo_path + "/" + .path)
    else (.path // "")
    end
  '
}

mode="dry-run"
target_list=""
limit_per_mp=0
json=0
CONFIRMS=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) mode="dry-run"; shift ;;
    --apply) mode="apply"; shift ;;
    --target-list) target_list="${2:-}"; shift 2 ;;
    --limit-per-mp) limit_per_mp="${2:-0}"; shift 2 ;;
    --confirm) CONFIRMS="$CONFIRMS ${2:-}"; shift 2 ;;
    --json) json=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

if [[ "$mode" == "apply" ]]; then
  missing=""
  for mp in $MPS; do
    if ! confirmed "$mp"; then
      missing="$missing $mp=apply"
    fi
  done
  if [[ -n "$missing" ]]; then
    printf 'refusing --apply; missing per-scaffolder confirmations:%s\n' "$missing" >&2
    exit 3
  fi
fi

if [[ -n "$target_list" ]]; then
  [[ -r "$target_list" ]] || { printf 'target-list not readable: %s\n' "$target_list" >&2; exit 2; }
else
  [[ -r "$DEFAULT_RESULTS" ]] || { printf 'default results not readable: %s\n' "$DEFAULT_RESULTS" >&2; exit 2; }
fi

run_one() {
  local mp="$1" target="$2" script
  script="$(scaffolder_for_mp "$mp")"
  [[ -x "$script" ]] || { printf 'scaffolder not executable: %s\n' "$script" >&2; return 2; }
  if [[ "$json" -eq 1 ]]; then
    jq -nc --arg sv "$SCHEMA_VERSION" --arg mode "$mode" --arg mp "$mp" --arg target "$target" \
      '{schema_version:$sv,event:"scaffolder_invocation",mode:$mode,mp_id:$mp,target:$target}'
  else
    printf '\n# %s %s %s\n' "$mode" "$mp" "$target"
  fi
  "$script" "--$mode" "$target"
}

run_default_for_mp() {
  local mp="$1" count=0 target
  while IFS= read -r target; do
    [[ -n "$target" ]] || continue
    run_one "$mp" "$target"
    count=$((count + 1))
    if [[ "$limit_per_mp" -gt 0 && "$count" -ge "$limit_per_mp" ]]; then
      break
    fi
  done < <(jq -r --arg mp "$mp" 'select(.mp_id == $mp and .status == "FAIL") | .repo_path + "/" + .path' "$DEFAULT_RESULTS")
}

if [[ -z "$target_list" ]]; then
  for mp in $MPS; do
    run_default_for_mp "$mp"
  done
  exit 0
fi

for mp in $MPS; do
  count=0
  while IFS= read -r line; do
    [[ -n "$line" ]] || continue
    if [[ "$line" == \{* ]]; then
      row_mp="$(jq -r '.mp_id // .mp // ""' <<<"$line")"
      target="$(target_from_json <<<"$line")"
      [[ -z "$row_mp" || "$row_mp" == "$mp" ]] || continue
    else
      target="$line"
    fi
    [[ -n "$target" ]] || continue
    run_one "$mp" "$target"
    count=$((count + 1))
    if [[ "$limit_per_mp" -gt 0 && "$count" -ge "$limit_per_mp" ]]; then
      break
    fi
  done <"$target_list"
done
