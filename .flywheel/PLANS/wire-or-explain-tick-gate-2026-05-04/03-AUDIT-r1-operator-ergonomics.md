---
title: "Phase 3 Audit R1 - Operator Ergonomics"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 3 Audit R1 - Operator Ergonomics

Plan: `wire-or-explain-tick-gate-2026-05-04`
Lens: operator ergonomics
Mode: plan-space, read-only
Date: 2026-05-04

## Scope

This audit asks whether the r2 wire-or-explain plan will be usable under live
orchestrator pressure.

It does not relitigate ledger authority, bootstrap recursion, idempotency,
atomicity, or security. Those are covered by the existing Phase 3 audit lenses:

- `03-AUDIT-r1-cross-cutting.md`
- `03-AUDIT-r1-idempotency.md`
- `03-AUDIT-r1-bootstrap-recursion.md`
- `03-AUDIT-r1-security.md`

This lens focuses on B5 doctor field naming, B11 `/flywheel:wire-status`, B6
tick-close gate failure text, B7 override UX, B8 backfill progress, B10 doctrine
drift workflow, B12 rollout/onboarding, B15 memory visibility, FM4 bottleneck
escape hatch, and onboarding curve.

Donella frame: Meadows #6, information flows. The useful intervention is not a
reminder; it is a surface that gives the operator, tick handler, and fleet
doctor the same state, owner, reason, and next command.

Socraticode preflight: 5 queries, 50 indexed chunks observed.

## Sources Read

- `02-REFINE-r2.md:307-320` - B5 doctor fields.
- `02-REFINE-r2.md:322-331` - B6 tick-close gate.
- `02-REFINE-r2.md:333-341` - B7 shadow/enforce/override.
- `02-REFINE-r2.md:343-351` - B8 dogfood import.
- `02-REFINE-r2.md:365-373` - B10 L109 doctrine.
- `02-REFINE-r2.md:375-384` - B11 wire-status.
- `02-REFINE-r2.md:386-395` - B12 cross-orch rollout.
- `02-REFINE-r2.md:417-425` - B15 memory and learn promotion.
- `02-REFINE-r2.md:427-455` - CLI surface contract.
- `02-REFINE-r2.md:464-478` - rollout state machine and flip criteria.
- `02-REFINE-r2.md:486-499` - open Phase 3 questions.
- `~/.claude/commands/flywheel/status.md:112-114` - Hidden gates line.
- `~/.claude/commands/flywheel/status.md:199-212` - Gate and suggested commands.
- `~/.claude/commands/flywheel/tick.md:17-23` - current tick args.
- `~/.claude/commands/flywheel/tick.md:794-880` - current tick receipt.
- `~/.claude/commands/flywheel/plan.md:165-202` - TRUE blocker classes.
- `~/.claude/commands/flywheel/plan.md:213-224` - severity mapping.
- `~/.claude/skills/canonical-cli-scoping/SKILL.md:16-33` - required commands.
- `~/.claude/skills/canonical-cli-scoping/SKILL.md:177-187` - output/schema flags.
- `~/.claude/skills/canonical-cli-scoping/SKILL.md:199-224` - mutation discipline.
- `~/.claude/skills/canonical-cli-scoping/SKILL.md:226-239` - progress events.

## Operator Surface Inventory

Surface 1: B5 `flywheel-loop doctor --json` `.wire_or_explain`

Primary users: tick handler, `/flywheel:status`, fleet rollups, recovery
dispatches. Grade: B-. Strong count/top-row plan, but not yet action-rich.

Surface 2: B11 `/flywheel:wire-status`

Primary users: active orchestrator, human operator, fleet dispatcher. Grade: A-.
The surface is compact, read-only, and action-oriented; the risk is drifting
from B5 instead of rendering the same action objects.

Surface 3: B6 tick-close failure

Primary users: orch-of-orch tick handler, local orchestrator, closeout path.
Grade: C+. Durable failure is specified; deterministic human-readable refusal
text is not yet specified.

Surface 4: B7 override/defer UX

Primary users: emergency closeout, false-positive handling, warn-to-enforce
transition. Grade: C. Policy exists; command shape does not.

Surface 5: B8 dogfood/backfill importer

Primary users: migration worker, verifier, future recovery worker. Grade: B-.
Dry-run and idempotency are strong; progress, resume, and final import summary
are not explicit.

Surface 6: B10 doctrine drift workflow

Primary users: doctrine worker, fleet installer, L-rule reviewer. Grade: B-.
The three surfaces are named, but the operator needs one canonical check/repair
path, not "or equivalent".

Surface 7: B12 rollout/onboarding

Primary users: fleet orchestrator, repo orchestrator, new repo worker. Grade: B.
Ownership and states are clear; install/onboard quickstart is implicit.

Surface 8: B15 memory/learn promotion

Primary users: `/flywheel:learn`, status dashboard, future doctrine workers.
Grade: C+. Write path exists; dashboard read path is too faint.

Surface 9: `/flywheel:status`

Primary users: Joshua, orchestrator, worker deciding whether to wait or act.
Grade: C+. The command is the first operator surface, but wire-or-explain would
currently appear only as a generic hidden-gate failure unless Phase 5 amends it.

Surface 10: `/flywheel:tick`

Primary users: orch-of-orch, per-repo orchestrator, closeout loop. Grade: C+.
Current docs expose only plain, `--dry-run`, and `--help`; future gate explain,
close-hook-only, and override flows need explicit operator affordances.

Surface 11: `.flywheel/scripts/wire-or-explain-gate.sh`

Primary users: implementer, tests, debug operator. Grade: B+. The helper CLI
has a good base, but canonical CLI scoping also expects `quickstart`, topic
help, completion, `--no-color`, `--no-emoji`, `--width`, and schemas.

## Findings Table

| ID | Severity | Beads affected | Description | Phase 5 polish ask |
|---|---|---|---|---|
| ERG-F1 | high | B5,B11,status | `/flywheel:status` can hide wire-or-explain behind a generic Hidden gates line. | Add a first-class Wire/Explain dashboard row and one suggested next command. |
| ERG-F2 | high | B6,B11 | Tick-close failure proves durability but not operator comprehension. | Require a deterministic failure message with row id, reason, owner, mode, and safe commands. |
| ERG-F3 | high | B7,tick | Override policy exists without a documented operator command shape. | Add override/defer dry-run/apply CLI with reason, expiry, audit id, and idempotency key. |
| ERG-F4 | medium | B8 | Dogfood import lacks progress and resume output requirements. | Require NDJSON events, resume token, final counts, and zero-duplicate rerun proof. |
| ERG-F5 | medium | B10 | Doctrine drift has a check but no single operator repair path. | Bind B10 to the existing canonical doctrine sync/check/repair path. |
| ERG-F6 | medium | B12 | Fleet rollout names states but not the repo install/onboard quickstart. | Add install dry-run/apply and rollout doctor commands. |
| ERG-F7 | medium | B15,status | Memory promotion is write-specified but not dashboard-visible. | Surface latest promoted memory/doctrine candidate in status learning signals. |
| ERG-F8 | medium | B5 | Doctor field names mix long artifact prefixes and shorter deferred prefixes. | Normalize under `.wire_or_explain.summary`, `.rows`, `.actions`, `.rollout`. |
| ERG-F9 | low | CLI contract | Helper CLI is close to canonical but lacks self-doc/capture affordances. | Add quickstart, topic help, completion, and capture flags. |

Findings total: 9

Findings by severity: critical 0, high 3, medium 5, low 1

## Per-Surface Ergonomics Review

### B5 Doctor Fields

Evidence: B5 exposes `.wire_or_explain`, counts, top rows, freshness, and
producer/measurement/consumer/promotion metadata at `02-REFINE-r2.md:311-320`.

Good: the doctor becomes the right upstream data source for status, fleet
rollups, and automation.

Risk: counts are not enough. The cross-cutting audit already asks for
machine-readable actions at `03-AUDIT-r1-cross-cutting.md:301-333`; this lens
adds that those actions must be the primary operator affordance, not an
afterthought.

Polish: add `wire_or_explain.actions[]` with `ship_event_id`,
`recommended_action`, `resolve_command`, `dry_run_command`, `owner_hint`,
`blocking_scope`, and `expires_at`.

### B11 `/flywheel:wire-status`

Evidence: B11 requires <=50 lines, mode, counts, top three actions, `--json`,
read-only behavior, and exact resolve/defer commands at `02-REFINE-r2.md:379-384`.

Good: this is the strongest operator surface in r2.

Risk: if B11 builds command text independently from B5, doctor JSON and status
can disagree.

Polish: B11 renders B5 `actions[]` objects directly. `wire-status --json` and
doctor JSON must agree on row ids and action count.

### B6 Tick-Close Failure

Evidence: B6 writes a durable failed tick receipt when enforce mode blocks at
`02-REFINE-r2.md:326-331`.

Good: failed closeout is durable.

Risk: durability does not equal comprehension. The terminal refusal must be as
mechanical as the receipt.

Polish: require this template:

```text
WIRE_OR_EXPLAIN_BLOCKED mode=<mode> repo=<repo> tick_id=<id>
row=<ship_event_id> class=<artifact_class> owner=<owning_orch>
reason=<reason_code> next=<resolve_command> defer=<defer_command>
why=<why_command> receipt=<failed_receipt_path>
```

### B7 Override UX

Evidence: B7 rejects empty reasons and expired overrides at
`02-REFINE-r2.md:337-341`, while current `/flywheel:tick` documents only plain,
`--dry-run`, and `--help` at `~/.claude/commands/flywheel/tick.md:17-23`.

Good: the policy rejects the obvious bad bypasses.

Risk: without a documented command, override becomes either environment-variable
folklore or ledger hand-editing.

Polish: define:

```bash
.flywheel/scripts/wire-or-explain-gate.sh override --repo "$REPO" \
  --row <ship_event_id> --reason "<reason>" --expires-in 30m \
  --dry-run --json
.flywheel/scripts/wire-or-explain-gate.sh override --repo "$REPO" \
  --row <ship_event_id> --reason "<reason>" --expires-in 30m \
  --apply --idempotency-key <key> --json
```

### B8 Dogfood Import

Evidence: B8 requires dry-run exact rows, idempotent apply, zero duplicates on
rerun, D2 baseline, and ranked known unresolved rows at `02-REFINE-r2.md:347-351`.

Good: the import is already bounded and idempotent.

Risk: a historical backfill can look hung or ambiguous without progress events.
Canonical CLI scoping requires long-running commands to emit `started`,
`progress`, `warning`, `blocked`, `completed`, and `failed` events at
`~/.claude/skills/canonical-cli-scoping/SKILL.md:226-239`.

Polish: B8 emits NDJSON progress, a resume token, and final planned/written/
duplicate/unresolved counts.

### B10 Doctrine Drift

Evidence: B10 says three surfaces must be updated and
`sync-canonical-doctrine.sh --check or equivalent` must pass at
`02-REFINE-r2.md:369-373`.

Good: the three surfaces are explicit.

Risk: "or equivalent" is an operator fork. The cross-cutting audit already
requires reusing the existing path at `03-AUDIT-r1-cross-cutting.md:349-373`.

Polish: expose exactly:

```bash
.flywheel/scripts/sync-canonical-doctrine.sh --check --json
.flywheel/scripts/sync-canonical-doctrine.sh --repair --dry-run --json
.flywheel/scripts/sync-canonical-doctrine.sh --repair --apply --idempotency-key <key> --json
```

### B12 Rollout and Onboarding

Evidence: B12 requires fleet config, `ship_repo`, `ship_actor`, repo-owned
blocking, cross-repo pending visibility, and fleet smoke fixtures at
`02-REFINE-r2.md:390-395`. r2 state machine is off/shadow/warn/enforce/rollback
at `02-REFINE-r2.md:464-470`.

Good: repo ownership and fleet scope are visible.

Risk: new repo onboarding has no one-screen command path.

Polish: add install dry-run/apply and rollout doctor commands:

```bash
.flywheel/scripts/wire-or-explain-gate.sh install --repo "$REPO" --dry-run --json
.flywheel/scripts/wire-or-explain-gate.sh install --repo "$REPO" --apply --idempotency-key <key> --json
.flywheel/scripts/wire-or-explain-gate.sh doctor --repo "$REPO" --scope rollout --json
```

### B15 Memory Visibility

Evidence: B15 requires memory file, fuckup row processing, learn promotion, and
branch/reset callback contract at `02-REFINE-r2.md:421-425`. Current status
learning signals show top unprocessed classes and promotion readiness at
`~/.claude/commands/flywheel/status.md:118-123`.

Good: the write path is clear.

Risk: no clear read path says "promotion already landed and is active."

Polish: status learning signals distinguish `promotion_ready` from
`promoted_recent`, with memory path and evidence refs.

## Confusing Error Message Audit

FM1 timeout:

```text
WIRE_OR_EXPLAIN_SCAN_TIMEOUT repo=<repo> elapsed_ms=<N> partial_rows=<N>
next="<health command>"
```

FM2 false positive:

```text
WIRE_OR_EXPLAIN_FALSE_POSITIVE_CANDIDATE row=<id> artifact=<path>
reason=<reason_code> next="<why command>" resolve="<evidence dry-run command>"
```

FM3 missed collector:

```text
WIRE_OR_EXPLAIN_COLLECTOR_MISSED since=<sha> unclassified=<N>
next="<backfill dry-run command>"
```

FM4 bottleneck escape hatch:

```text
WIRE_OR_EXPLAIN_LATENCY_BOTTLENECK p95_ms=<N> threshold_ms=5000
mode=<mode> next="<rollback-to-warn dry-run command>"
```

Rationale: r2 requires `wire_or_explain_gate_p95_latency_ms < 5000` before flip
at `02-REFINE-r2.md:474-478`. The escape hatch is rollback/warn while retaining
row collection, not disabling measurement.

FM5 bootstrap recursion:

```text
WIRE_OR_EXPLAIN_BOOTSTRAP_PENDING seed=<id> consumer=<static_registry|D2_sync>
next="<bootstrap self-test command>"
```

Rationale: bootstrap seed must remain distinct from normal override, matching
the bootstrap audit split at `03-AUDIT-r1-bootstrap-recursion.md:143-172`.

FM6 cross-repo pending:

```text
WIRE_OR_EXPLAIN_CROSS_REPO_PENDING row=<id> owner=<repo/orch>
blocking_scope=<repo|fleet|none_until_expiry> expires_at=<ts>
next="<owner wire-status command>"
```

Rationale: B12 says cross-repo pending rows surface fleet-wide but do not halt
unrelated repos before expiry at `02-REFINE-r2.md:392-394`.

FM7 stale consumer:

```text
WIRE_OR_EXPLAIN_STALE_CONSUMER row=<id> old_consumer=<path> last_seen=<ts>
next="<repair dry-run command>"
```

Expired override:

```text
WIRE_OR_EXPLAIN_OVERRIDE_EXPIRED row=<id> expired_at=<ts>
reason=<stored_reason> next="<renew/defer dry-run command>"
```

DCG orphan reset:

B14 is already strong: block message names the orphan commit and recovery
commands at `02-REFINE-r2.md:411-415`. Reuse the B6 refusal pattern so DCG and
tick-close blocks feel like one system.

## TRUE-Blocker Class Evaluation

Source: `/flywheel:plan` allows only six legitimate pauses at
`~/.claude/commands/flywheel/plan.md:165-202`. Audit findings that are not TRUE
blockers become Phase 4/5 work by severity mapping at
`~/.claude/commands/flywheel/plan.md:213-224`.

1. `new-platform-or-vendor-not-in-mission-lock`: not triggered.
   No new platform, vendor, deploy target, or external service is proposed.

2. `secret-rotation-or-new-credential-creation`: not triggered.
   No credential is created or rotated. Override UX is redaction-safe command
   design only.

3. `financial-commitment-above-mission-budget`: not triggered.
   No paid resource or budget change is proposed.

4. `legal-or-compliance-decision`: not triggered.
   No ToS, DPA, legal term, or compliance decision is introduced.

5. `destructive-irreversible-on-shared-state`: not triggered.
   This audit is read-only. Future apply commands must carry dry-run,
   idempotency key, and audit id before mutation.

6. `paradigm-conflict-with-active-mission`: not triggered.
   The audit reinforces the active paradigm: wire artifacts or explain why
   they are not wired before closing ticks.

TRUE blocker conclusion: none.

## Composite Score

Composite operator-ergonomics score: 7.1 / 10

Why:

- Strong: ledger, doctor, wire-status, close-hook, and rollout states are
  coherent.
- Strong: r2 CLI base already covers inspect, validate, rank, audit, why,
  repair, and close-hook.
- Weak: first-contact surfaces are incomplete. `/flywheel:status`, tick failure
  text, and override/defer commands need to be as mechanical as the ledger.
- Residual risk: a live operator can still see "blocked" before seeing "run this
  exact command."

Severity posture:

- Critical: 0
- High: 3
- Medium: 5
- Low: 1

Predicted convergence if Phase 5 accepts the top five polish asks: 8.4 / 10.

## Top 5 Ergonomic Improvements for Phase 5 Polish

1. Add first-class Wire/Explain line to `/flywheel:status`.

Acceptance: mode, unresolved, overdue, p95, top row, top action, and
`/flywheel:wire-status --repo <repo>` suggested command when unresolved > 0.

2. Standardize B6 failure text from doctor action objects.

Acceptance: row id, reason, owner, mode, blocking scope, receipt path, and exact
safe commands appear in terminal output, failed receipt, doctor JSON, and
wire-status JSON.

3. Define override/defer CLI before implementation.

Acceptance: dry-run/apply split, required reason, bounded expiry, idempotency
key, audit id, `why` trace, and cross-repo scope check.

4. Make B8 dogfood import observable and resumable.

Acceptance: NDJSON events, resume token, final planned/written/duplicate/
unresolved counts, and rerun writes zero duplicates.

5. Add onboarding quickstart and canonical self-doc.

Acceptance: `quickstart` covers inspect, fix/defer, and close-tick workflows;
`help override` documents safe bypass; completion exists; install dry-run
reports planned files, mode, ledger path, owner, and next rollout state.

## Phase 5 Amendment Map

| Bead | Operator amendment |
|---|---|
| B5 | Normalize `.wire_or_explain` schema and add `actions[]`. |
| B6 | Assert deterministic failure message and failed receipt parity. |
| B7 | Add explicit override/defer command contract. |
| B8 | Add progress, resume, and final import summary. |
| B10 | Use one canonical doctrine check/repair path. |
| B11 | Render B5 action objects; do not synthesize separate action text. |
| B12 | Add install/onboard quickstart and rollout doctor command. |
| B15 | Add visible "promotion landed" status read path. |

## Final Verdict

No TRUE blocker class fires.

Disposition: auto-advance with Phase 5 ergonomic amendments.

The plan is strong enough to proceed, but the operator surface is load-bearing.
The close gate will run before every orchestrator every tick. If the operator
cannot tell what blocked, why, who owns it, and which safe command comes next,
the gate will be bypassed in practice.
