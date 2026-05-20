#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
AUDIT_SCRIPT="$ROOT/.flywheel/scripts/supabase-rls-audit.sh"
AUDIT_JSON=""
json=0

usage() {
  cat <<'EOF'
usage: supabase-rls-fleet-gate.sh [--json] [--audit-json FILE]

Tier 4.5 pre-push gate. Fails closed if any attached Supabase project has
public-schema tables with RLS disabled.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --json) json=1; shift ;;
    --audit-json) AUDIT_JSON="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'unknown arg: %s\n' "$1" >&2; usage >&2; exit 64 ;;
  esac
done

if [[ -n "$AUDIT_JSON" ]]; then
  summary="$(cat "$AUDIT_JSON")"
else
  if ! summary="$("$AUDIT_SCRIPT" --json)"; then
    summary="$(jq -nc '{schema_version:"flywheel.supabase_rls_fleet_gate.v1",status:"blocked",reason:"audit_failed",rls_disabled_count:null}')"
    [[ "$json" -eq 1 ]] && printf '%s\n' "$summary"
    exit 1
  fi
fi

disabled="$(jq -r '.rls_disabled_count // .post_reaudit_rls_disabled_count // empty' <<<"$summary")"
if [[ -z "$disabled" ]]; then
  out="$(jq -nc '{schema_version:"flywheel.supabase_rls_fleet_gate.v1",status:"blocked",reason:"missing_rls_disabled_count"}')"
  [[ "$json" -eq 1 ]] && printf '%s\n' "$out"
  exit 1
fi

if [[ "$disabled" -gt 0 ]]; then
  out="$(jq -nc --argjson count "$disabled" '{schema_version:"flywheel.supabase_rls_fleet_gate.v1",status:"blocked",reason:"rls_disabled_in_public",rls_disabled_count:$count}')"
  [[ "$json" -eq 1 ]] && printf '%s\n' "$out"
  exit 1
fi

out="$(jq -nc '{schema_version:"flywheel.supabase_rls_fleet_gate.v1",status:"pass",reason:"no_rls_disabled_in_public",rls_disabled_count:0}')"
if [[ "$json" -eq 1 ]]; then
  printf '%s\n' "$out"
else
  printf 'supabase-rls-fleet-gate status=pass rls_disabled_count=0\n'
fi
