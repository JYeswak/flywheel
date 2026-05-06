#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
BIN="$ROOT/.flywheel/scripts/skillos-template-handshake.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/skillos-template-handshake.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0
pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

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
  local name="$1" expected="$2"; shift 2
  set +e
  "$@" >"$TMP/$name.out" 2>"$TMP/$name.err"
  rc=$?
  set -e
  [[ "$rc" == "$expected" ]] && pass "$name rc=$expected" || { fail "$name expected_rc=$expected actual_rc=$rc"; cat "$TMP/$name.err" >&2 || true; }
}

append_ack() {
  local ledger="$1" key="$2" state="$3" version="$4"
  jq -nc --arg key "$key" --arg state "$state" --arg version "$version" --arg ts "2026-05-06T16:00:00Z" '{
    schema_version:"skillos-template-handshake-ack/v1",
    type:"skillos_template_handshake_ack",
    idempotency_key:$key,
    state:$state,
    producer_version_provided:$version,
    templates:(if $state == "success" then [{skill:"agent-mail",template_class:"skill-injection-template",template_version:$version,template_ref:"skillos://templates/agent-mail"}] else [] end),
    acked_at:$ts,
    acker_orch:"skillos:1"
  } + (if $state == "success" then {} else {degraded_fallback:{reason:$state,safe_to_continue:false,fallback_state:$state}} end)' >>"$ledger"
}

bash -n "$BIN" && pass "helper_syntax" || fail "helper_syntax"
"$BIN" --info --json >"$TMP/info.json"
assert_jq "$TMP/info.json" '.name == "skillos-template-handshake" and (.subcommands | length == 4) and (.canonical_cli_flags | length == 5)' "info exposes four subcommands and five cli flags"

ledger1="$TMP/ledger1.jsonl"
"$BIN" request --ledger "$ledger1" --idempotency-key req-valid --skills agent-mail,socraticode --ttl-sec 60 --json >"$TMP/request.json"
jq '.request' "$TMP/request.json" >"$TMP/request-row.json"
expect_rc valid_request_schema 0 "$BIN" validate-request --json "$(jq -c . "$TMP/request-row.json")"
assert_jq "$TMP/request.json" '.state == "requested" and .ledger_written == true and .request.requested_skills == ["agent-mail","socraticode"]' "valid request writes ledger row"

jq 'del(.idempotency_key)' "$TMP/request-row.json" >"$TMP/request-missing-key.json"
expect_rc missing_idempotency_key_fails 1 "$BIN" validate-request --json "$(jq -c . "$TMP/request-missing-key.json")"

ledger2="$TMP/ledger2.jsonl"
"$BIN" request --ledger "$ledger2" --idempotency-key req-match --skills agent-mail --ttl-sec 60 --json >"$TMP/match-request.json"
append_ack "$ledger2" req-other success skillos-skill-injection-template/v1
"$BIN" await-ack --ledger "$ledger2" --idempotency-key req-match --timeout-sec 0 --json >"$TMP/mismatch-await.json"
assert_jq "$TMP/mismatch-await.json" '.state == "unavailable" and .degraded_fallback.reason == "ack_idempotency_key_mismatch_or_missing"' "ack idempotency mismatch rejected"

ledger3="$TMP/ledger3.jsonl"
jq -nc '{
  schema_version:"skillos-template-handshake-request/v1",
  type:"skillos_template_handshake_request",
  idempotency_key:"req-stale",
  producer_version_required:"skillos-skill-injection-template/v1",
  requested_template_class:"skill-injection-template",
  requested_skills:["agent-mail"],
  ttl_seconds:1,
  requestor_orch:"flywheel:1",
  requestor_session:"flywheel",
  requested_at:"2026-01-01T00:00:00Z"
}' >"$TMP/stale-request.json"
"$BIN" validate-request --json "$(jq -c . "$TMP/stale-request.json")" >/dev/null
cat "$TMP/stale-request.json" >"$ledger3"
"$BIN" await-ack --ledger "$ledger3" --idempotency-key req-stale --timeout-sec 0 --json >"$TMP/stale-await.json"
assert_jq "$TMP/stale-await.json" '.state == "stale" and .degraded_fallback.reason == "ttl_expired_before_ack"' "ttl expiry returns stale"

ledger4="$TMP/ledger4.jsonl"
"$BIN" request --ledger "$ledger4" --idempotency-key req-version --skills agent-mail --ttl-sec 60 --producer-version skillos-skill-injection-template/v2 --json >"$TMP/version-request.json"
append_ack "$ledger4" req-version success skillos-skill-injection-template/v1
"$BIN" await-ack --ledger "$ledger4" --idempotency-key req-version --timeout-sec 0 --json >"$TMP/version-await.json"
assert_jq "$TMP/version-await.json" '.state == "unavailable" and .degraded_fallback.reason == "producer_version_mismatch"' "producer version mismatch unavailable"

ledger5="$TMP/ledger5.jsonl"
"$BIN" request --ledger "$ledger5" --idempotency-key req-duplicate --skills agent-mail --ttl-sec 60 --json >"$TMP/dup-first.json"
"$BIN" request --ledger "$ledger5" --idempotency-key req-duplicate --skills agent-mail --ttl-sec 60 --json >"$TMP/dup-second.json"
assert_jq "$TMP/dup-second.json" '.state == "duplicate" and .ledger_written == false' "duplicate request returns duplicate state"

append_ack "$ledger5" req-duplicate success skillos-skill-injection-template/v1
tail -n 1 "$ledger5" >"$TMP/ack-row.json"
expect_rc valid_ack_schema 0 "$BIN" validate-ack --json "$(jq -c . "$TMP/ack-row.json")"
assert_jq "$TMP/valid_ack_schema.out" '.status == "pass"' "valid ack schema output passes"

printf 'RESULT pass=%s fail=%s\n' "$pass_count" "$fail_count"
[[ "$pass_count" -ge 11 && "$fail_count" == "0" ]]
