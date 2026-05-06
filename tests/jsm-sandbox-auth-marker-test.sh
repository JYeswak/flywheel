#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
VALIDATOR="$ROOT/.flywheel/scripts/validate-jsm-sandbox-auth-marker.sh"
FLYWHEEL_LOOP_BIN="${FLYWHEEL_LOOP_BIN:-/Users/josh/.claude/skills/.flywheel/bin/flywheel-loop}"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jsm-sandbox-auth-marker-test.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
check_pass() { printf 'CHECK %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

expect_rc() {
  local label="$1" want="$2"
  shift 2
  set +e
  "$@" >"$TMP/$label.out" 2>"$TMP/$label.err"
  local got=$?
  set -e
  if [[ "$got" -eq "$want" ]]; then
    return 0
  fi
  fail "$label rc expected=$want got=$got"
  cat "$TMP/$label.out" >&2 || true
  cat "$TMP/$label.err" >&2 || true
  return 1
}

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    return 0
  fi
  fail "$label"
  jq . "$file" >&2 || true
  return 1
}

iso_offset() {
  python3 - "$1" <<'PY'
import datetime as dt
import sys
hours = int(sys.argv[1])
print((dt.datetime.now(dt.timezone.utc) + dt.timedelta(hours=hours)).strftime("%Y-%m-%dT%H:%M:%SZ"))
PY
}

secret_path="$TMP/marker-hmac-secret"
secret_value="fixture-secret"
printf '%s' "$secret_value" >"$secret_path"
proof="$TMP/proof.txt"
printf 'fixture proof transcript\n' >"$proof"
proof_sha="$(shasum -a 256 "$proof" | awk '{print $1}')"

write_marker() {
  local path="$1" expiry="$2" schema_version="${3:-v1}" hmac_override="${4:-}"
  local tmp_payload="$TMP/payload.json" canonical hmac
  jq -n \
    --arg ts "$(iso_offset 0)" \
    --arg writer "skillos-guarded-runner" \
    --arg writer_session "skillos" \
    --argjson writer_pane 1 \
    --arg what_was_proven "guarded runner verified sandbox auth without live probe side effects" \
    --arg proof_artifact_sha256 "$proof_sha" \
    --arg proof_artifact_path "$proof" \
    --arg expiry_ts "$expiry" \
    --arg schema_version "$schema_version" \
    '{
      ts:$ts,
      writer:$writer,
      writer_session:$writer_session,
      writer_pane:$writer_pane,
      what_was_proven:$what_was_proven,
      proof_artifact_sha256:$proof_artifact_sha256,
      proof_artifact_path:$proof_artifact_path,
      expiry_ts:$expiry_ts,
      schema_version:$schema_version,
      hmac_sha256:""
    }' >"$tmp_payload"
  canonical="$(jq -S -c 'del(.hmac_sha256)' "$tmp_payload")"
  hmac="$(printf '%s' "$canonical" | openssl dgst -sha256 -hmac "$secret_value" -binary | xxd -p -c 256)"
  if [[ -n "$hmac_override" ]]; then
    hmac="$hmac_override"
  fi
  jq --arg hmac "$hmac" '.hmac_sha256 = $hmac' "$tmp_payload" >"$path"
}

run_case() {
  local label="$1" want_rc="$2" marker="$3" jq_filter="$4"
  if expect_rc "$label" "$want_rc" env JSM_SANDBOX_AUTH_SECRET_PATH="$secret_path" "$VALIDATOR" --path "$marker" --json; then
    if assert_jq "$TMP/$label.out" "$jq_filter" "$label json"; then
      pass "$label"
    fi
  fi
}

valid_marker="$TMP/valid.json"
write_marker "$valid_marker" "$(iso_offset 2)"
run_case "valid_marker" 0 "$valid_marker" '.valid == true and .reasons == []'

if expect_rc "valid_doctor" 0 env JSM_SANDBOX_AUTH_MARKER_PATH="$valid_marker" JSM_SANDBOX_AUTH_SECRET_PATH="$secret_path" "$FLYWHEEL_LOOP_BIN" doctor --repo "$ROOT" --scope jsm-sandbox-auth-marker --json; then
  if assert_jq "$TMP/valid_doctor.out" '.status == "pass" and .scope == "jsm-sandbox-auth-marker"' "valid_doctor json"; then
    check_pass "doctor_status_pass"
  fi
fi

missing_marker="$TMP/missing.json"
run_case "missing_marker" 2 "$missing_marker" '.valid == false and (.reasons | index("missing_sandbox_auth_marker"))'

if expect_rc "missing_doctor" 1 env JSM_SANDBOX_AUTH_MARKER_PATH="$missing_marker" JSM_SANDBOX_AUTH_SECRET_PATH="$secret_path" "$FLYWHEEL_LOOP_BIN" doctor --repo "$ROOT" --scope jsm-sandbox-auth-marker --json; then
  if assert_jq "$TMP/missing_doctor.out" '.status == "fail" and (.reasons | index("missing_sandbox_auth_marker"))' "missing_doctor json"; then
    check_pass "doctor_status_fail"
  fi
fi

expired_marker="$TMP/expired.json"
write_marker "$expired_marker" "$(iso_offset -1)"
run_case "expired_marker" 4 "$expired_marker" '.valid == false and (.reasons | index("expired"))'

hmac_marker="$TMP/hmac-mismatch.json"
write_marker "$hmac_marker" "$(iso_offset 2)" "v1" "0000000000000000000000000000000000000000000000000000000000000000"
run_case "hmac_mismatch" 3 "$hmac_marker" '.valid == false and (.reasons | index("hmac_mismatch"))'

schema_marker="$TMP/schema-wrong.json"
write_marker "$schema_marker" "$(iso_offset 2)" "v0"
run_case "wrong_schema_version" 1 "$schema_marker" '.valid == false and (.reasons | index("schema_version_invalid"))'

if [[ "$fail_count" -gt 0 ]]; then
  printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
  exit 1
fi

printf 'SUMMARY pass=%d fail=0\n' "$pass_count"
