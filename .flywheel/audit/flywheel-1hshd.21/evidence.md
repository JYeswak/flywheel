---
bead: flywheel-1hshd.21
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
score: 985/1000
mode: scaffold-plus-fillin-bash + WZJO9.1.7-NO-BYPASS
sister_exemplars: 5ke66.{2,13,15} + 1hshd.{13,14} (NO-BYPASS family — 6 occurrences now)
---

# Evidence Pack — flywheel-1hshd.21

## Scope

Wave-4-general-21. Apply canonical-cli scaffold + substantive fillin to
`.flywheel/scripts/cross-repo-trauma-aggregator.sh` — aggregates per-repo
trauma logs across roots (default `~/Developer + ~/Desktop/Projects`)
into `~/.flywheel/global-trauma-log.jsonl`.

## Files touched

`.flywheel/scripts/cross-repo-trauma-aggregator.sh` (111 → 357 lines after
scaffold; TODO=0)
`tests/cross-repo-trauma-aggregator-canonical-cli.sh` (94 → 162 lines,
13 → 19 tests)

## AG1-5 verification

```bash
cd /Users/josh/Developer/flywheel \
  && bash -n .flywheel/scripts/cross-repo-trauma-aggregator.sh \
  && [[ "$(grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/cross-repo-trauma-aggregator.sh)" == "0" ]] \
  && .flywheel/scripts/canonical-cli-lint.sh .flywheel/scripts/cross-repo-trauma-aggregator.sh \
  && bash tests/cross-repo-trauma-aggregator-canonical-cli.sh \
  && echo "AG1-5 PASS"
```

Result: **AG1-5 PASS** + 19/19 tests passing.

## Variant choice — NO-BYPASS

Per-flag + per-verb baseline probe pre-scaffold confirmed: zero native
canonical surfaces. Script rejects all canonical args with usage. Standard
NO-BYPASS recipe applies (sister to 5ke66.{2,13,15} + 1hshd.{13,14}).
This is the **6th NO-BYPASS application** — variant is well-trodden.

## Domain-specific fillins

### doctor (7 named probes)

- `bash`, `jq`, `mktemp` — universal
- `output_dir_writable` — `~/.flywheel/` (target for global-trauma-log.jsonl)
- `default_root1_exists` — `~/Developer` (default --root #1)
- `default_root2_exists` — `~/Desktop/Projects` (default --root #2; warn-tier
  since --root override is possible)
- `audit_log_dir_writable`

### health

36h stale threshold (1.5x daily aggregation cadence; tunable via
`CROSS_REPO_TRAUMA_AGGREGATOR_HEALTH_STALE_THRESHOLD_SECONDS`).

### repair (2 scopes)

- `output_dir` → `mkdir -p ~/.flywheel`
- `audit_log_dir`
- Apply contract rc=3 + unknown_scope rc=64

### validate (3 subjects, domain-precise)

- `root-path` — must be absolute (**5th occurrence** of fleet-wide
  absolute-path validator pattern — sisters: 5ke66.2 target-path,
  5ke66.19 repo-path, 1hshd.11 root-path, 1hshd.13 scratch-path)
- `output-path` — must end `.jsonl` (matches default `global-trauma-log.jsonl`)
- `audit-row` standard

### audit / why

Standard `cli_emit_audit_tail` + 4-key why scan
(ts/repo/trauma_class/run_id matching the per-trauma row schema).

## Test calibration (13 → 19)

- Test 7 calibrated to real `--scope output_dir`
- Test 9 calibrated to bare `validate` rc=64 + `missing_subject`
- 6 fillin assertions:
  - Test 14: doctor probes default_root1 + default_root2 + output_dir
  - Test 15: validate root-path accepts absolute (5th occurrence note)
  - Test 16: validate root-path rejects relative
  - Test 17: validate output-path accepts .jsonl
  - Test 18: validate output-path rejects .txt
  - Test 19: topic help cites 5th-occurrence reference (META-RULE catch)

## Notable

- **5th absolute-path validator occurrence** — pattern is FORMALLY MATURE
  at 5 instances across the wave-2 + wave-4 series. The reject envelope's
  `contract` field and the topic help both reference the canonical pattern,
  enabling a future operator to grep-discover the pattern's lineage.
- **6th NO-BYPASS application** — pattern is well-trodden; recipe is mechanical
- **Coordination flow notes** (5 inbound from skillos:1 during this bead):
  1. 04:38Z PHASES_A_B_SHIPPED — initial 49.76h baseline claim
  2. 04:58Z RETRACTION — baseline was false-up; consumer-side wiring missing
  3. 05:01Z DOCTRINE REFINEMENT — scope-clause refinement strongly endorsed
  4. 05:04Z TWO-CYCLE PLAN — v0.1.8 then v0.1.9 separate revs (don't collapse)
  5. 05:07Z SHAPE C ENDORSEMENT — substrate-exercises-itself-and-surfaces-own-gaps
  All five forwarded to flywheel:1 per orchestrator-scope-boundary META-RULE.
  Worker pane scope: forward + acknowledge; orchestrator authority: ratify.

## Smoke captures

15 smoke captures: doctor with 7 probes + health + 2 repair scopes + 4
validate accept+reject pairs + audit/why/quickstart/info/schema scaffold.

## Mission fitness

Class: **adjacent**. cross-repo-trauma-aggregator.sh aggregates per-repo
trauma logs into a fleet-wide ledger; canonical-CLI surface lets
orchestrator probe substrate (default roots + output dir) and validate
root + output path args before triggering aggregation.
