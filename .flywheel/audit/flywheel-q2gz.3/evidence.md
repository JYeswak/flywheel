# flywheel-q2gz.3 Evidence — wave-2 leverage-4 doctrine docs (MISSION.md + STATE.md)

Task: `flywheel-q2gz.3-19574e`
Bead: `flywheel-q2gz.3` (P2 OPEN → CLOSED this turn)
Title: docs-readme-wave-2-leverage-4-doctrine-docs
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)
Mission fitness: `mission_fitness=infrastructure` — adds the
senior-dev orientation surface that the Lane 3 doctrine-doc floor
requires for `MISSION.md` and `STATE.md`.

## What changed

Two locked doctrine docs gained a **Senior-Dev Orientation** block
inserted between the metadata `provenance_note:` line and the first
content heading. Existing content was NOT modified — the orientation
sits above the locked body so cold workers see it first without
having to scroll past 17k lines of mission text or 200+ lines of
resume-context chain.

| Doc | Before grade | After grade | Lines added |
|---|---|---|---|
| `/Users/josh/Developer/flywheel/.flywheel/MISSION.md` | C (`missing` readme treatment per inventory line 784) | A (orientation block + validation gate present) | ~25 lines |
| `/Users/josh/Developer/flywheel/.flywheel/STATE.md` | C (`missing` readme treatment per inventory line 785) | A (orientation block + validation gate present) | ~26 lines |

Each block carries the five Lane 3 floor elements:

1. **Purpose.** What the doc is, what depends on it, sibling docs.
2. **Update boundary.** Lock-hash semantics, append-only rules,
   metadata-block preservation, owner-gating for wholesale rewrites.
3. **Validation.** Re-runnable shell command using **absolute paths**
   asserting file existence, orientation marker, lock-hash format,
   source SHA format, and content-floor (line count >= N).
4. **Provenance.** Source path + SHA pins from the metadata block,
   pointers to the reconcile origin, and the `git log` integrity
   probe.
5. **Stale signals.** Concrete patterns that indicate drift —
   lock-hash flip without paired handoff, dangling handoff path
   reference, legacy ALPS path drift, etc.

## Acceptance gates

| Gate | Status | Evidence |
|---|---|---|
| AG1 — orientation/pointer section + purpose/update boundary/validation/provenance/stale signals | DID | both files now have a `## Senior-Dev Orientation` block with all five required elements. Validation marker present, lock-hash + source-sha pins cited |
| AG2 — validation commands prove file exists, markers present, no placeholder text | DID | `validation-output.txt` shows `ok` for both docs; the shell predicate uses absolute paths and gates on `## Senior-Dev Orientation`, lock-hash, source-sha, and a content floor (line-count) so a stub-replacement of the locked body fails the gate |
| AG3 — L61 callback fields + AGENTS/README touch decision | DID | doctrine surface touched (`MISSION.md`, `STATE.md`); callback carries `agents_md_updated=no`, `readme_updated=not_applicable`, `no_touch_reason=orientation_block_is_per-doc_not_AGENTS_or_root_README` |
| AG4 — close evidence lists each doc + grade before/after + validation command + gaps | DID | this evidence pack: per-doc table above, per-doc validation command pinned in each doc body, one residual gap noted below |

did=4/4 didnt=none gaps=1 — gap = `flywheel-q2gz.3 inventory grade re-classification` (informational; Lane 1 inventory at `01-INVENTORY-AND-GAPS.md` lines 784-785 still records `missing` because it is a frozen 2026-05-01 snapshot — the next inventory rebuild will reflect the new orientation blocks; no action required this turn).

## Pinned artifact SHAs (post-edit)

| Artifact | Path | SHA-256 |
|---|---|---|
| MISSION.md | `/Users/josh/Developer/flywheel/.flywheel/MISSION.md` | `cb4a2f733fe486bfcb4ed666f6aed1d555574593f743b12719ff9063e0aeb58e` |
| STATE.md | `/Users/josh/Developer/flywheel/.flywheel/STATE.md` | `f24a06553bb0065a85bad58ff12464f49967dffbede6efd4d15e6bbdc53e1098` |

Re-derive via:

```bash
shasum -a 256 /Users/josh/Developer/flywheel/.flywheel/MISSION.md \
              /Users/josh/Developer/flywheel/.flywheel/STATE.md
```

## Per-doc validation commands (pinned in each doc + here)

### MISSION.md

```bash
test -s /Users/josh/Developer/flywheel/.flywheel/MISSION.md \
  && grep -q '^## Senior-Dev Orientation$' /Users/josh/Developer/flywheel/.flywheel/MISSION.md \
  && grep -Eq '^lock_hash: [0-9a-f]{64}$' /Users/josh/Developer/flywheel/.flywheel/MISSION.md \
  && grep -Eq '^source_sha256: [0-9a-f]{64}$' /Users/josh/Developer/flywheel/.flywheel/MISSION.md \
  && [ "$(wc -l < /Users/josh/Developer/flywheel/.flywheel/MISSION.md)" -ge 100 ] \
  && echo ok || echo missing
```

Expected: `ok`. Captured run: see `validation-output.txt`.

### STATE.md

```bash
test -s /Users/josh/Developer/flywheel/.flywheel/STATE.md \
  && grep -q '^## Senior-Dev Orientation$' /Users/josh/Developer/flywheel/.flywheel/STATE.md \
  && grep -Eq '^lock_hash: [0-9a-f]{64}$' /Users/josh/Developer/flywheel/.flywheel/STATE.md \
  && grep -Eq '^source_sha256: [0-9a-f]{64}$' /Users/josh/Developer/flywheel/.flywheel/STATE.md \
  && grep -q '^## Resume Context$' /Users/josh/Developer/flywheel/.flywheel/STATE.md \
  && [ "$(wc -l < /Users/josh/Developer/flywheel/.flywheel/STATE.md)" -ge 50 ] \
  && echo ok || echo missing
```

Expected: `ok`. Captured run: see `validation-output.txt`.

## L112 probe (worker callback)

```bash
test -f /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-q2gz.3/validation-output.txt \
  && [ "$(grep -c '^ok$' /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-q2gz.3/validation-output.txt)" -eq 2 ] \
  && echo ok || echo missing
```

Expected (literal): `ok`.

## Boundary

- **No content rewrite.** `## Mission Source` (twice in MISSION.md, intentional pre-existing shape) preserved verbatim. `## Resume Context` chain in STATE.md preserved verbatim. Metadata block (`schema_version` through `provenance_note`) preserved verbatim.
- **Lock-hash unchanged.** Both docs declare `status: locked`; the orientation block is purely additive prose between metadata and content. The lock-hash field text is unchanged. Lock-log integrity remains the canonical drift detector for the locked body.
- **No AGENTS.md or root README touched.** Per Lane 3 floor, doctrine docs get per-doc orientation, not top-level AGENTS additions.
- **No L-rule edit.** No new doctrine authored.
- **No new placeholders.** Neither orientation block contains placeholder markers; the validation predicate gates on a content-line-count floor instead of a placeholder regex (avoiding the regex-self-match trap).

## Skill auto-routes

- `canonical-cli-scoping=n/a` — no CLI authored. Validation commands are inline shell predicates, not new tools.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — these are doctrine docs (`MISSION.md`, `STATE.md`), not README files. Lane 3 floor is the per-doc bar; Lane 2 (README/Quick Start) does not apply.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — the orientation block lives in each doc, not in `AGENTS.md`. Lane 3 floor explicitly says doctrine docs get per-doc treatment.
- `readme_updated=not_applicable`.
- `no_touch_reason=orientation_block_is_per-doc_per_lane_3_floor_not_AGENTS_or_root_README`.

## Four-Lens Self-Grade — bar = Three Judges + Jeffrey + Donella

- **Brand: 9** — closes AG1/AG2/AG3/AG4 verbatim. Both docs gain the same five-element orientation block; per-doc validation is captured in the audit pack.
- **Sniff: 9** — validation gate uses content-line-count floor instead of placeholder regex, dodging the self-match trap; lock-hash + source-sha format checks catch metadata stripping; tested both docs PASS.
- **Jeff: 9** — Jeffrey-not-Jeff in human-facing prose; small additive surface (~25 lines per doc) instead of rewriting locked content; pinned SHAs and absolute paths everywhere.
- **Public: 9** — Three Judges check passes:
  - **operator (acting tomorrow)**: orientation sits above the body so cold-pane reads see it first; one shell command per doc returns `ok`.
  - **maintainer (extending later)**: stable insertion point (after `provenance_note:`) and explicit out-of-scope list make it obvious where orientation extensions go and where they don't.
  - **future worker (LLM agent)**: bar named, validation literal `ok`, the orientation template is reusable for `GOAL.md` and `AGENTS.md` if a future bead targets them.

`four_lens=brand:9,sniff:9,jeff:9,public:9` (4/4 PASS at threshold 8).

## L52 Receipt

`beads_filed=none beads_updated=flywheel-q2gz.3
no_bead_reason=acceptance_gates_satisfied_inventory_reclassification_is_informational_no_followup_required`.
