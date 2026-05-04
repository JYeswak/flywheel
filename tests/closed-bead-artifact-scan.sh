#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCANNER="$ROOT/.flywheel/scripts/closed-bead-artifact-scan.py"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/closed-bead-artifact-scan.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1"; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then
    pass "$label"
  else
    fail "$label"
    jq . "$file" || true
  fi
}

run_scan() {
  local name="$1"; shift
  local out="$TMP/$name.json"
  local rc=0
  "$SCANNER" --json "$@" >"$out" || rc=$?
  printf '%s\n' "$rc" >"$TMP/$name.rc"
  printf '%s\n' "$out"
}

make_repo() {
  local repo="$TMP/repo"
  mkdir -p "$repo"
  git -C "$repo" init -q
  (cd "$repo" && br init >/dev/null)
  printf 'valid\n' >"$repo/valid.txt"
  printf '{"type":"object"}\n' >"$repo/schema.json"
  printf '{not-json\n' >"$repo/bad.schema.json"
  printf '#!/usr/bin/env bash\nexit 7\n' >"$repo/fail.sh"
  chmod +x "$repo/fail.sh"
  printf '#!/usr/bin/env bash\nexit 0\n' >"$repo/not-exec.sh"

  local missing_id command_id ambiguous_id valid_id nonexec_id schema_id
  missing_id="$(cd "$repo" && br create "fixture missing artifact" --type task --priority P2 --description fixture --json | jq -r '.id')"
  command_id="$(cd "$repo" && br create "fixture command fail" --type task --priority P2 --description fixture --json | jq -r '.id')"
  ambiguous_id="$(cd "$repo" && br create "fixture ambiguous prose" --type task --priority P2 --description fixture --json | jq -r '.id')"
  valid_id="$(cd "$repo" && br create "fixture valid artifact" --type task --priority P2 --description fixture --json | jq -r '.id')"
  nonexec_id="$(cd "$repo" && br create "fixture nonexec" --type task --priority P2 --description fixture --json | jq -r '.id')"
  schema_id="$(cd "$repo" && br create "fixture invalid schema" --type task --priority P2 --description fixture --json | jq -r '.id')"

  (cd "$repo" && br close "$missing_id" --reason "DONE artifact=missing-artifact.txt" --json >/dev/null)
  (cd "$repo" && br close "$command_id" --reason "DONE smoke_cmd=./fail.sh" --json >/dev/null)
  (cd "$repo" && br close "$ambiguous_id" --reason "DONE shipped by prose only" --json >/dev/null)
  (cd "$repo" && br close "$valid_id" --reason "DONE artifact=valid.txt schema_path=schema.json" --json >/dev/null)
  (cd "$repo" && br close "$nonexec_id" --reason "DONE executable=not-exec.sh" --json >/dev/null)
  (cd "$repo" && br close "$schema_id" --reason "DONE schema_path=bad.schema.json" --json >/dev/null)

  {
    printf 'missing=%s\n' "$missing_id"
    printf 'command=%s\n' "$command_id"
    printf 'ambiguous=%s\n' "$ambiguous_id"
    printf 'valid=%s\n' "$valid_id"
    printf 'nonexec=%s\n' "$nonexec_id"
    printf 'schema=%s\n' "$schema_id"
  } >"$TMP/ids.env"
  printf '%s\n' "$repo"
}

repo="$(make_repo)"
source "$TMP/ids.env"

schema_out="$(run_scan schema --repo "$repo" --schema)"
assert_jq "$schema_out" '.mutation_requires == ["--apply","--idempotency-key"] and .default_mode == "dry-run"' "B07 CLI schema documents dry-run/apply"

dry_out="$(run_scan dry --repo "$repo" --dry-run)"
dry_rc="$(cat "$TMP/dry.rc")"
if [[ "$dry_rc" == "1" ]]; then
  pass "B07_AG6 dry-run exits candidate nonzero"
else
  fail "B07_AG6 dry-run exits candidate nonzero rc=$dry_rc"
fi
assert_jq "$dry_out" '.reopen_candidates_count == 4 and (.planned_actions | length) == 4' "B07_AG6 dry-run emits JSON candidate list"
if jq -e --arg id "$missing" 'any(.candidates[]; .bead_id == $id and any(.checks[]; .reason == "path_missing"))' "$dry_out" >/dev/null; then
  pass "B07_AG1/B07_AG2 typed missing artifact candidate"
else
  fail "B07_AG1/B07_AG2 typed missing artifact candidate"
  jq . "$dry_out" || true
fi
if jq -e --arg id "$command" 'any(.candidates[]; .bead_id == $id and any(.checks[]; .type == "command" and .reason == "exit_nonzero"))' "$dry_out" >/dev/null; then
  pass "B07_AG2 command smoke fail candidate"
else
  fail "B07_AG2 command smoke fail candidate"
  jq . "$dry_out" || true
fi
if jq -e --arg id "$nonexec" 'any(.candidates[]; .bead_id == $id and any(.checks[]; .reason == "not_executable"))' "$dry_out" >/dev/null; then
  pass "B07_AG2 non-executable candidate"
else
  fail "B07_AG2 non-executable candidate"
  jq . "$dry_out" || true
fi
if jq -e --arg id "$schema" 'any(.candidates[]; .bead_id == $id and any(.checks[]; .reason == "invalid_json"))' "$dry_out" >/dev/null; then
  pass "B07_AG2 invalid schema candidate"
else
  fail "B07_AG2 invalid schema candidate"
  jq . "$dry_out" || true
fi
if jq -e --arg id "$valid" 'any(.valid[]; .bead_id == $id and .state == "closed_valid")' "$dry_out" >/dev/null; then
  pass "B07_AG3 valid artifact remains closed-valid"
else
  fail "B07_AG3 valid artifact remains closed-valid"
  jq . "$dry_out" || true
fi
if jq -e --arg id "$ambiguous" 'any(.unknown[]; .bead_id == $id and .state == "unknown")' "$dry_out" >/dev/null; then
  pass "B07_AG4 ambiguous prose is unknown no reopen"
else
  fail "B07_AG4 ambiguous prose is unknown no reopen"
  jq . "$dry_out" || true
fi

apply_no_key_out="$(run_scan apply-no-key --repo "$repo" --apply)"
if [[ "$(cat "$TMP/apply-no-key.rc")" == "1" ]]; then
  pass "B07_AG5 apply without idempotency key fails"
else
  fail "B07_AG5 apply without idempotency key fails"
fi
assert_jq "$apply_no_key_out" '.error == "--apply requires --idempotency-key"' "B07_AG5 idempotency key required"

apply_out="$(run_scan apply --repo "$repo" --apply --idempotency-key b07-test)"
assert_jq "$apply_out" '.status == "applied" and .audit_receipt.reopened_count == 4 and (.actual_actions | length) == 4' "B07_AG5 apply reopens candidates"
assert_jq "$apply_out" '.audit_receipt.receipt | test("validation-reopen/receipts/b07-test.json")' "B07_AG5 audit references validation receipt"

open_status="$(cd "$repo" && br show "$missing" --json | jq -r '.[0].status')"
valid_status="$(cd "$repo" && br show "$valid" --json | jq -r '.[0].status')"
ambiguous_status="$(cd "$repo" && br show "$ambiguous" --json | jq -r '.[0].status')"
if [[ "$open_status" == "open" && "$valid_status" == "closed" && "$ambiguous_status" == "closed" ]]; then
  pass "B07_AG5 mutation only reopens mechanical candidates"
else
  fail "B07_AG5 mutation only reopens mechanical candidates open=$open_status valid=$valid_status ambiguous=$ambiguous_status"
fi

replay_out="$(run_scan replay --repo "$repo" --apply --idempotency-key b07-test)"
assert_jq "$replay_out" '.status == "idempotent_replay" and (.actual_actions | length) == 0' "B07_AG5 apply idempotent replay"

doctor_out="$(run_scan doctor --repo "$repo" --doctor)"
assert_jq "$doctor_out" '.status == "pass" and .reopen_candidates_count == 0' "B07 doctor clean after reopen"

printf '\nSummary: %s passed, %s failed\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
