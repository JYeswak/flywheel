# Polish Gate

The Polish Gate is the flywheel-installed repo quality gate for publishable
surfaces. Its invariant is simple: a surface is not close-ready just because it
is wired; it is close-ready when the five-skill rubric is measured, recorded,
and visible to the loop operator.

This README is the operator contract for the template surface. The schemas and
fixtures in this directory are the current mechanical contract; the Phase 2
runner, discovery, doctor, and close-validator beads wire these fields into the
repo-local `flywheel-loop` surface.

## What is the Polish Gate?

The Polish Gate measures whether a flywheel surface is publishable after it has
been wired or touched.

| Piece | Meaning |
|---|---|
| Stock | Surfaces declared by the manifest, discovered as new, or touched by recent work. |
| Inflow | New templates, changed scripts, changed READMEs, CLI surfaces, and repo-local flywheel files. |
| Measurement | Five grades: `ubs`, `simplify`, `extreme-opt`, `readme`, and `canonical-cli`. |
| Receipt | One append-only JSONL row per graded surface. |
| Summary | A latest aggregate JSON document for doctor and close gates. |
| Outflow | PASS, NOT_APPLICABLE, WAIVED with expiry, or a repair bead for failed surfaces. |

The gate starts as visibility, then becomes enforcement. In bootstrap mode it
helps a newly installed repo learn which surfaces exist. In audit-only mode it
records findings without blocking close. In blocking mode it stops close when a
required surface is below the bar, missing a receipt, malformed, or protected
only by an expired waiver.

The gate is fleet-wide doctrine. The memory source is:
`feedback_post_wire_or_explain_three_skill_polish_gate.md`, updated on
2026-05-05 to make the gate five-skill rather than three-skill.

## Quick start

Current Phase 2 template verification:

```bash
bash templates/flywheel-install/tests/test_polish_gate_schemas.sh
bash templates/flywheel-install/tests/test_polish_gate_runner.sh
bash templates/flywheel-install/tests/test_render.sh
```

Expected result: all commands exit 0. The schema test validates manifest,
grade-receipt, latest-summary, and fixture JSON contracts. The runner test
validates local receipt storage and mode behavior. The render test protects the
install renderer from template regressions.

After P2-02 discovery and P2-03 runner/storage land, the operator surface should
read like this:

```bash
repo="/Users/josh/Developer/flywheel"
flywheel-loop polish-gate --repo "$repo" --json
flywheel-loop polish-gate --repo "$repo" doctor --json
flywheel-loop polish-gate --repo "$repo" why templates/flywheel-install/README.md --json
```

Expected result: the first command emits the current grade summary, the doctor
command emits halt-ready operator status, and `why` explains the producer,
measurement, consumer, grade receipt, and waiver state for one surface.

Do not treat those planned commands as shipped until the runner and scoped CLI
beads wire them. Until then, schema and fixture tests are the source of truth.

## Modes

The repo-local manifest field `mode` controls enforcement.

| Mode | Purpose | Close behavior | Good use |
|---|---|---|---|
| `bootstrap` | First install before all surfaces are declared or graded. | Warn on gaps; block malformed gate and expired waiver when configured. | New repo-local flywheel installs. |
| `audit_only` | Measure without failing close. | Record receipts and failures; do not block solely for sub-bar grade. | Fleet-wide audit, production survey, planning pass. |
| `blocking` | Enforce publishability for declared scope. | Block close on required failures, missing receipts, malformed gate, or expired waiver. | Mature repos and touched flywheel surfaces. |

The manifest field `scope` decides which surfaces are in view.

| Scope | Included surfaces |
|---|---|
| `new` | Surfaces created after the gate is installed. |
| `touched` | New surfaces plus existing surfaces changed by the current work. |
| `repo_local_flywheel` | Repo-local `.flywheel/` substrate and loop-facing files. |
| `all_declared` | Every declared surface in the manifest inventory. |

The field `legacy_bootstrap_policy` decides how pre-existing surfaces are
treated while a repo is still being reconciled.

| Policy | Meaning |
|---|---|
| `warn_until_touched` | Existing ungraded surfaces remain visible but do not block until touched. |
| `block_immediately` | Existing declared surfaces are required immediately. |

The field `blocking_when` is the halt list. Current schema values are
`new_surface`, `touched_required_surface`, `malformed_gate`, and
`expired_waiver`. A blocking repo should include the cases it is ready to
enforce mechanically.

## Runner

The Phase 2 runner is `polish-gate/run-grader.py`; `run-grader.sh` is the
portable shell entrypoint. Wave-0 uses JSON-passthrough lane envelopes and writes
the stable storage contracts. Actual skill CLI invocation is deferred to the
follow-up runner bead.

Run against a repo-local manifest:

```bash
python3 templates/flywheel-install/polish-gate/run-grader.py \
  --repo . \
  --manifest .flywheel/polish-gate/manifest.json \
  --mode audit_only \
  --apply \
  --json
```

Focused checks can skip discovery and grade one surface or lane:

```bash
python3 templates/flywheel-install/polish-gate/run-grader.py \
  --repo . \
  --surface .flywheel/GOAL.md \
  --lane readme \
  --dry-run \
  --json
```

Mode behavior:

| Mode | Runner behavior |
|---|---|
| `bootstrap` | Writes visibility when `--apply` is set and exits 0 even with sub-bar grades. |
| `audit_only` | Writes receipts with verdict `AUDIT_ONLY`; sub-bar grades remain record-only. |
| `blocking` | Returns exit 1 when any skill or composite is below 9.0. |

Storage behavior:

| Path | Writer behavior |
|---|---|
| `grade_storage` | Append-only JSONL receipt log; the runner appends via temp file plus rename. |
| `latest_summary` | Aggregate latest JSON summary; the runner rewrites via temp file plus rename. |
| `grade-run-result.schema.json` | Schema for the runner's stdout result object. |

Exit codes are stable: 0 for green or warn-only, 1 for blocking grade failure,
2 for schema errors, 3 for malformed manifests, and 4 for discovery failure.
Use `--schema` to print the runner result schema and `--explain` for a
human-readable local trace.

## Receipts

The grade receipt is an append-only JSONL row written to the manifest's
`grade_storage` path, defaulting to `.flywheel/polish-gate/grades.jsonl`.

Required receipt fields:

| Field | Meaning |
|---|---|
| `schema_version` | Must be `polish-gate/grade-receipt/v1`. |
| `ts` | ISO8601 timestamp for the grade event. |
| `surface_path` | Repo-relative path, never absolute. |
| `surface_name` | Operator-readable surface name. |
| `mode` | Manifest mode active when the grade was written. |
| `skills` | Five per-skill numeric grades. |
| `composite` | Numeric aggregate grade from 0 to 10. |
| `verdict` | PASS, FAIL, NOT_APPLICABLE, WAIVED, or AUDIT_ONLY. |
| `evidence_paths` | Repo-relative evidence files, receipts, tests, or reports. |
| `grader` | Agent, worker, or tool that produced the grade. |
| `mission_anchor_hash` | Hash tying the grade to the mission anchor in force. |

The latest summary is written to the manifest's `latest_summary` path,
defaulting to `.flywheel/polish-gate/latest.json`.

Required summary fields:

| Field | Meaning |
|---|---|
| `schema_version` | Must be `polish-gate/latest-summary/v1`. |
| `last_run_ts` | Timestamp for the run that produced the aggregate. |
| `mode` | Current manifest mode. |
| `surfaces_graded` | Number of surfaces with receipts in the run. |
| `surfaces_passed` | Count of passing surfaces. |
| `surfaces_failed` | Count of failing surfaces. |
| `pending_waivers` | Count of unexpired waivers still active. |
| `composite_avg` | Average composite grade. |
| `min_composite` | Lowest composite grade. |
| `min_composite_surface` | Surface carrying the lowest composite grade. |
| `audit_summary_path` | Optional path to a human-readable audit packet. |

Doctor and close gates should read the summary, then reconcile it against the
receipt log when enforcement matters. A summary without backing receipts is a
visibility bug, not proof.

## Ledger replay

`replay-to-ledger.py` is the replay adapter that translates local
`grades.jsonl` receipts into The Zest Ledger row contract. It keeps the local
polish-gate receipt log as the Phase 2 source, then bridges those events into
the wave-0 ledger stock when an operator needs chain-verified history, periodic
batch replay, or a one-shot historical bootstrap.

Dry-run is the default and writes nothing:

```bash
python3 templates/flywheel-install/polish-gate/replay-to-ledger.py \
  --source .flywheel/polish-gate/grades.jsonl \
  --target-ledger /tmp/polish-gate-ledger.jsonl \
  --dry-run \
  --json \
  --explain
```

Apply writes translated rows to the target ledger with temp-file plus rename.
Duplicate grade receipts are skipped by deterministic `identity_key`, so
re-running the same source is idempotent:

```bash
python3 templates/flywheel-install/polish-gate/replay-to-ledger.py \
  --source .flywheel/polish-gate/grades.jsonl \
  --target-ledger /tmp/polish-gate-ledger.jsonl \
  --apply \
  --json
```

Incremental replay uses `--from-ts` and includes only receipts after the named
timestamp. `--apply-to-live` targets `.flywheel/wire-or-explain/ledger.jsonl`,
requires `--apply`, and verifies the existing chain before append. If the live
chain is already corrupt, replay exits with `exit_code=1`, writes nothing, and
leaves recovery to the chain-verifier repair path.

Replay preserves `ts`, `surface_path`, `mode`, `composite`, `verdict`,
`evidence_paths`, and `mission_anchor_hash`. The receipt `skills` object becomes
the ledger `evidence_payload`, and `grader` becomes the ledger actor/agent
metadata. The replay output validates against
`polish-gate/v1/replay-output.schema.json`.

Failure modes:

| Failure mode | Operator signal | Recovery |
|---|---|---|
| Malformed source JSONL | `exit_code=4`. | Rebuild or trim the malformed receipt line; do not replay partial corrupt input. |
| Schema-fail receipt | `rows_skipped.schema-fail` increments. | Re-run grading or append a corrected receipt; valid sibling rows still replay. |
| Duplicate replay | `rows_skipped.dup` increments. | No action; idempotency is working. |
| Pre-timestamp skip | `rows_skipped.pre-from-ts` increments. | Adjust `--from-ts` if the batch window is wrong. |
| Live chain pre-fail | `chain_verify_pre=FAIL`, `exit_code=1`. | Run the Zest Ledger chain verifier and repair workflow before replaying. |
| Post-write chain fail | `chain_verify_post=FAIL`, `exit_code=2`. | Treat the target ledger as invalid and replay into a clean target after diagnosis. |

Use the live Zest Ledger as the long-lived source of truth for cross-surface
stock once replayed. Use polish-gate `grades.jsonl` as the local measurement
source that can be replayed without destroying either history.

## Waivers

A waiver is a receipt field, not a side note. It is valid only when the grade
receipt verdict is `WAIVED` and the waiver object contains all required fields.

| Field | Required behavior |
|---|---|
| `reason` | Names the concrete defect or temporary exception. |
| `expires_at` | ISO8601 expiry; expired waivers are halt-class in blocking mode. |
| `approver` | The accountable owner who accepted the exception. |

Approval should follow ownership. Flywheel-owned template substrate can be
waived by the flywheel orchestrator or Joshua. Client repo waivers belong to the
client repo owner or the owning delivery orchestrator. Risk-boundary exceptions
that affect production, credentials, safety gates, or external clients require
Joshua-level approval.

Waivers must be visible in doctor output. A hidden waiver is operationally the
same as bypassing the gate. A permanent waiver is not a waiver; it is either a
NOT_APPLICABLE verdict with evidence or an unresolved design debt bead.

## Lifecycle

The lifecycle is designed to move from visibility to enforcement without hiding
legacy debt.

| Stage | Operator meaning |
|---|---|
| Install | Template copies schemas, fixtures, manifest defaults, and this README. |
| Discover | P2-02 finds declared, new, touched, and repo-local flywheel surfaces. |
| Grade | P2-03 writes grade receipts and latest summary. |
| Explain | Scoped CLI and doctor surfaces report `why` for a path or failed field. |
| Enforce | P2-08 close validator blocks when the manifest says the failure is halt-class. |
| Reconcile | P2-09 compares discovered stock, receipts, summary, and bead state. |
| Expand | P2-10 proves scoped behavior across new, touched, repo-local, and declared fixtures. |

The lifecycle should be monotonic. Moving from `bootstrap` to `audit_only` to
`blocking` should increase information quality and enforcement. Moving backward
requires an explicit operator reason, a bead, or a waiver-shaped receipt.

For touched surfaces, the gate should run once on the converged surface, not
once per upstream bead. That prevents duplicate grade churn when several
wire-or-explain beads touch the same operator surface.

## Reconcile

Reconcile brings an existing flywheel-installed repo up to the polish-gate
contract without rewriting local mission or state content. It adds only the
missing `polish_gate_*` fields to `.flywheel/MISSION.md`, the runtime fields to
`.flywheel/STATE.md`, and the `polish_gate` object to `.flywheel/loop.json`.

Production and client repos default to `audit_only` during reconcile. That
preserves the rollout rule from
`feedback_stamp_in_flywheel_first_then_propagate.md`: prove the gate in
flywheel, bake it into the install template, then audit ecosystem surfaces
without in-place domain mutation.

Detect first:

```bash
bash templates/flywheel-install/scripts/reconcile-polish-gate.sh \
  --repo /path/to/repo \
  --detect \
  --json
```

Exit code `0` means the repo is already reconciled. Exit code `2` means the
repo needs reconcile. Exit code `3` means malformed local state, such as a
MISSION file missing the canonical Mission Anchor section.

Preview before writing:

```bash
bash templates/flywheel-install/scripts/reconcile-polish-gate.sh \
  --repo /path/to/repo \
  --dry-run \
  --json
```

Apply writes timestamped backup sidecars beside every modified file:
`MISSION.md.bak.<iso-ts>`, `STATE.md.bak.<iso-ts>`, and
`loop.json.bak.<iso-ts>`. Writes use temp files plus rename, and the resulting
`loop.json.polish_gate` object validates against
`polish-gate/v1/manifest.schema.json`.

```bash
bash templates/flywheel-install/scripts/reconcile-polish-gate.sh \
  --repo /path/to/repo \
  --apply \
  --mode audit_only \
  --json
```

If an operator already set `polish_gate_mode`, reconcile preserves that setting
unless `--mode` is explicitly supplied. Rollback restores the byte-exact prior
state from the named backup timestamp:

```bash
bash templates/flywheel-install/scripts/reconcile-polish-gate.sh \
  --repo /path/to/repo \
  --rollback 2026-05-05T232400Z \
  --json
```

## Scope allowlist

A scope-allowlist fixture is a repo profile that tells discovery which paths are
eligible for polish-gate grading before any domain terms or operator words are
interpreted. The fixture is schema-validated at
`polish-gate/v1/scope-allowlist.schema.json` and stored under
`polish-gate/fixtures/scope-allowlist/`.

Each profile declares:

| Field | Meaning |
|---|---|
| `profile_name` | Repo profile to load, such as `alps`, `skillos`, or `default`. |
| `allowlist_paths` | Repo-relative path globs that are in scope. |
| `blocklist_paths` | Repo-relative path globs that are always out of scope and take precedence. |
| `blocklist_reason_default` | Reason attached when a blocked path is filtered. |
| `domain_collision_terms` | Generic Yuzu words that also occur in this repo's domain. |
| `requires_word_boundary` | Whether term matching must use word-boundary regex. |

Manifest or reconcile code should select a profile with
`scope_allowlist_profile`. Missing profile selection falls back to `default`,
which allows only `.flywheel/` and excludes common app/domain roots.

ALPS is the strict fixture. Its allowlist is exactly `.flywheel/`; every root
path is healthcare, insurance, financial, CRM, or integration domain owned by
the client. The memory rule is
`feedback_scope_aware_rename_is_the_rule.md`: ALPS root is off-limits, and
terms such as `doctor`, `ledger`, `worker`, `dispatch`, `tick`, and `router`
must never be interpreted before path scope has been applied.

To add a repo profile:

1. Copy `default.json` to `scope-allowlist/<profile>.json`.
2. Set `profile_name`, `domain`, and `rationale`.
3. Add only the paths the owning repo has declared as operational substrate.
4. Add blocklist paths for generated, secret-bearing, client, product, or
   domain-owned surfaces.
5. List collision terms when generic Yuzu words also have domain meaning.
6. Add or extend the fixture test before wiring the profile into reconcile.

Failure modes:

| Failure mode | Operator signal | Recovery |
|---|---|---|
| Malformed fixture | Schema validation fails before discovery can run. | Fix the fixture; do not loosen the schema for bad state. |
| Missing profile | Manifest names a profile that is not installed. | Use `default` or add a schema-valid repo profile. |
| Allowlist bleed | A domain path survives the allowlist. | Tighten `allowlist_paths` or add a blocklist entry before grading. |
| Generic-term bleed | A collision term is matched in domain code. | Apply path scope first and use word-boundary matching when required. |
| Blocklist ignored | A blocklisted path still appears in receipts. | Treat the run as invalid; blocklist precedence is mandatory. |

## Failure modes

| Failure mode | Operator signal | Recovery |
|---|---|---|
| Missing manifest | Doctor cannot resolve mode or storage paths. | Install or regenerate the gate manifest before grading. |
| Malformed manifest | Schema validation fails. | Fix the manifest; do not edit the schema to make bad state pass. |
| Missing grade receipt | Summary says a surface is graded, but no JSONL row backs it. | Re-run grading or rebuild summary from receipts. |
| Stale latest summary | `last_run_ts` predates the touched surface or receipt log. | Re-run the summary writer. |
| Expired waiver | `expires_at` is before now. | Remove the waiver by fixing the defect, or renew with owner approval. |
| Scope bleed | A run grades files outside the manifest scope. | Correct discovery allowlists before trusting the receipt. |
| Sub-bar grade | One skill or composite falls below 9.0. | File or update a repair bead and keep the surface visible. |
| Evidence path missing | Receipt cites evidence that no longer exists. | Restore evidence, replace the receipt with a new grade row, or fail the surface. |
| Absolute surface path | Receipt is machine-local and not portable. | Regrade with repo-relative `surface_path`. |
| Handwritten pass | README or callback claims pass without receipt. | Refuse as prose-only proof and run the gate. |

In blocking mode, malformed gate state and expired waivers should be treated as
gate failures even if every surface grade is high.

## Anti-patterns

| Do not | Why it is wrong | Do this instead |
|---|---|---|
| Treat `audit_only` as publishable pass. | Audit-only is visibility, not enforcement. | Use it to create repair beads or prepare blocking mode. |
| Hide legacy debt by leaving scope at `new` forever. | The stock never drains. | Move to `touched`, then `repo_local_flywheel` or `all_declared`. |
| Delete receipts to make the summary look clean. | The log is the evidence chain. | Append a new receipt that changes verdict or grade. |
| Waive without expiry. | No owner revisits the exception. | Use `expires_at` and make doctor show pending waivers. |
| Approve your own risky waiver. | The gate becomes self-attestation. | Use the owning orchestrator, repo owner, or Joshua for risk boundaries. |
| Edit schemas to fit a bad run. | That changes the contract instead of fixing state. | Fix malformed manifest, receipt, or summary JSON. |
| Count docs as receipt. | Docs can explain the gate but cannot prove a grade. | Write schema-valid grade receipts. |
| Grade outside the allowlist. | It creates false confidence and noisy failures. | Fix discovery scope first. |
| Claim Phase 2 CLI commands are shipped before P2-02/P2-03 land. | Operators will call surfaces that do not exist yet. | State the current schema/fixture contract and the planned CLI separately. |

## 5-skill rubric reference

The gate stores one numeric grade for each required skill and a composite grade.
The close bar is 9.0 or better for every applicable skill and for the composite,
unless the verdict is NOT_APPLICABLE or a valid temporary waiver is present.

| Skill key | Rubric question | Failure example |
|---|---|---|
| `ubs` | Is the invariant named, measured, and halt-on-breach? | README says quality matters but names no halt condition. |
| `simplify` | Is the surface minimal, legible, and free of avoidable duplication? | Three parallel ledgers report the same state. |
| `extreme-opt` | Is the hot path bounded and cheap enough for loop cadence? | Doctor scans the whole repo every tick without scope. |
| `readme` | Can an operator run, interpret, and recover the surface from the README? | README has concepts but no commands, states, or failures. |
| `canonical-cli` | Are verbs, flags, scopes, and exit semantics canonical? | A field-specific status uses a bespoke command outside `flywheel-loop`. |

Grade receipt `skills` object:

```json
{
  "ubs": 9.2,
  "simplify": 9.0,
  "extreme-opt": 9.1,
  "readme": 9.4,
  "canonical-cli": 9.0
}
```

The rubric is not a prose checklist. It is a measured surface contract whose
consumer is close validation, doctor visibility, and future fleet-wide audits.

## Operator checklist

Before closing a polish-gated surface, confirm:

1. The manifest validates against `polish-gate/v1/manifest.schema.json`.
2. The mode is intentional for the repo maturity.
3. Every touched required surface has a grade receipt.
4. Every receipt validates against `polish-gate/v1/grade-receipt.schema.json`.
5. The latest summary validates against `polish-gate/v1/latest-summary.schema.json`.
6. The latest summary reconciles with the append-only receipt log.
7. Every active waiver has `reason`, `expires_at`, and `approver`.
8. No expired waiver is being treated as pass.
9. No scope-bleed path appears in receipts.
10. Sub-bar grades are attached to repair beads or valid temporary waivers.
11. The README for the surface ends with the Yuzu Method footer.
12. Planned CLI examples are not represented as shipped until the CLI bead lands.

This is also the close-validator mental model. The operator should be able to
answer "what failed, who owns it, what receipt proves it, and what blocks close"
without reading implementation code.

Part of the Yuzu Method framework by ZestStream.
