# flywheel-vkewo Evidence — APPROVE-A on lock_hash semantic collision

Task: `flywheel-vkewo-e14432`
Bead: `flywheel-vkewo` (P1 OPEN → CLOSED this turn)
Title: [cross-orch:skillos] mission_lock_hash collision — Petal-9 input on options A/B/C
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=infrastructure` — substrate-validation
work + cross-orch disposition. CORE invariant per the bead's "Mission
fitness" line: lock collision blocks every MISSION.md edit fleet-wide.

## Disposition

**APPROVE-A** — Schema bump separating `mission_anchor_hash` from
`lock_hash` (body sha256). Skillos:1's recommendation ratified.

Response handoff: `.flywheel/handoffs/2026-05-09T173900Z-from-flywheel-1-to-skillos-1-mission-lock-hash-resolution.md`.

## Acceptance gates (line by line)

| Gate | Status | Evidence |
|---|---|---|
| 1. Read handoff fully | DID | full body cited in response handoff with exact source location quote (`lib/repo.d/part-01-...sh:78-122`) |
| 2. Validate finding against flywheel's lock_hash consumers | DID | `validation-evidence.txt` — 10 files in `~/.claude/skills/.flywheel/lib/` + `bin/` reference `lock_hash` or `frontmatter_lock_hash`; flywheel doctrine docs reproduce the same drift pattern |
| 3. Pick A/B/C with reasoning | DID | APPROVE-A with Three Judges + Jeffrey + Donella reasoning section in the response handoff |
| 4. Draft response handoff | DID | `2026-05-09T173900Z-from-flywheel-1-to-skillos-1-mission-lock-hash-resolution.md` (frontmatter-tagged, schema-versioned, includes propagation plan) |
| 5. xpane skillos:1 with disposition | DID | `ntm send skillos --pane=1 ...` with disposition signal `APPROVE-A flywheel-vkewo` (see callback section); `xpane` is shorthand for `ntm send <session> --pane=N`, no separate binary |

did=5/5 didnt=none gaps=none.

## Validation receipts

### Source code citation matches

Skillos:1 cited `~/.claude/skills/.flywheel/lib/repo.d/part-01-repo_dirty_count-to-repo_infisical_state.sh:78-122`. Confirmed: that path exists, the function is `repo_docs_state()`, and the comparison is `lock_hash != body_hash → drift=1`. Reproduced verbatim in `validation-evidence.txt`.

### Fleet impact confirmed on flywheel itself

Flywheel `.flywheel/MISSION.md`, `GOAL.md`, `STATE.md` all show lock_hash ≠ source_sha256 today. Same collision class as skillos. Substrate is fleet-wide-affected, not skillos-only:

```
MISSION.md: lock_hash=96db8f2f0805f846 source_sha256=cff6eb918478d7de DRIFT
GOAL.md:    lock_hash=77891224844c4055 source_sha256=576e5bb5975e223e DRIFT
STATE.md:   lock_hash=bf7d082005faa217 source_sha256=388526164bd1d0c5 DRIFT
```

### Lock_hash consumer count

10 files in `~/.claude/skills/.flywheel/`:

```
lib/mission.sh
lib/canonical.sh
lib/print.sh
lib/reconcile.sh
lib/render.sh
lib/bead.sh
lib/repo.d/part-01-...   (the drift checker)
lib/misc.d/part-04-...
bin/flywheel-autoloop
bin/flywheel-lock-repair
```

Plus `~/.claude/hooks/_shared/frontmatter.sh` accessor functions.
Cross-orch propagation cost is real but bounded.

## Reasoning summary (full reasoning in the response handoff)

Schema bump (Option A) wins because:

1. **Two distinct semantics get two distinct fields.** Identity stamp (immutable, mission-anchor) vs body integrity (auto-managed, sha256-of-body) are conceptually orthogonal. Separating them resolves the root cause.
2. **Donella leverage tier #5** (rules of the system) — the highest leverage class for this fix. Options B/C operate at tier #3 (parameters of the existing rule).
3. **Fail-closed** — Option C is fail-open (a real drift could be silenced if it happens to look like the mission anchor). Option A fails closed on either field mismatching its semantic.
4. **Future-proof** — mission anchor rotation works cleanly under A. Option C breaks (special-case becomes obsolete after rotation).
5. **Migration cost is bounded** — one shell helper (`migrate_mission_v1_to_v2`) per repo; 5 repos in the fleet today.

## Pinned artifact SHAs

| Artifact | Path | SHA-256 |
|---|---|---|
| inbound handoff | `.flywheel/handoffs/2026-05-09T170000Z-from-skillos-1-mission-lock-hash-collision-finding.md` | `a4c02e613f141c8c2e5c4b25d411dc0d2fe0dd0270f091dd26d8beb9231ebb2c` |
| outbound handoff | `.flywheel/handoffs/2026-05-09T173900Z-from-flywheel-1-to-skillos-1-mission-lock-hash-resolution.md` | `f52ab1aae7b77a9bd223114414a23f41878d6ac5ce6aac0694dcf5005ec3b1f8` |

## Verification commands (re-runnable)

```bash
# Confirm response handoff exists with disposition=APPROVE-A
test -f /Users/josh/Developer/flywheel/.flywheel/handoffs/2026-05-09T173900Z-from-flywheel-1-to-skillos-1-mission-lock-hash-resolution.md \
  && grep -q '^disposition: APPROVE-A$' /Users/josh/Developer/flywheel/.flywheel/handoffs/2026-05-09T173900Z-from-flywheel-1-to-skillos-1-mission-lock-hash-resolution.md \
  && echo ok || echo missing

# Reproduce the fleet drift probe
for f in MISSION.md GOAL.md STATE.md; do
  P="/Users/josh/Developer/flywheel/.flywheel/$f"
  L=$(grep -E '^lock_hash:' "$P" | awk '{print $2}')
  S=$(grep -E '^source_sha256:' "$P" | awk '{print $2}')
  [[ "$L" != "$S" ]] && echo "$f DRIFT" || echo "$f OK"
done
```

## L112 probe (worker callback)

```bash
test -f /Users/josh/Developer/flywheel/.flywheel/handoffs/2026-05-09T173900Z-from-flywheel-1-to-skillos-1-mission-lock-hash-resolution.md \
  && grep -q '^disposition: APPROVE-A$' /Users/josh/Developer/flywheel/.flywheel/handoffs/2026-05-09T173900Z-from-flywheel-1-to-skillos-1-mission-lock-hash-resolution.md \
  && echo ok || echo missing
```

Expected (literal): `ok`.

## Boundary

- **No schema bump executed.** The disposition is petal-9 input + cross-orch ratification. Skillos:1 owns Phase 1 (schema change in `~/.claude/hooks/_shared/frontmatter.sh`); flywheel:1 owns Phase 2 (consumer rename across the 10 files); each tentacle owns Phase 3 (one-time migration of its own MISSION/GOAL/STATE).
- **No frontmatter edits.** Today's MISSION.md / GOAL.md / STATE.md frontmatter is unchanged on flywheel. Drift remains until Phase 3 lands.
- **No flywheel-loop edit.** `repo_docs_state()` is unchanged. The disposition is informational; nothing in the doctor surface flips today.
- **`xpane` resolves to `ntm send <session> --pane=N`.** No separate binary; the dispatch verb maps to the canonical NTM transport per fleet doctrine. No shadow tooling introduced.

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — handoff doc, not a public README.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — disposition / petal-9 input only; the doctrine surface change (schema bump) is owner-gated and routes through Phase 1/2/3 in the response handoff.
- `readme_updated=not_applicable`.
- `no_touch_reason=cross-orch_disposition_only_no_doctrine_or_AGENTS_change_authored_today`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes all 5 acceptance lines verbatim. Disposition is unambiguous (APPROVE-A) with explicit why-not for B and C.
- **Sniff: 9** — every claim has a re-runnable shell predicate (source path exists, drift reproduces on flywheel docs, consumer count grep is reproducible, response handoff frontmatter is grep-checkable).
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small surface (one response handoff + one audit pack); refuses to author the schema bump itself (Joshua-disposes per Petal-9); cross-orch propagation plan is explicit and bounded.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: APPROVE-A is a single grep-friendly disposition; the propagation plan is a numbered table.
  - **maintainer (extending later)**: schema migration helper signature is sketched (`migrate_mission_v1_to_v2`); the proposed field shape is explicit so Phase 1 can land cleanly.
  - **future worker (LLM agent)**: Three Judges + Jeffrey + Donella reasoning is the bar; option-comparison template (operator / maintainer / future-worker rows × A/B/C) is reusable for the next collision-class disposition.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-vkewo
no_bead_reason=disposition_only_phase_1_2_3_implementation_routes_through_skillos_1_phase_1_bead_and_a_paired_flywheel_phase_2_bead_authored_after_skillos_1_ratifies_APPROVE-A`.
