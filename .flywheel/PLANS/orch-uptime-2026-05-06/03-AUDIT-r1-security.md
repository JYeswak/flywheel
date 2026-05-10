---
title: "Orchestrator Uptime Phase 3 Audit: Lens 1 Security"
type: plan
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# Orchestrator Uptime Phase 3 Audit: Lens 1 Security

task_id: orch-uptime-audit-lens1-security-2026-05-06
lens: security-negative-invariants
primary_input: .flywheel/plans/orch-uptime-2026-05-06/00-PLAN.md
dispatch_input: /tmp/dispatch_orch-uptime-audit-2026-05-06.md
scope: read-only plan audit
result: auto_advance_with_security_mitigations
socraticode_queries: 10
indexed_chunks_observed: 100

## Donella Trace

- Boundary: usage-limit detector -> credential-rotation authorization -> CAAM selector switch -> recovery ledger -> post-check.
- Stock: live orchestrator capacity, vaulted CAAM profiles, secret-free receipts, valid recovery rows, fresh topology for pane-touching recovery.
- Flow break audited: credential rotation can proceed without topology freshness, but must not widen into pane mutation, token creation, launchctl, or vault writes.
- Feedback loop: usage-limit signal -> scoped selector swap -> secret-free proof row -> next tick observes recovered capacity.
- Leverage: Meadows #5 rules for authorization scope and #6 information flows for redacted, schema-valid recovery evidence.
- Safety invariant: the plan may name profile selectors and safe helpers; it may not expose token values, auth file content, vault internals, or copied secret-bearing pane text.

## Inputs Read

- `.flywheel/plans/orch-uptime-2026-05-06/00-PLAN.md`
- `.flywheel/plans/orch-uptime-2026-05-06/01-RESEARCH-A.md`
- `.flywheel/validation-schema/v1/recovery-ledger.schema.json`
- `.flywheel/scripts/capacity-halt-pane-authorization.sh`
- `AGENTS.md` L58 and `.flywheel/MISSION.md` SEC-001..006 security invariants
- Prior security-negative-invariants precedent in `INCIDENTS.md`

## Skills Cited

- `agent-security`: independent authorization, action validation, credential management, secret hygiene.
- `caam`: account/profile switching through vaulted auth files; `activate`, `status`, `ls`.
- `coding-agent-usage-tracker`: quota/rate-limit automation must use JSON and avoid tight retry loops.
- `agent-monitoring`: recovery must be observable and doctor-visible.
- `rate-limiting`: repeated limit events need scoped idempotency, retry discipline, and clear reset behavior.
- `agent-orchestration`: no ad-hoc coordination; recovery fan-out must have tracked dependencies and failure handling.

## Socraticode Survey

1. `caam auto rotate usage limit profile selector token values auth file vault internals recovery primitive`
2. `capacity halt pane authorization recovery_class credential_rotation topology stale protected refusal`
3. `recovery ledger schema recovery_class profile_selector primitive_invoked required receipt fields`
4. `profile selector redacted profile names caam status list ls JSON schema stability unknown fields`
5. `allow unhealthy flag explicit operator action unhealthy profile caam recovery`
6. `security negative invariants secret_values_allowed credential_touch close validator token rotation vault writes`
7. `caam recovery path probe profiles health status unknown field redaction vault selector`
8. `codex usage limit detector caam_auto_rotate idempotency digest repeated usage limit legitimate rotation`
9. `authorization gate recovery class bypass must not authorize pane mutation launchctl vault writes`
10. `recovery doctor probe counts recovery_class credential_rotation post_check failure_class doctor metrics`

Key substrate hits:
- L58 forbids secret material in pane-visible text, dispatch packets, callbacks, reports, and copied transcript evidence.
- SEC-001..006 already encode no secret values, safe credential receipts, bounded close-validator authority, and per-surface principal metadata.
- Existing recovery-ledger schema requires `actor`, target, `pane_role`, `trauma_class`, `signal_text`, `decision_reason`, `budget_state`, `transport`, `post_check`, `failure_class`, and `primitive_invoked`.
- Existing `capacity-halt-pane-authorization.sh` currently refuses stale topology and non-worker panes; `credential_rotation` is therefore a high-sensitivity exception.

## Findings

| ID | Severity | Blocker class verdict | Finding | Required mitigation |
|---|---:|---|---|---|
| SEC-A1 | high | none-fire | `--recovery-class credential_rotation` bypasses topology freshness. That is correct only for vault-profile selection, but the Phase 4 implementation must prove the bypass cannot authorize pane input, respawn, launchctl, token rotation, OAuth refresh, or vault writes. | Gate on `tool=codex`, `recovery_class=credential_rotation`, and primitive name `caam-auto-rotate-on-usage-limit`. Emit `stale_topology_allowed=true` only with `authorized_operations=["caam_activate_existing_profile","caam_status_post_check","append_recovery_ledger"]` and `forbidden_operations` naming pane mutation, respawn, launchctl, new credential creation, token rotation, OAuth refresh, and vault write. |
| SEC-A2 | high | none-fire | Idempotency by `tool:session:pane:digest` can suppress a legitimate second recovery if the same usage-limit text recurs after a successful profile switch. That can strand the pane while returning `already_rotated_for_signal`. | Add active-profile context to the idempotency row: `limited_profile_before`, `selected_profile`, `post_check_active_profile`, and `rotated_at`. Treat the same digest as duplicate only when the active profile and selected profile match the prior success inside a bounded TTL. A changed active profile must create a new eligible key. |
| SEC-A3 | medium | none-fire | `caam list || caam ls || caam status` JSON parsing is called out, but schema stability is not guaranteed by the plan. Unknown fields could leak vault metadata if logged wholesale. | Parse only stable documented fields: profile `name`, `active`, `system`, `health/status`, and status active profile. Drop or redact unknown fields in result JSON and ledger rows. On parse failure, emit `failure_class=caam_schema_unrecognized` with redacted shape summary, not raw payload. |
| SEC-A4 | medium | none-fire | Adding `recovery_class` and `profile_selector` to `recovery-ledger.schema.json` is safe only if additive. Existing required receipt fields must remain required and cannot be replaced by CAAM-specific fields. | Keep `recovery_class` optional in v1. Keep `additionalProperties=true` unless a v2 migration is explicitly planned. Test that a CAAM row still requires every existing canonical field, especially `transport`, `post_check`, `failure_class`, and `primitive_invoked`. |
| SEC-A5 | medium | none-fire | `--allow-unhealthy` is allowed by Lane A research for critical/expired profiles, but the dispatch requires it never default on. It is dangerous in auto-recovery because it can switch into a known-bad credential state. | Default false. Refuse it during detector-driven `--auto-recover` unless an explicit operator flag and reason are present, for example `--allow-unhealthy --operator-ack <nonempty>`. Ledger must record `allow_unhealthy=true`, `operator_ack_present=true`, and candidate health. |
| SEC-A6 | low | none-fire | Profile names are selector labels, not token values, but current examples include email-shaped labels. These are acceptable operational selectors, yet reports and callbacks should avoid turning them into unnecessary PII. | Emit `profile_selector` with `from`, `to`, `tool`, `redacted`, and `selector_sha256`. Default reports to selector names only when needed; otherwise use stable hash plus `redacted=true`. Never print auth file paths beyond tool-level source labels. |

counts:
critical: 0
high: 2
medium: 3
low: 1

## Negative-Invariant Pass Matrix

| Invariant | Audit verdict | Notes |
|---|---|---|
| No token values/auth file content/vault internals in primitive output | pass_with_mitigation | Lane A states this directly. Add redacted unknown-field handling and selector hashing. |
| Idempotency does not poison legitimate rotation | needs_mitigation | Add profile context and TTL-aware duplicate logic. |
| CAAM JSON parsing avoids schema assumptions | needs_mitigation | Parse allowlisted fields only; redact unknowns. |
| Recovery-ledger additions do not bypass existing receipt requirements | pass_with_mitigation | Existing schema is strong; tests must prove required fields remain required. |
| `--allow-unhealthy` requires explicit operator action | needs_mitigation | Must be refused by default and in auto-recover without ack. |
| `credential_rotation` bypass is tightly scoped | pass_with_mitigation | The concept is sound because it is vault-selector-only; implementation must encode forbidden operations. |

## Joshua-Blocker Class Check

No critical finding maps to a true Joshua-blocker class.

- Class 1 new platform/vendor: none-fire. Existing codex, CAAM, NTM, launchd surfaces only.
- Class 2 secret rotation/new credential creation: none-fire under current plan. It would fire only if Phase 4 expands from existing-profile activation into OAuth refresh, token creation, vault writes, or live credential rotation.
- Class 3 financial commitment: none-fire.
- Class 4 legal/compliance decision: none-fire.
- Class 5 destructive irreversible shared-state mutation: none-fire if CAAM action is limited to reversible existing-profile activation plus append-only ledger.
- Class 6 paradigm conflict: none-fire. The plan reduces founder paging by recovering credential exhaustion autonomously.

## Required Phase 4 Acceptance Tests

- Fixture proves `credential_rotation` authorizes with stale topology but refuses any pane mutation, respawn, launchctl, token rotation, OAuth refresh, or vault-write operation.
- Fixture proves same `tool:session:pane:digest` after active-profile change is not treated as a duplicate success.
- Fixture proves raw CAAM output with unknown keys is redacted/dropped and never copied into primitive result or recovery ledger.
- Fixture proves `--allow-unhealthy` is false by default and refused for auto-recover unless explicit operator ack is present.
- Fixture proves CAAM recovery row fails schema validation when any pre-existing required recovery-ledger field is missing.
- Secret scan over the new script, fixtures, and `/tmp` report examples catches no token-shaped values, auth JSON content, or vault internals.

## Disposition

audit_disposition_recommended: auto_advance
self_grade: 9
reason: zero criticals; two high findings are mechanical scoping/idempotency requirements suitable for Phase 4 acceptance criteria.
read_only_audit: true
tests_run: none
caam_mutation: none
repo_mutation: none

L112: OK_orch_uptime_audit_lens1_complete

Mission-anchor: continuous-orchestrator-uptime-self-sustaining-fleet
