#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-surface-conflicts.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  conflicts) printf '%s\n' '{"status":"ok","conflicts":[{"path":"fixture.txt","agents":["a","b"]}]}' ;;
  *) printf 'null\n' ;;
esac
SH
chmod +x "$TMP/ntm"

out="$(NTM_BIN="$TMP/ntm" "$ROOT/.flywheel/scripts/shared-surface-reservation-check.sh" --check "$TMP/fixture.txt" --ledger "$TMP/reservations.jsonl" --json)"
jq -e '.ntm_conflicts.native_surface == "ntm conflicts --json" and .ntm_conflicts.conflict_count == 1' <<<"$out" >/dev/null

callsite_count="$(rg -n 'ntm conflicts|conflicts \"\\$SESSION\"|conflicts \"\\$NTM_SESSION\"|conflicts_probe|ntm_conflicts_snapshot' "$ROOT/.flywheel/scripts/dispatch-and-verify.sh" "$ROOT/.flywheel/scripts/dispatch-delivery-verify.sh" "$ROOT/.flywheel/scripts/validate-callback-before-close.sh" "$ROOT/.flywheel/scripts/shared-surface-reservation-check.sh" | wc -l | tr -d ' ')"
[[ "$callsite_count" -ge 3 ]]
echo "ntm-surface-conflicts PASS callsites=$callsite_count"
