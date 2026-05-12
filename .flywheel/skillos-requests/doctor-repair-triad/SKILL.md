---
name: doctor-repair-triad
description: "Use when 'doctor command', 'health command', 'repair command', 'doctor --json', 'health --json', 'repair --dry-run', 'repair --apply', 'repair refusal', 'CLI self-heal', 'diagnostic surface', 'structured health', 'repair receipt', 'failure classifier', 'L60 producer', 'promotion table', 'operator recovery', 'safe mutation', or 'reversible repair'."
license: MIT
distribution: forbidden
version: 0.1.0
status: skillos-request
---

# Doctor Repair Triad

## Status

Draft for skillos review. This file is a flywheel-local request artifact for
bead `flywheel-pgf8`; it is not installed as a live skill and is not published
to JSM.

## Hard Rules

1. Every operational substrate with recurring failure modes exposes a read-only
   `doctor --json` surface before any repair command exists.
2. Doctor output has a stable `schema_version`, `status`, `checks[]`,
   `failure_class`, `severity`, `evidence`, `recommended_action`, and
   `owner_hint`.
3. Health output is a compact summary, not a second doctor: it reports
   `status`, top counters, freshness, and whether repair is currently safe.
4. Repair is split into preview and mutation: `repair --dry-run --json` must
   produce the exact plan before `repair --apply --json` can mutate state.
5. Repair refuses when the source of truth is corrupt, when rollback cannot be
   proven, or when a previous failed repair left evidence that has not been
   acknowledged.
6. Repair receipts are append-only evidence with `schema_version`,
   `idempotency_key`, `dry_run_plan_hash`, `actions[]`, `result`, and
   `rollback_available`.
7. Exit codes are stable: `0` healthy or repaired, `1` unhealthy but
   classifiable, `2` unsafe-to-repair/refused, `3` invalid invocation, `4`
   substrate unavailable.
8. The triad includes validate/audit/why siblings when the surface will be used
   by agents: validation proves shape, audit checks history, and why explains a
   classification.
9. L60-style routing is declared in the same artifact: producer, measurement,
   consumer, promotion trigger, and repair owner.
10. Secret-shaped or credential-shaped values never appear in doctor, health,
    repair plans, or receipts; emit references and redacted classes instead.

## THE EXACT PROMPT

```text
Create or revise a skill named doctor-repair-triad for <surface>. Define the
doctor signal shape, health summary shape, repair --dry-run/--apply separation,
stable exit codes, refusal classes, append-only repair receipt, and L60
producer/measurement/consumer/promotion table. Include a self-test that verifies
SKILL.md structure and rejects drafts missing doctor --json, health --json,
repair --dry-run, repair --apply, refusal behavior, stable schema_version, and
anti-pattern coverage. Cite Jeff corpus evidence and preserve flywheel
DID/DIDNT/GAPS callback contracts when the triad feeds worker receipts. Do not
mutate live skills or run jsm push until Joshua approves publication.
```

## Decision Tree

| Situation | Required triad posture |
|---|---|
| New operational CLI or script | Add `doctor --json`, `health --json`, and `repair --dry-run` before mutation support |
| Existing checker emits findings | Add repair owner, promotion trigger, and L60 table before calling it complete |
| Repair would rewrite source evidence | Refuse and emit `unsafe_source_of_truth` |
| Repair reaches a network or credential boundary | Do not call it repair; emit owner route and manual action |
| Health is noisy or verbose | Move detail to doctor; health stays summary-only |
| Agents consume the output | Add JSON schema, stable exit codes, and replay fixtures |

## Doctor Signal Shape

Minimum JSON:

```json
{
  "schema_version": "doctor-repair-triad/doctor/v1",
  "status": "pass|warn|fail",
  "surface": "example-substrate",
  "checks": [
    {
      "id": "source_truth_parse",
      "status": "pass|warn|fail",
      "failure_class": null,
      "severity": "none|low|medium|high|critical",
      "evidence": ["path:line-or-command"],
      "recommended_action": "none|repair_dry_run|owner_route",
      "owner_hint": "flywheel|skillos|human|unknown"
    }
  ],
  "repair_safe": true,
  "why": "short operator-facing explanation"
}
```

## Health Summary Shape

Health is the fast summary surface:

```json
{
  "schema_version": "doctor-repair-triad/health/v1",
  "status": "healthy|degraded|unhealthy|unknown",
  "surface": "example-substrate",
  "freshness_seconds": 12,
  "failing_checks_count": 0,
  "repair_available": true,
  "repair_safe": true
}
```

## Repair Contract

Dry-run output:

```json
{
  "schema_version": "doctor-repair-triad/repair-plan/v1",
  "mode": "dry-run",
  "surface": "example-substrate",
  "idempotency_key": "operator-supplied-or-generated",
  "actions": [{"id": "rebuild_index", "mutates": [".beads/beads.db"]}],
  "rollback_plan": {"available": true, "evidence": ["backup-path"]},
  "plan_hash": "sha256:..."
}
```

Apply output must include the dry-run plan hash it executed:

```json
{
  "schema_version": "doctor-repair-triad/repair-receipt/v1",
  "mode": "apply",
  "surface": "example-substrate",
  "idempotency_key": "same-key",
  "dry_run_plan_hash": "sha256:...",
  "result": "applied|refused|noop|failed",
  "rollback_available": true,
  "audit_row": "path/to/append-only.jsonl#L42"
}
```

## L60 Producer Table

| Field | Meaning |
|---|---|
| `producer` | Script, CLI, command, or hook emitting the doctor signal |
| `measurement` | Stable counter or status field doctor exposes |
| `consumer` | Tick, close gate, skillos route, or owner that acts on the signal |
| `promotion_trigger` | Threshold that turns repeated findings into a bead, incident, or skill |
| `repair_owner` | Actor allowed to run apply mode |
| `receipt` | Append-only row or artifact proving the repair or refusal happened |

## Source Evidence

- `.flywheel/jeff-corpus/v1/learnings/06-skill-enhancement-matrix.md:39-44`
  names `doctor-repair-triad` as a new sibling skill candidate and states the
  missing home: observer/classifier/dry-run/apply repair contract.
- `.flywheel/jeff-corpus/v1/learnings/01-doctrine-cluster.md:43-60`
  defines the doctor/health/repair cluster as operational tools exposing state
  inspection, structured health, and dry-run/apply repair paths.
- `.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:24-49` says to extend
  the triad as a flywheel design invariant and import doctor signal templates
  with `check`, `why`, and `repair --dry-run` siblings.
- `.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:195-203` deduplicates
  the pattern: doctor observes, repair dry-runs/applies, migrations are repair
  subclasses.

## Flywheel Adaptation Notes

- Flywheel worker callbacks keep `DID/DIDNT/GAPS`; triad receipts are evidence,
  not a replacement callback envelope.
- Repair output must be JSON-only and secret-safe because panes, callbacks, and
  `ntm grep` make command output durable substrate.
- The triad is a skillos-owned sibling skill because many skills mention the
  words doctor, health, and repair, but no live skill owns the full reusable
  contract.
- JSM publication is staged only: validate first, then Joshua decides whether
  skillos runs `jsm push`.

## Executable Self-Test

Run:

```bash
bash scripts/self_test.sh .
```

Expected pass output:

```json
{"checks":12,"status":"pass"}
```

## Publication Staging

After skillos review and Joshua approval:

```bash
jsm validate /path/to/doctor-repair-triad --json --offline
jsm push /path/to/doctor-repair-triad
```

No `jsm push` is authorized by this draft.

## Anti-Patterns

| Anti-pattern | Why it fails | Required replacement |
|---|---|---|
| Doctor that mutates state | Operators cannot inspect safely and agents cannot run diagnostics before repair | Keep doctor read-only and put mutation behind repair apply |
| Health duplicates full doctor output | Health becomes slow/noisy and stops working as a quick readiness signal | Health summarizes counters and points to doctor for detail |
| Repair without dry-run | Mutation plan cannot be reviewed, hashed, or replayed | Require `repair --dry-run --json` before `repair --apply --json` |
| Repair rewrites evidence | The original failure disappears and later debugging loses chronology | Append correction rows and preserve failed-repair artifacts |
| Generic failure string | Orchestrators cannot route ownership or decide whether repair is safe | Emit stable `failure_class`, `severity`, and `owner_hint` |
| Success-only repair receipts | Refusals and no-ops vanish from the learning substrate | Receipt includes `applied`, `refused`, `noop`, and `failed` outcomes |
| Env-enabled mutation gates | Ambient pane state can silently make repair live | `--apply`, `--force`, credentials, and idempotency keys are command-only |
| Callback replacement | New receipt breaks flywheel close gates and dispatch validators | Attach triad receipt as evidence while preserving DID/DIDNT/GAPS |
