#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-wave2-native-probes.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-surface-cass.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  "cass status --json") printf '%s\n' '{"status":"healthy","indexed_sessions":3}' ;;
  cass\ search*) printf '%s\n' '{"results":[{"session":"flywheel","score":1}]}' ;;
  "cass insights --json") printf '%s\n' '{"insights":["fixture"]}' ;;
  *) printf 'unsupported: %s\n' "$*" >&2; exit 2 ;;
esac
SH
chmod +x "$TMP/ntm"

out="$(NTM_BIN="$TMP/ntm" "$SCRIPT" cass --json)"
jq -e '.surface == "cass" and (.native_calls | length) == 3 and .cass_status.status == "healthy" and (.search.results | length) == 1' <<<"$out" >/dev/null

callsites="$(rg -n 'ntm cass|cass status|cass search|cass insights' "$SCRIPT" "$0" | wc -l | tr -d ' ')"
[[ "$callsites" -ge 3 ]]
echo "ntm-surface-cass PASS callsites=$callsites"
