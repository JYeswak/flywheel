#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
WRAPPER="$ROOT/.flywheel/scripts/br-stage-wrapper.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/br-residual-dirt.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() {
  pass_count=$((pass_count + 1))
  printf 'ok %d - %s\n' "$pass_count" "$1"
}

fail() {
  fail_count=$((fail_count + 1))
  printf 'not ok %d - %s\n' "$((pass_count + fail_count))" "$1" >&2
}

fake_br="$TMP/br-real"
cat >"$fake_br" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
cmd="${1:-}"
mkdir -p .beads .flywheel
case "$cmd" in
  create)
    printf '{"id":"fixture-sprint","status":"open"}\n' >> .beads/issues.jsonl
    ;;
  close)
    printf '{"id":"fixture-sprint","status":"closed"}\n' >> .beads/issues.jsonl
    ;;
  *)
    printf 'fake br unsupported: %s\n' "$cmd" >&2
    exit 64
    ;;
esac
SH
chmod +x "$fake_br"

repo="$TMP/repo"
mkdir -p "$repo/.flywheel" "$repo/.beads"
git -C "$repo" init -q
git -C "$repo" config user.email fixture@example.test
git -C "$repo" config user.name "Fixture User"
printf '{"id":"seed","status":"open"}\n' >"$repo/.beads/issues.jsonl"
git -C "$repo" add .beads/issues.jsonl
git -C "$repo" commit -q -m seed

jq -nc '{event:"ack",task_id:"fixture-sprint",status:"STARTED"}' >>"$repo/.flywheel/dispatch-log.jsonl"
git -C "$repo" add .flywheel/dispatch-log.jsonl
git -C "$repo" commit -q -m "ack row"
if [[ -z "$(git -C "$repo" status --short)" ]]; then
  pass "clean after ack commit"
else
  fail "clean after ack commit"
fi

(cd "$repo" && BR_STAGE_WRAPPER_REAL_BR="$fake_br" "$WRAPPER" create "fixture sprint" >/dev/null)
git -C "$repo" commit -q -m "create bead"
if [[ -z "$(git -C "$repo" status --short)" ]]; then
  pass "clean after create commit"
else
  fail "clean after create commit"
fi

(cd "$repo" && BR_STAGE_WRAPPER_REAL_BR="$fake_br" "$WRAPPER" close fixture-sprint --reason "done" >/dev/null)
jq -nc '{event:"worker_callback",task_id:"fixture-sprint",status:"DONE"}' >>"$repo/.flywheel/dispatch-log.jsonl"
git -C "$repo" add .flywheel/dispatch-log.jsonl
git -C "$repo" commit -q -m "close bead"

status="$(git -C "$repo" status --short)"
if [[ -z "$status" ]]; then
  pass "no residual dirt after final commit"
else
  fail "no residual dirt after final commit"
  printf '%s\n' "$status" >&2
fi

if git -C "$repo" log --name-only --oneline -1 | rg -q '\.beads/issues\.jsonl'; then
  pass "final commit included staged issues.jsonl"
else
  fail "final commit included staged issues.jsonl"
fi

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
