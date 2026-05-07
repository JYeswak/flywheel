#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-surface-changes.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  history) printf '%s\n' '{"entries":[{"prompt":"task-123","targets":["1"],"success":true}]}' ;;
  activity) printf '%s\n' '{"agents":[{"pane":1,"state":"THINKING"}]}' ;;
  changes) printf '%s\n' '{"status":"ok","changes":[{"path":"a.txt","agent":"fixture"}]}' ;;
  conflicts) printf '%s\n' '{"status":"ok","conflicts":[]}' ;;
  *) printf 'null\n' ;;
esac
SH
chmod +x "$TMP/ntm"

out="$("$ROOT/.flywheel/scripts/dispatch-delivery-verify.sh" --ntm "$TMP/ntm" --session fixture --pane 1 --task-id task-123 --timeout-sec 1 --json)"
jq -e '.verified == true and (.ntm_changes.changes | length) == 1' <<<"$out" >/dev/null

callsite_count="$(rg -n 'ntm changes|changes \"\\$SESSION\"|changes \"\\$NTM_SESSION\"|changes_probe' "$ROOT/.flywheel/scripts/dispatch-and-verify.sh" "$ROOT/.flywheel/scripts/dispatch-delivery-verify.sh" "$ROOT/.flywheel/scripts/validate-callback-before-close.sh" | wc -l | tr -d ' ')"
[[ "$callsite_count" -ge 3 ]]
echo "ntm-surface-changes PASS callsites=$callsite_count"
