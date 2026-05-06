#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
SCRIPT="$ROOT/.flywheel/scripts/jeff-daily-diff.sh"
TEMPLATE="$ROOT/.flywheel/scripts/jeff-report-template.sh"
VERDICT="$ROOT/.flywheel/scripts/jeff-verdict-heuristic.sh"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/jeff-daily-diff.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

pass_count=0
fail_count=0

pass() { printf 'PASS %s\n' "$1"; pass_count=$((pass_count + 1)); }
fail() { printf 'FAIL %s\n' "$1" >&2; fail_count=$((fail_count + 1)); }

assert_jq() {
  local file="$1" filter="$2" label="$3"
  if jq -e "$filter" "$file" >/dev/null; then pass "$label"; else fail "$label"; jq . "$file" >&2 || true; fi
}

assert_file_contains() {
  local file="$1" pattern="$2" label="$3"
  if rg -q "$pattern" "$file"; then pass "$label"; else fail "$label"; sed -n '1,160p' "$file" >&2 || true; fi
}

commit_repo() {
  local repo="$1" file="$2" text="$3" msg="$4"
  printf '%s\n' "$text" >"$repo/$file"
  git -C "$repo" add "$file"
  git -C "$repo" commit -q -m "$msg"
  git -C "$repo" rev-parse HEAD
}

make_repo() {
  local repo="$1"
  mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" config user.email "fixture@example.com"
  git -C "$repo" config user.name "Fixture"
}

bash -n "$SCRIPT" "$TEMPLATE" "$VERDICT" && pass "script_syntax" || fail "script_syntax"
shellcheck "$SCRIPT" "$TEMPLATE" "$VERDICT" && pass "script_shellcheck" || fail "script_shellcheck"
"$SCRIPT" --info --json | jq -e '.schema_version == "jeff-daily-diff/info/v1" and .status == "pass"' >/dev/null && pass "script_info_json" || fail "script_info_json"
"$SCRIPT" --schema --json | jq -e '.schema_version == "jeff-daily-diff/schema/v1" and .status == "pass" and (.report_sections | index("Run metadata")) and (.report_sections | index("New Commits (by repo)")) and (.report_sections | index("Aggregate \"What can we learn\" digest")) and (.verdict_enum | index("YES_ADOPT"))' >/dev/null && pass "script_schema_json" || fail "script_schema_json"
"$TEMPLATE" --info --json | jq -e '.schema_version == "jeff-report-template/schema/v1" and (.sections | index("New Tweets (doodlestein)")) and (.verdict_enum | index("NEED_RESEARCH"))' >/dev/null && pass "template_schema_json" || fail "template_schema_json"
"$VERDICT" --repo mcp_agent_mail --commit "fix mcp_agent_mail JSONL append gate" --json | jq -e '.verdict == "YES_ADOPT" and (.matched | length) > 0' >/dev/null && pass "verdict_yes_adopt" || fail "verdict_yes_adopt"
"$VERDICT" --repo model_lab --commit "train pytorch cuda checkpoint" --json | jq -e '.verdict == "NO_NOT_OUR_DOMAIN"' >/dev/null && pass "verdict_no_not_our_domain" || fail "verdict_no_not_our_domain"
"$VERDICT" --repo cli_schema --commit "add callback schema tests" --json | jq -e '.verdict == "YES_ADAPT"' >/dev/null && pass "verdict_yes_adapt" || fail "verdict_yes_adapt"
"$TEMPLATE" --example --output "$TMP/example.md" --json | jq -e '.status == "pass" and (.sections | index("Run metadata"))' >/dev/null && pass "template_example_json" || fail "template_example_json"
assert_file_contains "$TMP/example.md" '^## Run metadata' "template_example_run_metadata"
assert_file_contains "$TMP/example.md" '^## New Commits \(by repo\)' "template_example_commits"
assert_file_contains "$TMP/example.md" 'YES_ADOPT' "template_example_yes_adopt"
assert_file_contains "$TMP/example.md" '^## Actionable Signals' "template_example_actionable_signals"
assert_file_contains "$TMP/example.md" 'Apply-to-flywheel hypothesis' "template_example_apply_hypothesis"
assert_file_contains "$TMP/example.md" '^## Aggregate "What can we learn" digest' "template_example_digest"

repo_root="$TMP/repos"
state_dir="$TMP/state"
mkdir -p "$repo_root" "$state_dir"

make_repo "$repo_root/changed_repo"
old_changed="$(commit_repo "$repo_root/changed_repo" README.md old "old commit")"
new_changed="$(commit_repo "$repo_root/changed_repo" README.md new "add mcp_agent_mail JSONL append gate")"

make_repo "$repo_root/unchanged_repo"
unchanged_sha="$(commit_repo "$repo_root/unchanged_repo" README.md stable "stable commit")"

make_repo "$repo_root/fetch_fail_repo"
fetch_fail_sha="$(commit_repo "$repo_root/fetch_fail_repo" README.md stable "stable commit")"
git -C "$repo_root/fetch_fail_repo" remote add origin "$TMP/missing-remote"

jq -n \
  --arg old_changed "$old_changed" \
  --arg unchanged_sha "$unchanged_sha" \
  --arg fetch_fail_sha "$fetch_fail_sha" \
  --arg changed_path "$repo_root/changed_repo" \
  --arg unchanged_path "$repo_root/unchanged_repo" \
  --arg fetch_fail_path "$repo_root/fetch_fail_repo" \
  '{
    schema_version:"jeff-daily-diff-state/v1",
    last_run_ts:"2026-05-04T00:00:00Z",
    blog:{last_hash:"old"},
    repos:{
      changed_repo:{path:$changed_path,last_seen_sha:$old_changed,last_success_ts:"2026-05-04T00:00:00Z"},
      unchanged_repo:{path:$unchanged_path,last_seen_sha:$unchanged_sha,last_success_ts:"2026-05-04T00:00:00Z"},
      fetch_fail_repo:{path:$fetch_fail_path,last_seen_sha:$fetch_fail_sha,last_success_ts:"2026-05-04T00:00:00Z"}
    }
  }' >"$state_dir/last-diff-run.json"

cat >"$TMP/x.md" <<'EOF'
Agent Mail is still very useful for coordinating multiple full agents, especially because file reservations are critical.
https://x.com/doodlestein/status/1
---
I always break things into chunks of work using beads. It is the only way to get good results beyond trivial scripts.
https://x.com/doodlestein/status/2
---
The ntm process is powerful because of parallelism and combining different models and harnesses.
https://x.com/doodlestein/status/3
EOF
cat >"$TMP/rss.xml" <<'EOF'
<rss><channel><title>Jeffrey Emanuel</title><item><title>New post</title></item></channel></rss>
EOF

"$SCRIPT" \
  --repo-root "$repo_root" \
  --state-dir "$state_dir" \
  --now "2026-05-05T07:00:00Z" \
  --x-fixture "$TMP/x.md" \
  --rss-fixture "$TMP/rss.xml" \
  --skip-fetch \
  --json >"$TMP/first.json"

assert_jq "$TMP/first.json" '.status == "pass" and .repo_count == 3 and .changed_repo_count == 1 and .actionable_signal_count >= 3 and .reindex_queued_count == 1 and .sources_failed == 0 and .skip_fetch == true' "first_run_detects_one_change_without_fetch"
report_path="$(jq -r '.report_path' "$TMP/first.json")"
test -s "$report_path" && pass "durable_report_written" || fail "durable_report_written"
test -s "/tmp/jeff-report-2026-05-05.md" && pass "tmp_report_written" || fail "tmp_report_written"
assert_file_contains "$report_path" '^# Jeff Daily Report' "report_has_canonical_heading"
assert_file_contains "$report_path" '^## Run metadata' "report_has_run_metadata_section"
assert_file_contains "$report_path" '^## New Commits \(by repo\)' "report_has_new_commits_section"
assert_file_contains "$report_path" 'skip_fetch: true' "report_records_skip_fetch"
assert_file_contains "$report_path" 'Verdict: YES_ADOPT' "report_has_yes_adopt_verdict"
assert_file_contains "$report_path" '^## Actionable Signals' "report_has_actionable_signals_section"
assert_file_contains "$report_path" 'Signal class: agent-mail' "report_has_agent_mail_signal_class"
assert_file_contains "$report_path" 'Apply-to-flywheel hypothesis' "report_has_apply_hypothesis"
if [[ "$(rg -c 'Verdict: (YES_ADOPT|YES_ADAPT|NEED_RESEARCH)' "$report_path" || true)" -ge 3 ]]; then
  pass "report_has_three_actionable_verdicts"
else
  fail "report_has_three_actionable_verdicts"
fi
grep "YES_ADOPT" "$report_path" >/dev/null && pass "grep_yes_adopt_hit" || fail "grep_yes_adopt_hit"
assert_file_contains "$report_path" 'changed_repo' "report_names_changed_repo"
assert_file_contains "$report_path" 'queued `changed_repo`' "report_names_reindex_queue"

if jq -e --arg new_changed "$new_changed" '.repos.changed_repo.last_seen_sha == $new_changed' "$state_dir/last-diff-run.json" >/dev/null; then
  pass "state_tracks_new_sha"
else
  fail "state_tracks_new_sha"
  jq . "$state_dir/last-diff-run.json" >&2 || true
fi
assert_jq "$state_dir/reindex-queue.jsonl" '.repo == "changed_repo" and .old_sha != .new_sha' "reindex_queue_only_changed_repo"
[[ "$(wc -l <"$state_dir/reindex-queue.jsonl" | tr -d ' ')" == "1" ]] && pass "reindex_queue_one_row" || fail "reindex_queue_one_row"
test -s "$state_dir/daily-runs.jsonl" && pass "daily_runs_ledger_written" || fail "daily_runs_ledger_written"

"$SCRIPT" \
  --repo-root "$repo_root" \
  --state-dir "$state_dir" \
  --now "2026-05-05T07:05:00Z" \
  --x-fixture "$TMP/x.md" \
  --rss-fixture "$TMP/rss.xml" \
  --json >"$TMP/second.json"

assert_jq "$TMP/second.json" '.status == "pass" and .changed_repo_count == 0 and .reindex_queued_count == 0' "second_run_idempotent_zero_diffs"
[[ "$(wc -l <"$state_dir/reindex-queue.jsonl" | tr -d ' ')" == "1" ]] && pass "second_run_no_extra_reindex_rows" || fail "second_run_no_extra_reindex_rows"

dry_state="$TMP/dry-state"
mkdir -p "$dry_state"
cp "$state_dir/last-diff-run.json" "$dry_state/last-diff-run.json"
"$SCRIPT" \
  --repo-root "$repo_root" \
  --state-dir "$dry_state" \
  --now "2026-05-05T07:10:00Z" \
  --x-fixture "$TMP/x.md" \
  --rss-fixture "$TMP/rss.xml" \
  --dry-run \
  --json >"$TMP/dry.json"
assert_jq "$TMP/dry.json" '.dry_run == true and .report_path == "/tmp/jeff-report-2026-05-05.md"' "dry_run_reports_tmp_path"
if [[ ! -e "$dry_state/daily-runs.jsonl" && ! -e "$dry_state/reindex-queue.jsonl" ]]; then
  pass "dry_run_no_durable_ledger_or_queue"
else
  fail "dry_run_no_durable_ledger_or_queue"
fi

if [[ "$fail_count" -gt 0 ]]; then
  printf 'FAIL jeff-daily-diff tests pass=%s fail=%s\n' "$pass_count" "$fail_count" >&2
  exit 1
fi

printf 'PASS jeff-daily-diff tests pass=%s fail=%s\n' "$pass_count" "$fail_count"
