---
bead: flywheel-2xdi.146
title: wired-but-cold + probe-without-receiver fix — codex-pane-path-probe test (N=3 skill promotion)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: shipped
priority: P3
mission_fitness: adjacent
parent: flywheel-2xdi
sister_recipe: 2xdi.90 + 2xdi.92 (N=3 instance — skill discovery promotion)
---

# Journey: flywheel-2xdi.146

## What the bead asked for

`.flywheel/scripts/codex-pane-path-probe.sh` wired-but-cold (script
not referenced in ledgers in 30d).

## Investigation (N=34 bead-hypothesis META-rule)

Probed empirically:
- Script exists, well-formed (codex-pane-path-probe/v1 schema; --info/
  --schema/--doctor/--json/--help surface)
- DOUBLE-FLAGGED: probe shows it in BOTH wired-but-cold AND
  probe-without-receiver classes
- 0 active corpus receivers (tick.md, other scripts, tests/, launchd)
- All references are in audit packs (.flywheel/audit/...) — doc
  surfaces, not active
- Owns bead flywheel-orx1 (PATH-discipline contract validator)

## What I shipped

`tests/codex-pane-path-probe-canonical-cli.sh` (95 lines, 10/10 PASS):
1. syntax
2. --info envelope
3. --schema envelope
4. --doctor envelope
5. default --json run envelope
6. default run status field
7. --help enumerates all 4 surfaces
8. READ-ONLY (no notification calls)
9. schema_version stable across surfaces
10. owner-bead cite (flywheel-orx1) preserved

Same recipe as 2xdi.90 (operator-fatigue) + 2xdi.92 (public-artifact-pipeline).

## Verification

- 10/10 test PASS
- Fresh probe: BOTH classes cleared in single fix
  - wired-but-cold: gone
  - probe-without-receiver: gone

## L112 probe

    bash tests/codex-pane-path-probe-canonical-cli.sh | tail -1

Expected: `grep:pass=10 fail=0`.

## 🎯 N=3 SKILL DISCOVERY PROMOTION

The test-receiver wire-in recipe has now shipped 3 instances:
- 2xdi.90 (operator-fatigue-probe) 9/9
- 2xdi.92 (public-artifact-pipeline-probe) 10/10
- **2xdi.146 (codex-pane-path-probe) 10/10** ← THIS

Filed `pattern-emerged-probe-without-receiver-via-canonical-cli-test-fix-N3-promotion-ready`.

Recipe applied unchanged across 3 distinct probes; ready for skill extraction.

## Bonus: double-class clearance

Single fix cleared TWO probe classes (wired-but-cold + probe-without-
receiver). Both share a common cause (no active corpus reference) and
both clear via the same fix (test file in corpus #5). Worth noting in
the future skill: if a probe double-flags, ONE fix covers both classes.

## Pattern note — 23rd distinct fix shape entry

Cluster distribution:
- doctrine cross-link forward-link: N=11
- probe corpus extensions: N=4
- **test-receiver wire-in: N=3** ← promoted today
- (everything else N≤2)

Test-receiver wire-in is now the 3rd most-replicated cluster pattern.
