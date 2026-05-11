---
bead: flywheel-ugjvq
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
score: 985/1000
mode: scaffold-plus-fillin-bash
sister_exemplars: 64hud (985), x0k3j (985), vs78t (985), lrdum (985), gbfpo (985), kz7o0 (985), bu0es (985), 05ost (985)
---

# Evidence Pack — flywheel-ugjvq

## Scope

Wave-1-jeff-corpus-11 (11th of 17 ok1sk sub-beads). Apply canonical-cli
scaffold + substantive fillin to `.flywheel/scripts/jeff-philosophy-mine.sh`
— bash wrapper around python3 heredoc that mines philosophy patterns
from `$JEFF_PHILOSOPHY_REPO_ROOT` (default `~/Developer/jeff-corpus`)
into `patterns.jsonl` + `daily-snapshots/` under `$JEFF_PHILOSOPHY_STATE_DIR`
(default `~/.local/state/jeff-philosophy`).

## Files touched

`.flywheel/scripts/jeff-philosophy-mine.sh` (626 → 872 lines after scaffold; TODO=0)
`tests/jeff-philosophy-mine-canonical-cli.sh` (94 → 152 lines, 13 → 19 tests)

## AG1-5 verification

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/jeff-philosophy-mine.sh \
  && [[ "$(grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/jeff-philosophy-mine.sh)" == "0" ]] \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/jeff-philosophy-mine.sh \
  && bash tests/jeff-philosophy-mine-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

Result: **AG1-5 PASS** + 19/19 tests passing.

## Domain-specific fillins

### doctor (9 named probes — domain-tailored)

- `bash`, `jq`, `mktemp` — universal
- `python3_available` — **load-bearing**: bash wrapper around python3
  heredoc; without python3 the entire script is non-functional
- `git_available` — **load-bearing**: daily snapshots use git history
  walks across discovered jeff-corpus repos
- `repo_root_exists` — `$JEFF_PHILOSOPHY_REPO_ROOT`
- `state_dir_writable` — `$JEFF_PHILOSOPHY_STATE_DIR` write target for
  patterns.jsonl + audit.jsonl
- `daily_snapshot_dir_writable` — `$state_dir/daily-snapshots/` (the
  mining script creates dated subdirs here per L329/L398)
- `audit_log_dir_writable` — `~/.local/state/flywheel`

### health

Reads `$SCAFFOLD_AUDIT_LOG`; status=warn at >36h stale (daily mining
cadence with 1.5x grace; tunable via
`JEFF_PHILOSOPHY_HEALTH_STALE_THRESHOLD_SECONDS`).

### repair (2 scopes, apply contract)

- `state_dir` → `mkdir -p $JEFF_PHILOSOPHY_STATE_DIR`
  AND `mkdir -p $state_dir/daily-snapshots` (matches python heredoc
  behavior at L433-L434 which creates BOTH dirs)
- `audit_log_dir` → `mkdir -p $(dirname $SCAFFOLD_AUDIT_LOG)`
- `--apply` requires `--idempotency-key` (rc=3 refusal)
- Unknown scope rc=64 + `unknown_scope`

### validate (3 subjects, domain-precise)

- `repo-name` regex `^[A-Za-z0-9_.-]+$` — matches all canonical
  jeff-corpus repo names (mcp_agent_mail, beads_rust, frankensqlite,
  dcg, etc.)
- `pattern-jsonl-path` extension whitelist `.jsonl` only — matches
  patterns.jsonl + audit.jsonl that the mining script writes (per
  L589/L591 of original); rejects .json since the mining script writes
  jsonl-only
- `audit-row` — JSONL `ts` + `action` standard

### audit / why

audit uses `cli_emit_audit_tail`. why scans 4 keys (ts/repo/pattern_id/run_id).

## Test extension (13 → 19, calibrated)

- Test 7 calibrated to `--scope state_dir` (was `none` rc=64)
- Test 9 calibrated to bare `validate` rc=64 + `missing_subject`
- 6 fillin assertions: python3+git+daily_snapshot_dir probe presence,
  repo-name accept canonical (frankensqlite), repo-name reject spaces (rc=1),
  pattern-jsonl-path accept .jsonl, pattern-jsonl-path reject .json (rc=1
  + unsupported_extension), repair unknown_scope rc=64

## Smoke captures

15 smoke captures verify domain-specific responses (repo-name rejection
cites pattern, pattern-jsonl-path rejection lists valid_extensions, repair
state_dir reports daily_snapshot_dir target separately).

## Mission fitness

Class: **adjacent** (per dispatch). jeff-philosophy-mine.sh extracts
philosophy patterns from Jeff's corpus into the substrate intelligence
layer; making it canonical-CLI inspectable lets the orchestrator validate
mining inputs/outputs, supporting the substrate-watchtower portion of
continuous-orchestrator-uptime.
