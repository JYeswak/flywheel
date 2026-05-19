#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
WRAPPER="$ROOT/.flywheel/scripts/br-stage-wrapper.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/br-stage-wrapper.XXXXXX")"
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

assert_status() {
  local repo="$1" pattern="$2" label="$3"
  if git -C "$repo" status --short | rg -q "$pattern"; then
    pass "$label"
  else
    fail "$label"
    git -C "$repo" status --short >&2 || true
  fi
}

assert_no_status() {
  local repo="$1" pattern="$2" label="$3"
  if git -C "$repo" status --short | rg -q "$pattern"; then
    fail "$label"
    git -C "$repo" status --short >&2 || true
  else
    pass "$label"
  fi
}

make_fake_br() {
  local path="$1"
  cat >"$path" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
cmd="${1:-}"
case "$cmd" in
  create|close|update)
    mkdir -p .beads
    printf '{"id":"fixture-%s","status":"mutated"}\n' "$cmd" >> .beads/issues.jsonl
    ;;
  dep)
    mkdir -p .beads
    printf '{"id":"fixture-dep","status":"mutated"}\n' >> .beads/issues.jsonl
    ;;
  show|list|ready|blocked)
    printf 'readonly %s\n' "$cmd"
    ;;
  fail-write)
    mkdir -p .beads
    printf '{"id":"fixture-fail","status":"mutated"}\n' >> .beads/issues.jsonl
    exit 9
    ;;
  *)
    printf 'unknown fake br cmd: %s\n' "$cmd" >&2
    exit 64
    ;;
esac
SH
  chmod +x "$path"
}

make_repo() {
  local repo="$1"
  mkdir -p "$repo/.beads"
  git -C "$repo" init -q
  git -C "$repo" config user.email fixture@example.test
  git -C "$repo" config user.name "Fixture User"
  printf '{"id":"seed","status":"open"}\n' >"$repo/.beads/issues.jsonl"
  git -C "$repo" add .beads/issues.jsonl
  git -C "$repo" commit -q -m seed
}

fake_br="$TMP/br-real"
make_fake_br "$fake_br"

for cmd in create close update dep; do
  repo="$TMP/repo-$cmd"
  make_repo "$repo"
  (cd "$repo" && BR_STAGE_WRAPPER_REAL_BR="$fake_br" "$WRAPPER" "$cmd" fixture >/dev/null)
  assert_status "$repo" '^M  \.beads/issues\.jsonl$' "$cmd stages issues.jsonl in index"
  git -C "$repo" commit -q -m "$cmd"
done

for cmd in show list ready blocked; do
  repo="$TMP/repo-$cmd"
  make_repo "$repo"
  (cd "$repo" && BR_STAGE_WRAPPER_REAL_BR="$fake_br" "$WRAPPER" "$cmd" fixture >/dev/null)
  assert_no_status "$repo" '\.beads/issues\.jsonl' "$cmd does not stage read-only op"
done

repo_added="$TMP/repo-added"
mkdir -p "$repo_added"
git -C "$repo_added" init -q
git -C "$repo_added" config user.email fixture@example.test
git -C "$repo_added" config user.name "Fixture User"
(cd "$repo_added" && BR_STAGE_WRAPPER_REAL_BR="$fake_br" "$WRAPPER" create fixture >/dev/null)
assert_status "$repo_added" '^A  \.beads/issues\.jsonl$' "create stages issues.jsonl as Added in empty repo"

repo_fail="$TMP/repo-fail"
make_repo "$repo_fail"
set +e
(cd "$repo_fail" && BR_STAGE_WRAPPER_REAL_BR="$fake_br" "$WRAPPER" fail-write fixture >/dev/null 2>&1)
rc=$?
set -e
if [[ "$rc" -eq 9 ]]; then
  pass "failed br exit code preserved"
else
  fail "failed br exit code preserved"
fi
assert_status "$repo_fail" '^ M \.beads/issues\.jsonl$' "failed write is not staged"

printf 'SUMMARY pass=%d fail=%d\n' "$pass_count" "$fail_count"
[[ "$fail_count" -eq 0 ]]
