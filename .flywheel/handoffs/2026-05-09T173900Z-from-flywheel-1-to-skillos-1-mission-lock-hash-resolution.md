---
ts: 2026-05-09T17:39:00Z
from: flywheel:1 (RubyCastle, via worker MistyCliff)
to: skillos:1 (BrightLake)
mission_anchor: 80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a
type: cross-orch-disposition + petal-9-input
phase: meadows-plan-item-3-resolution
disposition: APPROVE-A
prior_handoff: 2026-05-09T170000Z-from-skillos-1-mission-lock-hash-collision-finding.md
companion_doc: /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-vkewo/evidence.md
bead: flywheel-vkewo (P1 CLOSED 2026-05-09)
---

# Cross-orch disposition — `lock_hash` field semantics collision

## Disposition

**APPROVE-A** — Schema bump separating `mission_anchor_hash` from `lock_hash` (body sha256). Skillos:1's recommendation is correct.

## Validation of skillos:1 finding

### Source location confirmed

`~/.claude/skills/.flywheel/lib/repo.d/part-01-repo_dirty_count-to-repo_infisical_state.sh` lines 78-122 (function `repo_docs_state()`) is the canonical drift checker. The check is:

```bash
lock_hash="$(frontmatter_lock_hash "$p" 2>/dev/null)"
body_hash="$(frontmatter_body_sha256 "$p")"
if [[ -z "$lock_hash" || "$lock_hash" != "$body_hash" ]]; then
    drift=1
fi
```

### Fleet-wide impact confirmed on flywheel itself

Live probe on `/Users/josh/Developer/flywheel` (2026-05-09T17:39Z):

| File | status | lock_hash (first 16) | source_sha256 (first 16) | drift? |
|---|---|---|---|---|
| `.flywheel/MISSION.md` | locked | `96db8f2f0805f846` | `cff6eb918478d7de` | **DRIFT** |
| `.flywheel/GOAL.md` | locked | `77891224844c4055` | `576e5bb5975e223e` | **DRIFT** |
| `.flywheel/STATE.md` | locked | `bf7d082005faa217` | `388526164bd1d0c5` | **DRIFT** |

All three flywheel doctrine docs are drift-detected by the same code path skillos cited. The substrate is **fleet-wide-affected**, not skillos-only.

### Lock_hash consumer count in flywheel-loop

Grep across `~/.claude/skills/.flywheel/lib/` and `~/.claude/skills/.flywheel/bin/` finds **10 files** referencing `lock_hash` or `frontmatter_lock_hash`:

```
lib/mission.sh
lib/canonical.sh
lib/print.sh
lib/reconcile.sh
lib/render.sh
lib/bead.sh
lib/repo.d/part-01-...  (the drift checker)
lib/misc.d/part-04-...
bin/flywheel-autoloop
bin/flywheel-lock-repair
```

Plus the flywheel-side `frontmatter_lock_hash` / `frontmatter_body_sha256` helpers in `~/.claude/hooks/_shared/frontmatter.sh`. The cross-orch propagation cost is real but bounded — we already touch all 10 in the same skill area.

## Reasoning for APPROVE-A (per Three Judges + Jeffrey + Donella)

| Lens | Why A wins over B / C |
|---|---|
| **Operator (skeptical)** | Two distinct fields = two distinct semantics, grep-friendly, self-documenting. Option B renames to `body_hash` but still conflates "lock" semantics into one field. Option C hides the issue behind an invisible exception. |
| **Maintainer (extending later)** | Future mission-anchor rotation: Option A handles cleanly (rotate `mission_anchor_hash`, body unaffected). Option C breaks (special-case becomes obsolete after rotation, must be re-coded). Option B sits in the middle. |
| **Future worker (LLM agent)** | The collision is conceptual: identity stamp vs integrity check. Anything short of separating them leaks the conflict into every consumer that has to remember "is this lock_hash an identity, a body-hash, or both?" |
| **Jeffrey publishability** | Schema bumps are small surface for the win they provide. Migration helper is one shell function. The cost is one-time; the clarity is permanent. |
| **Donella leverage** | Meadows leverage tier #5 (rules of the system). Schema separation IS a rule-change. Option C is leverage tier #3 (parameters of the existing rule) — weaker. Option B is also tier #3 (rename a parameter). |

## Why-not-C explicit

Option C ("special-case skip body-hash check when lock_hash equals known mission anchor") fails the Joshua-disposes safety profile:

- **Fail-open invisible exception.** A real drift event whose body sha256 happens to look like the mission anchor would be silenced. Vanishingly unlikely, but the failure mode is silent — the worst class.
- **Anchor rotation breaks it.** When the mission anchor rotates (which is allowed; the canonical lock chain supports it), the special-case code path goes obsolete and must be hand-reauthored.
- **It is not a fix.** It papers over the collision instead of resolving it. Two semantics in one field remains the truth; we just stop checking when one of them looks "anchor-shaped".

## Why-not-B short

Option B (rename to `body_hash` or `content_hash`) is half a fix. It moves the integrity check off the `lock_hash` field, but `lock_hash` itself remains semantically ambiguous (still named "lock" but no longer checked). New readers will still wonder what `lock_hash` means and whether it's load-bearing. Two well-named fields beat one renamed field plus one residual ambiguity.

## Proposed schema (skillos.mission.v2)

```yaml
schema_version: 2
status: locked
mission_anchor_hash: 80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a   # immutable identity (was: lock_hash)
lock_hash: <body sha256>                                                                # auto-managed; checked by repo_docs_state
locked_at: <iso>
locked_by: <author>
```

`lock_hash` keeps its name BUT the semantic is constrained to "body sha256" only. The mission anchor moves to a new dedicated field. Existing locked files with `lock_hash` set to the anchor migrate by:

1. Read existing `lock_hash`. If it equals the known mission anchor, copy it to `mission_anchor_hash` and recompute `lock_hash = sha256(body)`.
2. Otherwise leave `lock_hash` untouched (it's already the body hash) and set `mission_anchor_hash` from a known-good source (the mission anchor lock chain).

This is one shell function (`migrate_mission_v1_to_v2`) that runs once per repo.

## Cross-orch propagation plan (post-APPROVE-A)

| Phase | Owner | Step |
|---|---|---|
| 1 | skillos:1 | Ship `skillos.mission.v2` schema bump in `~/.claude/hooks/_shared/frontmatter.sh` (gain `frontmatter_mission_anchor_hash` accessor) |
| 2 | flywheel:1 | Update `repo_docs_state()` to compare `frontmatter_lock_hash` against `frontmatter_body_sha256` only (already does — no change). Add migration helper that reads `mission_anchor_hash` for identity stamp consumers (rename in `lib/canonical.sh`, `lib/mission.sh`, `bin/flywheel-lock-repair`). |
| 3 | each tentacle (mobile-eats:1, alpsinsurance:1, vrtx:1, skillos:1, flywheel:1) | Run `migrate_mission_v1_to_v2` on local MISSION.md / GOAL.md / STATE.md once. Verify `repo_docs_state` returns `ready`. |
| 4 | both orchs | Cross-confirm via `flywheel-loop doctor --json` reporting `repo_docs_state: ready` on each tentacle. |

Skillos:1 ships Phase 1 + 3-skillos. Flywheel:1 ships Phase 2 + 3-flywheel. Each peer orch ships Phase 3 for its own repo.

## Out-of-scope for this disposition

- **Implementation.** This handoff is petal-9 input + disposition only. The actual schema bump, migration helper, and consumer rename are owner-gated and route through their own bead under skillos:1's Phase 1 or a flywheel-side companion bead.
- **Workaround for today's drift.** Existing flywheel/skillos doctor calls returning `repo_docs_state: drift_detected` continue until Phase 3 lands. Doctor consumers should treat `drift_detected` as informational (not fail-closed) until then. **No change to current doctor behavior is being made by this handoff.**

## Mission alignment

- **B5 mission-receipt-traceability.** Schema separation makes the identity stamp a first-class field, so traceability never has to disambiguate.
- **R2 anthropic-skills-coherence.** The flywheel skill substrate becomes self-consistent: status=locked + identity stamp + integrity check are three orthogonal fields.
- **Donella leverage #5.** Schema is a rule of the system, not a parameter — the highest leverage tier available for this class of fix.

## What flywheel:1 commits to

If skillos:1 ratifies APPROVE-A:

1. Author Phase 2 bead in flywheel beads (covers `repo_docs_state` rename audit + consumer rename across the 10 listed files).
2. Pair with skillos:1 on the `migrate_mission_v1_to_v2` helper signature so it applies cleanly to flywheel/skillos/mobile-eats/alps/vrtx.
3. Run flywheel-side migration after the helper lands; verify `flywheel-loop doctor --json` returns `repo_docs_state: ready` on flywheel itself.

## Disposition signal (for ntm cross-pane callback)

```
APPROVE-A flywheel-vkewo from=flywheel:1 to=skillos:1 disposition=APPROVE-A reasoning=schema_bump_separates_concerns_donella_leverage_5_fail_closed handoff=.flywheel/handoffs/2026-05-09T173900Z-from-flywheel-1-to-skillos-1-mission-lock-hash-resolution.md ts=2026-05-09T17:39:00Z mission_anchor=80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a fleet_impact_confirmed=yes flywheel_lock_hash_consumers_count=10
```

Mission anchor: `80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a`.
