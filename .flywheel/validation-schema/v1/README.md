# Validation Receipt Schema v1

Canonical path: `.flywheel/validation-schema/v1/`

This directory defines the first machine-readable receipt contract for validating worker callbacks before the orchestrator summarizes, integrates, closes, reopens, or routes learning events. A worker `DONE` or `BLOCKED` callback is a claim; this receipt is the proof envelope the later B02-B14 beads consume.

## Files

| path | purpose |
|---|---|
| `schema.json` | JSON Schema contract for validation receipts. |
| `tick-receipt.schema.json` | JSON Schema contract for tick receipts with VALIDATE phase summaries. |
| `parse.sh` | Read-only parser and semantic invariant checker. |
| `dispatch-template-audit.sh` | Read-only audit for dispatch packets and the shared dispatch template. |
| `wire-or-explain-ledger.schema.json` | JSON Schema contract for The Zest Ledger. |
| `portfolio-company-registry.schema.json` | ZestStream holding-company registry contract; refuses to count a portfolio company without signed-owner, equity, first-paying-customer, and substrate-share receipts. |
| `substrate-share-receipt.schema.json` | ZestStream holding-company substrate-share receipt; names tenant declaration, package manifest, adopted `@zeststream/*` packages, and N+1 measurement inputs. |
| `holding-company-launch-economics.schema.json` | ZestStream holding-company launch economics ledger; refuses N+1 cheaper-than-N claims without at least two comparable launch rows. |
| `holding-company-objective-coverage.schema.json` | ZestStream holding-company prompt-to-artifact coverage matrix; maps the full standing goal to evidence rows and refuses completion claims while blockers remain. |
| `holding-company-runway-receipt.schema.json` | ZestStream holding-company redacted runway receipt; proves launch runway months without storing balances, burn-rate dollars, account identifiers, or secret material. |
| `holding-company-candidate-fit.schema.json` | ZestStream holding-company candidate-fit ledger; refuses candidate/press/formation clear status without legacy-SMB sharpening or AI-first incubation classification, SMB owner-operator target proof, AI problem evidence, and no target drift. |
| `holding-company-peel-interviews.schema.json` | ZestStream holding-company PEEL interview ledger; refuses formation-cash clear/commit status without client-talk/community/field-trip source provenance plus five qualified prospect interviews. |
| `holding-company-press-readiness.schema.json` | ZestStream holding-company PRESS readiness ledger; refuses PRESS/formation clear status without v0.1 release, signed-equity, SkillOS, flywheel, package, Yuzu, owner-economics, and substrate-share refs. |
| `holding-company-owner-search-phasing.schema.json` | ZestStream holding-company owner-search phasing ledger; refuses public/cold sourcing before sub #3 and clear/signed status without phasing proof. |
| `holding-company-sustainable-pace.schema.json` | ZestStream holding-company sustainable-pace ledger; refuses Year 2+ clear status without measured weekly hours at or below 60 and 50%+ substrate coaching-time offset. |
| `holding-company-legal-structure.schema.json` | ZestStream holding-company legal-structure readiness ledger; refuses sub #2 owner-signing clearance without binding artifact, attorney review, and CPA review refs for required terms. |
| `holding-company-brand-naming.schema.json` | ZestStream holding-company brand-naming ledger; refuses name/launch clear status without own-brand proof plus owner and community naming provenance refs. |
| `holding-company-anti-pitch-voice.schema.json` | ZestStream holding-company anti-pitch voice ledger; refuses public-clear status while builder-framing hits remain or the holding-company story is absent. |
| `holding-company-anthropic-adoption.schema.json` | ZestStream holding-company Anthropic SDK adoption ledger; proves the recent-progress package-adoption claim only when SkillOS gate evidence, pack-applied rows, and three real consumer repos agree. |
| `holding-company-brand-voice-skill.schema.json` | ZestStream holding-company brand voice skill ledger; refuses skill-alignment clear status without holding-company canon, grounding rules, explicit anti-builder rejection, and an approved JSM workflow receipt. |
| `holding-company-founder-post-voice.schema.json` | ZestStream holding-company founder-post voice ledger; refuses Joshua post/public-share clear status without holding-company positioning, receipt-led claims, fact-check clearance, human ratification, publisher receipt, and no builder framing. |
| `holding-company-mobile-eats-shipping.schema.json` | ZestStream holding-company Mobile Eats recent-progress ledger; separates product/substrate shipping proof from the stricter first-portfolio-company formation claim. |
| `holding-company-skillos-forever-os-lock.schema.json` | ZestStream holding-company SkillOS Forever-OS lock ledger; refuses full recent-progress proof unless v3 goal, anti-punt receipts, and a distinct 2026-05-17 structure-lock receipt are present. |
| `holding-company-owner-voice.schema.json` | ZestStream holding-company Yuzu owner-operator voice ledger; refuses clear status unless owner voice, community context, Yuzu review, owner-operator, and public-surface refs are present without ZestStream meta voice. |
| `holding-company-progress-velocity.schema.json` | ZestStream holding-company progress-velocity ledger; refuses the 4,000+ commits in 7 days across 9 product surfaces claim unless exact surface set, fixed window, command evidence, and per-surface counts prove it. |
| `holding-company-recent-progress-claim-honesty.schema.json` | ZestStream holding-company recent-progress claim-honesty receipt; summarizes active recent-progress claim text and ties each claim to its validator status so blocked/partial claims cannot be restated as current facts. |
| `holding-company-public-surface-audit-supersession.schema.json` | ZestStream holding-company public-surface audit supersession receipt; records stale audit rows superseded by newer anti-pitch and public-story evidence while preserving the incomplete standing-goal counts. |
| `holding-company-public-story.schema.json` | ZestStream holding-company public-story ledger; refuses clear status unless public surfaces lead with receipt/proof evidence and avoid build-app/workflow-builder framing. |
| `holding-company-nonprofit-extension.schema.json` | ZestStream holding-company future nonprofit/social-cause extension ledger; refuses readiness without social-cause scope, legal, governance, operating-separation, funding, and public-story refs. |
| `holding-company-lifecycle-disposition.schema.json` | ZestStream holding-company lifecycle disposition ledger; refuses close, pivot, or graduation clearance without owner/operator, customer, financial, substrate-retention, public-update, and holding-plane-continuity refs. |
| `holding-company-coach-role.schema.json` | ZestStream holding-company post-launch coach-role ledger; refuses clear status unless operating control transfers to the owner while Joshua retains coach role and majority stake. |
| `holding-company-pour-readiness.schema.json` | ZestStream holding-company POUR readiness ledger; refuses launch-clear status without own brand, public surface, first customer, owner-operator, and operating-control handoff refs. |
| `holding-company-operating-health.schema.json` | ZestStream holding-company operating-health ledger; refuses revenue/profit clear status without redacted first-customer, revenue, positive gross-profit, owner report/distribution, operating-control, and substrate-share refs. |
| `holding-company-peer-coach.schema.json` | ZestStream holding-company NURTURE peer-coach ledger; refuses eligible/active status without Tier 2+ owner, sustainable cash, operating-control, peer-coach agreement, and 5% equity grant refs. |
| `holding-company-owner-economics.schema.json` | ZestStream holding-company owner-economics ledger; refuses signed/active deal clearance without 25% owner equity, 45-75% tiered owner distributions, owner/cap-table/distribution/legal refs, and substrate-share proof. |
| `holding-company-shared-stack.schema.json` | ZestStream holding-company NURTURE shared-stack ledger; refuses clear status unless SkillOS, flywheel, JSM, `@zeststream/*` packages, and brand voice all have present receipt refs. |
| `holding-company-recycle-loop.schema.json` | ZestStream holding-company RECYCLE ledger; refuses propagated friction clearance without friction, SkillOS capability, package/substrate, and portfolio propagation refs inside the configured window. |
| `agent-security-control.schema.json` | JSON Schema contract for `agent-security-control/v1` security-control receipts. |
| `fixtures/pass/*.json` | Receipts that must validate. |
| `fixtures/fail/*.json` | Receipts that must be rejected with deterministic JSON errors. |
| `fixtures/dispatch-template/*.md` | Valid and invalid dispatch-packet fixtures for B02. |

## Agent Security Control

`agent-security-control/v1` defines the sandbox-only security contract for
fleet agent settings: the canonical deny template path, path denies, redacted
Bash output policy, synthetic fixture policy, doctor signals, issuance metadata,
and rollback guard. The canonical deny template lives at
`.flywheel/security/v1/claude-settings-deny.json`.

Temporary exceptions must use the `canonical-security-allow` token with owner,
reason, expiry, risk acknowledgement, tracking bead, and exact path or command
scope. Wildcard and parent-directory exceptions are intentionally outside the
v1 contract.

Run:

```bash
python3 -m json.tool .flywheel/validation-schema/v1/agent-security-control.schema.json >/dev/null
jq -e '.properties.schema_version.const == "agent-security-control/v1"' .flywheel/validation-schema/v1/agent-security-control.schema.json
python3 -m json.tool .flywheel/security/v1/claude-settings-deny.json >/dev/null
jq -e '.permissions.deny | length >= 20' .flywheel/security/v1/claude-settings-deny.json
```

## The Zest Ledger - Part of the Yuzu Method framework by ZestStream.

The Zest Ledger is the append-only JSONL stock ledger for wire-or-explain work.
It uses schema name `flywheel.wire-or-explain.v1` and canonical runtime path
`~/.local/state/flywheel/wire-or-explain-ledger.jsonl`.

The ledger encodes the L110 primitive: every durable observation/finding/artifact must declare its stock, class, consumer or explicit deferral, owner, action ledger, verification probe, and tick/status consequence.

Rows include `sequence_num`, `prev_hash`, and `checksum` so chain verification can
detect tampering without printing payload data. Duplicate event identity keys are
idempotent: the writer emits a duplicate receipt and does not create a second
active row.

Run:

```bash
bash .flywheel/scripts/wire-or-explain-ledger-writer.sh --info --json
bash .flywheel/scripts/wire-or-explain-ledger-writer.sh --row tests/fixtures/wire-or-explain-ledger/valid-wired.json --ledger /tmp/wire-or-explain-ledger.jsonl --json
bash .flywheel/scripts/wire-or-explain-chain-verifier.sh --ledger /tmp/wire-or-explain-ledger.jsonl --json
bash tests/wire-or-explain-ledger.sh
```

## Parser

Run:

```bash
bash .flywheel/validation-schema/v1/parse.sh .flywheel/validation-schema/v1/fixtures/pass/*.json
bash .flywheel/validation-schema/v1/parse.sh .flywheel/validation-schema/v1/fixtures/fail/*.json
```

Exit codes:

| code | meaning |
|---:|---|
| 0 | every supplied receipt is valid |
| 1 | at least one supplied receipt is invalid |
| 2 | usage error |

The parser emits JSON with stable keys: `schema`, `valid`, `files_checked`, `results[]`, and `errors[]`. Error rows are sorted by file, code, and message.

## Dispatch Template Audit

B02 adds a required `VALIDATION BLOCK` to the shared worker dispatch template at
`/Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md`. The audit
checks that a packet or template includes the validation schema/parser refs,
callback fields, Agent Mail reservation/release instructions, L52/L53 receipts,
L70 chain fields, agent-context proof, and the orchestrator-side
`validate-callback` step.

Run:

```bash
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh /Users/josh/.claude/commands/flywheel/_shared/dispatch-template.md
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh .flywheel/validation-schema/v1/fixtures/dispatch-template/valid-*.md
bash .flywheel/validation-schema/v1/dispatch-template-audit.sh .flywheel/validation-schema/v1/fixtures/dispatch-template/invalid-*.md
```

The first two commands must exit 0. The invalid fixture command must exit 1
with deterministic JSON errors.

## Required Fields And 3-Q Mapping

| field | purpose | Q1 validated | Q2 documented | Q3 surfaced |
|---|---|---|---|---|
| `schema_version` | Pins this contract to `validation-receipt/v1`. | Parser rejects wrong versions. | This README and `schema.json`. | Canonical path is registered in `.flywheel/canonical-paths.txt`. |
| `dispatch_id` | Connects receipt to the dispatched work. | Non-empty id required. | Used by B02/B03 dispatch docs. | Can be routed into dispatch logs and learn ledgers. |
| `callback_ref` | Records callback transport, session, pane, kind, timestamp, and raw ref. | Parser rejects malformed refs. | Transport/kind enums in schema. | Lets orchestrator trace the callback source. |
| `status` | Validation verdict: `pass`, `fail`, or `unknown` only. | Parser rejects any other value. | Enum documented in schema. | Downstream doctor/tick can count pass/fail/unknown. |
| `failure_class` | Canonical single-class routing value. | Parser rejects unknown enum values and flaky retry policies for correctness/invalid callbacks. | Taxonomy table below. | Doctor, dispatch logs, and validators can route without prose parsing. |
| `retry_policy` | Deterministic retry behavior: `none`, `exponential`, `manual`, or `permanent`. | Parser rejects transient/non-transient policy mismatches. | Taxonomy table below. | Prevents correctness regressions and invalid callbacks from becoming flakes. |
| `recovery_hint` | Operator-facing next action paired with the class. | Parser requires non-empty text. | Taxonomy table below. | Callback validators can emit repair guidance in JSON. |
| `failure_classes[]` | Names machine-actionable failures. | `fail` requires at least one; `pass` forbids them. | Class array documented in schema. | Feeds fix-bead, reopen, fuckup, and learn routing. |
| `evidence[]` | Typed proof references. | Parser checks type/ref shape and secret-like values. | Supported types listed below. | Durable refs are usable by B06/B07/B09. |
| `artifact_checks[]` | Checks claimed artifact paths and status. | `pass` cannot include missing artifacts. | Shape documented in schema. | Feeds missing-artifact doctor/reopen signals. |
| `runtime_context` | Separates agent context from orchestrator shell context. | Timeout/unresponsive maps to `unknown`; drift cannot pass. | L69 behavior encoded in README/schema. | Feeds `agent_context_probe_drift_count`. |
| `bead_actions[]` | Records bead filed/updated/no-bead/reopen decisions. | Weak `no_bead_reason` is rejected. | Action enum documented in schema. | Feeds L52 and auto-open/reopen logic. |
| `learn_route` | States how the event enters or skips `/flywheel:learn`. | Route and reason required. | Route enum documented in schema. | B09 uses it for exactly-once learning. |
| `chain_blocker` | Records next phase, capacity, and blocker reason. | Capacity plus next phase cannot silently pass without a blocker reason. | L70 behavior documented here. | Feeds `ticks_punted_count`. |

## Evidence Types

The schema supports the required typed references:

- `path`
- `command`
- `dispatch_log`
- `bead_id`
- `commit_sha`
- `transcript_hash`
- `joshua_confirmation_hash`

It also supports `fuckup_log` because L53 requires BLOCKED callbacks to surface a durable trauma row.

## Failure Taxonomy

Every validation receipt carries both the legacy detail list
`failure_classes[]` and the canonical routing triple:
`failure_class`, `retry_policy`, and `recovery_hint`.

| `failure_class` | Meaning | `retry_policy` | Recovery rule |
|---|---|---|---|
| `null` | Validation passed. | `none` | No recovery needed. |
| `transient` | Timeout or runtime unresponsive signal that may clear on bounded retry. | `exponential` | Retry once with bounded backoff; repeated hits become persistent substrate work. |
| `persistent` | Stable substrate condition such as locked DB, schema mismatch, or I/O failure. | `manual` | Repair substrate state before rerunning the receipt. |
| `correctness` | Test, assertion, L112, dependency, or implementation regression. | `permanent` | Fix code or graph; never classify as a flake. |
| `missing_artifact` | Claimed evidence or artifact path is absent. | `manual` | Restore/regenerate the artifact and rerun validation with the same path. |
| `invalid_callback` | Callback shape, schema, remediation, ecosystem, or request-linkage contract is invalid. | `manual` | Regenerate the callback with required fields and durable routing. |
| `context_drift` | Agent context and orchestrator shell context disagree. | `manual` | Reprobe both contexts before summary or integration. |
| `unknown` | No stable class exists yet. | `manual` | Preserve raw failure detail and add a taxonomy alias or migration-tested class. |

Doctor and validator JSON MUST expose `failure_class` directly. Consumers should
use `failure_class` for routing and keep `failure_classes[]` as detailed
evidence.

## Fixture Coverage

| fixture | directory | required class covered |
|---|---|---|
| `valid-done.json` | `pass` | valid DONE, typed artifact evidence |
| `runtime-unresponsive-unknown.json` | `pass` | runtime-unresponsive maps to `unknown`, never `pass` |
| `valid-no-bead-reason.json` | `pass` | valid no-bead reason |
| `missing-artifact-done.json` | `fail` | missing-artifact DONE cannot pass |
| `blocked-without-fuckup.json` | `fail` | BLOCKED without fuckup evidence |
| `context-drift-pass.json` | `fail` | context drift cannot pass |
| `invalid-no-bead-reason.json` | `fail` | weak no-bead reason |
| `closed-bead-missing-artifact.json` | `fail` | closed bead claim with missing artifact |
| `tick-punted.json` | `fail` | next phase with capacity and no chain blocker |
| `valid-claude-worker.md` | `dispatch-template` | valid Claude worker packet with validation block |
| `valid-codex-worker.md` | `dispatch-template` | valid Codex worker packet with validation block |
| `invalid-missing-validation-block.md` | `dispatch-template` | packet missing validation callback instructions |

## Safety

Fixtures use synthetic paths, hashes, command refs, transcript hashes, and Joshua-confirmation hashes. They do not include real secrets or real Agent Mail tokens. The parser also rejects common token-shaped fixture values.
