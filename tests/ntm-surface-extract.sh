#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-wave2-native-probes.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-surface-extract.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  extract\ flywheel\ --last*) printf '%s\n' '{"blocks":[{"lang":"bash","code":"echo ok"}]}' ;;
  extract\ flywheel\ --json*) printf '%s\n' '{"blocks":[{"lang":"text","code":"fixture"}]}' ;;
  *) printf 'unsupported: %s\n' "$*" >&2; exit 2 ;;
esac
SH
chmod +x "$TMP/ntm"

out="$(NTM_BIN="$TMP/ntm" NTM_WAVE2_SESSION=flywheel "$SCRIPT" extract --json)"
jq -e '.surface == "extract" and (.native_calls | length) == 3 and (.last.blocks | length) == 1' <<<"$out" >/dev/null

callsites="$(rg -n 'ntm extract|extract \"\\$SESSION\"|extract flywheel|--last --json|--lang bash' "$SCRIPT" "$0" | wc -l | tr -d ' ')"
[[ "$callsites" -ge 3 ]]
echo "ntm-surface-extract PASS callsites=$callsites"
