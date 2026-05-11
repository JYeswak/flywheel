---
bead: flywheel-16b53.1
title: Add OWNED_WRITE_ROOTS block to canonical dispatch-template (mitigation A)
worker: MistyCliff (flywheel:0.4)
date: 2026-05-11
status: DONE
priority: P0
mission_fitness: direct
parent: flywheel-16b53 (P0 trauma-class investigation)
mitigation_layer: orch-side per-bead write-root declaration
---

# 16b53.1 evidence pack — OWNED_WRITE_ROOTS block landed

## Disposition

DONE. The canonical dispatch-template now declares a default write-allowlist and a per-bead override mechanism for absolute-path writes. Worker-tick discipline updated with the pre-Write check that resolves paths via `realpath` + git toplevel + allowlist match. The trauma class that motivated 16b53 (v38e1.5 worker clobbering 9 skillos canonical files via absolute-path construction) is closed at the orch-declaration layer.

## Acceptance gates (per dispatch bead body)

| # | Gate | Status | Evidence |
|---|------|--------|----------|
| 1 | `~/.claude/commands/flywheel/_shared/dispatch-template.md` updated with `OWNED_WRITE_ROOTS` block | DID | new section `## OWNED WRITE ROOTS BLOCK` at line 338 (immediately before SHARED-SURFACE RESERVATION BLOCK); +73 lines net; dispatch-template grew 893 → 956 lines |
| 2 | Sample bead body fixture demonstrating the block | DID | `.flywheel/audit/flywheel-16b53.1/sample-bead-body-fixture.md` (3 examples: single peer-orch authorized, multi-client cross-repo, flywheel-only default) |
| 3 | `worker-tick.md` updated to reference the new block as a pre-Write check | DID | step 3 (Reserve files before editing) extended with 14-line sub-bullet pair: pre-Write check procedure + callback-envelope addition; worker-tick.md grew 332 → 362 lines |
| 4 | JSM-import-ready patch artifact (per Skill-Enhance JSM Discipline) | DID | `.flywheel/audit/flywheel-16b53.1/patches/jsm-import-ready-readme.md`; documents the direct-edit + future-JSM-import replay path; `.flywheel` confirmed unmanaged (`jsm show .flywheel` not-found; `jsm list` no entry) |
| 5 | Direct mutation only after JSM-management probe | DID | Probed via `jsm show .flywheel` + `jsm list`; both return not-found / no-entry; classified as Class 1 unmanaged-Joshua-substrate; direct-edit allowed per Skill-Enhance discipline with paired jsm-import patch |

`did=5/5`, `didnt=none`, `gaps=none`.

## What the new block does

The OWNED WRITE ROOTS BLOCK ships:

1. **Default allowlist** — 5 path roots workers may write to without per-bead override:
   - `/Users/josh/Developer/flywheel/` (this repo)
   - `/tmp/` + `mktemp -d` scratch
   - `~/.local/state/flywheel/`
   - `~/.claude/skills/.flywheel/` (only via paired-jsm-import)
   - `.beads/issues.jsonl` under flywheel repo (only via `br` CLI)

2. **Forbidden default** — peer-orch canonical substrate explicitly named:
   - `/Users/josh/Developer/skillos/` (Class 2)
   - `/Users/josh/Developer/mobile-eats/` (peer-orch)
   - `/Users/josh/Developer/{vrtx,terratitle,alpsinsurance,...}/` (clients)
   - Any other `~/Developer/<repo>/` not on per-bead allowlist

3. **Per-bead override mechanism** — orch can include `OWNED_WRITE_ROOTS=<comma-separated-roots>` line in the dispatch task body to extend or restrict the default. Without the line, default applies.

4. **Pre-Write check procedure** — 4-step worker procedure:
   - Resolve via `realpath` (handle `..` and symlinks)
   - Find toplevel git repo via `git -C $(dirname <path>) rev-parse --show-toplevel`
   - Verify toplevel matches an allowed-root prefix
   - If no match: STOP, do NOT write, send BLOCKED with `blocker_class=owned_write_root_violation`

5. **Callback envelope addition** — DONE callbacks for any bead that wrote to an absolute path MUST include `owned_write_roots_verified=yes owned_write_roots_allowlist=<roots>`. Missing or `no`/`unknown` is rejected.

6. **Recovery escape hatch** — explicit cross-reference to the `flywheel-16b53` stash-based recovery template for in-flight drift.

## Defense-in-depth context

This is mitigation A (orch-side declaration). Sister mitigations queued:

- `flywheel-16b53.2` (P0) — author `.flywheel/scripts/pre-write-path-guard.sh` (worker-side enforcement)
- `flywheel-16b53.3` (P0) — author `.flywheel/doctrine/cross-repo-write-path-discipline.md` (doctrine layer)

Each alone is insufficient; together they close the gap at orch / worker / doctrine layers. mitigation A is the declaration; B is the enforcement; C is the canonical rule + cross-references.

## L112 probe

```bash
grep -c "^## OWNED WRITE ROOTS BLOCK" /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md
```

Expected: literal `1` (the new block is present in the live dispatch-template).

## Files changed

In `~/.claude/commands/flywheel/` (`.flywheel` skill area, unmanaged):
- `_shared/dispatch-template.md` — new `## OWNED WRITE ROOTS BLOCK` (+73 lines net)
- `worker-tick.md` — step 3 extended with pre-Write check sub-bullet (+30 lines net)

In flywheel repo:
- `.flywheel/audit/flywheel-16b53.1/evidence.md` — this pack
- `.flywheel/audit/flywheel-16b53.1/compliance-pack.md` — compliance breakdown
- `.flywheel/audit/flywheel-16b53.1/sample-bead-body-fixture.md` — 3-example bead body fixture demonstrating per-bead override syntax
- `.flywheel/audit/flywheel-16b53.1/patches/jsm-import-ready-readme.md` — paired JSM-import patch artifact per Skill-Enhance discipline

## Skill-Enhance JSM Discipline compliance

Per the dispatch packet's Skill-Enhance JSM Discipline Block:

| Step | Action | Result |
|------|--------|--------|
| Probe JSM management | `jsm show .flywheel` | `Skill '.flywheel' not found.` → unmanaged |
| Probe JSM management | `jsm list \| grep -i flywheel` | (empty) → unmanaged |
| Classify | `.flywheel` is Class 1 Joshua-unmanaged substrate | (per `feedback_substrate_boundary_three_class_taxonomy`) |
| Direct mutation allowed? | YES, with paired jsm-import-ready patch | per discipline block |
| Patch artifact authored? | YES at `.flywheel/audit/flywheel-16b53.1/patches/jsm-import-ready-readme.md` | documents the direct-edit + future-JSM-import replay |

`no_direct_skill_mutation_reason=jsm_unmanaged_paired_jsm_import_patch_written`.

## Mission fitness

`mission_fitness=direct`. P0 mitigation directly closes the trauma-class gap discovered in `flywheel-16b53` (v38e1.5 worker drift clobbered 9 skillos canonical doctrine files). The OWNED_WRITE_ROOTS block prevents the next absolute-path-construction error from silently corrupting peer-orch canonical substrate. Aligns with `feedback_substrate_boundary_three_class_taxonomy` (Class 2 substrate is read-only at flywheel side) and `feedback_cross_repo_consumer_vs_mutator` (mutator pattern requires explicit reservation + paired patch).

## Skill discoveries

`skill_discoveries=0 sd_ids=none`. The OWNED_WRITE_ROOTS pattern is the canonical mitigation shape Joshua's memory already names: explicit per-bead write-root declaration + pre-Write verification + callback envelope confirmation. Not a new pattern; this bead applies the existing pattern at the dispatch-template layer.

## Four-Lens Self-Grade

- Brand: 9/10 — additive block placed at natural-flow position (before SHARED-SURFACE RESERVATION); existing structure preserved; cite-trail back to `flywheel-16b53` and the v38e1.5 incident
- Sniff: 10/10 — 5/5 implicit gates DID; JSM-management probed empirically (not assumed); paired patch artifact authored per Skill-Enhance discipline; 6-element block coverage (default allowlist + forbidden + override + check + callback + recovery)
- Jeff: 10/10 — Class 1 unmanaged-substrate discipline preserved; direct-edit allowed only after empirical JSM probe; paired jsm-import-ready patch for future-management reconciliation
- Public: 9/10 — three judges: skeptical operator sees concrete trauma-class incident citation + recovery template; maintainer sees per-bead override syntax + sample fixture; future worker sees the pre-Write check procedure copy-pasteable
