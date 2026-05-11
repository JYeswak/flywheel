---
bead: flywheel-2xdi.164
title: gap-hunt-probe wired-but-cold false-positive fix for subprocess-validator-pattern scripts
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: DONE
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sibling: flywheel-2xdi.157 (false-positive discovery)
---

# 2xdi.164 evidence pack — classifier extension landed

## What this bead ships

Extends the wired-but-cold detector in `.flywheel/scripts/gap-hunt-probe.sh` with an 8th corpus (`flywheel_script_bodies_corpus`) that scans ALL `.flywheel/scripts/*.sh` bodies (excluding `gap-hunt-probe.sh` itself for self-reference noise). The 8th corpus catches subprocess-validator-pattern scripts whose only callsite is another `*-probe.sh` (which is excluded from the existing `flywheel_script_callers_corpus` by design — probe→probe doc cross-refs aren't receivers for the `probe-without-receiver` detector).

## Root cause (probed in 2xdi.157)

`flywheel-2xdi.157` was auto-filed for `loop-integrity-signals.sh` (wired-but-cold). Empirical disproof:
- script self-doctor returns `status: ok`
- 5 references in `.flywheel/scripts/gap-hunt-probe.sh` (line 2072 + 4 others)
- invoked via `subprocess.run([validator, "--project", project, ...])` per project loop
- script returns JSON via stdout; output consumed in-memory; never writes JSONL ledger

The classifier's 7 existing corpora all rely on either ledger trace (4 of them) or non-probe script references / launchd plists / skill MD prose / test files. Subprocess-from-probe-to-validator is a legitimate wiring shape with no representation in those 7 corpora.

## Fix design

Added `flywheel_script_bodies_corpus()` at `.flywheel/scripts/gap-hunt-probe.sh:795` (just above `test_files_corpus`). Properties:

1. Scans `REPO_ROOT/.flywheel/scripts/*.sh` (all, including `*-probe.sh`)
2. **Self-exclusion**: skips `gap-hunt-probe.sh` itself to avoid matching the script's own usage strings, schema literals, and error messages
3. Caches via `_FLYWHEEL_SCRIPT_BODIES_CORPUS` global (consistent with other corpus functions)
4. 3 MB cap (consistent with `flywheel_script_callers_corpus`)
5. Wired into `probe_wired_but_cold` at the existing 7-corpus condition as the 8th OR branch: `if not (... or in_script_bodies):`

## Acceptance gates (implicit; bead body specifies classifier extension)

| # | Gate | Status | Evidence |
|---|------|--------|----------|
| 1 | Author 8th corpus function for subprocess-callsite detection | DID | `flywheel_script_bodies_corpus()` at gap-hunt-probe.sh:795 (60+ lines, docstring explains 2xdi.164 + 2xdi.157 lineage) |
| 2 | Wire 8th corpus into `probe_wired_but_cold` classifier | DID | `in_script_bodies` variable + extended OR condition at probe_wired_but_cold (line 1330-ish) |
| 3 | Self-exclude `gap-hunt-probe.sh` to prevent self-reference noise | DID | corpus function filters `p.name != "gap-hunt-probe.sh"` |
| 4 | Verify `loop-integrity-signals.sh` no longer flagged after fix | DID | `tests/gap-hunt-probe-subprocess-validator-callsite.sh` AG1 PASS (0 hits) |
| 5 | Verify `gap_class_distribution.wired-but-cold` field preserved | DID | AG2 PASS — count=6 (down from 7+ before fix) |
| 6 | Bash + Python syntax clean | DID | `bash -n` rc=0; python3 compile rc=0 |
| 7 | Regression test authored + passing | DID | `tests/gap-hunt-probe-subprocess-validator-callsite.sh` 4/4 PASS |

`did=7/7`, `didnt=none`, `gaps=none`.

## L112 probe

```bash
bash /Users/josh/Developer/flywheel/tests/gap-hunt-probe-subprocess-validator-callsite.sh 2>&1 | tail -1
```

Expected: literal `PASS gap-hunt-probe-subprocess-validator-callsite (4/4)`.

## Files changed

- `.flywheel/scripts/gap-hunt-probe.sh` — new corpus function + cache global + classifier wire-in (+78 lines)
- `tests/gap-hunt-probe-subprocess-validator-callsite.sh` — new regression test (4 acceptance gates)
- `.flywheel/audit/flywheel-2xdi.164/evidence.md` — this evidence pack
- `.flywheel/audit/flywheel-2xdi.164/compliance-pack.md` — compliance breakdown

## Mission fitness

`mission_fitness=adjacent`. Classifier precision improvement reduces noise in the auto-bead-filing pipeline. Specifically prevents the trauma class "false-positive wired-but-cold auto-bead-filed → worker probes → disproves → files follow-up → orch dispatches follow-up" cycle that 2xdi.157 → 2xdi.164 represents. Each cycle costs ~3 worker dispatches; this fix prevents the cycle for the entire subprocess-validator-pattern script class.

## Skill discoveries

`skill_discoveries=0 sd_ids=none`. Classifier extension pattern (add N-th corpus when a new wiring shape is observed) is canonical in gap-hunt-probe.sh (see comments referencing 2xdi.88, 2xdi.98, 2xdi.106, 2xdi.140 — all prior corpus extensions). This is the 5th instance of the same META-pattern.

## Four-Lens Self-Grade

- Brand: 9/10 — extension follows gap-hunt-probe's canonical META-pattern; docstring references the lineage (2xdi.157 + 2xdi.164)
- Sniff: 10/10 — empirical disproof in sister bead + empirical re-verification post-fix (test passes, count drops, target unflagged)
- Jeff: 9/10 — Class 1 (flywheel-substrate) discipline preserved; surgical edit with self-exclusion to prevent matchback noise
- Public: 9/10 — three judges: skeptical operator sees concrete test + count drop; maintainer can extend pattern to 9th corpus when next shape appears; future worker can copy this fix template
