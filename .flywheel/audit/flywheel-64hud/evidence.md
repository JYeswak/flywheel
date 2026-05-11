---
bead: flywheel-64hud
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
score: 985/1000
mode: scaffold-plus-fillin-bash
sister_exemplars: x0k3j (985), vs78t (985), lrdum (985), gbfpo (985), kz7o0 (985), bu0es (985), 05ost (985)
---

# Evidence Pack — flywheel-64hud

## Scope

Wave-1-jeff-corpus-10 (10th of 17 ok1sk sub-beads). Apply canonical-cli
scaffold + substantive fillin to `.flywheel/scripts/jeff-issue-response-poll.sh`
— polls `$JEFF_ISSUES_REGISTRY` (jsonl) for new Jeff responses on
upstream-filed issues and auto-creates triage beads via `br create` when
`last_jeff_response_ts > last_triage_bead_ts`.

## Files touched

`.flywheel/scripts/jeff-issue-response-poll.sh` (128 → 374 lines after
scaffold; TODO=0)
`tests/jeff-issue-response-poll-canonical-cli.sh` (94 → 152 lines, 13 → 19 tests)

## AG1-5 verification

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/jeff-issue-response-poll.sh \
  && [[ "$(grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/jeff-issue-response-poll.sh)" == "0" ]] \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/jeff-issue-response-poll.sh \
  && bash tests/jeff-issue-response-poll-canonical-cli.sh \
  && echo "AG1-5 PASS"
# expected: AG1-5 PASS + SUMMARY pass=19 fail=0
```

Result: **AG1-5 PASS** + 19/19 tests passing.

## Domain-specific fillins

### doctor (8 named probes — domain-tailored)

- `bash`, `jq`, `mktemp` — universal
- `br_available` — **load-bearing**: this script's central action is
  `br create` to file triage beads when Jeff responds; without br the
  script cannot perform its primary function (also probes
  `~/.cargo/bin/br` per source-code L16-L17 fallback path)
- `jeff_issues_status_available` — pre-poll refresh hook
  (`$JEFF_ISSUES_STATUS_BIN` poll, default `~/.local/bin/jeff-issues-status`);
  warn if missing because the script falls back to using the existing
  registry as-is
- `repo_dir_is_git` — `$JEFF_ISSUE_RESPONSE_POLL_REPO/.git` (default
  `/Users/josh/Developer/flywheel`); needed because `br create` runs
  inside this repo
- `registry_readable` — `$JEFF_ISSUES_REGISTRY` (default
  `~/.local/state/flywheel/jeff-issues.jsonl`); warn if missing because
  the script returns `noop reason=no_registry` rather than failing
- `audit_log_dir_writable` — `~/.local/state/flywheel`

### health

Reads `$SCAFFOLD_AUDIT_LOG` (default
`~/.local/state/flywheel/jeff-issue-response-poll-runs.jsonl`) and emits
last_run_ts, age_seconds, recent_runs, total_runs. Status flips to
`warn` at >12h stale (intra-day cadence; tunable via
`JEFF_ISSUE_RESPONSE_POLL_HEALTH_STALE_THRESHOLD_SECONDS`).

### repair (2 scopes, apply contract)

- `registry_dir` → `mkdir -p $(dirname $JEFF_ISSUES_REGISTRY)`
- `audit_log_dir` → `mkdir -p $(dirname $SCAFFOLD_AUDIT_LOG)`
- `--apply` requires `--idempotency-key` (rc=3 refusal)
- Unknown scope returns rc=64 with `unknown_scope` reason

### validate (3 subjects, domain-precise)

- `jeff-issue-ref` regex `^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+#[0-9]+$` —
  matches Jeff's canonical issue ref form (e.g.
  `dicklesworthstone/beads_rust#270`); rejects malformed refs without
  slash or hash
- `registry-row` — JSONL with required `repo` (string) + `number` (number)
  fields per the registry schema this script consumes; uses `has(...)`
  + null + type checks to catch missing/null/non-numeric `number`
- `audit-row` — JSONL `ts` + `action` (canonical fleet pattern)

### audit / why

audit uses `cli_emit_audit_tail` (positional path-then-schema-then-limit).
why scans against ts / issue_ref / bead_id / run_id keys; states
found / not_found / unavailable.

## Test extension (13 → 19, calibrated)

- Test 7 calibrated to use real `--scope registry_dir` (was `none` which
  is now an unknown-scope rc=64 refusal)
- Test 9 calibrated to test bare `validate` returning rc=64 +
  `missing_subject` envelope per
  `feedback_calibrate_test_to_actual_contract` META-RULE 2026-05-09
- 6 fillin assertions: br + jeff_issues_status probe presence,
  jeff-issue-ref accept canonical (dicklesworthstone/beads_rust#270),
  jeff-issue-ref reject malformed (rc=1), registry-row accept well-formed,
  registry-row reject missing-number (rc=1), repair unknown_scope rc=64

## Notable

- Initial registry-row jq filter used `(.number // empty) == ""` which
  evaluates `null // empty == ""` as `empty == ""` → produces no result,
  so `select` would not emit and the validator returned ok for malformed
  rows. Caught by test 18 (rc=0 instead of expected 1). Fixed to
  `has("number") | not` + `.number == null` + `(.number | type) != "number"`
  to actually catch missing/null/wrong-type fields. Sister scripts using
  the same pattern do NOT have this issue because their required fields
  are all strings (ts/action) so `(.x // empty) == ""` works for
  string-typed fields but fails for numeric ones. Recipe-specific bug;
  no fleet-wide issue.

## Smoke captures

15 smoke captures in this dir verify domain-specific responses
(jeff-issue-ref rejection cites pattern, registry-row rejection cites
missing fields with sample, repair refusals cite reason, audit/why work
against missing log).

## Mission fitness

Class: **adjacent** (per dispatch). jeff-issue-response-poll.sh
auto-creates triage beads when Jeff responds upstream — the dogfood
loop that converts upstream responses into actionable substrate work,
supporting continuous-orchestrator-uptime mission via the upstream-
substrate watchtower.
