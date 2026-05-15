# josh-request schema drift audit — 2026-05-15

**Bead:** flywheel-meadows-doctor-freshness-gauge-reverse-lookup-cy5ay (AC3)
**Goal anchor:** P1 of `~/Desktop/zeststream-goals/flywheel/substrate-compounding-v2-20260515.txt`
**Authored by:** flywheel:1 (Claude Opus 4.7, 1M ctx)

## Why this audit exists

The josh-request substrate has **documented schema v2** but **stores in v1
shape**. The drift is hidden by a runtime converter (the finalize-state-lock
auto-flush pipeline that writes v2-shape `needs_triage` blocks into MISSION.md
from the v1 jsonl). Consumers reading the v2 schema doc and the v1 jsonl side
by side get inconsistent contracts.

Forward consumers (anything that reads MISSION.md absorbed rows) see v2.
Backward consumers (anything that tails the jsonl directly) see v1. Today
flywheel-loop doctor reads from the jsonl path; the
`josh-requests-reverse-lookup` probe also reads jsonl. Both see v1. The schema
doc tells them they should see v2.

## Documented schema (v2)

Source: `templates/josh-request-schema.md` frontmatter `schema_version: 2`,
`previous_version: 1`, `status: shipped`, `shipped_at: 2026-05-03`.

Required fields per row (per the schema doc, section 3 "Entry Shape"):

| Field | Type | Notes |
|---|---|---|
| `id` | string | `jr-<iso-utc-no-colons>-<3digit>` |
| `captured_at` | timestamp | ISO 8601 |
| `source_session` | string | e.g. `flywheel` |
| `source_pane` | int | pane number |
| `transcript_path` | string \| null | claude transcript jsonl path |
| `source_message_id` | string \| null | transcript message id |
| `prompt_hash` | string \| null | `sha256:<hex>` |
| `request_text_hash` | string | `sha256:<hex>` of excerpt |
| `sanitized_excerpt` | string | ≤500 chars |
| `inferred_action` | string \| null | orch interpretation |
| `state` | enum | `needs_triage`/`acknowledged`/`in_progress`/`blocked`/`waiting_on_external`/`done`/`deferred`/`wont_do` |
| `owner` | string | agent identity |
| `priority` | enum | `P0`/`P1`/`P2`/`P3` |
| `scope` | enum | `single-repo`/`cross-session`/`fleet-wide` |
| `last_updated_at` | timestamp | mutates on lifecycle transitions |

## Actual jsonl shape (v1)

Source: head -1 of `~/.local/state/flywheel/josh-requests.jsonl` (1769 rows).

```json
{
  "id": "jr-2026-05-03T21-24-17Z-457",
  "ts": "2026-05-03T21:24:17Z",
  "session": "<uuid>",
  "pane": "null",
  "status": "open",
  "captured_via": "hook",
  "excerpt": "<text>",
  "prompt_hash": "<sha256>",
  "repo": "/Users/josh/Developer/flywheel"
}
```

## Field-by-field drift

| v2 field (documented) | v1 field (actual) | Drift class |
|---|---|---|
| `id` | `id` | match |
| `captured_at` | `ts` | **renamed** |
| `source_session` | `session` | **renamed** (also v1 uses UUID, v2 expects session-name like `flywheel`) |
| `source_pane` | `pane` | **renamed**, also v1 stores `"null"` (string) instead of null/int |
| `transcript_path` | _absent_ | **missing in v1** |
| `source_message_id` | _absent_ | **missing in v1** |
| `prompt_hash` | `prompt_hash` | match |
| `request_text_hash` | _absent_ | **missing in v1** |
| `sanitized_excerpt` | `excerpt` | **renamed** (v1 not sanitized by name; content sanitization unverified) |
| `inferred_action` | _absent_ | **missing in v1** |
| `state` | `status` | **renamed AND value-set drift** — v1 uses `open` (not in v2 enum) |
| `owner` | _absent_ | **missing in v1** |
| `priority` | _absent_ | **missing in v1** |
| `scope` | _absent_ | **missing in v1** |
| `last_updated_at` | _absent_ | **missing in v1** |
| _absent_ | `captured_via` | **extra in v1** (audit metadata) |
| _absent_ | `repo` | **extra in v1** (could fit under source-context) |

**Summary:** 1 exact match (`id`, `prompt_hash`), 5 renames, 8 fields missing
in v1 that the schema declares mandatory, 2 fields present in v1 that the
schema doesn't acknowledge, 1 enum-value-set mismatch (`status` values not in
v2's `state` enum).

## The hidden converter

`flywheel-loop finalize-state-lock` runs an absorption pass that reads recent
v1 rows from the jsonl and emits v2-shape markdown blocks into MISSION.md
under the "{operator} Requests" section. We observed this firsthand in commit
`7f0733c1` (+966 lines of MISSION.md, all v2-shape rows with `state:
needs_triage`, `owner: unassigned`, `priority: P1`, `scope: single-repo`).

The converter defaults the missing fields:
- `state: needs_triage`
- `owner: unassigned`
- `priority: P1`
- `scope: single-repo`
- `last_updated_at: captured_at`
- `transcript_path`, `source_message_id`, `inferred_action`, `closure_*`: null

These defaults are runtime gluework, not documented in the schema.

## Reconcile paths

### Path A — Migrate jsonl forward to v2 (preserve history)

Steps:
1. Author `.flywheel/scripts/josh-request-migrate-v1-to-v2.py`. Read v1 rows,
   emit v2 rows with the same default-value mapping the absorption converter
   uses, plus `previous_v1_row_hash` field linking to source.
2. Append `migration_marker_2026-05-15.jsonl` row separating pre- and post-
   migration eras.
3. Write migrated rows to `~/.local/state/flywheel/josh-requests-v2.jsonl`.
   Do **not** rewrite the v1 file (tombstone-and-rewrite is forbidden per
   goal CONTRACT).
4. Update the writer hook (`~/.claude/hooks/josh-request-capture.sh`) to
   emit v2-shape rows going forward.
5. Update the absorption converter to be a pass-through (no defaulting
   needed; v2 rows already valid).
6. Update `josh-requests-reverse-lookup.py` to read v2 schema.

Reversibility: v1 file unchanged. New v2 file separate. Writer hook revert
via git. Convergence after burn-in.

Blast radius: medium. Writer hook + absorption converter + reverse-lookup
probe + any other consumer.

Stalls: writer hook may have edge cases (PHASE/DONE-callback misclassification
we saw earlier). Migration script needs to handle "null" string vs null.

### Path B — Update schema doc to v1 with deprecation note

Steps:
1. Edit `templates/josh-request-schema.md`: set `schema_version: 1`,
   `status: shipped (legacy)`, add `aspirational_v2: archived`. Move the
   audit-grade v2 spec into `templates/josh-request-schema.v2-archive.md`
   for future use.
2. Document the v1 shape verbatim from the actual jsonl row format.
3. Update the absorption converter doc to call its output "v2 markdown
   projection" not "v2 schema entry" — projection is operator-readable, not
   audit-grade.

Reversibility: pure doc change. Git revert one commit.

Blast radius: low. Doc only. No code or data changes.

Stalls: kicks the audit-grade ambition down the road. v2 features
(priority, owner, lifecycle states, closure evidence) remain unbuilt.

## Recommendation

**Path B for now, Path A as a follow-up bead.**

Reasoning:
- Path B is the smallest reversible substrate-delta. Closes AC3 today.
- Path A is a real migration with edge cases (writer hook updates,
  consumer updates, "null"-string handling, etc.) and needs its own bead.
- The goal CONTRACT says reversibility per move; Path B is single-commit
  reversible. Path A is multi-commit, harder to roll back.
- Joshua can decide Path A later when there's pull for v2 features
  (audit-grade lifecycle, ownership routing, etc.).

## Next-step beads (not filed in this audit; recommend filing as follow-ups)

1. **flywheel-josh-request-schema-pin-v1-with-deprecation** — execute Path B.
   Updates the schema doc to v1 with deprecation note. ≤30 LOC across two
   files (the schema doc + this audit's reference).
2. **flywheel-josh-request-v1-to-v2-migration-pipeline** — execute Path A.
   New migration script + writer-hook update + consumer updates.
   ≤200 LOC across ~5 files. Multi-wave bead.

## AC3 closure evidence

This audit is the AC3 deliverable: substrate-delta is the tracked
`.flywheel/audits/josh-request-schema-drift-2026-05-15.md` commit. cy5ay AC3
can close once Path B (or Path A) is executed. Marking AC3 as
**audit-complete-pending-execution**.
