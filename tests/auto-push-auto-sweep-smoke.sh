#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
AUTO_PUSH="$ROOT/.flywheel/scripts/auto-push.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0

record_pass() {
  pass=$((pass + 1))
  printf 'ok %d - %s\n' "$pass" "$1"
}

record_fail() {
  fail=$((fail + 1))
  printf 'not ok %d - %s\n' "$((pass + fail))" "$1"
}

ok() {
  local name="$1"
  shift
  if "$@"; then
    record_pass "$name"
  else
    record_fail "$name"
  fi
}

ok_jq() {
  local name="$1" expr="$2" file="$3"
  if jq -e "$expr" "$file" >/dev/null; then
    record_pass "$name"
  else
    record_fail "$name"
    jq . "$file" >&2 || true
  fi
}

make_gate_stubs() {
  cat >"$TMP/act" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${FAKE_ACT_LOG:?}"
exit 0
SH
  chmod +x "$TMP/act"

  cat >"$TMP/gitguardian" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${FAKE_GG_LOG:?}"
jq -nc '{status:"clean",reason:"fixture",exit_code:0}'
exit 0
SH
  chmod +x "$TMP/gitguardian"

  cat >"$TMP/supabase-mirror-gate" <<'SH'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"${FAKE_SUPABASE_MIRROR_LOG:?}"
jq -nc '{status:"pass",reason:"fixture",exit_code:0}'
exit 0
SH
  chmod +x "$TMP/supabase-mirror-gate"
}

write_policy() {
  local repo="$1" auto_sweep="$2" allow_mode="$3" message="${4:-}"
  cat >"$repo/.flywheel/auto-push-policy.yaml" <<YAML
schema_version: skillos.auto_push_policy.v1
enabled: true
upstream_required: true
local_ci_gate: true
gitguardian_gate: true
supabase_mirror_gate: true
post_commit_fire: true
push_cadence: post-commit
allowed_branches_regex: "^(main|master|feature/.*)$"
forbidden_branches_regex: "^(private/.*|wip/.*)$"
private_paths_blocklist: []
known_dirty_paths_allow_list:
YAML
  case "$allow_mode" in
    mission)
      cat >>"$repo/.flywheel/auto-push-policy.yaml" <<'YAML'
  - ".flywheel/MISSION.md"
YAML
      ;;
    mission-runtime)
      cat >>"$repo/.flywheel/auto-push-policy.yaml" <<'YAML'
  - ".flywheel/MISSION.md"
  - ".flywheel/runtime/auto-push-ledger.jsonl"
YAML
      ;;
    empty)
      printf '  []\n' >>"$repo/.flywheel/auto-push-policy.yaml"
      ;;
    *)
      printf 'unknown allow_mode: %s\n' "$allow_mode" >&2
      exit 2
      ;;
  esac
  cat >>"$repo/.flywheel/auto-push-policy.yaml" <<YAML
auto_sweep_on_dirty_tree: $auto_sweep
ledger_path: ".flywheel/runtime/auto-push-ledger.jsonl"
on_failure: "block_next_commit"
YAML
  if [[ -n "$message" ]]; then
    printf 'auto_sweep_commit_message: "%s"\n' "$message" >>"$repo/.flywheel/auto-push-policy.yaml"
  fi
}

make_repo() {
  local name="$1" auto_sweep="$2" allow_mode="$3" message="${4:-}"
  local base="$TMP/$name"
  local bare="$base/origin.git"
  local repo="$base/repo"
  mkdir -p "$base"
  git init -q --bare "$bare"
  git clone -q "$bare" "$repo"
  git -C "$repo" config user.email fixture@example.invalid
  git -C "$repo" config user.name Fixture
  mkdir -p "$repo/.flywheel/scripts" "$repo/.flywheel/runtime" "$repo/.github/workflows"
  cp "$AUTO_PUSH" "$repo/.flywheel/scripts/auto-push.sh"
  write_policy "$repo" "$auto_sweep" "$allow_mode" "$message"
  printf '# Mission\n' >"$repo/.flywheel/MISSION.md"
  printf 'name: fixture\non: [push]\njobs: {fixture: {runs-on: ubuntu-latest, steps: [{run: "true"}]}}\n' >"$repo/.github/workflows/ci.yml"
  printf 'baseline\n' >"$repo/README.md"
  git -C "$repo" add .
  git -C "$repo" commit -q -m baseline
  git -C "$repo" push -q -u origin HEAD
  printf '%s\n' "$repo"
}

run_auto_push() {
  local repo="$1" out="$2" source="$3"
  (
    cd "$repo"
    FAKE_ACT_LOG="$TMP/act.log" \
      FAKE_GG_LOG="$TMP/gg.log" \
      FAKE_SUPABASE_MIRROR_LOG="$TMP/supabase-mirror.log" \
      FLYWHEEL_AUTO_PUSH_ACT_BIN="$TMP/act" \
      FLYWHEEL_AUTO_PUSH_GITGUARDIAN_GATE="$TMP/gitguardian" \
      FLYWHEEL_AUTO_PUSH_SUPABASE_MIRROR_GATE="$TMP/supabase-mirror-gate" \
      .flywheel/scripts/auto-push.sh --source "$source" --json >"$out"
  )
}

make_gate_stubs

repo_default="$(make_repo default-message true mission-runtime)"
printf 'allow-listed drift\n' >>"$repo_default/.flywheel/MISSION.md"
run_auto_push "$repo_default" "$TMP/default.json" default-message
ok_jq "all allow-listed dirty paths auto-sweep and push" '.status=="clean" and .reason=="pushed" and .auto_swept==true and (.swept_paths|index(".flywheel/MISSION.md")) and (.non_swept_paths|length==0) and (.sweep_commit_sha|test("^[0-9a-f]{40}$"))' "$TMP/default.json"
ok "default sweep commit message is canonical" test "$(git -C "$repo_default" log -1 --pretty=%s)" = "chore(state): auto-sweep accreting substrate paths [auto-push]"
default_branch="$(git -C "$repo_default" rev-parse --abbrev-ref HEAD)"
default_remote_sha="$(git -C "$repo_default" ls-remote origin "refs/heads/$default_branch" | awk '{print $1}')"
ok "remote received default sweep commit" test "$(git -C "$repo_default" rev-parse HEAD)" = "$default_remote_sha"

repo_override="$(make_repo override-message true mission-runtime "fixture override sweep")"
printf 'override drift\n' >>"$repo_override/.flywheel/MISSION.md"
run_auto_push "$repo_override" "$TMP/override.json" override-message
ok_jq "policy override still auto-sweeps" '.status=="clean" and .auto_swept==true and (.swept_paths|index(".flywheel/MISSION.md"))' "$TMP/override.json"
ok "override sweep commit message is honored" test "$(git -C "$repo_override" log -1 --pretty=%s)" = "fixture override sweep"

repo_block="$(make_repo block true mission)"
printf 'non-allow drift\n' >>"$repo_block/README.md"
set +e
run_auto_push "$repo_block" "$TMP/block.json" block
block_rc=$?
set -e
ok "single non-allow-listed path exits 12" test "$block_rc" -eq 12
ok_jq "single non-allow-listed path emits non_allowlist_dirty" '.status=="blocked" and .reason=="non_allowlist_dirty" and .auto_swept==false and (.non_swept_paths|index("README.md")) and (.swept_paths|length==0)' "$TMP/block.json"

repo_mixed="$(make_repo mixed true mission)"
printf 'allow drift\n' >>"$repo_mixed/.flywheel/MISSION.md"
printf 'non-allow drift\n' >>"$repo_mixed/README.md"
set +e
run_auto_push "$repo_mixed" "$TMP/mixed.json" mixed
mixed_rc=$?
set -e
ok "mixed dirty tree exits 12" test "$mixed_rc" -eq 12
ok_jq "mixed dirty tree reports swept and non-swept paths without commit" '.status=="blocked" and .reason=="non_allowlist_dirty" and .auto_swept==false and (.swept_paths|index(".flywheel/MISSION.md")) and (.non_swept_paths|index("README.md"))' "$TMP/mixed.json"
ok "mixed dirty tree did not stage allow-listed path" git -C "$repo_mixed" diff --cached --quiet

repo_false="$(make_repo disabled false mission)"
printf 'legacy block\n' >>"$repo_false/README.md"
set +e
run_auto_push "$repo_false" "$TMP/disabled.json" disabled
disabled_rc=$?
set -e
ok "auto-sweep disabled preserves exit 12" test "$disabled_rc" -eq 12
ok_jq "auto-sweep disabled preserves dirty_tree reason" '.status=="blocked" and .reason=="dirty_tree" and .auto_swept==false and .auto_sweep_on_dirty_tree==false' "$TMP/disabled.json"

repo_empty="$(make_repo empty true empty)"
printf 'empty allow-list drift\n' >>"$repo_empty/.flywheel/MISSION.md"
set +e
run_auto_push "$repo_empty" "$TMP/empty.json" empty
empty_rc=$?
set -e
ok "empty allow-list exits 12" test "$empty_rc" -eq 12
ok_jq "empty allow-list does not sweep" '.status=="blocked" and .reason=="non_allowlist_dirty" and .auto_swept==false and (.swept_paths|length==0) and (.non_swept_paths|index(".flywheel/MISSION.md"))' "$TMP/empty.json"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 && "$pass" -ge 14 ]]
