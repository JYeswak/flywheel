# Phase 3 AUDIT r1 Lens 2 — Idempotency

Plan: `agent-security-controls-fleet-wide-2026-05-04`
Input: `.flywheel/plans/agent-security-controls-fleet-wide-2026-05-04/00-PLAN.md`
Lens: idempotency only
ladder_passed: yes

## 1. Skills And Socraticode Queries Used

Skills consulted:

- `jeff-convergence-audit`: Phase 1 broad-sweep discipline and structured finding output.
- `safe-migrations`: expand/contract, rollback, validation, and partial-failure resume posture.
- `backward-compatibility`: schema evolution, additive changes, and consumer contract compatibility.
- `retry-backoff-patterns`: idempotency-key requirement before retry/replay.
- `testing-conformance-harnesses`: MUST-clause extraction, golden outputs, differential tests, and conformance matrix.

Socraticode queries:

- `idempotency audit propagation receipt replay doctor signal bead promotion duplicate settings merge`
- `sync canonical doctrine idempotent backup apply doctor signal promotion dedupe receipt atomic`

Local precedent surfaced:

- `tests/validation-fix-bead.sh` requires `--apply` to carry an `--idempotency-key` and verifies duplicate replay returns the existing result instead of re-creating work.
- `tests/doctor-validation-signals.sh` validates doctor signal metadata but does not by itself prove same-input deterministic output.

## 2. Findings

### I1

finding_id: I1
severity: high
class: re-apply safety
location: `00-PLAN.md` Canonical Settings Deny Block lines 82-86; Propagation lines 88-90; B03 acceptance gates lines 194-199
description: B03 says re-run apply is idempotent, but the plan does not define canonical merge semantics for settings objects and deny arrays. Without a deterministic array-set merge, repeated apply can append duplicate deny entries or reorder settings, producing drift even when the logical policy is unchanged.
attack_vector: A worker runs the propagation apply twice; the second run appends the same `.env*` and `.ssh/**` deny entries to `permissions.deny`, then doctor reports a different count/hash and creates a false drift or masks a real missing entry.
mitigation: Amend B03/B09: require parse-merge-sort-write semantics where managed arrays are treated as sets keyed by normalized rule ID/path, unmanaged keys are preserved, output is canonical JSON, and a fixture proves `apply; shasum; apply; shasum` is byte-identical.
joshua_decision_needed: no
joshua_question: n/a

### I2

finding_id: I2
severity: high
class: partial-failure resume
location: `00-PLAN.md` rollout line 17; Propagation lines 88-90; B03 lines 194-199; Rollout Plan lines 370-384
description: The rollout is sequential and requires receipts, but it does not define per-repo checkpoint state or resume semantics for an abort after a partial fleet apply. A rerun can duplicate already-written receipts, skip failed repos incorrectly, or overwrite the rollback evidence from successful repos.
attack_vector: Propagation applies to 15 repos, fails on 2 malformed settings files, and writes a fleet receipt. The next run sees existing receipts for the 15 successful repos but no stable operation ID, so it either reapplies them with new backups or reports success while the two failed repos remain unprotected.
mitigation: Amend B03/B09: require a fleet operation ID plus per-repo states `pending|applied|blocked|rolled_back`, content hashes before/after, retry count, and resume logic that no-ops already-applied repos when current hash matches expected output and retries only blocked/pending repos.
joshua_decision_needed: no
joshua_question: n/a

### I3

finding_id: I3
severity: medium
class: receipt collision
location: `00-PLAN.md` Canonical Contract line 80; doctor signal line 121; B03 lines 198-199; B09 lines 311-317
description: The plan references issued/expires metadata and validation receipts but does not require a unique idempotency key for a logical security operation. Two markers for the same apply can authorize overlapping bounded mutations and leave competing receipts for the same repo state.
attack_vector: Two workers independently issue security-control receipts for the same propagation run; both are valid and unexpired, so each writes settings and rollback receipts with different IDs, making rollback and validation ambiguous.
mitigation: Amend B01/B03/B09: add `operation_id`, `idempotency_key`, `repo_scope_hash`, and `supersedes` fields; `--apply` must reject missing idempotency key; duplicate keys return the original receipt/result without performing another mutation.
joshua_decision_needed: no
joshua_question: n/a

### I4

finding_id: I4
severity: medium
class: doctor signal idempotency
location: `00-PLAN.md` Doctor Signals lines 104-121; B04 lines 214-220; B05 lines 233-239
description: The plan defines thresholds and promotion paths, but it does not require doctor JSON to be stable for the same inputs. Fields such as freshness, scanned-at timestamps, top failing repos, or monotonic counters can change between two doctor runs in the same minute and spuriously trigger promotion.
attack_vector: `flywheel-loop doctor --json` runs twice against identical fixtures; the second output has a new timestamp or reordered failing repo list, B05 treats it as a distinct drift event, and an auto-doctor bead is created again.
mitigation: Amend B04/B05/B09: add deterministic fixture mode with fixed clock/input ordering, stable sort keys, and a test that two doctor runs against the same fixture are byte-identical after allowed volatile fields are stripped; promotion dedupe must key on normalized signal class, repo, window, and evidence hash.
joshua_decision_needed: no
joshua_question: n/a

### I5

finding_id: I5
severity: medium
class: override receipt churn
location: `00-PLAN.md` override pattern line 86; B01 lines 156-161; B04 lines 214-220
description: Override state is discussed as a receipt surface, but add/remove/re-add ordering and tombstone semantics are undefined. The same final active override set can produce different doctor results depending on receipt history order.
attack_vector: A user adds an override, removes it, then re-adds the same scoped override; another repo has only the final active override. Both are logically equivalent, but doctor reports different active counts or stale receipt freshness because historical tombstones are interpreted differently.
mitigation: Amend B01/B04/B09: define override state as a canonical projection from append-only events using `override_id`, `generation`, `created|revoked|expired` events, deterministic last-valid-wins rules, and a conformance fixture proving equivalent histories produce identical active-state JSON.
joshua_decision_needed: no
joshua_question: n/a

### I6

finding_id: I6
severity: medium
class: pre-commit hook re-install
location: `00-PLAN.md` Pre-Commit lines 96-98; B07 lines 272-277; doctor signals lines 115-116
description: B07 checks that existing hooks are preserved or chained, but it does not specify the managed block markers or reinstall behavior. Running installer twice can append duplicate hook invocations, clobber a chained hook, or create different hook files across repos.
attack_vector: The hook installer is run once by propagation and again during fleet smoke; the second run appends another `security-posture-probe.sh` invocation to the same hook file, causing duplicate scans and different stderr/order on every commit.
mitigation: Amend B07/B09: require delimited managed hook blocks, canonical hook file rendering, backup-before-write, and a fixture proving install twice yields byte-identical hook contents and preserves unmanaged hook content outside the managed block.
joshua_decision_needed: no
joshua_question: n/a

### I7

finding_id: I7
severity: high
class: bead promotion replay
location: `00-PLAN.md` B05 acceptance gates lines 233-239; doctor signal table lines 117-121
description: B05 says duplicate promotion should not happen on re-run, but the dedupe key is not specified. Without a stable idempotency key, replaying the same doctor failure after a retry, clock tick, or evidence path reorder can create multiple auto-doctor beads.
attack_vector: `leaked_secret_pattern_count > 0` is emitted by the same repo on two consecutive doctor runs; the evidence JSON includes a new timestamp, promotion sees a new event, and creates two P0 beads for one logical leak.
mitigation: Amend B05/B09: require promotion idempotency key `auto-doctor:<signal>:<repo_realpath>:<normalized_failure_class>:<evidence_hash>:<window>`; dry-run and apply must return the existing bead when the key already exists, matching the `validation-fix-bead` idempotency-key precedent.
joshua_decision_needed: no
joshua_question: n/a

### I8

finding_id: I8
severity: medium
class: migration replay
location: `00-PLAN.md` Propagation lines 88-90; B03 lines 194-199; Rollout Plan lines 378-383
description: Running B03 against an already-protected repo is intended to no-op, but metadata preservation is underspecified. A replay can refresh issued timestamps, rotate backups, or overwrite prior rollback guards even when the effective deny block is unchanged.
attack_vector: A repo already has the canonical deny block and a rollback receipt from yesterday; a fleet rerun overwrites the receipt with today's timestamp and backup path while leaving settings unchanged, destroying the original rollback reference for the prior operation.
mitigation: Amend B03/B09: distinguish `noop_already_current` from `applied`; no-op must not write a new backup or mutate receipt state except an append-only observation row, and tests must prove already-current replay preserves settings, managed metadata, and rollback references.
joshua_decision_needed: no
joshua_question: n/a

### I9

finding_id: I9
severity: high
class: validation receipt overwrite
location: `00-PLAN.md` B03 receipt lines 198-199; B09 validation receipt line 317; Three-Q lines 400-403
description: The plan requires validation receipts but not atomic create, lock, or conflict behavior. Two workers finishing the same bead or fleet smoke can interleave writes to the same receipt path, yielding truncated JSON, last-writer-wins evidence loss, or mismatched status.
attack_vector: Two workers complete B09 conformance in parallel and both write `.flywheel/validation-receipts/security-control.json`; one writes `status=pass`, the other writes `status=fail`, and the final file is whichever write wins rather than a deterministic aggregate.
mitigation: Amend B09 and the receipt schema: write receipts to a temp file then atomic rename, include `operation_id` and `worker_id`, reject overwrite unless idempotency key matches, and aggregate parallel receipts through a manifest keyed by bead ID and operation ID.
joshua_decision_needed: no
joshua_question: n/a

### I10

finding_id: I10
severity: medium
class: cross-runtime drift
location: `00-PLAN.md` cross-cutting conclusions lines 70-74; settings block lines 82-86; open questions lines 388-392
description: The plan acknowledges Codex parity, but it does not require Claude and Codex renderers to produce byte-identical canonical JSON for the same security block. Different whitespace, ordering, escaping, or path normalization can make no-op detection and drift hashes runtime-dependent.
attack_vector: Claude writes pretty JSON with one key order and Codex writes compact JSON with another; doctor sees hash drift on every alternated runtime apply, repeatedly reporting security settings drift even though the logical policy is the same.
mitigation: Amend B01/B03/B09: define one canonical serializer and normalized path grammar shared by Claude/Codex; add a cross-runtime golden fixture where both runtimes render the same input and `shasum -a 256` matches exactly.
joshua_decision_needed: yes
joshua_question: Should Phase 4 require byte-identical canonical JSON across Claude and Codex, or allow semantic equivalence with normalized hashes?

## 3. Hunt List Coverage

| Hunt item | Result |
|---|---|
| Re-apply safety | I1 |
| Partial-failure resume | I2 |
| Receipt collision | I3 |
| Doctor signal idempotency | I4 |
| Override receipt churn | I5 |
| Pre-commit hook re-install | I6 |
| Bead promotion replay | I7 |
| Migration replay | I8 |
| Validation receipt overwrite | I9 |
| Cross-runtime drift | I10 |

Every requested hunt class has at least one finding.

## 4. Critical And High Findings

Critical findings: 0

High findings for Joshua-disposes visibility:

- I1 re-apply safety
- I2 partial-failure resume
- I7 bead promotion replay
- I9 validation receipt overwrite

Joshua decisions needed:

- I10 cross-runtime canonical JSON policy

## 5. Three-Q Audit

VALIDATED:

- Every finding cites `00-PLAN.md` section and line range.
- Every finding includes a concrete replay or race scenario.
- Socraticode was queried twice for local idempotency, promotion, receipt, and doctor-signal precedent.

DOCUMENTED:

- Each finding has an explicit mitigation as an amendment to B01-B09.
- Skills consulted are named in section 1.
- Critical/high findings are separated for Joshua-disposes.

SURFACED:

- Findings map to existing beads; no new standalone bead is mandatory from Lens 2 unless Phase 3 synthesis decides cross-runtime canonicalization deserves its own bead.
- The highest-risk theme is missing operation-level idempotency keys across settings propagation, promotion, and validation receipts.

## 6. Ladder Check

Plan-space only:

- No settings mutations.
- No source implementation edits.
- No bead creation.
- No commits.
- Output artifact only: `.flywheel/plans/agent-security-controls-fleet-wide-2026-05-04/03-AUDIT-r1-lens2-idempotency.md`.

Ladder verdict: `ladder_passed=yes`.
