#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PROP="$ROOT/.flywheel/scripts/worker-discipline-propagate.sh"
PROBE="$ROOT/.flywheel/scripts/discipline-conformance-probe.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/worker-discipline-propagate.XXXXXX")"
ASSERTIONS=0

cleanup() {
  rm -rf "$TMP"
}
trap cleanup EXIT

fail() {
  printf 'ASSERTION FAILED: %s\n' "$1" >&2
  exit 1
}

pass() {
  ASSERTIONS=$((ASSERTIONS + 1))
}

assert_jq() {
  local file="$1" query="$2" label="$3"
  jq -e "$query" "$file" >/dev/null || fail "$label"
  pass
}

make_repo() {
  local name="$1"
  local repo="$TMP/$name"
  mkdir -p "$repo/.flywheel/doctrine" "$repo/.flywheel/scripts" "$repo/.claude-memory"
  git init -q "$repo"
  git -C "$repo" config user.email "worker-discipline-test@example.com"
  git -C "$repo" config user.name "Worker Discipline Test"
  printf 'seed\n' >"$repo/README.md"
  git -C "$repo" add README.md
  git -C "$repo" commit -q -m "seed"
  printf '%s\n' "$repo"
}

write_hooks() {
  local repo="$1"
  cat >"$repo/.flywheel/scripts/dispatch-template.md" <<'EOF'
Codex panes use /goal through the activation primitive.
Post-callback verify auto_push_status=ok before close.
NEVER stash other workers' WIP.
dry-run/apply parity uses the same computation.
DCG pre-authorized scopes are checked before escalation.
runtime doctrine separation stays read-only unless gated.
EOF
}

fleet_json() {
  python3 - "$@" <<'PY'
import json
import sys
pairs = {}
for item in sys.argv[1:]:
    name, path = item.split("=", 1)
    pairs[name] = path
print(json.dumps(pairs))
PY
}

empty_repo="$(make_repo empty)"
write_hooks "$empty_repo"
export WORKER_DISCIPLINE_FLEET_JSON
WORKER_DISCIPLINE_FLEET_JSON="$(fleet_json "empty=$empty_repo")"

"$PROP" --target-orch empty --apply --json >"$TMP/empty-apply.json"
assert_jq "$TMP/empty-apply.json" '.mutated_files | length >= 6' "empty target created doctrine files"
assert_jq "$TMP/empty-apply.json" '.post_apply_complete == true' "empty target complete after apply"

partial_repo="$(make_repo partial)"
write_hooks "$partial_repo"
mkdir -p "$partial_repo/.flywheel/doctrine"
printf 'custom preexisting doctrine\n' >"$partial_repo/.flywheel/doctrine/auto-push-blocked-worker-discipline.md"
before_hash="$(shasum -a 256 "$partial_repo/.flywheel/doctrine/auto-push-blocked-worker-discipline.md" | awk '{print $1}')"
WORKER_DISCIPLINE_FLEET_JSON="$(fleet_json "partial=$partial_repo")"
"$PROP" --target-orch partial --apply --json >"$TMP/partial-apply.json"
after_hash="$(shasum -a 256 "$partial_repo/.flywheel/doctrine/auto-push-blocked-worker-discipline.md" | awk '{print $1}')"
[[ "$before_hash" == "$after_hash" ]] || fail "partial target overwrote existing doctrine"
pass
assert_jq "$TMP/partial-apply.json" '[.planned_actions[] | select(.type=="copy_doctrine")] | length == 5' "partial target fills only missing doctrines"

"$PROP" --target-orch partial --apply --json >"$TMP/partial-rerun.json"
assert_jq "$TMP/partial-rerun.json" '.planned_actions | length == 0' "idempotent rerun has no planned actions"
assert_jq "$TMP/partial-rerun.json" '.mutated_files | length == 0' "idempotent rerun mutates nothing"

missing_doc_repo="$(make_repo missing-doc)"
write_hooks "$missing_doc_repo"
mkdir -p "$missing_doc_repo/.claude-memory"
for pin in \
  feedback_goal_mode_is_codex_usage_limit_workaround \
  feedback_codex_goal_mode_runtime_enforcement \
  feedback_auto_push_blocked_worker_abandonment \
  feedback_dry_run_apply_parity_contract; do
  printf '%s\n' "$pin" >>"$missing_doc_repo/.claude-memory/MEMORY.md"
done
WORKER_DISCIPLINE_FLEET_JSON="$(fleet_json "missing-doc=$missing_doc_repo")"
"$PROBE" --fleet-default --dry-run --json >"$TMP/missing-doc-probe.json"
assert_jq "$TMP/missing-doc-probe.json" '.repos[0].failures[] | select(.kind=="doctrine" and .id=="auto-push-blocked-worker-discipline")' "probe flags missing doctrine"

missing_memory_repo="$(make_repo missing-memory)"
write_hooks "$missing_memory_repo"
WORKER_DISCIPLINE_FLEET_JSON="$(fleet_json "missing-memory=$missing_memory_repo")"
"$PROP" --target-orch missing-memory --apply --json >/dev/null
rm -f "$missing_memory_repo/.claude-memory/MEMORY.md"
"$PROBE" --fleet-default --dry-run --json >"$TMP/missing-memory-probe.json"
assert_jq "$TMP/missing-memory-probe.json" '.repos[0].failures[] | select(.kind=="memory_pin" and .pin=="feedback_dry_run_apply_parity_contract")' "probe flags missing memory pin"

healthy_repo="$(make_repo healthy)"
write_hooks "$healthy_repo"
WORKER_DISCIPLINE_FLEET_JSON="$(fleet_json "healthy=$healthy_repo")"
"$PROP" --target-orch healthy --apply --json >/dev/null
"$PROBE" --fleet-default --dry-run --auto-bead --threshold 0.85 --json >"$TMP/healthy-probe.json"
assert_jq "$TMP/healthy-probe.json" '.repos[0] | has("bead_action") | not' "auto-bead does not fire for conforming repo"

bad_repo="$(make_repo bad)"
WORKER_DISCIPLINE_FLEET_JSON="$(fleet_json "bad=$bad_repo")"
"$PROBE" --fleet-default --dry-run --auto-bead --threshold 0.85 --json >"$TMP/bad-probe.json"
assert_jq "$TMP/bad-probe.json" '.repos[0].bead_action.status == "dry_run" and .repos[0].bead_action.priority == "2"' "auto-bead dry-run fires below threshold"

printf 'PASS worker-discipline-propagate-smoke assertions=%s\n' "$ASSERTIONS"
