---
bead: flywheel-1hshd.13
title: cleanup-scratch.sh canonical-CLI scaffold + 18-TODO fillin (NEW SELECTIVE-VERB-BYPASS variant — 5th wzjo9.1.7)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-10
status: shipped
priority: P2
mission_fitness: adjacent
parent: flywheel-1hshd (jloib wave-4; sub-bead 13 of 37)
sister_exemplars: cross-variant — distinct from all 4 prior wzjo9.1.7 variants
---

# Journey: flywheel-1hshd.13

## What Joshua asked for

Wave-4-general-13. Surface: cleanup-scratch.sh = the canonical scratch-
cleanup primitive used by every worker tick this session
(`flywheel-cleanup-scratch --apply --json $WORK_TMP`). Self-referential
ship.

## What I shipped

**NEW WZJO9.1.7 VARIANT: SELECTIVE-VERB-BYPASS**. The 5th variant
joins the family — distinct from NO-BYPASS / PARTIAL-BYPASS /
NUANCED-PARTIAL-BYPASS / BYPASS-ALL.

Prior variants split bypass at the verb-vs-flag boundary. This variant
goes finer: per-verb AND per-flag selective bypass. Required because
cleanup-scratch.sh natively implements 6 of 7 canonical verbs PLUS the
--info flag with rich envelopes, but lacks 4 verbs + 2 flags entirely.

Bypass list:
- VERBS bypassed: doctor / health / schema / info / examples / why
- VERBS scaffold-owned: repair / validate / audit / quickstart / completion
- FLAGS bypassed: --info
- FLAGS scaffold-owned: --schema / --examples

- 18 TODO markers replaced with substantive impl
- doctor: 5 named probes (defensive fallback; native is authoritative)
- health: 30d stale threshold (defensive fallback)
- repair: 1 minimal scope (audit_log_dir; native cleanup is via default
  ABSOLUTE_PATH arg form, not via repair verb)
- validate: 3 subjects (scratch-path absolute-only — 4TH occurrence of
  this pattern; mode-name enum {dry-run,apply}; audit-row standard)
- audit: cli_emit_audit_tail; why: defensive fallback (native authoritative)
- Test 13 → 19 with calibration:
  - Tests 5/6/11: native verbs (doctor subsystems, health, why path-policy)
  - Tests 3/4: scaffold flags (--schema/--examples NOT bypassed)
  - Test 14: SELECTIVE-VERB-BYPASS annotation grep-discoverable
  - Test 15: NEW 4-DIRECTION fidelity check (native verb + scaffold verb
    + native flag + scaffold flag all in one assertion)
  - Test 19: native schema verb has documented mutation_modes + stable_exit_codes

## AG verification

AG1-5 strict apply-spec validation predicate: **AG1-5 PASS**. 19/19 tests pass.
Lint clean (0 violations). All 4 routing directions functional.

## Notable

- **5-variant family complete**: SELECTIVE-VERB-BYPASS rounds out the
  wzjo9.1.7 taxonomy. Variant matrix now covers every native-canonical-
  coverage scenario:
  | Native verbs | Native flags | Variant |
  |---|---|---|
  | None | None | NO-BYPASS |
  | None | All 3 (--info/--schema/--examples) | PARTIAL-BYPASS |
  | None | Subset | NUANCED-PARTIAL-BYPASS |
  | All 7+ | All 3+ | BYPASS-ALL |
  | **Subset** | **Subset (any combo)** | **SELECTIVE-VERB-BYPASS (NEW)** |

- **4-direction fidelity check** (test 15) is a new canonical pattern
  for SELECTIVE variants. Asserts native verb + scaffold verb + native
  flag + scaffold flag all route correctly in one assertion.

- **scratch-path absolute-only** is the FOURTH occurrence of the
  absolute-only path-arg pattern (5ke66.2 target-path, 5ke66.19 repo-path,
  1hshd.11 root-path, 1hshd.13 scratch-path). FORMALLY MATURE at 4
  occurrences — strong META-RULE candidate for feedback memory.

- **Self-referential**: I've used `cleanup-scratch.sh --apply --json
  $WORK_TMP` in 18+ prior worker ticks this session. Now those same
  calls coexist with newly-canonical doctor/health/validate/audit
  surfaces.

## Files touched

- `.flywheel/scripts/cleanup-scratch.sh` (207 → 453 lines)
- `tests/cleanup-scratch-canonical-cli.sh` (94 → 168 lines)
- `.flywheel/audit/flywheel-1hshd.13/{evidence,journey,compliance,15 smoke,test-run,lint,diff,before}`
- `.flywheel/journal/flywheel-1hshd.13.md`

## Mission fitness

Class: **adjacent**. cleanup-scratch.sh is the canonical scratch-cleanup
primitive used by every worker tick. NEW SELECTIVE-VERB-BYPASS preserves
its rich native canonical coverage while adding missing scaffold
surfaces for orchestrator-side use.
