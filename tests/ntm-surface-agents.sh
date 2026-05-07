#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-wave2-native-probes.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-surface-agents.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "$*" in
  "agents list --json") printf '%s\n' '{"agents":[{"name":"codex","capabilities":["code"]}]}' ;;
  "agents stats --json") printf '%s\n' '{"stats":[{"name":"codex","success_rate":1}]}' ;;
  agents\ recommend*) printf '%s\n' '{"recommendation":{"agent":"codex","reason":"fixture"}}' ;;
  *) printf 'unsupported: %s\n' "$*" >&2; exit 2 ;;
esac
SH
chmod +x "$TMP/ntm"

out="$(NTM_BIN="$TMP/ntm" "$SCRIPT" agents --json)"
jq -e '.surface == "agents" and (.native_calls | length) == 3 and .profiles.agents[0].name == "codex" and .recommendation.recommendation.agent == "codex"' <<<"$out" >/dev/null

callsites="$(rg -n 'ntm agents|agents list|agents stats|agents recommend' "$SCRIPT" "$0" | wc -l | tr -d ' ')"
[[ "$callsites" -ge 3 ]]
echo "ntm-surface-agents PASS callsites=$callsites"
