#!/usr/bin/env bash
set -euo pipefail

BIN="${FLYWHEEL_LOOP_BIN:-$HOME/.claude/skills/.flywheel/bin/flywheel-loop}"
REPO="${FLYWHEEL_LOOP_HEALTH_REPO:-/Users/josh/Developer/flywheel}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/flywheel-loop-health.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" expr="$2" label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" >&2 || true
  fi
}

expect_rc() {
  local label="$1" want="$2"
  shift 2
  set +e
  "$@" >"$TMP/$label.out" 2>"$TMP/$label.err"
  local got=$?
  set -e
  if [[ "$got" -eq "$want" ]]; then
    pass "$label"
  else
    fail "$label expected_rc=$want got_rc=$got"
    cat "$TMP/$label.out" >&2 || true
    cat "$TMP/$label.err" >&2 || true
  fi
}

tree_hash() {
  local dir="$1"
  find "$dir" -type f -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256 | awk '{print $1}'
}

mkdir -p "$TMP/state"
printf '{"status":"ok"}\n' >"$TMP/state/last_tick.json"
printf '{"session":"fixture","effective_at":"2026-05-05T00:00:00Z"}\n' >"$TMP/topology.jsonl"

env_base=(
  "FLYWHEEL_LOOP_STATE_DIR=$TMP/state"
  "FLYWHEEL_SESSION_TOPOLOGY=$TMP/topology.jsonl"
)

bash -n "$BIN" && pass "shell_syntax" || fail "shell_syntax"

expect_rc "health_exits_0_all_alive" 0 env "${env_base[@]}" "$BIN" health --repo "$REPO"

env "${env_base[@]}" "$BIN" health --repo "$REPO" --json >"$TMP/health.json"
assert_jq "$TMP/health.json" '.success == true' "json_success_true"
assert_jq "$TMP/health.json" '.version == "flywheel-loop.health.v1"' "json_version_field"
assert_jq "$TMP/health.json" '.output_format == "json"' "json_output_format"
assert_jq "$TMP/health.json" '(.subsystems | type) == "array" and (.subsystems | length) >= 5' "json_subsystems_array"
assert_jq "$TMP/health.json" 'all(.subsystems[]; (.name|type) == "string" and (.status|IN("ALIVE","DEGRADED","DOWN","NOT_CONFIGURED")) and (.latency_ms|type) == "number" and has("last_error"))' "json_subsystem_shape"

set +e
env "${env_base[@]}" timeout -s INT 3 "$BIN" health --watch -i 1 --json >"$TMP/watch.jsonl"
watch_rc=$?
set -e
if [[ "$(wc -l <"$TMP/watch.jsonl" | tr -d ' ')" -ge 2 ]]; then
  while IFS= read -r line; do jq -e '.command == "health"' >/dev/null <<<"$line"; done <"$TMP/watch.jsonl"
  case "$watch_rc" in
    0|124|130) pass "watch_two_iterations_sigint_clean" ;;
    *) fail "watch_two_iterations_sigint_clean rc=$watch_rc" ;;
  esac
else
  fail "watch_two_iterations_sigint_clean"
fi

expect_rc "degraded_exit_1" 1 env "${env_base[@]}" FLYWHEEL_LOOP_HEALTH_MOCK_STATUS=DEGRADED "$BIN" health --repo "$REPO" --json
expect_rc "down_exit_3" 3 env "${env_base[@]}" FLYWHEEL_LOOP_HEALTH_MOCK_STATUS=DOWN "$BIN" health --repo "$REPO" --json

env "${env_base[@]}" "$BIN" --no-color health --repo "$REPO" >"$TMP/no-color.txt"
if LC_ALL=C rg -q $'\033' "$TMP/no-color.txt"; then
  fail "no_color_has_no_ansi"
else
  pass "no_color_has_no_ansi"
fi

env "${env_base[@]}" "$BIN" schema health --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.schema_version == "flywheel-loop.health.v1" and (.required | index("subsystems")) and .properties.subsystems.items.properties.status.enum' "schema_health_published"

env "${env_base[@]}" "$BIN" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.subcommands | index("health")' "info_lists_health"

env "${env_base[@]}" "$BIN" --examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" 'any(.examples[]; .name == "health_watch") and any(.examples[]; .name == "health_json_filter")' "examples_include_health_watch_and_json_filter"

env "${env_base[@]}" "$BIN" --no-color --no-emoji --width 100 health --repo "$REPO" --json >"$TMP/triad-health.json"
assert_jq "$TMP/triad-health.json" '.success == true and .status == "ALIVE"' "canonical_cli_triad_health_agrees"

before_hash="$(tree_hash "$TMP/state")"
env "${env_base[@]}" "$BIN" health --repo "$REPO" --json >/dev/null
after_hash="$(tree_hash "$TMP/state")"
if [[ "$before_hash" == "$after_hash" ]]; then
  pass "health_pure_read_state_hash_unchanged"
else
  fail "health_pure_read_state_hash_unchanged"
fi

if awk '/^health_item_json\(\)/,/^portable_repair\(\)/' "$BIN" | rg -n 'set|write|update' >/dev/null; then
  fail "health_code_path_no_mutation_verbs"
else
  pass "health_code_path_no_mutation_verbs"
fi

if [[ "$fail_count" -eq 0 ]]; then
  printf 'OK_44fn tests_passed=%s/%s\n' "$pass_count" "$pass_count"
else
  printf 'FAIL tests_passed=%s/%s\n' "$pass_count" "$((pass_count + fail_count))" >&2
  exit 1
fi
