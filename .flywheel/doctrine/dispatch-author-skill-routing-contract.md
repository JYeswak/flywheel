---
title: "Dispatch Author Skill Routing Contract"
type: doctrine
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Dispatch Author Skill Routing Contract

Version: `dispatch-author-skill-routing-contract/v1`
Owner: `/flywheel:dispatch` packet author
Status: canonical Wave 2 contract, shipped 2026-05-06

This contract turns the Phase 2/3 skill-routing plan into dispatch-author data.
It consumes Wave 1 deliverables without mutating them:

- `.flywheel/scripts/dispatch-skill-router-collision-resolver.sh`
- `.flywheel/scripts/idempotency-replay-guard.sh`
- `.flywheel/scripts/mission-lock-negative-invariants-validator.sh`
- `.flywheel/validation-schema/v1/dispatch-receipt.schema.json`

## 1. Scope

Every non-trivial worker dispatch must include a `skill_routing` packet block or
a mechanically equivalent receipt that this contract can probe. The author owns
the send/no-send decision; planners may propose classes and skillos may publish
taxonomies, but the final packet must prove the route.

Tiny single-file or less-than-20-line changes may use `skill_floor_mode=minimal`.
Minimal mode still records `socraticode`, the exact domain skill, and an explicit
collapsed skip receipt for universal tokens that do not apply.

## 2. Deterministic Class Merge

Class detection inputs are merged in this order:

1. Bead labels and title tokens.
2. Touched file prefixes.
3. Mission-lock declared surfaces.
4. Socraticode hits against prior similar work.
5. Explicit worker-packet override with reason.

The packet records:

- `dispatch_class_merge_order`
- `collision_policy=resolved`
- `strictest_invariant_wins=true`
- `collisions[]`
- `notes[]`

When multiple classes fire, preserve input order, dedupe skills, apply the
strictest invariant, and keep collision receipts. The Wave 1 resolver's
`prompt_budget_policy` remains the canonical pruning policy.

## 3. Discovery Precedence

Discovery-source disagreement resolves in this exact order:

```text
exact:get_skill > local:SKILL.md-readable > semantic:socraticode > external:npx-skills-find-installable-only > fallback:rg-filesystem
```

External install discovery can suggest candidates, but cannot override an exact
local readable skill. A `blocked_no_source` route warns and forces local
`SKILL.md` read fallback when the file is readable; it blocks only when the
local skill cannot be read.

## 4. Required Overlays

Universal tokens must be represented by applied, alias, not-applicable, or skip
receipts:

- `canonical-cli-scoping`
- `readme-writing`
- `de-slopify`
- `simplify` aliasing to `code-simplifier` by default
- `socraticode`

Cross-cutting overlays trigger independently of bead class:

- `agent-mail`
- `agent-monitoring`
- `cost-attribution`
- `search-tool-routing-doctrine`

Security and credential tags additionally route through the Wave 1 negative
invariants validator's no-raw-secret policy.

## 5. Secret-Value Bans

Dispatch packets may name secret classes, key names, vault paths, and safe
helpers. They may not include secret values, token fragments, raw env output,
Agent Mail bearer tokens, registration tokens, private keys, or copied
secret-bearing pane text.

Required marker:

```text
secret_values_allowed=false
```

This closes SEC-001 and SEC-003 at the dispatch-author layer while preserving
the Wave 1 security validator as the mission-lock checker.

## 6. Route Receipts Schema

Route receipts use `dispatch-author-route-receipt/v1` and preserve the additive
dispatch receipt schema from Wave 1. Required fields:

- `skill_routing`
- `skill_receipts[]`
- `receipt_identity_key`
- `skill`
- `source`
- `action_taken`
- `policy_version`
- `evidence`
- `alias_of`
- `not_applicable_reason`
- `idempotency_key`
- `replay_detection_hash`
- `transaction_boundary`
- `receipt_completeness`

Naming a skill without receipt evidence is insufficient. Duplicate or replayed
packets must resolve through `idempotency-replay-guard.sh` before send.

### Live-substrate verification gate

Version or upgrade-class dispatches must prove their target was live-checked
before the packet was authored. The author applies the dispatch-time guard in
`feedback_jeff_substrate_version_drift.md`: probe the installed binary version,
probe upstream latest tag or release, and cite both numbers in the packet.

The dispatch-log row for any version or upgrade-class dispatch must emit:

- `live_state_verified_at: <iso-ts>`
- `live_state_evidence: <paths-or-command-receipt-refs>`

For Jeff-substrate upgrade packets, `live_state_evidence` must include both the
local installed-version probe and the upstream latest probe. If live installed
version is greater than or equal to the packet target, the author refuses to
dispatch, logs `dispatch-author-stale-version-target`, and closes or re-authors
from live evidence.

Validators that inspect `dispatch-log.jsonl` may refuse to count a version-class
dispatch as conformant when `live_state_verified_at` or `live_state_evidence`
is absent. Treat missing fields as a CSR-class extension: the packet may still
be visible as an attempted dispatch, but it does not satisfy the dispatch-author
contract until the live-state receipt exists.

## 7. Prompt-Budget Pruning

Default packet shape is skill names plus one-line reasons. Excerpts are reserved
for the primary one to three skills, policy-critical recovery sections, or cases
where the worker cannot read local skills. Excerpts are capped at the smaller of
25 percent of packet budget or 1200 tokens.

Pruning order:

1. Keep required skill names and receipt obligations.
2. Keep policy-critical excerpts.
3. Replace secondary excerpts with paths.
4. Move low-risk context to a receipt path or follow-up bead.

Budget overage is `verdict=partial`, not a silent pass. It must include a
pruning recommendation before dispatch can be rendered again.

## 8. Conformance Probe

`.flywheel/scripts/dispatch-author-contract-probe.sh` is the read-only probe for
this contract. It validates packet markers and emits:

```json
{
  "ts": "date-time",
  "dispatch_path": "path",
  "checks": {
    "deterministic_class_merge": {},
    "discovery_precedence": {},
    "required_overlays": {},
    "secret_value_bans": {},
    "route_receipts_schema": {},
    "prompt_budget_within_limit": {}
  },
  "verdict": "pass|partial|fail",
  "violations": []
}
```

The probe is intentionally narrower than the Wave 1 resolver. It checks packet
contract conformance and cites sibling tools; it does not recalculate the entire
skill graph.

## 9. Versioning

Version `v1` is append-only. Future versions may add optional fields, but may
not weaken:

- exact/local discovery precedence
- universal token representation
- `secret_values_allowed=false`
- route receipt identity and replay fields
- unresolved collision failure
- prompt-budget partial verdicts

Breaking changes require a new contract version, an INCIDENTS entry, and a
fixture in `.flywheel/tests/test_dispatch_author_contract_probe.sh`.
