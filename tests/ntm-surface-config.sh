#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-wave2-native-probes.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-surface-config.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  "config show --json") printf '%s\n' '{"config":{"coordinator":{"auto_assign":false}}}' ;;
  "config validate --json") printf '%s\n' '{"valid":true,"errors":[]}' ;;
  "config diff --json") printf '%s\n' '{"drifts":[]}' ;;
  *) printf 'unsupported: %s\n' "$*" >&2; exit 2 ;;
esac
SH
chmod +x "$TMP/ntm"

out="$(NTM_BIN="$TMP/ntm" "$SCRIPT" config --json)"
jq -e '.surface == "config" and (.native_calls | length) == 3 and .validate.valid == true and (.diff.drifts | length) == 0' <<<"$out" >/dev/null

callsites="$(rg -n 'ntm config|config show|config validate|config diff' "$SCRIPT" "$0" <flywheel-state>/bin/flywheel | wc -l | tr -d ' ')"
[[ "$callsites" -ge 3 ]]
echo "ntm-surface-config PASS callsites=$callsites"
