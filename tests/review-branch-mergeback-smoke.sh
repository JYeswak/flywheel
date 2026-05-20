#!/usr/bin/env bash
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
RUNNER="$ROOT/.flywheel/scripts/review-branch-mergeback.sh"
INSTALLER="$ROOT/.flywheel/scripts/install-review-branch-mergeback-launchd.sh"
FLEET="$ROOT/.flywheel/scripts/review-branch-mergeback-fleet-rollout.sh"
TMP=$(mktemp -d -t review-branch-mergeback.XXXXXX)
PASS=0
FAIL=0

cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

ok() { PASS=$((PASS + 1)); printf 'ok - %s\n' "$1"; }
not_ok() { FAIL=$((FAIL + 1)); printf 'not ok - %s\n' "$1" >&2; }

json_field() {
  python3 - "$1" "$2" <<'PY'
import json, sys
data = json.loads(sys.argv[1])
value = data
for part in sys.argv[2].split("."):
    value = value[part]
if isinstance(value, bool):
    print(str(value).lower())
else:
    print(value)
PY
}

assert_eq() {
  local got=$1 want=$2 label=$3
  if [[ $got == "$want" ]]; then
    ok "$label"
  else
    not_ok "$label got=$got want=$want"
  fi
}

setup_fixture() {
  local name=$1
  local base="$TMP/$name" remote="$TMP/$name/origin.git" seed="$TMP/$name/seed" work="$TMP/$name/work"
  mkdir -p "$base"
  git init --bare "$remote" >/dev/null
  git init -b main "$seed" >/dev/null
  git -C "$seed" config user.email test@example.com
  git -C "$seed" config user.name "Test User"
  printf 'base\n' > "$seed/file.txt"
  git -C "$seed" add file.txt
  git -C "$seed" commit -m base >/dev/null
  git -C "$seed" remote add origin "$remote"
  git -C "$seed" push -u origin main >/dev/null
  git --git-dir="$remote" symbolic-ref HEAD refs/heads/main
  git -C "$seed" switch -c review/demo >/dev/null
  printf 'review\n' > "$seed/review.txt"
  git -C "$seed" add review.txt
  git -C "$seed" commit -m review >/dev/null
  git -C "$seed" push -u origin review/demo >/dev/null
  git -C "$seed" switch main >/dev/null
  git clone "$remote" "$work" >/dev/null 2>&1
  git -C "$work" config user.email test@example.com
  git -C "$work" config user.name "Test User"
  printf '%s:%s\n' "$seed" "$work"
}

fixture=$(setup_fixture clean)
seed=${fixture%%:*}; work=${fixture#*:}
printf 'main advance\n' >> "$seed/file.txt"
git -C "$seed" add file.txt
git -C "$seed" commit -m main-advance >/dev/null
git -C "$seed" push origin main >/dev/null
out=$(REVIEW_BRANCH_MERGEBACK_AUDIT_LOG="$TMP/audit-clean.jsonl" "$RUNNER" run --repo "$work" --branch review/demo --apply --push --json)
assert_eq "$(json_field "$out" schema_version)" "review_branch_mergeback.v1" "run schema"
assert_eq "$(json_field "$out" outcome)" "rebased" "clean mergeback rebased"
assert_eq "$(json_field "$out" pushed)" "true" "clean mergeback pushed"
if git -C "$work" merge-base --is-ancestor origin/main origin/review/demo; then ok "remote review contains main"; else not_ok "remote review contains main"; fi
assert_eq "$(git -C "$work" branch --show-current)" "main" "original branch restored"

fixture=$(setup_fixture dryrun)
seed=${fixture%%:*}; work=${fixture#*:}
head_before=$(git -C "$work" rev-parse HEAD)
out=$(REVIEW_BRANCH_MERGEBACK_AUDIT_LOG="$TMP/audit-dry.jsonl" "$RUNNER" run --repo "$work" --branch review/demo --dry-run --json)
assert_eq "$(json_field "$out" outcome)" "dry-run" "dry run outcome"
assert_eq "$(git -C "$work" rev-parse HEAD)" "$head_before" "dry run no mutation"

fixture=$(setup_fixture dirty)
work=${fixture#*:}
printf 'dirty\n' >> "$work/file.txt"
out=$(REVIEW_BRANCH_MERGEBACK_AUDIT_LOG="$TMP/audit-dirty.jsonl" "$RUNNER" run --repo "$work" --branch review/demo --apply --json)
assert_eq "$(json_field "$out" outcome)" "skipped" "dirty tree skipped"
assert_eq "$(json_field "$out" reason)" "dirty-tree" "dirty tree reason"

fixture=$(setup_fixture conflict)
seed=${fixture%%:*}; work=${fixture#*:}
git -C "$seed" switch main >/dev/null
printf 'main conflict\n' > "$seed/file.txt"
git -C "$seed" commit -am main-conflict >/dev/null
git -C "$seed" push origin main >/dev/null
git -C "$seed" switch review/demo >/dev/null
printf 'review conflict\n' > "$seed/file.txt"
git -C "$seed" commit -am review-conflict >/dev/null
git -C "$seed" push origin review/demo >/dev/null
mkdir -p "$TMP/bin"
cat > "$TMP/bin/gh" <<'SH'
#!/usr/bin/env bash
printf 'https://github.example.invalid/issues/1\n'
SH
chmod +x "$TMP/bin/gh"
out=$(PATH="$TMP/bin:$PATH" REVIEW_BRANCH_MERGEBACK_AUDIT_LOG="$TMP/audit-conflict.jsonl" "$RUNNER" run --repo "$work" --branch review/demo --apply --conflict-action issue --json)
assert_eq "$(json_field "$out" outcome)" "conflict" "conflict outcome"
assert_eq "$(json_field "$out" followup_filed)" "true" "conflict followup filed"
assert_eq "$(git -C "$work" branch --show-current)" "main" "conflict restored original branch"

out=$(REVIEW_BRANCH_MERGEBACK_LAUNCH_AGENTS_DIR="$TMP/LaunchAgents" REVIEW_BRANCH_MERGEBACK_STATE_DIR="$TMP/state" "$INSTALLER" --repo "$work" --branch review/demo --dry-run --json)
assert_eq "$(json_field "$out" schema_version)" "review_branch_mergeback_launchd.v1" "installer schema"
assert_eq "$(json_field "$out" outcome)" "dry-run" "installer dry-run"
if [[ ! -e "$TMP/LaunchAgents" ]]; then
  ok "installer dry-run no mutation"
else
  not_ok "installer dry-run no mutation"
fi

out=$(REVIEW_BRANCH_MERGEBACK_REPOS="fixture:$work:review/demo:main" REVIEW_BRANCH_MERGEBACK_LAUNCH_AGENTS_DIR="$TMP/LaunchAgents" REVIEW_BRANCH_MERGEBACK_STATE_DIR="$TMP/state" "$FLEET" --dry-run --json)
assert_eq "$(json_field "$out" schema_version)" "review_branch_mergeback_fleet_rollout.v1" "fleet schema"
assert_eq "$(json_field "$out" outcome)" "dry-run" "fleet dry-run"

printf 'SUMMARY pass=%s fail=%s\n' "$PASS" "$FAIL"
[[ $FAIL -eq 0 ]]
