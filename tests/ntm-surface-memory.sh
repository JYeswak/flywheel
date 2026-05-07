#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-wave2-native-probes.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-surface-memory.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  memory\ context*) printf '%s\n' '{"context":[{"id":"fixture","text":"remember this"}]}' ;;
  "memory privacy --json") printf '%s\n' '{"privacy":{"cross_agent":true}}' ;;
  *) printf 'unsupported: %s\n' "$*" >&2; exit 2 ;;
esac
SH
chmod +x "$TMP/ntm"

out="$(NTM_BIN="$TMP/ntm" "$SCRIPT" memory --json)"
jq -e '.surface == "memory" and (.native_calls | length) == 3 and (.context.context | length) == 1' <<<"$out" >/dev/null

callsites="$(rg -n 'ntm memory|memory context|memory privacy' "$SCRIPT" "$0" | wc -l | tr -d ' ')"
[[ "$callsites" -ge 3 ]]
echo "ntm-surface-memory PASS callsites=$callsites"
