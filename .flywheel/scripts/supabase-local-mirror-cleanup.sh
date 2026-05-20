#!/usr/bin/env bash
# shellcheck disable=SC2016
set -euo pipefail

SCHEMA_VERSION="flywheel.supabase_local_mirror_cleanup.v1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
DEFAULT_LEDGER="$ROOT/.flywheel/runtime/supabase-local-mirror-ledger.jsonl"

json=0
dry_run=0
project=""
mirror_dir=""
remove_state=0
ledger="$DEFAULT_LEDGER"
supabase_bin="${SUPABASE_BIN:-supabase}"
docker_bin="${DOCKER_BIN:-docker}"

usage() {
  cat <<'EOF'
usage: supabase-local-mirror-cleanup.sh --project REF [options]

Stops the local mirror stack. Idempotent: missing stacks/directories are clean.

Options:
  --project REF_OR_NAME    Project ref/name used for container naming
  --mirror-dir DIR         Local mirror workspace
  --remove-state           Remove local mirror workspace after stop
  --ledger FILE            Append cleanup event
  --dry-run                Report planned cleanup only
  --json                   Emit structured JSON
EOF
}

die_usage() {
  printf 'ERR: %s\n' "$1" >&2
  usage >&2
  exit 2
}

iso_now() {
  date -u +%Y-%m-%dT%H:%M:%SZ
}

jq_json() {
  jq -nc "$@"
}

sanitize() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9_-' '-'
}

append_ledger() {
  local status="$1" detail="$2"
  mkdir -p "$(dirname "$ledger")"
  jq_json \
    --arg schema "$SCHEMA_VERSION" \
    --arg ts "$(iso_now)" \
    --arg event "cleanup" \
    --arg status "$status" \
    --arg project_ref "$project" \
    --arg mirror_dir "$mirror_dir" \
    --arg detail "$detail" \
    '{schema_version:$schema,ts:$ts,event:$event,status:$status,project_ref:$project_ref,mirror_dir:$mirror_dir,detail:$detail}' >>"$ledger"
}

emit() {
  local status="$1" reason="$2" stop_mode="$3" exit_code="$4"
  if [[ "$json" -eq 1 ]]; then
    jq_json \
      --arg schema "$SCHEMA_VERSION" \
      --arg ts "$(iso_now)" \
      --arg status "$status" \
      --arg reason "$reason" \
      --arg project_ref "$project" \
      --arg mirror_dir "$mirror_dir" \
      --arg stop_mode "$stop_mode" \
      --arg ledger "$ledger" \
      --argjson dry_run "$dry_run" \
      --argjson remove_state "$remove_state" \
      --argjson exit_code "$exit_code" \
      '{schema_version:$schema,ts:$ts,status:$status,reason:$reason,project_ref:$project_ref,mirror_dir:$mirror_dir,stop_mode:$stop_mode,ledger:$ledger,dry_run:($dry_run == 1),remove_state:($remove_state == 1),exit_code:$exit_code}'
  else
    printf 'supabase-local-mirror-cleanup status=%s reason=%s stop_mode=%s mirror_dir=%s\n' "$status" "$reason" "$stop_mode" "$mirror_dir"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --dry-run) dry_run=1; shift ;;
    --project) project="${2:-}"; [[ -n "$project" ]] || die_usage "--project requires value"; shift 2 ;;
    --project=*) project="${1#--project=}"; shift ;;
    --mirror-dir) mirror_dir="${2:-}"; [[ -n "$mirror_dir" ]] || die_usage "--mirror-dir requires DIR"; shift 2 ;;
    --mirror-dir=*) mirror_dir="${1#--mirror-dir=}"; shift ;;
    --remove-state) remove_state=1; shift ;;
    --ledger) ledger="${2:-}"; [[ -n "$ledger" ]] || die_usage "--ledger requires FILE"; shift 2 ;;
    --ledger=*) ledger="${1#--ledger=}"; shift ;;
    --supabase-bin) supabase_bin="${2:-}"; [[ -n "$supabase_bin" ]] || die_usage "--supabase-bin requires CMD"; shift 2 ;;
    --docker-bin) docker_bin="${2:-}"; [[ -n "$docker_bin" ]] || die_usage "--docker-bin requires CMD"; shift 2 ;;
    --help|-h) usage; exit 0 ;;
    *) die_usage "unknown option: $1" ;;
  esac
done

[[ -n "$project" ]] || die_usage "--project is required"
safe_ref="$(sanitize "$project")"
mirror_dir="${mirror_dir:-$ROOT/.flywheel/runtime/supabase-local-mirror/$safe_ref}"

stop_mode="none"
if [[ "$dry_run" -eq 1 ]]; then
  stop_mode="planned"
else
  if [[ -d "$mirror_dir" && -f "$mirror_dir/supabase/config.toml" && "$(command -v "$supabase_bin" || true)" != "" ]]; then
    (cd "$mirror_dir" && "$supabase_bin" stop >/dev/null 2>&1) || true
    stop_mode="supabase-cli"
  fi
  if command -v "$docker_bin" >/dev/null 2>&1; then
    "$docker_bin" rm -f "flywheel-supabase-mirror-$safe_ref" >/dev/null 2>&1 || true
    [[ "$stop_mode" == "none" ]] && stop_mode="docker-postgres-fallback"
  fi
  if [[ "$remove_state" -eq 1 && -d "$mirror_dir" ]]; then
    rm -rf "$mirror_dir"
  fi
fi

append_ledger "pass" "$stop_mode"
emit "pass" "cleanup_complete" "$stop_mode" 0
