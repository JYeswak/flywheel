#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$ROOT/.flywheel/scripts/orch-worker-identity-manifest.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; exit 1; }

assert_jq() {
  local file="$1"
  local expr="$2"
  local label="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    pass "$label"
  else
    jq . "$file" >&2 || true
    fail "$label"
  fi
}

mkdir -p "$TMP/loops" "$TMP/agent-mail/sessions" "$TMP/tokens" "$TMP/out"
cat >"$TMP/loops/flywheel.json" <<'JSON'
{"session":"flywheel","active":true}
JSON
cat >"$TMP/loops/skillos.json" <<'JSON'
{"session":"skillos","active":true}
JSON
cat >"$TMP/loops/old.json.bak" <<'JSON'
{"session":"old","active":true}
JSON
cat >"$TMP/topology.jsonl" <<'JSONL'
{"session":"flywheel","effective_at":"2026-05-04T18:00:00Z","orchestrator_pane":1,"agent_kind":"codex","worker_panes":[2,3],"worker_agent_kind":"codex","worker_model":"gpt-5.5","worker_effort":"xhigh","fleet_mail_identity":"LavenderGlen"}
{"session":"skillos","effective_at":"2026-05-04T18:01:00Z","orchestrator_pane":1,"agent_kind":"codex","worker_panes":[2],"worker_agent_kind":"codex","worker_model":"gpt-5.5","worker_effort":"xhigh","fleet_mail_identity":"BrightLake"}
JSONL
cat >"$TMP/agent-mail/sessions/flywheel:2.json" <<JSON
{"schema_version":"agent-mail-identity-registry/v2","session":"flywheel","pane":2,"identity_name":"CloudyMill","status":"active","role":"worker","registered_ts":"2026-05-04T18:02:00Z","token_path":"$TMP/tokens/CloudyMill.token"}
JSON
cat >"$TMP/agent-mail/sessions/flywheel:3.json" <<'JSON'
{"schema_version":"agent-mail-identity-registry/v2","session":"flywheel","pane":3,"identity_name":"GoldenNorth","status":"needs_registration","role":"worker","registered_ts":"2026-05-04T18:02:00Z","token_path":null}
JSON
cat >"$TMP/agent-mail/sessions/skillos:2.json" <<JSON
{"schema_version":"agent-mail-identity-registry/v2","session":"skillos","pane":2,"identity_name":"RainyCat","status":"active","role":"worker","registered_ts":"2026-05-04T18:02:00Z","token_path":"$TMP/tokens/RainyCat.token"}
JSON
touch "$TMP/tokens/CloudyMill.token" "$TMP/tokens/RainyCat.token"

zsh -n "$SCRIPT" && pass "manifest_script_syntax" || fail "manifest_script_syntax"
"$SCRIPT" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.dry_run_supported == true and .apply_supported == true and .no_raw_tokens == true' "info_surface"
"$SCRIPT" --examples --json >"$TMP/examples.json"
assert_jq "$TMP/examples.json" '.examples | length >= 3' "examples_surface"
"$SCRIPT" --schema --json >"$TMP/schema.json"
assert_jq "$TMP/schema.json" '.properties.workers.type == "array" and .properties.schema_version.const == "orch-worker-identity/v1"' "schema_surface"

"$SCRIPT" --fleet --dry-run --json --loop-dir "$TMP/loops" --topology "$TMP/topology.jsonl" --agent-mail-dir "$TMP/agent-mail" --out-dir "$TMP/out" >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.mode == "dry-run" and .manifests_written == 0 and .sessions.flywheel.workers == 2 and .sessions.flywheel.registered == 1 and .sessions.skillos.registered == 1' "dry_run_fleet_summary"
test ! -e "$TMP/out/flywheel.json" && pass "dry_run_does_not_write" || fail "dry_run_does_not_write"

"$SCRIPT" --fleet --apply --json --loop-dir "$TMP/loops" --topology "$TMP/topology.jsonl" --agent-mail-dir "$TMP/agent-mail" --out-dir "$TMP/out" >"$TMP/apply.json"
assert_jq "$TMP/apply.json" '.mode == "apply" and .manifests_written == 2' "apply_writes_two_manifests"
assert_jq "$TMP/out/flywheel.json" '.validation.all_workers_registered == false and .validation.unregistered_count == 1 and (.workers[] | select(.pane == 2).fleet_mail_identity) == "CloudyMill" and (.workers[] | select(.pane == 3).registration_status) == "needs_registration"' "flywheel_manifest_content"
assert_jq "$TMP/out/skillos.json" '.validation.all_workers_registered == true and (.workers[] | select(.pane == 2).fleet_mail_identity) == "RainyCat"' "skillos_manifest_content"

if ! grep -R -E 'registration_token|token=' "$TMP/out" >/dev/null; then
  pass "manifest_omits_raw_tokens"
else
  fail "manifest_omits_raw_tokens"
fi
