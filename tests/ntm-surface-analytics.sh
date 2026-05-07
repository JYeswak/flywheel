#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-wave2-native-probes.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-surface-analytics.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  analytics\ --format\ json\ --days*) printf '%s\n' '{"summary":{"sessions":2}}' ;;
  analytics\ --format\ json\ --sessions*) printf '%s\n' '{"sessions":[{"name":"flywheel"}]}' ;;
  analytics\ --format\ prometheus*) printf '%s\n' '{"prometheus":"ntm_sessions_total 2"}' ;;
  *) printf 'unsupported: %s\n' "$*" >&2; exit 2 ;;
esac
SH
chmod +x "$TMP/ntm"

out="$(NTM_BIN="$TMP/ntm" "$SCRIPT" analytics --json)"
jq -e '.surface == "analytics" and (.native_calls | length) == 3 and .summary.summary.sessions == 2' <<<"$out" >/dev/null

callsites="$(rg -n 'ntm analytics|analytics --format json|analytics --format prometheus' "$SCRIPT" "$0" | wc -l | tr -d ' ')"
[[ "$callsites" -ge 3 ]]
echo "ntm-surface-analytics PASS callsites=$callsites"
