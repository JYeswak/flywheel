---
bead: flywheel-x0k3j
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
score: 985/1000
mode: scaffold-plus-fillin-bash
sister_exemplars: vs78t (985), lrdum (985), gbfpo (985), kz7o0 (985), bu0es (985), 05ost (985)
---

# Evidence Pack — flywheel-x0k3j

## Scope

Wave-1-jeff-corpus-9 (9th of 17 ok1sk sub-beads). Apply canonical-cli scaffold +
substantive fillin to `.flywheel/scripts/jeff-daily-diff.sh` — bash wrapper
around python3 heredoc that produces daily git-diff reports across the
jeff-corpus repos (mcp_agent_mail, beads_rust, frankensqlite, etc.) under
`$JEFF_DAILY_DIFF_REPO_ROOT` (default `~/Developer/jeff-corpus`, legacy
`~/Developer/dicklesworthstone-stack`).

## Files touched

`.flywheel/scripts/jeff-daily-diff.sh` (535 → 781 lines after scaffold; TODO=0)
`tests/jeff-daily-diff-canonical-cli.sh` (94 → 142 lines, 13 → 19 tests)

## AG1-5 verification

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/jeff-daily-diff.sh \
  && [[ "$(grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/jeff-daily-diff.sh)" == "0" ]] \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/jeff-daily-diff.sh \
  && bash tests/jeff-daily-diff-canonical-cli.sh \
  && echo "AG1-5 PASS"
# expected: AG1-5 PASS + SUMMARY pass=19 fail=0
```

Result: **AG1-5 PASS** + 19/19 tests passing.

## Domain-specific fillins

### doctor (8 named probes — domain-tailored)

- `bash`, `jq`, `mktemp` — universal
- `python3_available` — **load-bearing**: jeff-daily-diff.sh is a
  python3 heredoc wrapper; without python3 the entire script is non-functional
- `git_available` — **load-bearing**: the daily diff IS `git -C <repo> diff`
  across discovered jeff-corpus repos
- `repo_root_exists` — checks `~/Developer/jeff-corpus` (canonical) AND
  `~/Developer/dicklesworthstone-stack` (legacy fallback per source code
  L280-L283); reports which root is effective
- `state_dir_writable` — `$JEFF_INTEL_STATE_DIR` (default
  `~/.local/state/jeff-intel`) write target for last-diff-run.json,
  daily-runs.jsonl, reindex-queue.jsonl, reports/
- `audit_log_dir_writable` — `~/.local/state/flywheel` for
  jeff-daily-diff-runs.jsonl

### health

Reads `$SCAFFOLD_AUDIT_LOG` (default
`~/.local/state/flywheel/jeff-daily-diff-runs.jsonl`) and emits
last_run_ts, age_seconds, recent_runs (last 20), total_runs.
Status flips to `warn` at >36h stale (1.5x daily cadence; threshold env-
tunable via `JEFF_DAILY_DIFF_HEALTH_STALE_THRESHOLD_SECONDS`).

### repair (2 scopes, apply contract)

- `state_dir` → `mkdir -p $JEFF_INTEL_STATE_DIR` (default
  `~/.local/state/jeff-intel`)
- `audit_log_dir` → `mkdir -p $(dirname $SCAFFOLD_AUDIT_LOG)`
- `--apply` requires `--idempotency-key` (rc=3 refusal)
- Unknown scope returns rc=64 with `unknown_scope` reason

### validate (3 subjects, domain-precise)

- `repo-name` regex `^[A-Za-z0-9_.-]+$` — matches all canonical jeff-corpus
  repo dir names (mcp_agent_mail, beads_rust, frankensqlite, dcg, cass,
  watcherctl, etc.); rejects names with spaces or shell metacharacters
- `state-path` extension whitelist (`.json`, `.jsonl`) — matches all
  state file names defined at L753-L756 of original script
  (last-diff-run.json, daily-runs.jsonl, reindex-queue.jsonl)
- `audit-row` — JSONL `ts` + `action` required (canonical fleet pattern)

### audit / why

audit uses `cli_emit_audit_tail` (canonical positional path-then-schema-then-
limit signature). why scans against ts / repo / run_id keys and emits
found / not_found / unavailable states.

## Test extension (13 → 19, calibrated)

- Test 7 calibrated to use real `--scope state_dir` (was `none` which is
  now an unknown-scope rc=64 refusal under the actual repair contract)
- Test 9 calibrated to test bare `validate` returning rc=64 +
  `missing_subject` envelope (per `feedback_calibrate_test_to_actual_contract`
  META-RULE 2026-05-09)
- 6 fillin assertions: python3 + git probe presence, repo-name accept
  canonical (mcp_agent_mail), repo-name reject spaces (rc=1), state-path
  accept .jsonl, state-path reject .txt (rc=1 + unsupported_extension),
  repair unknown_scope rc=64 + canonical envelope

## Smoke captures

13 smoke captures in this dir verify domain-specific responses (repo-name
rejection cites pattern, state-path rejection lists valid_extensions,
repair refusals cite reason, audit/why work against missing log).

## Mission fitness

Class: **adjacent** (per dispatch packet MISSION FITNESS CLAIM BLOCK).
jeff-daily-diff.sh is the daily Jeff-corpus intelligence-gathering surface
that feeds the substrate watchtower; this scaffold makes the surface
inspectable to the orchestrator via canonical-CLI, supporting the
continuous-orchestrator-uptime mission.
