#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/idle-pane-auto-dispatch.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/idle-pane-auto-dispatch-watch-guard.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
printf 'ntm should not be called when ntm#124 is open\n' >&2
exit 9
SH
chmod +x "$TMP/ntm"

FLYWHEEL_NTM_124_STATUS=open \
  "$SCRIPT" --session fixture --repo "$TMP/repo" --ntm-bin "$TMP/ntm" --apply --watch --json \
  >"$TMP/out.json"

jq -e '
  .status == "refused_watch_dependency_open"
  and .watch == true
  and .blocked_native_dependency.issue == "ntm#124"
  and .blocked_native_dependency.status == "open"
' "$TMP/out.json" >/dev/null

printf 'PASS watch mode refuses while ntm#124 is open\n'
