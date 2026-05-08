#!/usr/bin/env bash
set -euo pipefail

TMP="$(mktemp -d -t worker-close-git.XXXXXX)"
trap 'rm -rf "$TMP"' EXIT

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
DISPATCH_TEMPLATE="$HOME/.claude/commands/flywheel/_shared/dispatch-template.md"
CLOSE_HANDLER="$HOME/.claude/commands/flywheel/_shared/close-handler.md"
AGENTS="$ROOT/AGENTS.md"
CANONICAL="$ROOT/.flywheel/AGENTS-CANONICAL.md"
INSTALL_TEMPLATE="$ROOT/templates/flywheel-install/AGENTS.md"
COMPLIANCE_SKILL="$HOME/.claude/skills/beads-compliance-and-completion-verification/SKILL.md"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$*"
}

need() {
  command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

extract_scope() {
  local packet="$1"
  sed -n 's/.*scope=\[\([^]]*\)\].*/\1/p' "$packet" \
    | tr ',' '\n' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | sed '/^$/d'
}

validate_close() {
  local repo="$1" packet="$2" callback="$3" start_rev="$4"
  local scope=()
  local path
  while IFS= read -r path; do
    scope+=("$path")
  done < <(extract_scope "$packet")
  ((${#scope[@]} > 0)) || {
    printf 'no declared file scope\n' >&2
    return 2
  }

  local dirty
  dirty="$(git -C "$repo" status --porcelain -- "${scope[@]}")"
  if [[ -n "$dirty" ]]; then
    printf 'declared scope has uncommitted changes — commit before close\n' >&2
    return 1
  fi

  case "$callback" in
    *" git_committed=yes "*)
      if git -C "$repo" log --format=%H "${start_rev}..HEAD" -- "${scope[@]}" | grep -q .; then
        return 0
      fi
      printf 'git_committed=yes without declared-scope commit\n' >&2
      return 1
      ;;
    *" git_committed=no_changes "*)
      return 0
      ;;
    *" git_committed=skipped "*)
      printf 'git_committed=skipped is a workflow violation\n' >&2
      return 1
      ;;
    *)
      printf 'missing git_committed callback field\n' >&2
      return 1
      ;;
  esac
}

need git
need rg

rg -q 'git_committed=<yes\|no_changes\|skipped>' "$DISPATCH_TEMPLATE" || fail "dispatch template missing git_committed field"
rg -q 'declared scope has uncommitted changes' "$CLOSE_HANDLER" || fail "close-handler missing dirty-scope refusal"
for f in "$AGENTS" "$CANONICAL" "$INSTALL_TEMPLATE"; do
  rg -q '^## L143 — WORKER-CLOSE-REQUIRES-GIT-COMMIT' "$f" || fail "missing L143 in $f"
done
rg -q 'declared_scope_dirty_at_close' "$COMPLIANCE_SKILL" || fail "beads-compliance skill missing deterministic check"
pass "static doctrine surfaces wired"

repo="$TMP/repo"
mkdir -p "$repo"
git -C "$repo" init -q
git -C "$repo" config user.name "fixture"
git -C "$repo" config user.email "fixture@example.invalid"
printf 'one\n' >"$repo/a.sh"
printf 'two\n' >"$repo/b.sh"
git -C "$repo" add a.sh b.sh
git -C "$repo" commit -q -m "initial"
start_rev="$(git -C "$repo" rev-parse HEAD)"

packet="$TMP/dispatch.md"
printf 'Dispatch packet declares scope=[a.sh, b.sh]\n' >"$packet"

printf 'changed\n' >"$repo/a.sh"
if validate_close "$repo" "$packet" 'DONE fixture git_committed=yes ' "$start_rev" >"$TMP/dirty.out" 2>"$TMP/dirty.err"; then
  fail "dirty declared scope should refuse close"
fi
rg -q 'declared scope has uncommitted changes' "$TMP/dirty.err" || fail "dirty refusal reason mismatch"
pass "dirty declared scope refuses close"

git -C "$repo" add a.sh
git -C "$repo" commit -q -m "change a"
validate_close "$repo" "$packet" 'DONE fixture git_committed=yes ' "$start_rev" >/dev/null
pass "git_committed yes passes with declared-scope commit"

clean_repo="$TMP/clean"
mkdir -p "$clean_repo"
git -C "$clean_repo" init -q
git -C "$clean_repo" config user.name "fixture"
git -C "$clean_repo" config user.email "fixture@example.invalid"
printf 'one\n' >"$clean_repo/a.sh"
printf 'two\n' >"$clean_repo/b.sh"
git -C "$clean_repo" add a.sh b.sh
git -C "$clean_repo" commit -q -m "initial"
clean_start="$(git -C "$clean_repo" rev-parse HEAD)"
validate_close "$clean_repo" "$packet" 'DONE fixture git_committed=no_changes ' "$clean_start" >/dev/null
pass "git_committed no_changes passes with clean declared scope"

printf 'RESULT worker_close_requires_git_commit pass=4 fail=0\n'
