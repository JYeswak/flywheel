# flywheel-ztau1 — backfill cfs-expo source_repo='.' to absolute path

## Bead context

- ID: `flywheel-ztau1` (P2)
- Title: `[source-repo-backfill] cfs-expo source_repo='.' rows (98) need backfill to absolute path`
- Filed by: `flywheel-8x2le` (parent disposition decision)
- Cross-ref: jeff-issue draft at `.flywheel/evidence/flywheel-8x2le/jeff-br-source-repo-issue-draft.md` (Jeff-owned repos out of scope per `feedback_no_push_ntm_br`)

## DoD gates (4)

| Gate | Status | Evidence |
|---|---|---|
| 1. SQL UPDATE backfills `source_repo='.'` → `'/Users/josh/Developer/cfs-expo'` in DB | DONE | `sqlite3 .beads/beads.db "UPDATE issues SET source_repo='/Users/josh/Developer/cfs-expo' WHERE source_repo='.';"` ran inside cfs-expo cwd |
| 2. `br sync` re-aligns JSONL with DB | DONE | `br sync --flush-only --force` exported 98 issues + 54 dependencies; `br sync --status` returns `Status: In sync` |
| 3. Count drops to 0 in DB | DONE | `SELECT count(*) FROM issues WHERE source_repo='.';` returns 0 (was 98); `SELECT count(*) FROM issues WHERE source_repo='/Users/josh/Developer/cfs-expo';` returns 98 |
| 4. Commit lands the JSONL change | DONE | cfs-expo commit `83019af8` on branch `main`; only `.beads/issues.jsonl` staged per PICOZ scope discipline |

`did=4/4`

## Live effect

Before:
```
DB:   source_repo  | count
       .            | 98

JSONL distinct source_repo:
  98 .
```

After:
```
DB:   source_repo                          | count
       /Users/josh/Developer/cfs-expo      | 98

JSONL distinct source_repo:
  98 /Users/josh/Developer/cfs-expo
```

Fleet-wide audits that aggregate by `source_repo` now see cfs-expo issues attributed to their canonical absolute path rather than the legacy relative `.` token.

## Why `--force` on the flush

Direct SQL UPDATE bypasses br's dirty-tracking. After the UPDATE, `br sync` reported `Nothing to export (no dirty issues)` and `JSONL is current (hash unchanged since last import)` because the DB didn't carry a "dirty" marker for the rows. `br sync --flush-only --force` overrides the cache-hash guard and re-exports the DB → JSONL.

Safety: a backup of both the pre-backfill DB and JSONL was taken to WORK_TMP (`/private/tmp/flywheel-ztau1.XXX/{beads.db,issues.jsonl}.pre-backfill`) before the UPDATE. The backup is removed when WORK_TMP is cleaned up; durable evidence (sha256 of post-state, before/after counts) lives in `pinned-shas.txt` and `probe-output.txt`.

## Out-of-scope (intentional)

Per the bead body's explicit Jeff-owned exclusion clause:

> Jeff-owned repos (frankenterm 2465 rows, vibe_cockpit 167 rows, ntm 195 rows) excluded per memory rule feedback_no_push_ntm_br: these are Joshua-local working copies of Jeff repos and the .beads DB stays local-only; backfilling there has no upstream consequence but is out of scope for this dispatch.

Also out of scope:

- `.beads/.br_history/` rotation churn (~100 deletes from br's automatic history rotation since the 2026-03-27 commit `ce515ef`). These are pre-existing dirty state in cfs-expo, not caused by this dispatch. They should be addressed by a dedicated cleanup bead.

T2.3 (the parent's broader fleet-wide source_repo-backfill gate) will still fail until the Jeff-owned repos are addressed via a separate dispatch decision (per parent `flywheel-8x2le`).

## Mission fitness

`adjacent` — bead ztau1 backfills source_repo metadata so fleet-wide audits attribute cfs-expo issues correctly. Removes one of three remaining `source_repo='.'` cohorts blocking T2.3 of the parent disposition. Serves continuous-orchestrator-uptime by tightening fleet-attribution accuracy that drives orchestrator triage and bead-routing decisions.

## L52 bead receipt

- `beads_filed=none`
- `beads_updated=flywheel-ztau1` (closed by this dispatch)
- `no_bead_reason=Jeff-owned repos (frankenterm/vibe_cockpit/ntm) excluded per bead body and memory rule feedback_no_push_ntm_br; T2.3 owner decides whether to file a separate dispatch for the Jeff cohort`

## L61 ECOSYSTEM-TOUCH

- `agents_md_updated=not_applicable`
- `readme_updated=not_applicable`
- `no_touch_reason=metadata backfill in cfs-expo .beads/issues.jsonl; no doctrine, INCIDENTS, canonical L-rule, or skill surface touched in flywheel repo`

## Skill auto-routes

| Route | Status | Note |
|---|---|---|
| canonical-cli-scoping | n/a | Used existing canonical CLIs (`sqlite3`, `br sync --flush-only --force`); no new CLI authored. |
| rust-best-practices | n/a | No Rust touched. |
| python-best-practices | n/a | No Python touched. |
| readme-writing | n/a | No README touched. |

## Four-Lens Self-Grade

- **brand: 9** — minimal, surgical: SQL UPDATE in canonical cwd, force-flush, commit. No theater.
- **sniff: 9** — verified before/after counts in BOTH the DB and JSONL; confirmed `br sync --status` returns `In sync`; backed up pre-state to WORK_TMP before the UPDATE; PICOZ-scoped commit (only `.beads/issues.jsonl`).
- **jeff: 9** — single-source-of-truth: DB → JSONL alignment via canonical br tooling, not manual JSONL edit. Respects `feedback_beads_jsonl_writes_via_br_only` memory rule.
- **public: 9** — Three Judges: skeptical operator (count gate is 0, exact target met); maintainer (PICOZ scope keeps the commit clean of br history rotation churn); future worker (the `--force` flag rationale is documented; backup posture is captured; Jeff-cohort exclusion is cited from canonical doctrine).

`four_lens=brand:9,sniff:9,jeff:9,public:9`
