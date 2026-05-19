#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/flywheel-loop-doctor-stale-descendant-reaper.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-loop-doctor-reaper.XXXXXX")"
parents=()

cleanup() {
  for pid in "${parents[@]:-}"; do
    kill -KILL "$pid" >/dev/null 2>&1 || true
  done
  pkill -KILL -f "$TMP" >/dev/null 2>&1 || true
  rm -rf "$TMP"
}
trap cleanup EXIT

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

assert_jq() {
  local file="$1" expr="$2" name="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass=$((pass + 1))
    printf 'ok %d - %s\n' "$pass" "$name"
  else
    fail=$((fail + 1))
    printf 'not ok %d - %s\n' "$((pass + fail))" "$name"
    jq . "$file" >&2 || true
  fi
}

write_chain() {
  local dir="$1" term_mode="$2"
  mkdir -p "$dir"
  cat >"$dir/flywheel-loop" <<'SH'
#!/usr/bin/env bash
script_dir="$(cd "$(dirname "$0")" && pwd -P)"
if [[ "${1:-}" == "doctor" ]]; then
  bash "$script_dir/check-cli-scoping.sh" "$script_dir/wait4path" &
  child=$!
  wait "$child"
fi
SH
  cat >"$dir/check-cli-scoping.sh" <<'SH'
#!/usr/bin/env bash
"$1" &
child=$!
wait "$child"
SH
  if [[ "$term_mode" == "ignore-term" ]]; then
    cat >"$dir/wait4path" <<'SH'
#!/usr/bin/env bash
trap '' TERM
while true; do sleep 60; done
SH
  else
    cat >"$dir/wait4path" <<'SH'
#!/usr/bin/env bash
trap 'exit 0' TERM
while true; do sleep 60; done
SH
  fi
  chmod +x "$dir/flywheel-loop" "$dir/check-cli-scoping.sh" "$dir/wait4path"
}

start_chain() {
  local name="$1" term_mode="$2" dir
  dir="$TMP/$name"
  write_chain "$dir" "$term_mode"
  bash "$dir/flywheel-loop" doctor >/dev/null 2>&1 &
  local pid=$!
  parents+=("$pid")
  for _ in {1..50}; do
    if "$SCRIPT" --dry-run --json --max-age-hours 0 --root-pid "$pid" \
      | jq -e '.stale_descendant_count >= 3' >/dev/null; then
      printf '%s\n' "$pid"
      return 0
    fi
    sleep 0.1
  done
  return 1
}

ok "script syntax" bash -n "$SCRIPT"

parent="$(start_chain normal term)"
"$SCRIPT" --dry-run --json --max-age-hours 0 --root-pid "$parent" >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.mode == "dry-run" and .stale_descendant_count >= 3 and .killed_count == 0' "dry-run identifies stale tree without killing"
ok "dry-run leaves parent alive" kill -0 "$parent"

"$SCRIPT" --apply --json --max-age-hours 0 --root-pid "$parent" >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.mode == "apply" and .stale_descendant_count >= 3 and .killed_count >= 3 and .residual_count == 0' "apply kills stale tree"

"$SCRIPT" --apply --json --max-age-hours 0 --root-pid "$parent" >"$TMP/idempotent.json"
assert_jq "$TMP/idempotent.json" '.mode == "apply" and .stale_descendant_count == 0 and .killed_count == 0 and .residual_count == 0' "second apply is no-op"

resistant="$(start_chain resistant ignore-term)"
"$SCRIPT" --apply --json --max-age-hours 0 --root-pid "$resistant" >"$TMP/escalate.json"
assert_jq "$TMP/escalate.json" '.signal_escalation_count >= 1 and any(.actions[]; .signal == "SIGKILL" and .recovered == true)' "SIGKILL escalation path classified"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 ]]
