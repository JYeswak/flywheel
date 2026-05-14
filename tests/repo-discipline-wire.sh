#!/usr/bin/env bash
# tests/repo-discipline-wire.sh
# End-to-end regression for git-repo-discipline doctrine wiring.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/repo-discipline-check.sh"
HYGIENE_SCRIPT="$ROOT/.flywheel/scripts/repo-hygiene-check.sh"
TEMPLATE_SCRIPT="$ROOT/templates/flywheel-install/scripts/repo-discipline-check.sh"
TEMPLATE_HYGIENE_SCRIPT="$ROOT/templates/flywheel-install/scripts/repo-hygiene-check.sh"
DISPATCH_GATE="$ROOT/.flywheel/scripts/dispatch-capacity-gate.sh"

pass_count=0
fail_count=0
pass() { pass_count=$((pass_count + 1)); printf 'PASS %s\n' "$1"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL %s\n' "$1" >&2; }

assert_contains() {
  local file="$1" pattern="$2" label="$3"
  if rg -q "$pattern" "$ROOT/$file"; then
    pass "$label"
  else
    fail "$label"
  fi
}

TMPREPO="$(mktemp -d -t repo-discipline-wire.XXXXXX)"
trap 'rm -rf "$TMPREPO"' EXIT

(
  cd "$TMPREPO"
  git init -q
  git config user.email "test@example.com"
  git config user.name "test"
  printf 'a\n' > a.txt
  git add a.txt
  git commit -q -m init
) || { fail "tmp repo init"; exit 1; }

reset_tmprepo() {
  (
    cd "$TMPREPO" || exit
    git reset --hard -q HEAD
    git clean -fdq
  )
}

make_untracked_n() {
  local n="$1"
  reset_tmprepo
  (
    cd "$TMPREPO" || exit
    for ((i=0; i<n; i++)); do
      printf 'junk %d\n' "$i" > "junk-$i.tmp"
    done
  )
}

if bash -n "$SCRIPT" 2>/dev/null; then pass "script syntax"; else fail "script syntax"; fi
if bash -n "$HYGIENE_SCRIPT" 2>/dev/null; then pass "hygiene script syntax"; else fail "hygiene script syntax"; fi
if bash -n "$TEMPLATE_SCRIPT" 2>/dev/null; then pass "template script syntax"; else fail "template script syntax"; fi
if bash -n "$TEMPLATE_HYGIENE_SCRIPT" 2>/dev/null; then pass "template hygiene script syntax"; else fail "template hygiene script syntax"; fi

if "$SCRIPT" --info 2>/dev/null | jq -e '.version and .thresholds.untracked_janitor and .handler? // true' >/dev/null; then
  pass "--info envelope"
else
  fail "--info envelope"
fi

if "$SCRIPT" --help 2>/dev/null | grep -q 'usage:'; then
  pass "--help"
else
  fail "--help"
fi

reset_tmprepo
if "$SCRIPT" --repo "$TMPREPO" --no-append --json | jq -e '.class == "clean" and .dirty_total == 0 and .halt == false' >/dev/null; then
  pass "clean classification"
else
  fail "clean classification"
fi

reset_tmprepo
printf 'edit\n' >> "$TMPREPO/a.txt"
if "$SCRIPT" --repo "$TMPREPO" --no-append --json | jq -e '.class == "notable" and .tracked_dirty_count == 1 and .action == "commit_restore_gitignore_or_file_bead_before_close"' >/dev/null; then
  pass "tracked dirty notable"
else
  fail "tracked dirty notable"
fi

make_untracked_n 5
if "$SCRIPT" --repo "$TMPREPO" --no-append --json | jq -e '.class == "janitor_triage_class" and .janitor_triage_required == true and .handler == "/git-repo-janitor"' >/dev/null; then
  pass "untracked janitor threshold"
else
  fail "untracked janitor threshold"
fi

make_untracked_n 20
"$SCRIPT" --repo "$TMPREPO" --no-append --json >/tmp/repo-discipline-wire.json
rc=$?
if jq -e '.class == "halt" and .halt == true and .action == "halt_new_dispatch_until_repo_janitor_plan_or_cleanup_commit"' </tmp/repo-discipline-wire.json >/dev/null && [[ "$rc" -eq 1 ]]; then
  pass "untracked halt threshold"
else
  fail "untracked halt threshold rc=$rc"
fi

TMPSTATE="$(mktemp)"
cat >"$TMPSTATE" <<'EOF'
# Test State

Body.
EOF
make_untracked_n 2
"$SCRIPT" --repo "$TMPREPO" --update-state-md "$TMPSTATE" --no-append --json >/dev/null
"$SCRIPT" --repo "$TMPREPO" --update-state-md "$TMPSTATE" --no-append --json >/dev/null
if [[ "$(grep -c 'repo-hygiene-snapshot:begin' "$TMPSTATE")" -eq 1 ]] && rg -q '/git-repo-janitor' "$TMPSTATE"; then
  pass "STATE block idempotent"
else
  fail "STATE block idempotent"
fi
rm -f "$TMPSTATE"

make_untracked_n 20
ASSIGN_JSON='{}' HEALTH_JSON='{}' DISPATCH_GATE_REPO="$TMPREPO" "$DISPATCH_GATE" test-session 1 >/tmp/repo-discipline-dispatch.json
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.reason == "git_repo_hygiene_halt_threshold" and .repo_hygiene.handler == "/git-repo-janitor"' </tmp/repo-discipline-dispatch.json >/dev/null; then
  pass "dispatch gate halts dirty repo"
else
  fail "dispatch gate halts dirty repo rc=$rc"
fi

reset_tmprepo
(
  cd "$TMPREPO" || exit
  printf '*.generated\n' > .gitignore
  printf 'tracked generated output\n' > tracked.generated
  git add .gitignore
  git add -f tracked.generated
  git commit -q -m shadowed-output
)
ASSIGN_JSON='{}' HEALTH_JSON='{}' DISPATCH_GATE_REPO="$TMPREPO" "$DISPATCH_GATE" test-session 1 >/tmp/repo-hygiene-dispatch.json
rc=$?
if [[ "$rc" -eq 1 ]] && jq -e '.reason == "repo_hygiene_operational_protocol_fail" and .repo_hygiene_operational.fail >= 1 and (.repo_hygiene_operational.checks[] | select(.id == "H-1" and .verdict == "fail"))' </tmp/repo-hygiene-dispatch.json >/dev/null; then
  pass "dispatch gate halts H-1 repo hygiene failure"
else
  fail "dispatch gate halts H-1 repo hygiene failure rc=$rc"
  cat /tmp/repo-hygiene-dispatch.json >&2 || true
fi

assert_contains ".flywheel/doctrine/git-repo-discipline.md" "dirty state is a queue" "doctrine paradigm"
assert_contains "templates/flywheel-install/doctrine/git-repo-discipline.md" "/git-repo-janitor" "template doctrine handler"
assert_contains ".flywheel/doctrine/git-repo-discipline.md" "repo-hygiene-operational-protocol.md" "repo doctrine folds hygiene sister"
assert_contains ".flywheel/doctrine/repo-hygiene-operational-protocol.md" "substrate-hygiene-doctrine-cluster" "hygiene doctrine joins substrate cluster"
assert_contains "templates/flywheel-install/doctrine/repo-hygiene-operational-protocol.md" "substrate-hygiene-doctrine-cluster" "template hygiene doctrine joins substrate cluster"
assert_contains "templates/flywheel-install/STATE.md.tmpl" "Repo Hygiene Snapshot" "state template snapshot"
assert_contains ".flywheel/rules/L095-L144-git-stash-janitor-fleet-hygiene.md" "git-repo-janitor" "L144 names repo janitor"
assert_contains ".flywheel/rules/L095-L144-git-stash-janitor-fleet-hygiene.md" "repo-hygiene-check.sh" "L144 requires repo hygiene protocol"
assert_contains ".flywheel/scripts/dispatch-capacity-gate.sh" "repo-discipline-check.sh" "dispatch gate calls repo discipline"
assert_contains ".flywheel/scripts/dispatch-capacity-gate.sh" "repo-hygiene-check.sh" "dispatch gate calls repo hygiene protocol"
assert_contains ".flywheel/scripts/daily-report.sh" "repo_handler" "daily report emits handler"
assert_contains ".flywheel/scripts/daily-report.sh" "repo_hygiene_protocol" "daily report emits repo hygiene protocol"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
