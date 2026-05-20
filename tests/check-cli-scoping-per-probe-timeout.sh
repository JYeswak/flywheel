#!/usr/bin/env bash
set -euo pipefail

CHECKER="${CANONICAL_CLI_CHECKER:-$HOME/.claude/skills/canonical-cli-scoping/scripts/check-cli-scoping.sh}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/check-cli-probe-timeout.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

cat >"$TMP/fixture-cli" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${PROBE_LOG:?}"
case "${1:-}" in
  doctor)
    if [[ "${2:-}" == "--help" ]]; then sleep 5; fi
    ;;
  health|repair|validate|audit|why|quickstart|help|completion)
    [[ "${2:-}" == "--help" ]] && exit 0
    ;;
  --help)
    printf 'usage: fixture --json --dry-run\n'
    ;;
  --info|--examples)
    exit 0
    ;;
esac
exit 0
EOF
chmod +x "$TMP/fixture-cli"

set +e
start="$(python3 - <<'PY'
import time
print(time.time())
PY
)"
PROBE_LOG="$TMP/probes.log" CHECK_CLI_SCOPING_PROBE_TIMEOUT_SECONDS=0.1 \
  bash "$CHECKER" --json "$TMP/fixture-cli" >"$TMP/out.json"
rc=$?
end="$(python3 - <<'PY'
import time
print(time.time())
PY
)"
set -e

elapsed="$(python3 - "$start" "$end" <<'PY'
import sys
print(float(sys.argv[2]) - float(sys.argv[1]))
PY
)"

test "$rc" -eq 1
python3 - "$elapsed" <<'PY'
import sys
raise SystemExit(0 if float(sys.argv[1]) < 2 else 1)
PY
jq -e '
  .checker_version == "0.3.3"
  and any(.checks[]; .name == "doctor_command" and .status == "FAIL" and (.evidence | contains("timed out")))
  and any(.checks[]; .name == "health_command" and .status == "PASS")
' "$TMP/out.json" >/dev/null
grep -q '^health --help$' "$TMP/probes.log"

printf 'PASS check-cli-scoping per-probe timeout bounds hanging probe and continues\n'
