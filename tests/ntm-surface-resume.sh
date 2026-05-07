#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-wave2-native-probes.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-surface-resume.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT
handoff="$TMP/handoff.md"
printf '# Handoff\n' >"$handoff"

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  resume\ flywheel*) printf '%s\n' '{"session":"flywheel","dry_run":true,"handoff":"latest"}' ;;
  resume\ --from*) printf '%s\n' '{"session":"from-file","dry_run":true,"handoff":"explicit"}' ;;
  *) printf 'unsupported: %s\n' "$*" >&2; exit 2 ;;
esac
SH
chmod +x "$TMP/ntm"

out="$(NTM_BIN="$TMP/ntm" NTM_WAVE2_SESSION=flywheel NTM_WAVE2_HANDOFF_FILE="$handoff" "$SCRIPT" resume --json)"
jq -e '.surface == "resume" and (.native_calls | length) == 3 and .latest.dry_run == true and .explicit.handoff == "explicit"' <<<"$out" >/dev/null

callsites="$(rg -n 'ntm resume|resume \"\\$SESSION\"|resume --from|--dry-run --json' "$SCRIPT" "$0" | wc -l | tr -d ' ')"
[[ "$callsites" -ge 3 ]]
echo "ntm-surface-resume PASS callsites=$callsites"
