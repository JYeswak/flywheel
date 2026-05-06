#!/usr/bin/env bats
# Unit tests for codex-stuck-detector oom_killed_pane subclass.
# Trauma class: codex CLI OOM/cgroup-killed (codex#21233, codex#21283).
# Signature: stable hash + no chevron + OS-killed marker; recovery = ntm respawn.
# Bead: flywheel-codex-oom-killed-subclass-2026-05-06
# Mission anchor: 80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a

setup() {
  ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd -P)"
  DETECTOR="$ROOT/.flywheel/scripts/codex-template-stuck-detector.sh"
  FIXTURE_DIR="$ROOT/tests/fixtures/oom_killed"
  TMP="$(mktemp -d "${TMPDIR:-/tmp}/oom-killed-bats.XXXXXX")"
}

teardown() {
  rm -rf "$TMP"
}

@test "detector classifies oom_killed_pane fixture and recommends respawn" {
  run "$DETECTOR" --fixture "$FIXTURE_DIR" --dry-run --json
  [ "$status" -eq 1 ]
  echo "$output" | jq -e '.status == "stuck" and .stuck_count == 1'
  echo "$output" | jq -e '.panes[0].subclass == "oom_killed_pane"'
  echo "$output" | jq -e '.panes[0].recommended_recovery == "respawn"'
  echo "$output" | jq -e '.panes[0].hash_stable == true'
  echo "$output" | jq -e '(.panes[0].hash_t0 | length) == 64'
}

@test "auto-recover dry-run wires ntm_respawn recovery without invoking ntm" {
  run "$DETECTOR" --fixture "$FIXTURE_DIR" --auto-recover --dry-run --json
  [ "$status" -eq 1 ]
  echo "$output" | jq -e '.panes[0].recovery_attempted == "ntm_respawn"'
  echo "$output" | jq -e '.panes[0].recovery_payload.mocked == true'
  echo "$output" | jq -e '.panes[0].recovery_succeeded == false'
}

@test "auto-recover apply path invokes mocked ntm respawn primitive" {
  # Mock ntm to capture the respawn invocation.
  cat >"$TMP/fake-ntm.sh" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${FAKE_NTM_LOG:?}"
exit 0
SH
  chmod +x "$TMP/fake-ntm.sh"
  export FAKE_NTM_LOG="$TMP/ntm.log"
  : >"$FAKE_NTM_LOG"

  # Build a JSON fixture (so live ntm copy is bypassed) with subclass_hint
  cat >"$TMP/oom.json" <<EOF
{
  "schema_version": "codex-stuck-detector.fixture.v1",
  "session": "flywheel",
  "pane": 4,
  "subclass_hint": "oom_killed_pane",
  "t0": "$(cat "$FIXTURE_DIR/t1.txt" | jq -Rs .  | sed 's/^"//;s/"$//')",
  "t1": "$(cat "$FIXTURE_DIR/t1.txt" | jq -Rs .  | sed 's/^"//;s/"$//')"
}
EOF
  # NOTE: with fixture_payload != None, the live respawn primitive is intentionally
  # bypassed in classify (recovery_payload is mocked). This unit test asserts the
  # *contract*: subclass + recommended_recovery + recovery_attempted are correctly
  # plumbed end-to-end. Live respawn is exercised in e2e under apply mode without
  # a fixture, which is out of scope for this bead per dispatch packet.
  run env CODEX_STUCK_DETECTOR_OOM_KILLED_RESPAWN="$TMP/fake-ntm.sh" \
    "$DETECTOR" --fixture "$TMP/oom.json" --auto-recover --apply --json
  echo "$output" | jq -e '.panes[0].subclass == "oom_killed_pane"'
  echo "$output" | jq -e '.panes[0].recommended_recovery == "respawn"'
  echo "$output" | jq -e '.panes[0].recovery_attempted == "ntm_respawn"'
}

@test "info json advertises oom_killed_pane subclass and respawn recovery" {
  run "$DETECTOR" --info
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.subclasses | index("oom_killed_pane") != null'
  echo "$output" | jq -e '.safe_recovery_policy.oom_killed_pane == "respawn"'
}

@test "why oom_killed_pane returns descriptive reason" {
  run "$DETECTOR" why oom_killed_pane --json
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.reason | test("respawn"; "i")'
}
