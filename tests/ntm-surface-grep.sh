#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-surface-grep.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
LOG="$TMP/ntm.log"

cat >"$TMP/ntm" <<SH
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >>"$LOG"
case "\${1:-}" in
  activity|errors) printf '%s\n' '{"agents":[],"errors":[]}' ;;
  wait) printf '%s\n' '{"status":"healthy"}' ;;
  grep) printf '%s\n' '{"session":"fixture","match_count":1,"matches":[{"pane":"fixture__cod_1","content":"Implement {feature}"}]}' ;;
  *) printf '%s\n' '{"agents":[]}' ;;
esac
SH
chmod +x "$TMP/ntm"

CODEX_STUCK_DETECTOR_NTM_BIN="$TMP/ntm" \
  "$ROOT/.flywheel/scripts/codex-template-stuck-detector.sh" --session fixture --pane 1 --json >/dev/null || true

grep -q '^grep ' "$LOG"
callsite_count="$(rg -n 'ntm grep|\\$[A-Z_]*\"? grep|\\$NTM_BIN\" grep|\\$NTM\" grep' "$ROOT/.flywheel/scripts/codex-template-stuck-detector.sh" "$ROOT/.flywheel/scripts/frozen-pane-detector.sh" "$ROOT/.flywheel/scripts/recovery-escape-then-reprompt.sh" "$ROOT/.flywheel/scripts/worker-stall-alert-probe.sh" | wc -l | tr -d ' ')"
[[ "$callsite_count" -ge 3 ]]
echo "ntm-surface-grep PASS callsites=$callsite_count"
