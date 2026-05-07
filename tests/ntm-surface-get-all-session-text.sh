#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-wave2-native-probes.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-surface-gast.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  get-all-session-text*) printf '%s\n' '{"sessions":[{"name":"flywheel","panes":4}]}' ;;
  *) printf 'unsupported: %s\n' "$*" >&2; exit 2 ;;
esac
SH
chmod +x "$TMP/ntm"

out="$(NTM_BIN="$TMP/ntm" "$SCRIPT" get-all-session-text --json)"
jq -e '.surface == "get-all-session-text" and (.native_calls | length) == 3 and .full.sessions[0].name == "flywheel"' <<<"$out" >/dev/null

callsites="$(rg -n 'ntm get-all-session-text|get-all-session-text --lines|get-all-session-text --compact' "$SCRIPT" "$0" | wc -l | tr -d ' ')"
[[ "$callsites" -ge 3 ]]
echo "ntm-surface-get-all-session-text PASS callsites=$callsites"
