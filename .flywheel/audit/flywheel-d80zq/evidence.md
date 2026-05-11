---
bead: flywheel-d80zq
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
score: 985/1000
mode: scaffold-plus-fillin-bash
sister_exemplars: ugjvq (985), 64hud (985), x0k3j (985), vs78t (985), lrdum (985), gbfpo (985), kz7o0 (985), bu0es (985), 05ost (985)
---

# Evidence Pack — flywheel-d80zq

## Scope

Wave-1-jeff-corpus-12 (12th of 17 ok1sk sub-beads). Apply canonical-cli
scaffold + substantive fillin to `.flywheel/scripts/jeff-verdict-heuristic.sh`
— stateless heuristic classifier that emits one of 4 verdicts
(YES_ADOPT, YES_ADAPT, NO_NOT_OUR_DOMAIN, NEED_RESEARCH) per Jeff repo
artifact based on commit/path/diff text matching against keyword rules.

## Files touched

`.flywheel/scripts/jeff-verdict-heuristic.sh` (146 → 392 lines after scaffold; TODO=0)
`tests/jeff-verdict-heuristic-canonical-cli.sh` (94 → 158 lines, 13 → 19 tests)

## AG1-5 verification

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/jeff-verdict-heuristic.sh \
  && [[ "$(grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/jeff-verdict-heuristic.sh)" == "0" ]] \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/jeff-verdict-heuristic.sh \
  && bash tests/jeff-verdict-heuristic-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

Result: **AG1-5 PASS** + 19/19 tests passing.

## Domain-specific fillins

### doctor (6 named probes — minimal-footprint stateless classifier)

- `bash`, `jq`, `mktemp` — universal
- `python3_available` — **load-bearing**: bash wrapper around python3
  heredoc; without python3 the entire surface is non-functional
- `state_dir_writable` — `$JEFF_VERDICT_HEURISTIC_STATE_DIR` (default
  `~/.local/state/jeff-verdict-heuristic`); warn-tier (stateless surface
  but capability exists for verdict caching)
- `audit_log_dir_writable` — `~/.local/state/flywheel`
- Note: doctor envelope explicitly flags `stateless classifier — substrate
  footprint minimal (no git/repo/network deps)` to differentiate this
  surface from sister jeff-corpus surfaces (x0k3j/ugjvq) which DO have
  git+repo dependencies

### health

Reads `$SCAFFOLD_AUDIT_LOG`; status=warn at >7d stale (on-demand
classifier; weekly grace). Differentiates from sister scripts which
have stricter staleness (12h-36h) due to scheduled cadence.

### repair (2 scopes, apply contract)

- `state_dir` → `mkdir -p $JEFF_VERDICT_HEURISTIC_STATE_DIR` (verdict
  cache target)
- `audit_log_dir` → `mkdir -p $(dirname $SCAFFOLD_AUDIT_LOG)`
- `--apply` requires `--idempotency-key` (rc=3 refusal)
- Unknown scope rc=64 + `unknown_scope`

### validate (3 subjects, domain-precise)

- `verdict` — **enum-typed** (case-sensitive) restricted to the 4 values
  the classifier emits per source-code L12: `YES_ADOPT`, `YES_ADAPT`,
  `NO_NOT_OUR_DOMAIN`, `NEED_RESEARCH`. Returns `valid_verdicts` list
  in the reject envelope. This is the load-bearing per-domain validator
  (the script's primary output schema).
- `repo-name` regex `^[A-Za-z0-9_.-]+$` — matches canonical jeff-corpus
  repo names
- `audit-row` — JSONL `ts` + `action` standard

### audit / why

audit uses `cli_emit_audit_tail`. why scans 4 keys (ts/repo/verdict/run_id).

## Test extension (13 → 19, calibrated)

- Test 7 calibrated to `--scope state_dir`
- Test 9 calibrated to bare `validate` rc=64 + `missing_subject`
- 6 fillin assertions: python3 + stateless-note presence, FULL-ENUM
  sweep on validate verdict (loops all 4 canonical values), reject
  unknown enum (MAYBE) with rc=1 + valid_verdicts list, reject lowercase
  (case-sensitivity contract), repo-name accept canonical, repair
  unknown_scope rc=64

## Notable bug-catch

- Initial test 14 jq query
  `[.checks[].name] | contains([...]) and (.note // "" | contains("stateless"))`
  failed with "Cannot index array with string 'note'" because after
  `[.checks[].name] |` the input becomes the array, not the original
  object, so `.note` was indexing the array. Fixed with explicit
  parentheses + restart-from-input pattern:
  `([.checks[].name] | contains([...])) and ((.note // "") | contains("stateless"))`
  — both subexpressions evaluate against the original input.

## Smoke captures

15 smoke captures verify domain-specific responses (verdict accept/reject
with full enum list, repair refusals cite reason, audit/why work against
missing log).

## Mission fitness

Class: **adjacent** (per dispatch). jeff-verdict-heuristic.sh is the
classifier that decides whether to adopt/adapt/skip Jeff's upstream
patterns; canonical-CLI surface lets the orchestrator validate verdict
labels in dispatch packets and probe the classifier's substrate before
batch classification runs.
