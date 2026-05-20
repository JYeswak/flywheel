#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/w10-mission-lock-cadence-tick.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/w10-cadence.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

ok() {
  local name="$1"
  shift
  if "$@"; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name"
  fi
}

repo="$TMP/repo"
mkdir -p "$repo/.flywheel/state" "$TMP/bin"
git -C "$repo" init -q

cat >"$TMP/bin/flywheel-loop" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >"${W10_DOCTOR_ARG_LOG:?}"
printf '{"mission_lock_age":{"mission_lock_age_hours":400}}\n'
EOF
chmod +x "$TMP/bin/flywheel-loop"

(
  cd /
  W10_REPO="$repo" \
    W10_CADENCE_LEDGER="$TMP/ledger.jsonl" \
    W10_FLYWHEEL_LOOP_BIN="$TMP/bin/flywheel-loop" \
    W10_DOCTOR_ARG_LOG="$TMP/args.log" \
    "$SCRIPT" tick >"$TMP/out.json"
)

ok "script syntax" bash -n "$SCRIPT"
ok "doctor invoked with --repo" grep -q -- "doctor --repo $repo --json" "$TMP/args.log"
ok "mission_lock_age parsed from doctor JSON" jq -e '.mission_lock_age_hours == 400' "$TMP/out.json" >/dev/null
ok "warn threshold reflects JSON age" jq -e '.warn_threshold_hit == true and .status == "warn-14d"' "$TMP/out.json" >/dev/null

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
