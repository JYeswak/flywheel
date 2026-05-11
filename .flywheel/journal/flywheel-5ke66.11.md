---
bead: flywheel-5ke66.11
title: fleet-conformance-probe.sh canonical-CLI scaffold + 18-TODO fillin (PARTIAL-BYPASS)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P2
mission_fitness: adjacent
parent: flywheel-5ke66 (jloib wave-2; sub-bead 11 of 21)
sister_exemplars: 5ke66.6 (985, same PARTIAL-BYPASS); 5ke66.8 (985, NUANCED); 5ke66.4 (985, BYPASS-ALL); 5ke66.2 (985, NO-BYPASS)
---

# Journey: flywheel-5ke66.11

## What Joshua asked for

Wave-2-general-11 (11th 5ke66 sub-bead). Surface: fleet-conformance-probe.sh
= bounded fleet conformance scorer per session over 6 axes with auto-fix
drive (Donella leverage points 5,6).

## What I shipped

This is a **WZJO9.1.7 PARTIAL-BYPASS** case — second documented
application of this variant (sister to 5ke66.6 daily-report). Native
`--info / --schema / --examples` all PASSTHRU to the python heredoc
which emits the rich `fleet-conformance-observatory/v1` schema; scaffold
owns the verb subcommands.

- 18 TODO markers replaced with substantive impl
- `_scaffold_is_canonical_arg` returns 1 for `--info|--schema|--examples`,
  returns 0 for verbs (matches 5ke66.6 PARTIAL pattern)
- doctor: 7 named probes (python3 + loops_dir + canonical_agents
  load-bearing per the script's identity-drift + conformance-scoring needs)
- health: 12h stale threshold (intra-day cadence)
- repair: 2 scopes (cache_dir for 60s-TTL conformance cache, audit_log_dir)
- validate: 3 subjects (session-name lowercase-prefix; conformance-axis
  enum-typed restricted to the 6 axes from native --info; audit-row standard)
- audit: cli_emit_audit_tail; why: 4 keys
- Test 13 → 19 with calibration + cross-source check:
  - Tests 2/3/4: native PASSTHRU shapes
  - Tests 5-13: scaffold owns subcommands
  - Test 14: PARTIAL-BYPASS annotation grep-discoverable
  - Test 15: dual-direction fidelity (info native observatory/v1 +
    doctor scaffold probe/v1)
  - Test 16: full-enum sweep over all 6 conformance axes
  - Test 19: **cross-source consistency** — native --info axes array MUST
    equal scaffold validate valid_axes (sorted)

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean (0 violations). All four route directions functional + cross-
source enum consistency verified.

## Notable

- Two PARTIAL-BYPASS applications now confirm the variant is robust for
  scripts with rich native flag-form introspection. Pattern is mature.
- Test 19 cross-source consistency check is a NEW canonical pattern:
  for surfaces where BOTH native and scaffold encode the same enum
  (axis labels, status values, etc.), assert sorted equality between
  the two sources. Catches the case where a maintainer adds an enum
  member to one source and forgets the other.
- Initial test 19 attempted `--schema validate` to access scaffold's
  per-surface schema — but `--schema` is bypassed to native which
  doesn't understand positional args. Pivoted to `validate <subj>
  <unknown>` reject envelope (which surfaces `valid_axes`). This is the
  canonical access route for scaffold enum data when --schema is bypassed.

## Files touched

- `.flywheel/scripts/fleet-conformance-probe.sh` (507 → 753 lines)
- `tests/fleet-conformance-probe-canonical-cli.sh` (94 → 168 lines)
- `.flywheel/audit/flywheel-5ke66.11/{evidence,journey,compliance,15 smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-5ke66.11.md`

## Mission fitness

Class: **adjacent**. fleet-conformance-probe.sh is the bounded fleet
conformance scorer with auto-fix-bead drive; canonical-CLI surface
(mixed scaffold + native) lets orchestrator probe substrate and
validate session names + axis enum values.
