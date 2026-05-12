---
contract: jeff-doctor-repair-contract
status: locked
source_bead: flywheel-hn8e
parent_synthesis: flywheel-avlj
phase4_verdict: EXTEND
jeff_patterns: [P01]
doctrine_refs: [L60, L71, L82]
related_skills: [system-health, canonical-cli-scoping, flywheel-doctor-author, agent-mail, cass]
created: 2026-05-06
---

# Jeff Doctor / Health / Repair Triad Contract

Codifies the operator triad that recurs across Jeff Emanuel's repos
(`mcp_agent_mail`, `flywheel_connectors`, `coding_agent_session_search`,
`meta_skill`) for any new operational substrate that other panes rely on.

This contract is load-bearing for any new `.flywheel/scripts/*-doctor.sh`,
`*-health*.sh`, or any CLI/script that exposes a probe consumed by another
agent (orch, watcher, peer worker).

## When to apply

ALWAYS apply when a new substrate:

- Is consulted by another pane to gate dispatch, claim readiness, or trigger
  recovery.
- Mutates shared state under any condition (then `repair` posture is
  required).
- Surfaces in a tick (`/flywheel:tick`), watchdog, or fleet-doctor probe.
- Replaces an existing one-off script that someone "just runs by hand".

DO NOT apply when:

- The script is a single-shot ad-hoc debugging command (no peer consumers).
- The substrate is purely a writer with no readiness semantics
  (e.g. `agents-md-fleet-propagator` — writer, governed by the lineage
  contract instead).
- An upstream Jeff binary already exposes the triad; flywheel uses its
  surface (`am doctor`, `cass health --json`, etc.) — wrap, do not
  re-implement.

## Pattern (Jeff source)

| Surface | Jeff source | ZestStream adaptation |
|---|---|---|
| `doctor --json` | `mcp_agent_mail/README.md:721,726` | `<script>.sh --doctor --json` (or subcommand `doctor`); ANSI-free, deterministic shape |
| `doctor repair --dry-run` | `mcp_agent_mail/README.md:793` | `<script>.sh repair --dry-run --json` MUST exist before any `repair --apply` |
| Multi-action repair | `flywheel_connectors/AGENTS.md:17` (`am doctor fix`, `am doctor repair`, `am doctor reconstruct`) | repair surfaces enumerate `--scope` rather than overload single repair |
| `health --json` truth | `coding_agent_session_search/README.md:55,86,90` | `<script>.sh --health --json` is the readiness oracle; cached scrollback is not |
| Conformance test of doctor | `meta_skill/tests/e2e/doctor_workflow.rs:179` | `tests/test-<surface>-doctor.sh` exists and runs in flywheel test pass |

## Required surface contract

Every operational substrate MUST expose the triad below. Subcommand vs flag
form is each surface's choice; behavior is invariant.

### 1. `doctor --json` (read-only, MANDATORY)

```json
{
  "schema_version": "<surface>-doctor/v1",
  "status": "pass|warn|fail",
  "checks": [
    {"name": "<id>", "result": "pass|warn|fail", "detail": "<machine string>"},
    ...
  ],
  "counters": {"<metric>": <number>, ...},
  "errors": [...],
  "warnings": [...]
}
```

- Exits 0 on `pass` or `warn`, non-zero on `fail` (so launchd / cron can
  alarm).
- ANSI-free; no terminal color codes.
- Counters MUST line up with `checks` (one counter per quantitative check).

### 2. `health --json` or `status --json` (read-only, MANDATORY)

- A subset of `doctor` — cheap enough to call from a tick loop without I/O
  cost concern.
- MUST be safe to call concurrently (no shared lock acquisition).

### 3. `repair --dry-run [--json]` (CONDITIONAL)

- Required if and only if the substrate has any path that mutates state.
- `--dry-run` MUST be the default; explicit `--apply` toggles mutation.
- `--apply` mutating paths MUST satisfy `jeff-lineage-safety-contract`
  (backup + lock + audit + rollback receipt).
- Output schema:

```json
{
  "schema_version": "<surface>-repair/v1",
  "mode": "dry-run|apply",
  "actions": [
    {"name": "<id>", "would_run": "<cmd or change>", "destructive": true|false},
    ...
  ],
  "applied": [...],
  "skipped": [...],
  "backup_receipt": "<path|null>"
}
```

### 4. Promotion route for repeat fail

A fail-then-fail-again MUST surface a bead via `br create` (see
`beads-workflow`), not just print red text. The promotion MUST cite the
doctor `schema_version` and the failing check name.

## Existing flywheel surfaces this contract covers

These already partially comply and are the audit set for proving the
contract:

- `.flywheel/scripts/jeff-corpus-doctor.sh` — exposes `--doctor --json`,
  emits `jeff-corpus-doctor/v1`.  Gap: no explicit `repair` subcommand.
- `.flywheel/scripts/agent-mail-fd-doctor.sh` — wraps `am doctor`.
- `.flywheel/scripts/ntm-fleet-health.sh` — health surface; needs explicit
  `--json` schema pin.
- `.flywheel/scripts/mission-lock-readiness-doctor.sh` — covered by
  `tests/test_mission_lock_readiness_doctor.sh`.
- `.flywheel/scripts/watcher-isomorphic-probe.sh` — already exposes
  `--doctor --json`, `repair --dry-run --json` (line 651). Reference impl.
- `.flywheel/scripts/peer-orch-respawn-permit.sh` — exposes
  `repair --scope ledger|substrate-contract|all [--dry-run|--apply] [--json]`.
  Reference impl for multi-scope repair.
- `.flywheel/scripts/vc-observability-probe.sh` — `--doctor --json` (line 594).
- `.flywheel/scripts/recovery-doctor-probe.sh`
- `.flywheel/scripts/fleet-mail-vault-doctor.sh`
- `.flywheel/scripts/test-loop-driver-doctor.sh`

## Compliance probe (the meta-doctor)

A meta-doctor probe MUST exist and emit:

```json
{
  "schema_version": "doctor-repair-contract-doctor/v1",
  "status": "pass|warn|fail",
  "substrates_audited": <int>,
  "missing_doctor_json": [...],
  "missing_health_subset": [...],
  "mutating_without_dry_run": [...],
  "mutating_without_backup_receipt": [...],
  "ansi_in_json_output": [...],
  "no_promotion_route_for_repeat_fail": [...]
}
```

`fail` blocks promotion of new operational scripts onto the launchd plist
or tick loop until the substrate complies.

## PASS / WARN / FAIL examples

- PASS: `watcher-isomorphic-probe.sh --doctor --json` returns a v1-pinned
  envelope; `repair --dry-run --json` enumerates actions; tests under
  `.flywheel/tests/` cover both.
- WARN: `jeff-corpus-doctor.sh` exposes `--doctor --json` but no explicit
  `repair --dry-run` path. Contract: surface is read-only-by-nature
  (manifest read), so repair is N/A — record an explicit `no_repair_reason`
  in the doctor output.
- FAIL: a new `*-watchdog.sh` exposes only stdout text and no `--json`.
  Contract refuses the substrate's wiring into ticks until the triad
  lands.

## Anti-patterns (DIVERGE from Jeff)

- Do NOT collapse `health` into `doctor`. `health` exists to be called
  cheaply from hot loops; `doctor` may be expensive.
- Do NOT use exit-code-only contracts (`exit 1` with no JSON). Failing
  silently into a launchd log is the failure mode this contract exists to
  prevent.

## DOD reference

This contract document satisfies `flywheel-hn8e` acceptance gate 1
(checklist exists). Gates 2 (audit one script), 3 (machine-readable warning
on missing repair posture), 4 (backup-before-write on mutating examples),
and 5 (PASS/WARN/FAIL examples) are seeded by the example sets above and
the audit-set list; follow-on beads file the meta-doctor probe and the
audit fixtures.
