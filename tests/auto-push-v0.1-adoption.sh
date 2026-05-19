#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
AUTO_PUSH="$ROOT/.flywheel/scripts/auto-push.sh"
SOAK="$ROOT/.flywheel/scripts/auto-push-soak-probe.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

pass=0
fail=0
ok() {
  local name="$1"; shift
  if "$@"; then pass=$((pass+1)); printf 'ok %d - %s\n' "$pass" "$name"; else fail=$((fail+1)); printf 'not ok %d - %s\n' "$((pass+fail))" "$name"; fi
}
ok_jq() {
  local name="$1" expr="$2" file="$3"
  if jq -e "$expr" "$file" >/dev/null; then pass=$((pass+1)); printf 'ok %d - %s\n' "$pass" "$name"; else fail=$((fail+1)); printf 'not ok %d - %s\n' "$((pass+fail))" "$name"; jq . "$file" >&2 || true; fi
}

bare="$TMP/origin.git"
repo="$TMP/repo"
git init -q --bare "$bare"
git clone -q "$bare" "$repo"
git -C "$repo" config user.email fixture@example.invalid
git -C "$repo" config user.name Fixture
mkdir -p "$repo/.flywheel/scripts" "$repo/.flywheel/runtime" "$repo/.github/workflows" "$repo/.git/hooks"
cp "$AUTO_PUSH" "$repo/.flywheel/scripts/auto-push.sh"
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
ledger_path: ".flywheel/runtime/auto-push-ledger.jsonl"
on_failure: "block_next_commit"
YAML
printf 'name: fixture\non: [push]\njobs: {fixture: {runs-on: ubuntu-latest, steps: [{run: "true"}]}}\n' >"$repo/.github/workflows/ci.yml"
printf 'baseline\n' >"$repo/README.md"
git -C "$repo" add .
git -C "$repo" commit -q -m baseline
git -C "$repo" push -q -u origin HEAD

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

cat >"$repo/.git/hooks/post-commit" <<'SH'
#!/usr/bin/env bash
set -euo pipefail
"$PWD/.flywheel/scripts/auto-push.sh" --source post-commit --json >/tmp/auto-push-hook.json
SH
chmod +x "$repo/.git/hooks/post-commit"
git -C "$repo" config core.hooksPath .git/hooks

export FAKE_ACT_LOG="$TMP/act.log"
export FAKE_GG_LOG="$TMP/gg.log"
export FAKE_SUPABASE_MIRROR_LOG="$TMP/supabase-mirror.log"
export FLYWHEEL_AUTO_PUSH_ACT_BIN="$TMP/act"
export FLYWHEEL_AUTO_PUSH_GITGUARDIAN_GATE="$TMP/gitguardian"
export FLYWHEEL_AUTO_PUSH_SUPABASE_MIRROR_GATE="$TMP/supabase-mirror-gate"

printf 'change\n' >>"$repo/README.md"
git -C "$repo" add README.md
git -C "$repo" commit -q -m "fixture auto push"

ledger="$repo/.flywheel/runtime/auto-push-ledger.jsonl"
ok "auto-push script syntax" bash -n "$AUTO_PUSH"
ok "soak probe syntax" bash -n "$SOAK"
ok "post-commit hook fired act" test -s "$TMP/act.log"
ok "post-commit hook fired gitguardian" test -s "$TMP/gg.log"
ok "post-commit hook fired supabase mirror gate" test -s "$TMP/supabase-mirror.log"
ok_jq "ledger records post-commit source" 'select(.source=="post-commit" and .local_ci_status=="pass" and .gitguardian_status=="pass" and .supabase_mirror_status=="pass")' "$ledger"
ok_jq "ledger records push success" 'select(.push_attempted==true and .push_success==true and .exit_code==0)' "$ledger"
ok "remote received commit" git -C "$repo" ls-remote --exit-code origin HEAD

AUTO_PUSH_LEDGER="$ledger" AUTO_PUSH_SECRET_LEDGER="$TMP/secret.jsonl" AUTO_PUSH_SOAK_LEDGER="$TMP/soak.jsonl" AUTO_PUSH_SOAK_DAY="$(date -u +%F)" "$SOAK" --json >"$TMP/soak-out.json"
ok_jq "soak probe emits counts" '.post_commit_hook_fired_count >= 1 and .push_success_count >= 1 and .push_blocked_count == 0 and .gitguardian_finding_count == 0' "$TMP/soak-out.json"
ok_jq "soak ledger row written" '.schema_version=="flywheel.auto_push_soak_probe.v1" and (.dashboard_line|contains("Auto-push soak:"))' "$TMP/soak.jsonl"

printf 'SUMMARY pass=%d fail=%d\n' "$pass" "$fail"
[[ "$fail" -eq 0 && "$pass" -ge 10 ]]
