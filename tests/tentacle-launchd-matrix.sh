#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/tentacle-launchd-matrix.sh"
TMPDIR="$(mktemp -d -t tentacle-launchd-test.XXXXXX)"
trap 'rm -rf "$TMPDIR"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

mkdir -p "$TMPDIR/bin" "$TMPDIR/plists"
touch "$TMPDIR/bin/good" "$TMPDIR/bin/stale" "$TMPDIR/bin/missing" "$TMPDIR/bin/disabled"
touch "$TMPDIR/plists/good.plist" "$TMPDIR/plists/stale.plist" "$TMPDIR/plists/missing.plist" "$TMPDIR/plists/disabled.plist"

cat >"$TMPDIR/registry.json" <<JSON
{
  "schema_version": "tentacle-daemon-registry/v1",
  "daemons": [
    {
      "name": "good",
      "plist_label": "fixture.good",
      "plist_path": "$TMPDIR/plists/good.plist",
      "expected_state": "running",
      "expected_uptime_seconds": 0,
      "binary_path": "$TMPDIR/bin/good",
      "restart_policy": "manual_restart_on_missing",
      "restart_command": "launchctl kickstart -k gui/501/fixture.good"
    },
    {
      "name": "missing",
      "plist_label": "fixture.missing",
      "plist_path": "$TMPDIR/plists/missing.plist",
      "expected_state": "running",
      "expected_uptime_seconds": 0,
      "binary_path": "$TMPDIR/bin/missing",
      "restart_policy": "manual_restart_on_missing",
      "restart_command": "launchctl kickstart -k gui/501/fixture.missing"
    },
    {
      "name": "stale",
      "plist_label": "fixture.stale",
      "plist_path": "$TMPDIR/plists/stale.plist",
      "expected_state": "running",
      "expected_uptime_seconds": 999999,
      "binary_path": "$TMPDIR/bin/stale",
      "restart_policy": "manual_restart_on_stale",
      "restart_command": "launchctl kickstart -k gui/501/fixture.stale"
    },
    {
      "name": "disabled",
      "plist_label": "fixture.disabled",
      "plist_path": "$TMPDIR/plists/disabled.plist",
      "expected_state": "disabled",
      "expected_uptime_seconds": 0,
      "binary_path": "$TMPDIR/bin/disabled",
      "restart_policy": "blocked_pending_upstream",
      "restart_command": null
    }
  ]
}
JSON

cat >"$TMPDIR/launchctl-list.txt" <<LIST
$$	0	fixture.good
$$	0	fixture.stale
$$	0	fixture.disabled
LIST

bash -n "$SCRIPT"
"$SCRIPT" --schema >/dev/null
"$SCRIPT" --info >/dev/null
"$SCRIPT" --examples | jq -e '.examples | length >= 4' >/dev/null
"$SCRIPT" help exit-codes | rg -q 'exit codes'
"$SCRIPT" completion bash | rg -q 'tentacle-launchd-matrix'
"$SCRIPT" repair --dry-run --json | jq -e '.planned_actions == [] and .actual_actions == []' >/dev/null

json="$TMPDIR/audit.json"
"$SCRIPT" --registry "$TMPDIR/registry.json" --launchctl-list "$TMPDIR/launchctl-list.txt" --json >"$json"

jq -e '
  .schema_version == "tentacle-launchd-matrix/v1" and
  .status == "warn" and
  .total == 4 and
  .mutation_performed == false and
  any(.rows[]; .plist_label == "fixture.good" and .status == "pass") and
  any(.rows[]; .plist_label == "fixture.missing" and .status == "warn" and .reason == "missing_launchd_label") and
  any(.rows[]; .plist_label == "fixture.stale" and .status == "warn" and .reason == "uptime_below_expected") and
  any(.rows[]; .plist_label == "fixture.disabled" and .status == "warn" and .reason == "disabled_but_loaded")
' "$json" >/dev/null || fail "audit reconciliation mismatch"

"$SCRIPT" validate --registry "$TMPDIR/registry.json" --launchctl-list "$TMPDIR/launchctl-list.txt" --json \
  | jq -e '.validation == "pass" and .registry_missing_required_count == 0' >/dev/null || fail "validation mismatch"

"$SCRIPT" matrix --registry "$TMPDIR/registry.json" --launchctl-list "$TMPDIR/launchctl-list.txt" --json \
  | jq -e '.mutation_performed == false and any(.restart_matrix[]; .plist_label == "fixture.missing" and .planned_restart_action != null)' >/dev/null \
  || fail "restart matrix mismatch"

printf 'PASS tests/tentacle-launchd-matrix.sh\n'
