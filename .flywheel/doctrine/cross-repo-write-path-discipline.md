---
title: "Cross-Repo Write-Path Discipline: Block Worker Drift to Peer-Canonical Substrate"
type: doctrine
created: 2026-05-11
frontmatter_source: scaffold-doc-frontmatter
promoted_from: flywheel-16b53 P0 trauma-class investigation (v38e1.5 incident 2026-05-11T21Z)
canonical_class: cross-repo-write-safety
status: canonical
---

# Cross-Repo Write-Path Discipline: Block Worker Drift to Peer-Canonical Substrate

Version: `cross-repo-write-path-discipline/v1`
Owner: dispatch authors + workers performing any absolute-path Write operation
Status: canonical, shipped 2026-05-11
Source bead: flywheel-16b53 (P0 trauma-class investigation; sub-beads 16b53.1/.2/.3 mitigation cohort)
Source incident: v38e1.5 worker drift 2026-05-11T~21Z (9 skillos canonical doctrine files + 1 README clobbered; recovered via skillos:1 `git stash`)
Promotion authority: P0 trauma-class root-cause-fix #3 of 3 (mitigation-C = this doctrine; mitigation-A = OWNED_WRITE_ROOTS block in 16b53.1; mitigation-B = pre-write-path-guard.sh in 16b53.2)

## TL;DR

A worker authoring files via absolute paths (`Write` tool, `cat > /Users/josh/...`, `cp ... /Users/josh/...`) can silently drift the destination root from the bead's intended repo (e.g. flywheel) to a **peer-orch canonical substrate** (e.g. skillos) and clobber load-bearing files. The trauma class is **absolute-path-construction-drift-to-peer-canonical-substrate**. Before any absolute-path Write outside `cwd`, workers MUST verify the destination's `git rev-parse --show-toplevel` matches the bead's `OWNED_WRITE_ROOTS` allowlist; the mechanization for this check is `.flywheel/scripts/pre-write-path-guard.sh` (shipped via flywheel-16b53.2). Cross-orch authored substrate (skillos, mobile-eats, etc.) is **READ-ONLY consumer pattern** for flywheel workers per `cross-repo-consumer-vs-mutator-boundary.md` — the only sanctioned cross-orch write path is the bilateral cross-orch handoff (per `outbox-discipline-cross-orch-ship-notification.md`).

## Canonical memory source

This doctrine codifies the v38e1.5 incident pattern. The trauma class is named **`absolute-path-construction-drift-to-peer-canonical-substrate`** and registered in the fuckup-log taxonomy.

## The trauma class

### Mechanism

A worker bead intends to write into the **flywheel** repo (e.g. ship doctrine stubs at `.flywheel/doctrine/<name>.md`). The worker correctly authors at `/Users/josh/Developer/flywheel/.flywheel/doctrine/<name>.md` for the primary set, but ALSO constructs a sibling absolute path `/Users/josh/Developer/skillos/.flywheel/doctrine/<name>.md` and writes there — outside the bead's owned-write scope. The Write succeeds because:

1. The worker has filesystem permission for both paths (same user).
2. No pre-Write check verifies the destination matches the bead's allowlist.
3. The cross-repo destination exists and looks "valid enough" to the worker's path-construction heuristic.

The v38e1.5 incident produced **905 lines deleted + 148 lines of stub content inserted** across 10 skillos canonical files — full canonical bodies replaced with thin stub pointers intended for the flywheel side only. See `.flywheel/audit/flywheel-16b53/evidence.md` for the per-file blast-radius table.

### Detection gap

No pre-Write path-vs-allowlist check existed at incident time:

- The dispatch template did NOT carry an `OWNED_WRITE_ROOTS` block (filed as 16b53.1 mitigation).
- Worker-tick discipline did NOT include a "resolve destination toplevel + match allowlist" step (filed as 16b53.1 + 16b53.2 mitigation).
- No tooling primitive existed to enforce the check across `Write`, `cat >`, `cp`, `mv`, or any equivalent surface (filed as 16b53.2 mitigation).
- The `git status` of the peer-orch substrate was not part of the worker's verification surface; the worker assumed silence == no peer-side impact.

### Recovery path (used in the v38e1.5 incident)

The skillos:1 orchestrator detected the unauthorized writes in its own working tree via routine `git status` polling. Captured the canonical content via:

```bash
git -C /Users/josh/Developer/skillos stash push -u -m \
  'v38e1.5-worker-drift-doctrine-stub-overwrites-skillos-canonical-2026-05-11T21'
```

The stash entry `stash@{0}` preserved all 10 file deltas BEFORE any commit. Verified via:

```bash
git -C /Users/josh/Developer/skillos stash show --stat 'stash@{0}'
# 10 files affected, -905/+148 line delta
```

**No data permanently lost** — the peer orch's working-tree `git stash` was the load-bearing recovery primitive. This is why orchestrators MUST hold uncommitted state intentionally (not auto-commit every change); peer-orch `git stash` is the canonical second-chance net.

## Discipline rules (canonical)

### Rule 1 — toplevel resolution before any cross-cwd Write

Workers MUST resolve the destination's git toplevel BEFORE any Write to a path **NOT under `cwd`**:

```bash
DEST_DIR="$(dirname "<destination-path>")"
DEST_TOPLEVEL="$(git -C "$DEST_DIR" rev-parse --show-toplevel 2>/dev/null)"
```

If the destination is outside any git repo (`$DEST_TOPLEVEL` empty), the Write must be classified per `OWNED_WRITE_ROOTS` (Rule 2) explicitly — silent path-construction is forbidden.

### Rule 2 — toplevel MUST match OWNED_WRITE_ROOTS allowlist

The resolved `$DEST_TOPLEVEL` MUST appear in the bead's `OWNED_WRITE_ROOTS` allowlist:

```bash
grep -Fxq "$DEST_TOPLEVEL" "$OWNED_WRITE_ROOTS_FILE" || {
    echo "ERR: pre-Write check failed: $DEST_TOPLEVEL not in OWNED_WRITE_ROOTS" >&2
    exit 2
}
```

If the toplevel is NOT in the allowlist, the Write MUST be aborted. The worker MUST send an in-band `ntm` message to the orchestrator asking for scope expansion BEFORE retrying (per PICOZ_WORKER_FILES discipline).

The `OWNED_WRITE_ROOTS` allowlist for a bead lives at `.flywheel/policy/write-roots/<bead-id>.txt` (one toplevel path per line, `#` comments allowed). If no per-bead file exists, the **default policy** at `.flywheel/policy/write-roots/default.txt` applies (typically the flywheel repo root only).

### Rule 3 — `pre-write-path-guard.sh` is the canonical mechanization

The shipped mechanization for Rules 1+2 is:

- **Primitive:** `.flywheel/scripts/pre-write-path-guard.sh` (~350L; canonical-CLI surface: `doctor / health / repair / audit / why / quickstart / info / schema / examples / help / completion`)
- **Helper:** `.flywheel/lib/canonical-cli-helpers.sh::cli_pre_write_check()` (~50L; routes through the guard; `FLYWHEEL_PRE_WRITE_CHECK_DISABLED` bypass for tests)
- **Test:** `.flywheel/tests/test-pre-write-path-guard.sh` (12-AG regression including AG12 = exact v38e1.5 trauma repro)

Workers do NOT roll their own path-check logic. Workers call:

```bash
.flywheel/scripts/pre-write-path-guard.sh --check "$DEST_PATH" --bead "$BEAD_ID" --json
```

Exit codes: `0` allowed, `2` blocked (not in allowlist), `3` blocked (realpath fail), `4` blocked (toplevel resolution fail).

Per Rule 3, **any worker pattern that bypasses the guard for performance/convenience is a fuckup-class violation** and gets logged to `~/.local/state/flywheel/fuckup-log.jsonl` with `class=cross_repo_write_path_guard_bypassed`.

### Rule 4 — cross-orch authored Class 2 substrate is READ-ONLY consumer pattern

Per `substrate-boundary-three-class-taxonomy.md` and `cross-repo-consumer-vs-mutator-boundary.md`:

| Substrate class | Detection | Write discipline for flywheel workers |
|---|---|---|
| **Joshua-substrate** (Class 1) | `jsm show` → not-found OR Joshua-as-author | Direct mutation + paired `jsm-import-ready` patch artifact |
| **Skillos-substrate** (Class 2, jsm-managed peer-orch) | `jsm show <skill>` → managed; peer-orch ownership (Joshua owns + skillos:1 tracks) | **READ-ONLY consumer**. No flywheel-worker mutation. Mutation requires bilateral cross-orch handoff per `outbox-discipline-cross-orch-ship-notification.md` |
| **Jeff-substrate** (Class 3, premium) | "Jeffrey's Premium Skill ⭐" marker | AUDIT-ONLY. No mutation. No patch. Jeff-issue only if ≥P2 + full workaround research |

**The v38e1.5 trauma is a Rule 4 violation:** the worker treated `/Users/josh/Developer/skillos/.flywheel/doctrine/` as a writable destination when it is in fact peer-orch canonical substrate (Class 2). Even if the path had appeared in some interpretation of OWNED_WRITE_ROOTS, Rule 4 would have blocked the write on substrate-class grounds.

## Cross-references (reciprocal)

- **`cross-repo-consumer-vs-mutator-boundary.md`** — sister doctrine: classifies "is the bead READING or WRITING into `.claude/skills/`?" This doctrine extends that to **any** cross-repo path under `/Users/josh/Developer/`, not just `.claude/skills/`.
- **`substrate-boundary-three-class-taxonomy.md`** — sister doctrine: classifies "WHO owns the target skill (Joshua / Skillos / Jeff)?" This doctrine's Rule 4 cites the 3-class taxonomy directly for cross-orch authored substrate determination.
- **`inbox-discipline-missed-during-deep-burndown-motion.md`** — cohort sister (also promoted 2026-05-11 in the v38e1 wave): the bilateral cross-orch protocol's inbox half. Inbox-discipline is what allowed skillos:1 to detect the v38e1.5 drift in time to stash-recover; this doctrine prevents the drift at source.
- **`outbox-discipline-cross-orch-ship-notification.md`** — cohort sister: the bilateral cross-orch protocol's outbox half. The sanctioned cross-orch write path (per Rule 4) is the bilateral handoff, not direct write into peer-orch substrate.
- **`cross-pane-git-discipline.md`** — adjacent: discipline for multi-pane work within a SINGLE repo (avoid clobbering peer-pane staged changes). This doctrine handles the cross-REPO case.
- **`canonical-cli-validate-mode-enum-projection.md`** — adjacent: `pre-write-path-guard.sh` follows the canonical-CLI surface that this projection doctrine prescribes.

### Reciprocal updates required (per L61 doctrine-landing wires-into-AGENTS-and-README)

The cross-references above are AUTHORED in this doc. The sister doctrines do NOT need symmetric back-references because:
- `cross-repo-consumer-vs-mutator-boundary.md` and `substrate-boundary-three-class-taxonomy.md` are upstream-in-scope (this doctrine extends them; they do not need to know about every extension).
- `inbox-discipline` and `outbox-discipline` are cohort sisters (peer doctrines in the bilateral-protocol family); this doctrine is a cross-cutting safety primitive, not a member of that family.

If a future bead needs to materialize a "see also" link FROM a sister doctrine TO this one, that's a separate bead per `L96 — DOCTRINE-LANDS-AS-3-SURFACE-DIFF-OR-DOES-NOT-LAND` (the 3-surface diff would be: this doctrine + sister back-ref + AGENTS.md catalog or doctrine/README.md count update).

## Mitigation cohort status (per flywheel-16b53 investigation)

The 16b53 P0 trauma-class investigation filed 3 mitigation sub-beads:

| Sub-bead | Mitigation layer | Status |
|---|---|---|
| **flywheel-16b53.1** | Orch-side per-bead `OWNED_WRITE_ROOTS` declaration block in canonical dispatch-template + worker-tick.md pre-Write check reference | ✓ SHIPPED |
| **flywheel-16b53.2** | Layer-1 prevention primitive: `pre-write-path-guard.sh` + `cli_pre_write_check()` helper + 12-AG regression test (incl. v38e1.5 exact repro AG12) | ✓ SHIPPED |
| **flywheel-16b53.3** (this doctrine) | Canonical doctrine documenting the trauma class + 4 discipline rules + cross-references | ✓ SHIPPED (this doc) |

The 3-layer defense is now operational:
- **Orch layer** (16b53.1): dispatch packets declare write-scope at the source-of-truth
- **Tool layer** (16b53.2): pre-Write guard enforces the check at every worker mutation point
- **Doctrine layer** (16b53.3, this doc): names the trauma class + makes the discipline auditable

## Trauma-class observability (for fuckup-log canonicalization)

Future occurrences of this trauma class get logged with:

```json
{
  "schema_version": "flywheel.fuckup.v1",
  "class": "cross_repo_write_path_drift",
  "severity": "high",
  "trauma_root_bead": "flywheel-16b53",
  "doctrine_ref": ".flywheel/doctrine/cross-repo-write-path-discipline.md",
  "dest_path": "<actual path attempted>",
  "dest_toplevel": "<git toplevel of dest>",
  "expected_toplevel": "<from bead OWNED_WRITE_ROOTS>",
  "guard_invoked": true|false,
  "guard_outcome": "blocked|bypassed|not-invoked",
  "recovery_path": "stash|git-checkout|none"
}
```

Per `feedback_8_strike_promotion_threshold` / fuckup-log promotion ladder (L56), the trauma class becomes a candidate for L-rule shard promotion if N≥8 across 30 days.

## What this doctrine is NOT

- Not a license to skip `OWNED_WRITE_ROOTS` declaration in dispatch packets — that's 16b53.1 territory.
- Not a substitute for the runtime guard — that's 16b53.2's `pre-write-path-guard.sh`.
- Not a license to silently mutate peer-orch substrate even within an "authorized" allowlist — Rule 4's substrate-class read-only discipline always wins.
- Not retroactive — does NOT mandate auditing pre-2026-05-11 worker writes for compliance (no time-travel discipline).

## Acceptance evidence (for this bead)

- Doctrine doc landed at `.flywheel/doctrine/cross-repo-write-path-discipline.md` ✓
- 4 discipline rules per bead body ✓ (Rules 1-4 above)
- Sister doctrines cross-referenced reciprocally ✓ (6 cross-refs, with rationale for which require reciprocal back-ref and which don't)
- `.flywheel/doctrine/README.md` `total_doctrines` frontmatter incremented from 89 to 90 ✓ (catalog auto-materializes via `ls -1 .flywheel/doctrine/*.md`; the count update is the AGENTS-catalog-equivalent surface)
- AGENTS.md / `.flywheel/AGENTS-CANONICAL.md` rule catalog NOT modified — those catalogs list L-rules (frontmatter-tagged with L-numbers), not doctrines; doctrine catalog is the auto-materialized `.flywheel/doctrine/README.md`. This is the correct AGENTS-catalog surface per L96 (3-surface-diff rule satisfied by: this doctrine + README count + audit evidence pack).


## Meta-Learning Cross-References (2026-05-19)

This doctrine surface was backfilled during JSM fleet audit batch-3 so recent doctrine cites the relevant MP lessons directly.

- **MP-17 — secret emission discipline:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-17-secret-emission-discipline.md` for the canonical pattern.
- **MP-29 — production safety guardrails:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-29-production-safety-guardrails.md` for the canonical pattern.
- **MP-30 — human-gated invasiveness:** see `/Users/josh/Developer/skillos/.flywheel/doctrine/meta-learnings/MP-30-human-gated-invasiveness.md` for the canonical pattern.
