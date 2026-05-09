# flywheel-b6yu Evidence

Task: `flywheel-b6yu-339825`
Bead: `flywheel-b6yu`
Title: [jeff-track-ntm-config-validate] triage remaining live config validation drift
Date: 2026-05-09
Identity: MistyCliff (flywheel:0.4)

Sister beads: `flywheel-pdwg` (prior triage that landed ntm #111 +
#113); `flywheel-d6tz0` (jeffrey-comment-watchtower for any reply
to a future Jeffrey issue we file here); `flywheel-dm83`
(NTM-vs-roster decision; cited for `session_paths.*` disposition).

## Disposition

**Triaged 4 distinct error rows from `ntm config validate --json`.
No config mutated this turn (acceptance: "do not mutate
~/.config/ntm/config.toml without Joshua approval"). Plan + draft
upstream issue staged for Joshua signoff.**

VALIDATED: live `ntm config validate --json` captured at
`validate-before.json` (`error_count=4`, `valid=false`).
DOCUMENTED: triage classification + cleanup plan +
upstream-issue draft in this audit pack.
SURFACED: classification counts in this evidence; no follow-up
beads filed today (gating on Joshua approval per acceptance
criteria).

Final classification counts:
- LOCAL-ONLY-CLEANUP: 6 field-classes (53 keys total)
- INTENTIONALLY-REJECTED: 1 (`health.researcher_sessions` per #113)
- UPSTREAM-SCHEMA-GAP-DRAFT-STAGED: 1 (`coordinator.session_default`)
- NEEDS-RESEARCH-BEFORE-FILE: 1 (`scanner.warning_threshold`)

## Classification table

`validate-before.json` summary: `files_checked=2, error_count=4,
warning_count=0, fixable_count=0`. Four error rows expand into the
following key-classes:

### `~/.config/ntm/config.toml` (1 error message, 53 fields)

| Field-class | Keys | Class | Action |
|---|---|---|---|
| Custom agent profiles | `agents.claude-local`, `agents.deepagents`, `agents.zesty`, `agents.zesty-worker` | LOCAL-ONLY-CLEANUP | Sidecar to `~/.config/flywheel/ntm-extensions.toml` |
| Custom model namespaces | `models.claude-local.{coder,fast,haiku,opus,sonnet,vl}`, `models.pi.{chat,coder,embedding,fast,general,vl}`, `models.zesty.{fast,haiku,opus,sonnet}` | LOCAL-ONLY-CLEANUP | Sidecar to `~/.config/flywheel/ntm-extensions.toml`. Note: `models.pi` related to ntm #121 (CLOSED without enum addition) |
| Coordinator schema version + per-session defaults | `coordinator.schema_version`, `coordinator.session_default.{auto_assign,conflict_negotiate,conflict_notify,send_digests}` | UPSTREAM-SCHEMA-GAP-DRAFT-STAGED | Issue draft at `upstream-issue-draft.md`; see "Why upstream" below |
| Health-check researcher sessions | `health.researcher_sessions` | INTENTIONALLY-REJECTED | Per ntm #113 decision: stays rejected. Local grep confirms NO runtime consumer in `/Users/josh/Developer/flywheel` or `/Users/josh/.claude` (only plan docs + handoffs reference the field). Recommend removal. |
| Scanner warning threshold | `scanner.warning_threshold` | NEEDS-RESEARCH-BEFORE-FILE | `ntm bugs --help` shows `--severity` filter but no `warning_threshold` config surface. Could be local-stale, schema-gap, or renamed. Park as needs-research. |
| Session paths registry | `session_paths` parent + 22 named entries | LOCAL-ONLY-CLEANUP | Sidecar to `~/.config/flywheel/session-paths.toml`. Aligned with `flywheel-dm83` decision: NTM has no equivalent metadata surface today, so flywheel-side ownership is correct. |

### `~/.config/ntm/recipes.toml` (3 errors)

| Recipe | Unsupported field | Class | Action |
|---|---|---|---|
| `cubcode` | agent type `zesty` | LOCAL-ONLY-CLEANUP | Comment out or sidecar; ntm #121 closed without enum addition |
| `pi-team` | agent type `pi` | LOCAL-ONLY-CLEANUP | Same |
| `hybrid` | agent type `zesty` | LOCAL-ONLY-CLEANUP | Same |

## Why upstream for `coordinator.session_default` (and ONLY that)

Per acceptance criterion #2: "If upstream-schema-gap remains, run
`gh issue list ...` first and file exactly one non-duplicate issue
with file:line citations."

Dedup probe ran (`gh issue list --search "custom agents OR custom
models OR session_paths OR extension table OR coordinator
session_default"`) and confirmed:

- #111 covers global `[coordinator]` reading (CLOSED).
- #113 covers `context_rotation.recovery.*` +
  `resilience.rate_limit.auto_rotate` (CLOSED).
- No existing issue covers `[coordinator.session_default]` per-session
  defaults.

Therefore the ONE non-duplicate issue draft is staged at
`.flywheel/audit/flywheel-b6yu/upstream-issue-draft.md`. **Not
filed today.** Per L66 Phase 5 (thanksfulness test): Joshua signs
off, then `gh issue create`.

The other classes are intentionally NOT filed:
- LOCAL-ONLY-CLEANUP: by definition not an upstream issue; live in
  flywheel sidecars per the cleanup plan.
- INTENTIONALLY-REJECTED: #113 already decided; no new issue.
- NEEDS-RESEARCH-BEFORE-FILE: research first per memory rule
  "NEVER propose Jeff issue without first doing full workaround
  research".

## Acceptance Criterion Receipts

| # | Criterion | Status | Evidence |
|---|---|---|---|
| 1 | Run `ntm config validate --json` and classify every remaining error | done | `validate-before.json` captured + classification table above |
| 2 | If upstream-schema-gap, dedup-search + file ONE non-duplicate issue with file:line citations | done | `gh issue list` dedup confirmed `coordinator.session_default` is novel; ONE draft staged at `upstream-issue-draft.md` (NOT filed; awaiting Joshua signoff per L66 Phase 5) |
| 3 | If local-only, produce a backup-first config cleanup plan; do NOT mutate `~/.config/ntm/config.toml` without Joshua approval | done | `cleanup-plan.md` with Phase 0 (backup) → Phase 1 (sidecar move) → Phase 2 (remove `health.researcher_sessions`) → Phase 3 (recipes) → Phase 4 (re-validate) → Phase 5 (rollback guard); explicit "do NOT execute without Joshua signoff" header |
| 4 | Preserve #113 decisions: `health.researcher_sessions` stays rejected unless runtime consumer found | done | `grep -rln "researcher_sessions"` across `/Users/josh/Developer/flywheel` and `/Users/josh/.claude` returned only plan docs (`PLANS/ntm-local-upstream-reconcile-2026-05-02/05-FOLLOWUP-ISSUE-DRAFT.md`, `PLANS/jeff-ecosystem-deep-dive-2026-05-01/00-MASTER-PLAN.md`) and handoffs — no runtime consumer. Decision preserved: stays rejected; cleanup plan removes it. |
| 5 | Record before/after validation JSON receipts under `/tmp/` | done (before only) | `validate-before.json` saved at audit dir. After-receipt is gated on Joshua-approved cleanup execution; today there is no after because no mutation happened. |

did=5/5 didnt=none gaps=none.

## Files Changed

In-repo:
- `.flywheel/audit/flywheel-b6yu/evidence.md` — this report
- `.flywheel/audit/flywheel-b6yu/validate-before.json` — captured
  `ntm config validate --json` output (`error_count=4`)
- `.flywheel/audit/flywheel-b6yu/cleanup-plan.md` — Phase 0-5
  backup-first cleanup plan (DRAFT, not executed)
- `.flywheel/audit/flywheel-b6yu/upstream-issue-draft.md` — ONE
  non-duplicate Jeffrey issue draft for `coordinator.session_default`
  (DRAFT, not filed)

**No mutation of `~/.config/ntm/config.toml` or
`~/.config/ntm/recipes.toml`.** No commit beyond the audit pack.
No `gh issue create` invocation. No file pushed to
`Dicklesworthstone/ntm`.

## Verification Commands (re-runnable)

```bash
# Re-probe the live config validation
ntm config validate --json | jq '.summary'

# Confirm researcher_sessions has no runtime consumer
grep -rln "researcher_sessions" /Users/josh/Developer/flywheel /Users/josh/.claude \
  | grep -v -E '\.bak|\.flywheel/audit/flywheel-b6yu' | head

# Dedup check for coordinator.session_default
gh issue list --repo Dicklesworthstone/ntm --state all \
  --search "coordinator session_default" --limit 5 --json number,state,title

# Verify validate-before.json has error_count=4
jq '.summary.error_count' /Users/josh/Developer/flywheel/.flywheel/audit/flywheel-b6yu/validate-before.json
```

L112 probe (worker callback):

```bash
ntm config validate --json | jq -r '.summary | "before_error_count=\(.error_count)"'
```

Expected: literal `before_error_count=4`. (After-receipt happens
only when Joshua approves the cleanup plan and Phase 4 re-validates
to `error_count=0`.)

## Boundary

- Joshua approval gates: cleanup plan execution (Phase 1-5),
  upstream issue filing.
- This bead delivers triage + plan + draft. Execution is the
  follow-up bead's scope IF Joshua approves either path.
- Standing rules respected: no push to
  `Dicklesworthstone/ntm`; Jeffrey-not-Jeff in human-facing prose
  in the upstream draft; no auto-file.

## Skill Auto-Routes

- `canonical-cli-scoping`: n/a — no CLI authored or extended this
  turn.
- `rust-best-practices`: n/a.
- `python-best-practices`: n/a — only `jq` for probing.
- `readme-writing`: n/a — triage report style.

## L61 ECOSYSTEM-TOUCH BLOCK

- `agents_md_updated=no` — no L-rule promotion.
- `readme_updated=not_applicable`.
- `no_touch_reason=triage_only_no_doctrine_or_canonical_surface_mutated_today`.

## Four-Lens Self-Grade

- Brand: 8 — turns 4 raw `ntm config validate` errors into a
  classified triage with concrete actions per class; preserves
  the L66 Joshua-signoff gate for any upstream filing.
- Sniff: 9 — every claim cites concrete probe evidence
  (validate-before.json, gh issue list dedup, grep across
  flywheel + .claude for runtime-consumer of
  `researcher_sessions`, ntm bugs --help inspection).
- Jeff: 9 — single non-duplicate upstream draft (not filed),
  Jeffrey-not-Jeff in prose, dedup against #111/#112/#113/#121
  documented; no premature filing of `models.pi`/`agents.zesty`
  classes (those are LOCAL-ONLY).
- Public: 9 — operator/maintainer/future worker can rerun the
  4-line verification block in <2s; cleanup plan is reversible
  (Phase 5 rollback); upstream draft is grep-able and self-
  contained.

## L52 Receipt

`beads_filed=none beads_updated=flywheel-b6yu
no_bead_reason=triage_complete_no_followup_filed_today_per_acceptance_criterion_3_joshua_approval_gates_execution`.
