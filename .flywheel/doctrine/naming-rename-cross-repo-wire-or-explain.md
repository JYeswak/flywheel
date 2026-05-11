---
title: "Naming-Rename Cross-Repo Wire-Or-Explain Discipline"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
---

# Naming-Rename Cross-Repo Wire-Or-Explain Discipline

Version: `naming-rename-cross-repo-wire-or-explain/v1`
Owner: anyone proposing a naming-convention rename touching shared substrate
Status: canonical, shipped 2026-05-11
Source bead: flywheel-2xdi.134 (memory-without-cross-link wire-in)

## TL;DR

A naming-convention rename in one place is **NEVER a local-rename**. It is a
cross-repo wire-or-explain event with **N declared consumers** across 13+
ecosystem surfaces. The rename does not ship until socraticode K≥10
discovery has enumerated every call-site and the Zest Ledger flags any
unwired consumer.

Joshua's 2026-05-05T~21:00Z directive (verbatim):
> "the thing is — a rename in one place impacts other surfaces — so
> socraticode and flagging is imperitive"

## Canonical memory source

This doctrine summarizes
`feedback_naming_rename_is_cross_repo_wire_or_explain.md` — the META-RULE
memory documenting the discipline. Read the memory for the full consumer
list (13 specific paths), 5 anti-patterns, and 5 related-rule cross-refs.

## The rule (formal)

A naming-rename ships only when ALL of these are true:

1. **Discovery complete:** socraticode K≥10 sweep across ALL ecosystem
   repos has enumerated every reference (flywheel, flywheel-install
   templates, alpsinsurance, mobile-eats, skillos, vrtx, swarm-daemon,
   ZestStream public, `~/.claude/skills/*`, memory files, INCIDENTS.md,
   runtime state).
2. **Consumer ledger built:** every call-site is recorded as a Zest
   Ledger row with `artifact_class=naming_rename_consumer` and `{old,
   new}` name pair.
3. **No flag fires:** every consumer is either wire-confirmed or
   explicitly carries a deferral receipt (`not_required` /
   `bypassed`).
4. **Coordinated apply:** all consumers update in coordinated multi-repo
   batches, tracked via one Zest Ledger view (NOT cross-orch dispatch).
5. **Grep test passes:** `rg -c '<old_name>'` returns `0` AND
   `rg -c '<new_name>'` returns `≥N` across ALL ecosystem repos.

## Discovery set (canonical 13)

| # | Path | Role |
|---|---|---|
| 1 | `/Users/josh/Developer/flywheel` | primary |
| 2 | `/Users/josh/Developer/flywheel/templates/flywheel-install/` | template propagator |
| 3 | `/Users/josh/Developer/alpsinsurance` | client repo |
| 4 | `/Users/josh/Developer/mobile-eats` | client repo |
| 5 | `/Users/josh/Developer/skillos` | peer orch + shared substrate |
| 6 | `/Users/josh/Developer/vrtx` | peer orch |
| 7 | `/Users/josh/Developer/swarm-daemon` | Yuzu-Method canon source-of-truth |
| 8 | `~/.claude/skills/*` | skill bodies |
| 9 | `~/.claude/skills/.flywheel/` | flywheel skill substrate |
| 10 | `~/.claude/projects/*/memory/` | session-persistent memory |
| 11 | INCIDENTS.md (per-repo) | doctrine surface |
| 12 | `~/.flywheel/loops/*.json` | runtime state |
| 13 | ZestStream public docs / brand surfaces | external lexicon |

## Why this matters

- The flywheel substrate spans 8+ repos that reference the same surface names
- Local-rename in flywheel without skillos/alps/mobile-eats updates **silently** breaks consumers — no syntax error, no test fail, just stale references in docs/dispatch-templates/skill bodies/memory files
- This is a wire-or-explain problem at the **meta-layer**: the rename is the artifact; consumers are the ecosystem repos; wired-state = "all repos reference the new name AND zero reference the old name"
- Donella #6 (information flow): renames change the lexicon all readers depend on. Inconsistent lexicon = inconsistent mental model = drift.
- Mission anchor (self-sustaining company): names are the company's terminology. Drift in terminology = drift in operating doctrine.

## Apply (procedural)

1. **BEFORE** the rename plan-arc converges, the plan MUST include a cross-repo discovery phase using socraticode K≥10 against every ecosystem repo.
2. Discovery output is `naming-rename-consumer-set.json` — list of every file:line that uses the old name, per repo, with each entry becoming a Zest Ledger row.
3. Zest Ledger schema entry: `naming_rename_consumer` with fields `{old_name, new_name, consumer_repo, consumer_file, consumer_line, consumer_role}`.
4. Apply runs as a coordinated multi-repo batch — `/simplify-and-refactor-code-isomorphically` per repo, with the Zest Ledger as the cross-repo coordination layer.
5. Verification gate: `rg -c '<old_name>'` returns `0` across ALL ecosystem repos AND `rg -c '<new_name>'` returns `≥N` across the same set.
6. Consumer flag fires if any repo cannot be updated (e.g., upstream Jeff repos we don't own — those get explicit `not_required` or `bypassed` Zest Ledger rows with deferral metadata).

## Anti-patterns (5)

| Anti-pattern | Why it fails |
|---|---|
| "I renamed it in flywheel; that's enough." | The rename ripples to N≥8 ecosystem repos; flywheel alone is one of N consumers, not the sole owner of the name. |
| "I'll rg the old name and rename in place." | That's the LOCAL action. The cross-repo flag must fire FIRST so the rename is coordinated, not opportunistic. |
| "We can fix the stragglers later." | Mid-flight inconsistent lexicon is worse than not renaming at all — teaches stale terminology to half the ecosystem. |
| "Memory files don't matter." | They persist across sessions. Stale memory references teach stale terminology to future-Claude sessions. |
| "Cross-orch dispatch will handle it." | Orchestrator scope boundary forbids cross-orch dispatch for renames. Coordinate via the flag-and-trace ledger, NOT cross-orch. |

## Sister doctrine + memory

- `feedback_naming_rename_is_cross_repo_wire_or_explain` (above-cited canonical source)
- `feedback_naming_convention_distinguishable_ownership` — the naming-convention rule itself (this doctrine is the HOW for that WHAT)
- `feedback_post_wire_or_explain_three_skill_polish_gate` — three-skill polish gate; this doctrine adds the cross-repo verification dimension
- `feedback_no_ad_hoc_per_repo_doctrine_edits` — fix propagation mechanism, not symptom; same Meadows class
- `feedback_orchestrator_scope_boundary` — orchestrator only re-dispatches own-session tasks; cross-repo renames coordinate via flag-and-trace, NOT cross-orch dispatch
- `socraticode` skill — K≥10 cross-project search is the discovery primitive

## Conformance

A naming-rename ship proves conformance via:
- Plan-arc cites this doctrine path as the procedural reference
- Discovery output `naming-rename-consumer-set.json` exists with N≥1 row per ecosystem repo (or explicit `not_required`/`bypassed` receipt)
- Zest Ledger contains `naming_rename_consumer` rows for the new+old name pair
- Verification grep test (`rg -c '<old>' = 0` ecosystem-wide) passes
- Apply receipt names commit SHAs for each consumer repo

## Lifecycle

This is a HARD RULE for any future naming-convention rename. The 2026-05-05
directive remains operative: socraticode + flag-and-trace + Zest Ledger
coordination is **table stakes** for renames touching shared substrate.
