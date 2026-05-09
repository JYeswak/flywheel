#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/ntm-pane-sidecar-respawn.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/ntm-pane-sidecar.XXXXXX")"

cleanup() {
  rm -f "$TMP/ntm" "$TMP/log" "$TMP/dry.json" "$TMP/apply.json" "$TMP/rollback.json"
  rmdir "$TMP" 2>/dev/null || true
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

cat >"$TMP/ntm" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >>"${FAKE_NTM_LOG:?}"
case "${1:-}" in
  respawn)
    [[ "$*" == "respawn flywheel --panes=2 --force --json" ]] || {
      printf 'unexpected respawn args: %s\n' "$*" >&2
      exit 2
    }
    jq -nc '{success:true,session:"flywheel",panes:[2],command_source:"recorded"}'
    ;;
  send)
    [[ "$*" == send\ flywheel\ --pane=2\ *\ --json ]] || {
      printf 'unexpected send args: %s\n' "$*" >&2
      exit 2
    }
    jq -nc '{success:true,sent:true,pane:2}'
    ;;
  health)
    [[ "$*" == "health flywheel --pane 2 --json" ]] || {
      printf 'unexpected health args: %s\n' "$*" >&2
      exit 2
    }
    jq -nc '{status:"ok",panes:[{pane:2,status:"ok",binary:"codex",version:"0.129.0"}]}'
    ;;
  version)
    [[ "$*" == "version --json" ]] || {
      printf 'unexpected version args: %s\n' "$*" >&2
      exit 2
    }
    jq -nc '{version:"fixture-ntm",commit:"fixture"}'
    ;;
  *) printf 'unsupported fake ntm args: %s\n' "$*" >&2; exit 2 ;;
esac
SH
chmod +x "$TMP/ntm"
export FAKE_NTM_LOG="$TMP/log"

bash -n "$SCRIPT"
"$SCRIPT" --help | rg -q 'ntm-pane-sidecar-respawn.sh' || fail "help missing command name"
"$SCRIPT" --info | jq -e '.mutation_default == "dry-run"' >/dev/null || fail "info shape"
"$SCRIPT" schema | jq -e '.modes | index("rollback")' >/dev/null || fail "schema shape"
"$SCRIPT" examples | jq -e '.examples | length == 2' >/dev/null || fail "examples shape"
"$SCRIPT" health --ntm-bin "$TMP/ntm" | jq -e '.status == "pass"' >/dev/null || fail "health shape"

"$SCRIPT" \
  --ntm-bin "$TMP/ntm" \
  --session flywheel \
  --pane 2 \
  --command-path /tmp/codex-sidecar \
  --command-arg --dangerously-bypass-approvals-and-sandbox \
  --cwd /Users/josh/Developer/flywheel \
  --env CODEX_HOME=/tmp/codex-sidecar-home \
  --config-override 'model="gpt-5.5"' \
  --dry-run \
  --json >"$TMP/dry.json"

jq -e '
  .schema_version == "ntm-pane-sidecar-respawn/v1"
  and .dry_run == true
  and .target.session == "flywheel"
  and .target.pane == 2
  and .command.path == "/tmp/codex-sidecar"
  and .cwd == "/Users/josh/Developer/flywheel"
  and .env_overrides[0].name == "CODEX_HOME"
  and .env_overrides[0].value_redacted == "<redacted>"
  and .config_overrides[0] == "model=\"gpt-5.5\""
  and .respawn_only_target_pane == true
  and (.planned_actions[0] | test("--panes=2"))
' "$TMP/dry.json" >/dev/null || {
  jq . "$TMP/dry.json" >&2
  fail "dry-run shape"
}

[[ ! -e "$TMP/log" ]] || fail "dry-run should not call ntm"

"$SCRIPT" \
  --ntm-bin "$TMP/ntm" \
  --session flywheel \
  --pane 2 \
  --command-path /tmp/codex-sidecar \
  --command-arg --dangerously-bypass-approvals-and-sandbox \
  --cwd /Users/josh/Developer/flywheel \
  --env CODEX_HOME=/tmp/codex-sidecar-home \
  --config-override 'model="gpt-5.5"' \
  --apply \
  --json >"$TMP/apply.json"

jq -e '
  .success == true
  and .status == "applied"
  and .respawn_only_target_pane == true
  and .health_evidence.payload.panes[0].binary == "codex"
  and .health_evidence.payload.panes[0].version == "0.129.0"
  and .binary_version_evidence.payload.version == "fixture-ntm"
' "$TMP/apply.json" >/dev/null || {
  jq . "$TMP/apply.json" >&2
  fail "apply shape"
}

rg -q '^respawn flywheel --panes=2 --force --json$' "$TMP/log" || fail "apply did not respawn target pane"
rg -q '^send flywheel --pane=2 ' "$TMP/log" || fail "apply did not send sidecar command"
rg -q '^health flywheel --pane 2 --json$' "$TMP/log" || fail "apply did not collect pane health"
rg -q '^version --json$' "$TMP/log" || fail "apply did not collect ntm version"

: >"$TMP/log"
"$SCRIPT" \
  --ntm-bin "$TMP/ntm" \
  --session flywheel \
  --pane 2 \
  --rollback \
  --apply \
  --json >"$TMP/rollback.json"

jq -e '
  .success == true
  and .rollback == true
  and .rollback_returns_to_recorded_command == true
  and .sidecar_send_evidence.stdout == "recorded-command rollback: sidecar send skipped"
' "$TMP/rollback.json" >/dev/null || {
  jq . "$TMP/rollback.json" >&2
  fail "rollback shape"
}

rg -q '^respawn flywheel --panes=2 --force --json$' "$TMP/log" || fail "rollback did not respawn target pane"
if rg -q '^send flywheel --pane=2 ' "$TMP/log"; then
  fail "rollback must not send sidecar command"
fi

printf 'PASS ntm-pane-sidecar-respawn dry_run=true apply_health=true rollback_recorded=true\n'
