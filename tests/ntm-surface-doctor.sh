#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
FLYWHEEL_BIN="${FLYWHEEL_BIN:-/Users/josh/.claude/skills/.flywheel/bin/flywheel}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-surface-doctor.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
  --help)
    cat <<'EOF'
Available Commands:
  doctor      Run diagnostics
  activity    Show activity
  analytics   Analytics
  assign      Assign
  attach      Attach
  bugs        Bugs
  checkpoint  Checkpoint
Flags:
EOF
    ;;
  doctor)
    if [[ "${NTM_DOCTOR_SCENARIO:-healthy}" == unhealthy ]]; then
      printf '%s\n' '{"overall":"fail","checks":[{"name":"fixture_bad","status":"fail"}]}'
    else
      printf '%s\n' '{"overall":"ok","checks":[{"name":"fixture_good","status":"pass"}]}'
    fi
    ;;
  *)
    printf 'null\n'
    ;;
esac
SH
chmod +x "$TMP/ntm"

healthy="$TMP/healthy.json"
NTM_BIN="$TMP/ntm" "$FLYWHEEL_BIN" doctor --repo "$ROOT" --json >"$healthy" || true
jq -e '.ntm_doctor.status == "PASS" and .ntm_doctor.failed_count == 0' "$healthy" >/dev/null

unhealthy="$TMP/unhealthy.json"
NTM_BIN="$TMP/ntm" NTM_DOCTOR_SCENARIO=unhealthy "$FLYWHEEL_BIN" doctor --repo "$ROOT" --json >"$unhealthy" || true
jq -e '.ntm_doctor.status == "FAIL" and (.soft_violations | index("ntm_doctor_failed"))' "$unhealthy" >/dev/null

rg -n 'ntm doctor|doctor --json|fw_ntm_doctor_json' "$FLYWHEEL_BIN" "$0" >/dev/null
echo "ntm-surface-doctor PASS"
