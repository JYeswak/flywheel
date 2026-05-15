#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/idle-pane-auto-dispatch.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/idle-pane-auto-dispatch-write.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_NTM_ARGV:?}"
case "${1:-}" in
  wait)
    jq -nc '{success:true,condition:"idle",matched:true}'
    ;;
  assign)
    jq -nc '{success:true,data:{assignments:[{bead_id:"flywheel-fixture",pane:2}],skipped:[]}}'
    ;;
  --robot-activity=*)
    # L153 capture-provenance gate fixture: one live+WAITING pane so the gate passes.
    jq -nc '{success:true,agents:[{pane_idx:2,agent_type:"codex",state:"WAITING",capture_provenance:"live",capture_collected_at:"2026-05-11T00:00:00Z"}]}'
    ;;
  *)
    printf 'unexpected fake ntm call: %s\n' "$*" >&2
    exit 2
    ;;
esac
SH
chmod +x "$TMP/ntm"

run_case() {
  local name="$1"; shift
  local repo="$TMP/repo-$name"
  mkdir -p "$repo"
  FAKE_NTM_ARGV="$TMP/$name.argv" "$SCRIPT" --session fixture --repo "$repo" --ntm-bin "$TMP/ntm" "$@" --json \
    >"$TMP/$name.json"
}

run_case dry --dry-run
if jq -e '.schema_version == "idle-pane-auto-dispatch/v3" and .status == "assigned" and .dry_run == true and .apply == false and .wait.exit_code == 0 and .assign.exit_code == 0' "$TMP/dry.json" >/dev/null \
  && grep -q '^wait fixture --until=idle --any --timeout=1s --json$' "$TMP/dry.argv" \
  && grep -q '^--robot-activity=fixture --json$' "$TMP/dry.argv" \
  && grep -q '^assign fixture --repo '"$TMP"'/repo-dry --json --limit=1 --dry-run$' "$TMP/dry.argv"; then
  pass "dry_run_waits_then_previews_native_assign"
else
  fail "dry_run_waits_then_previews_native_assign"
  cat "$TMP/dry.json" "$TMP/dry.argv" >&2
fi

run_case watch --apply --watch --watch-interval=5s --limit=2
if jq -e '.status == "assigned" and .watch == true and .apply == true and (.assign.native_command | contains("--watch")) and (.assign.native_command | contains("--auto"))' "$TMP/watch.json" >/dev/null \
  && grep -q '^assign fixture --repo '"$TMP"'/repo-watch --json --limit=2 --watch --stop-when-done --watch-interval=5s --auto$' "$TMP/watch.argv"; then
  pass "apply_watch_delegates_to_native_ntm_assign_watch"
else
  fail "apply_watch_delegates_to_native_ntm_assign_watch"
  cat "$TMP/watch.json" "$TMP/watch.argv" >&2
fi

"$SCRIPT" --info --json >"$TMP/info.json"
if jq -e '.native_surface | index("ntm assign <session> --watch --auto --json")' "$TMP/info.json" >/dev/null; then
  pass "info_exposes_native_watch_surface"
else
  fail "info_exposes_native_watch_surface"
fi

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" == "3" && "$fail_count" == "0" ]]
