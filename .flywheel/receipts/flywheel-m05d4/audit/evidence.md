# flywheel-m05d4 — create skillos state/kernel.json (file-existence gate)

## Bead context

- ID: `flywheel-m05d4` (P2)
- Title: `[skillos-gap] state/kernel.json missing or empty (blocks structural_validation_command)`
- Filed by: `flywheel-gibd` close (2026-05-09 live probe confirmed 3 of 4 structural files present in skillos; `state/kernel.json` missing).
- Bead's own narrowed scope: file existence/non-empty (the [-s state/kernel.json] gate inside `.flywheel/loop.json:structural_validation_command`).

## DoD gates (3)

| Gate | Status | Evidence |
|---|---|---|
| 1. `state/kernel.json` exists | DONE | 2156 bytes; sha256 `9c91157d…3636` |
| 2. `state/kernel.json` is non-empty AND schema-shaped | DONE | jq probe: `schema_version=skillos.kernel.v1 cap_total=40 tracks=bandit_track,mandate_track,task_track` |
| 3. `structural_validation_command` no longer exits 1 (file-missing-or-empty) | DONE | Now exits 2 (next blocker = `flywheel-loop doctor not ready_for_tick`) — clean ladder. |

`did=3/3`

## File shape (skillos.kernel.v1)

The schema mirrors the doctrine in `/Users/josh/Developer/skillos/ARCHITECTURE.md`:

> Loop 7 — Skill-pack synthesis / kernel — Compute the daily kernel: `mandate_track ∪ bandit_track ∪ task_track`, hard-cap 40. Synthesize function packs (client-discovery, proposal, finance, legal, taxes, delivery, vendor-ops) and industry packs (insurance, telecom, title, AI-infra) with lifecycle stages.

Top-level keys:

- `schema_version: "skillos.kernel.v1"`
- `loop_status: "bootstrap"` (Loop 7 is design-only per ROADMAP.md Phase 7; kernel is a structural seed, not a live recompute artifact)
- `cap_total: 40`
- `tracks.{mandate_track,bandit_track,task_track}` — each with `cap=40`, empty `items`, source-not-yet-wired sentinel
- `merged_kernel` — empty union with strategy named
- `function_packs` (7) and `industry_packs` (4) — all marked `stage: "design-only"` (honest)
- `owners`, `next_gates` — explicit plan-debt

The file does NOT lie about Loop 7's operational state. It is a structural-bootstrap seed designed to:
1. Pass the `[-s state/kernel.json]` gate this bead owns.
2. Preserve the schema shape so a future Loop 7 daily-recompute job can write into the same surface non-disruptively.

## Live effect

Before:
```
$ bash -c "$(jq -r '.structural_validation_command' .flywheel/loop.json)"
FAIL: state/kernel.json missing or empty
exit=1
```

After:
```
$ bash -c "$(jq -r '.structural_validation_command' .flywheel/loop.json)"
FAIL: flywheel-loop doctor not ready_for_tick
exit=2
```

The exit-1 path (this bead's scope) is closed. The exit-2 path is tracked at `flywheel-4n16r` (`[skillos-gap] flywheel-loop doctor returns action=split_flywheel_loop_dispatcher (not ready_for_tick)`). Clean blocker-ladder: each layer surfaces the next.

## Mission fitness

`adjacent` — bead m05d4 advances skillos substrate so its `.flywheel/loop.json` structural-validation gate clears, which lets skillos enter normal flywheel-loop tick rotation. That serves the continuous-orchestrator-uptime mission anchor by removing one of the two structural blockers keeping skillos from being driven by `flywheel-loop tick`.

## L52 bead receipt

- `beads_filed=none` (next blocker `flywheel-4n16r` already exists; no new bead needed)
- `beads_updated=flywheel-m05d4` (closed by this dispatch)
- `no_bead_reason=next_blocker_already_tracked_at_flywheel-4n16r`

## L61 ECOSYSTEM-TOUCH

- `agents_md_updated=not_applicable` — no doctrine surface touched in flywheel repo; only added a JSON state file in skillos.
- `readme_updated=not_applicable`
- `no_touch_reason=this is a structural-bootstrap seed in skillos/state/, not a doctrine or skill change. AGENTS.md / canonical L-rules in flywheel repo remain accurate.`

## Skill auto-routes

| Route | Status | Note |
|---|---|---|
| canonical-cli-scoping | n/a | No CLI/flag change; this is JSON-only data file authorship. |
| rust-best-practices | n/a | No Rust touched. |
| python-best-practices | n/a | No Python touched. |
| readme-writing | n/a | No README touched. |

## Four-Lens Self-Grade

- **brand: 9** — minimal, honest, cap-40 schema with clear `loop_status: "bootstrap"` field; doesn't lie about Loop 7's design-only state.
- **sniff: 9** — surgical fix for the file-existence gate; preserves schema shape so a future live recompute can fill `tracks[].items[]` without breaking shape; verified before/after exit codes (1 → 2 ladder).
- **jeff: 9** — single-source-of-truth: the schema mirrors the doctrine in skillos `ARCHITECTURE.md` Loop 7; future skillos owner of Loop 7 can write into this exact surface without renaming or reshaping.
- **public: 9** — Three Judges: skeptical operator (validates file-existence gate is fixed; next blocker surfaced cleanly), maintainer (file is honest about bootstrap state; doesn't claim Loop 7 is live), future worker (when Loop 7 ships, the same JSON surface accepts items into mandate/bandit/task tracks under the cap).

`four_lens=brand:9,sniff:9,jeff:9,public:9`

## Out-of-scope (intentional)

The bead's narrowed scope is the file-existence gate only. The following are NOT addressed in this dispatch:

1. **flywheel-loop doctor `action=split_flywheel_loop_dispatcher`** — tracked at `flywheel-4n16r`.
2. **Loop 7 daily kernel-recompute job** — tracked in skillos ROADMAP.md Phase 7 (design-only).
3. **mandate/bandit/task-track sources** — tracked in skillos ROADMAP.md Phase 7 next-gates.

This is correct scope discipline: the bead specifies "missing or empty (blocks structural_validation_command)" and we fix exactly that.
