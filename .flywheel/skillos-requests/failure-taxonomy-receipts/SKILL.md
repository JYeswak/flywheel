---
name: failure-taxonomy-receipts
description: "Use when 'failure taxonomy', 'failure class registry', 'reason code', 'retry policy', 'recovery hint', 'DONE receipt', 'BLOCKED receipt', 'callback envelope', 'no_bead_reason', 'fuckups_logged', 'validation receipt', 'redispatch decision', 'owner route', 'artifact missing', 'invalid callback', 'transport timeout', or 'worker close evidence'."
license: MIT
distribution: forbidden
version: 0.1.0
status: skillos-request
---

# Failure Taxonomy Receipts

## Status

Draft for skillos review. This file is a flywheel-local request artifact for
bead `flywheel-cmf4`; it is not installed as a live skill and is not published
to JSM.

## Hard Rules

1. Every failure-bearing receipt carries stable `schema_version`,
   `failure_class`, `reason_code`, `retry_policy`, `recovery_hint`, and
   `owner_route` fields before prose.
2. Failure classes are lowercase snake_case or kebab-case and remain stable
   across wording changes.
3. Retry policy is an enum: `none`, `exponential`, `manual`, or `permanent`.
4. `none` means no retry is useful because the result is already terminal or
   a gate is intentionally closed.
5. `exponential` is only for transient substrate uncertainty with bounded
   retries, a max-attempt count, and a next probe command.
6. `manual` means another owner must act; the receipt names the owner and the
   exact evidence required to resume.
7. `permanent` means the request should not be retried without a new input,
   code change, or bead.
8. DONE and BLOCKED callback receipts preserve flywheel `DID/DIDNT/GAPS`,
   `mission_fitness`, `josh_request_id`, `br_close_executed`, and delivery
   verification fields.
9. Every observed issue routes to exactly one durable outcome:
   `beads_filed`, `beads_updated`, or `no_bead_reason`.
10. BLOCKED receipts and trauma-bearing DONE receipts carry `fuckups_logged`
    or an explicit `none_clean` value when no trauma occurred.
11. Recovery hints are commands or owner routes, not vague advice. They name
    the validator, evidence path, pane/session, or bead owner needed next.
12. Validators include fixtures for pass, missing evidence, invalid callback,
    timeout/unknown, reservation conflict, and repeated unrecoverable failure.
13. Secret-shaped values never appear in failure evidence; receipts name secret
    classes or vault paths only.

## THE EXACT PROMPT

```text
Create or revise a skill named failure-taxonomy-receipts for <surface>. Define
a deterministic failure class registry, retry policy matrix, recovery hint
shape, owner route field, DONE/BLOCKED receipt fields, no-bead/fuckup routing,
and validator fixtures. Preserve flywheel DID/DIDNT/GAPS, mission_fitness,
josh_request_id, br_close_executed, and callback delivery fields. Include an
executable self-test that rejects drafts missing schema_version, failure_class,
reason_code, retry_policy, recovery_hint, owner_route, no_bead_reason,
fuckups_logged, and publication staging. Cite Jeff corpus evidence and do not
mutate live skills or run jsm push until Joshua approves publication.
```

## Decision Tree

| Situation | Receipt posture |
|---|---|
| Callback is valid and evidence exists | `status=pass`, `failure_class=null`, `retry_policy=none` |
| Evidence path is missing | `failure_class=missing_artifact`, `retry_policy=manual`, route to regenerate or restore evidence |
| Required callback field is absent | `failure_class=invalid_callback`, `retry_policy=manual`, request corrected callback |
| Runtime or substrate probe timed out | `failure_class=transient`, `retry_policy=exponential`, include max attempts and next probe |
| Reservation conflict blocks write | `failure_class=file_reservation_conflict`, `retry_policy=manual`, name holder and reread source after release |
| Same failure repeats past retry budget | `failure_class=retry_budget_exhausted`, `retry_policy=permanent`, file/update repair bead |
| Finding is real but not bead-worthy | Emit `no_bead_reason` with evidence and no silent absorption |
| BLOCKED callback hits a trauma | Log fuckup row first, then cite `fuckups_logged=<class>` |

## Failure Class Registry

Minimum classes for flywheel receipt validation:

| failure_class | retry_policy | owner_route | Recovery hint shape |
|---|---|---|---|
| `missing_artifact` | `manual` | producing worker or orchestrator | Restore/regenerate the named artifact, then rerun validator |
| `invalid_callback` | `manual` | producing worker | Resend callback with required fields and evidence |
| `transient` | `exponential` | current orchestrator | Retry bounded probe with max attempts and last output |
| `file_reservation_conflict` | `manual` | reservation holder or orchestrator | Wait/release/reread source before mutation |
| `gate_unmet_open_children` | `none` | bead owner | Close or explicitly defer open children |
| `retry_budget_exhausted` | `permanent` | repair bead owner | File/update durable repair bead before more retries |
| `secret_leak_risk` | `permanent` | security owner | Stop, scrub output, and route by secret class only |
| `unknown_unclassified` | `manual` | taxonomy owner | Add classifier fixture or map to an existing class |

## Receipt Schema

Minimum receipt:

```json
{
  "schema_version": "failure-taxonomy-receipts/v1",
  "status": "pass|fail|unknown|blocked",
  "surface": "callback-validator",
  "failure_class": "missing_artifact",
  "reason_code": "missing_artifact",
  "retry_policy": "manual",
  "recovery_hint": "Restore /tmp/evidence.md and rerun validate-callback.",
  "owner_route": "worker|orchestrator|skillos|human|repair-bead",
  "evidence": ["path/or/line/or/command"],
  "bead_route": {
    "beads_filed": [],
    "beads_updated": [],
    "no_bead_reason": null
  },
  "fuckup_route": {
    "fuckups_logged": ["missing_artifact"],
    "none_clean": false
  }
}
```

## Callback Field Contract

For flywheel worker callbacks, this skill extends but does not replace the
existing envelope. Validators must preserve:

- `did`, `didnt`, `gaps`
- `mission_fitness`
- `josh_request_id`
- `br_close_executed`
- `callback_delivery_verified`
- `socraticode_queries` and `indexed_chunks_observed` when dispatch required
- `files_reserved` and `files_released` when edits occurred
- one of `beads_filed`, `beads_updated`, or `no_bead_reason`
- `fuckups_logged` for BLOCKED or trauma-bearing DONE

## Source Evidence

- `.flywheel/jeff-corpus/v1/learnings/06-skill-enhancement-matrix.md:39-45`
  names `failure-taxonomy-receipts` as a new sibling skill candidate and states
  the gap: no live skill owns deterministic failure classes, retry policy,
  recovery hints, and DONE/BLOCKED receipt fields together.
- `.flywheel/jeff-corpus/v1/learnings/01-doctrine-cluster.md:98-114`
  describes the `error-handling-and-recovery` cluster: errors are classified,
  routed, and made recoverable with clear commands.
- `.flywheel/jeff-corpus/v1/learnings/01-doctrine-cluster.md:134-150`
  describes callback and receipt envelopes as structured evidence for worker
  completion.
- `.flywheel/jeff-corpus/v1/learnings/02-code-patterns.md:133-152` says
  flywheel should keep its DONE/BLOCKED callback shape but back it with
  reusable envelope validation helpers.
- `AGENTS.md` L118 requires stable failure reason codes before prose for
  callbacks, doctor JSON, validators, and Beads routing.

## Flywheel Adaptation Notes

- This is a skillos-owned sibling skill because failure classes currently live
  across AGENTS doctrine, callback validators, Beads routing, fuckup-log
  routing, and one-off tests.
- The skill should consume sibling contracts: `validation-fixture-contract` for
  fixture naming, `doctor-repair-triad` for owner/repair surfaces, and
  `mutation-safety-contract` for retry/idempotency collisions.
- Positive validation receipts stay out of the fuckup log; failed or unknown
  receipts route through L52/L53/L56.
- `jsm push` is staged only. This draft asks skillos to review, refine, and
  publish after Joshua approval.

## Executable Self-Test

Run:

```bash
bash scripts/self_test.sh .
```

Expected pass output:

```json
{"checks":13,"status":"pass"}
```

## Publication Staging

After skillos review and Joshua approval:

```bash
jsm validate /path/to/failure-taxonomy-receipts --json --offline
jsm push /path/to/failure-taxonomy-receipts
```

No `jsm push` is authorized by this draft.

## Anti-Patterns

| Anti-pattern | Why it fails | Required replacement |
|---|---|---|
| Prose-only failure | Downstream loops cannot group or route failures | Stable `failure_class` and `reason_code` |
| Retry everything | Permanent or owner-routed failures burn worker cycles | Bounded retry policy matrix |
| Missing owner route | Orchestrator cannot decide who acts next | Explicit `owner_route` and recovery evidence |
| Callback replacement | New receipt breaks flywheel close gates | Extend the existing DID/DIDNT/GAPS envelope |
| Silent finding absorption | Real gaps disappear from Beads and fuckup-log | `beads_filed`, `beads_updated`, or `no_bead_reason` |
| BLOCKED without fuckup row | Trauma survives only in scrollback | Log and cite `fuckups_logged` before callback |
| Generic unknown bucket | Unknown count hides classifier debt | `unknown_unclassified` plus fixture or owner route |
| Secret in evidence | Pane and callback logs persist sensitive values | Redact values and name only secret classes |

