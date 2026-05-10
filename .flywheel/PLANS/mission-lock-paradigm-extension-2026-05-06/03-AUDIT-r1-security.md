---
title: "Phase 3 Audit r1: Security Negative Invariants"
type: plan
created: 2026-05-06
frontmatter_source: scaffold-doc-frontmatter
---

# Phase 3 Audit r1: Security Negative Invariants

task_id: phase3-audit-security-negative-invariants-2026-05-06
parent_bead: flywheel-plan-mission-lock-paradigm-extension-2026-05-06
lens: security-negative-invariants
auditor: MagentaPond
created_at: 2026-05-06T14:21:00Z
scope: plan-space-only
socraticode_queries: 10
indexed_chunks_observed: 965

## 1. Problem Restatement

The r4 mission-lock paradigm extension is stable enough for Phase 3 audit, but
the security lens must prove the plan's negative invariants prevent false launch
confidence on credential, auth, secret, Agent Mail, skill-routing, and
cross-orchestrator trust surfaces.

The audit question is not "does the implementation currently leak secrets?"
There is no implementation in this plan-space artifact. The question is whether
the proposed mission-lock, dispatch-author, and close-validator contracts make
unsafe security states impossible to mark as ready.

## 2. Inputs Consumed

- `02-REFINE-r4.md`: r4 freezes the producer/consumer split and recommends
  this lens as Phase 3 audit input.
- `02-REFINE-r1.md`: defines the three gates, initial negative invariants,
  readiness doctor, dispatch-author, and close-validator contracts.
- `02-REFINE-r2.md`: adds skill suite injection, bead-class defaults, skill
  discovery receipts, and skillos coordination.
- `02-REFINE-r3.md`: resolves open questions, sets minimal-mode skip receipts,
  owns `/flywheel:dispatch` authority, and preserves skillos routing.
- `STATE.json`: confirms `convergence_streak=2`,
  `phase3_audit_eligible=true`, and three audit lenses.
- `AGENTS.md` L58: secret material never in pane text, dispatch packets,
  callbacks, reports, copied transcript evidence, or doctrine examples.
- `AGENTS.md` L92: audit findings route by data; critical/high findings create
  mitigation beads, not unscored Joshua pauses.
- Skills reviewed: `security-audit-for-saas`, `jeff-convergence-audit`,
  `donella-meadows-systems-thinking`, `socraticode`, and
  `codebase-archaeology`.
- Skill catalog routes checked for credential/auth/security surfaces:
  `cloudflare-api`, `infisical-secrets`, `mcp-secret-scanner`,
  `supabase-api`, `cryptography-and-auth`, `saas-cli-auth-flow`,
  `infisical-rotation-ops`, `security-audit-for-saas`,
  `security-review`, and `authentication-authorization`.

## 3. Lens Criteria

This lens grades the plan against these security-negative invariants:

1. Mission-lock MUST declare security-sensitive surfaces before implementation.
2. Dispatch packets MUST never carry secret values, token fragments, raw env
   dumps, private keys, bearer tokens, or Agent Mail registration tokens.
3. Credential-touching skill routes MUST require safe wrappers or structured
   secret sinks and MUST distinguish secret names from secret values.
4. Close-validator MUST be able to reject unsafe evidence, but MUST NOT mutate
   credential stores, rotate credentials, or overwrite auth configuration.
5. Cross-orchestrator coordination with skillos and peer sessions MUST exchange
   schema, aliases, receipts, and findings only; it MUST NOT exchange secret
   values or customer-private evidence.
6. Missing security negative invariants on an auth, credential, PII, or trust
   surface MUST block readiness for that surface, even if legacy audit-only mode
   would otherwise allow work to continue.
7. Evidence and receipts MUST be scrubbed enough that pane capture, INCIDENTS,
   bead JSONL, and callbacks can be copied without propagating secret material.

## 4. Findings Table

| ID | Severity | Finding | Evidence | Required Amendment |
|---|---:|---|---|---|
| SEC-001 | high | Dispatch-author has a skill and load-bearing contract, but no explicit packet-level ban on credential-shaped payloads. | r1 requires skill application and load-bearing classification; r2 injects skill suites; L58 forbids secret material in dispatch packets. | Add a dispatch template invariant: packets may name secret classes, secret keys, vault paths, and safe helper commands only; they may never include secret values, token fragments, raw env output, or Agent Mail bearer/registration tokens. |
| SEC-002 | medium | Credential-touching skill receipts do not yet carry a safe-execution marker. | r2 routes `infisical-secrets`, `infisical-rotation-ops`, `supabase-api`, `cloudflare-api`, and related skills; r3 requires `skill_receipts[]`. | Extend `skill_receipts[]` with `credential_touch`, `secret_value_allowed=false`, `safe_wrapper`, and `joshua_explicit_rotation_approval` when rotation/destructive credential work is involved. |
| SEC-003 | medium | Skillos coordination is schema-oriented, but the trust boundary is implicit rather than a negative invariant. | r2 defines skillos API/manifest touchpoint; r4 assigns skillos ownership of taxonomy, aliases, and templates. | Add a cross-orch invariant: skillos receives skill names, aliases, templates, route health, and redacted evidence only; it never receives repo secret values, customer data, raw pane captures, or env dumps. |
| SEC-004 | medium | Close-validator authority is strong enough to reject closure, but its credential immutability boundary is not explicit. | r1 gives close-validator independent evidence joins; r3 makes skill receipts validator input. | Add a validator invariant: close-validator may fail closure, open/update beads, and demand receipts, but may not rotate tokens, edit `.env`/MCP secret config, write vault values, or mark credential repair complete from pane text. |
| SEC-005 | medium | Mission-lock negative invariants mention raw secrets, but not least-privilege principal boundaries per surface. | r1 requires negative invariants and data lifecycle, and classifies credentials/auth/PII as load-bearing. | Add per-surface auth metadata: secret source of truth, principal type, allowed operations, forbidden principals, and whether service-role/admin credentials are ever permitted. |
| SEC-006 | low | Legacy audit-only continuation can be misread as safe on touched auth/credential/trust surfaces. | r1 fail-soft legacy chain allows continuation when dispatch-author proves touched surface is not blocked. | Clarify that missing negative invariants on touched auth, credential, PII, or customer-trust surfaces default to blocked readiness until Phase 0 scaffolding or a no-touch proof exists. |

findings_count: 6
critical: 0
high: 1
medium: 4
low: 1

## 5. Negative-Invariant Violations

These are not observed runtime violations. They are plan-coverage violations:

- Missing packet-level secret-value ban in the dispatch-author template.
- Missing `credential_touch` and safe-wrapper fields in skill receipt shape.
- Missing explicit "skillos never receives secrets/customer-private evidence"
  trust boundary.
- Missing close-validator credential-store immutability rule.
- Missing per-surface least-privilege principal declaration.
- Missing blocked-readiness rule for touched security surfaces when negative
  invariants are absent.

## 6. Required Plan Amendment Or No-Op

Required r5/Phase 4 amendments:

1. Add a `security_negative_invariants` section to mission-lock output with
   per-surface auth, credential, PII, and customer-trust invariants.
2. Add dispatch template fields:
   `secret_values_allowed=false`, `credential_touch`, `safe_wrapper_required`,
   `redaction_required`, and `no_raw_pane_secret_evidence`.
3. Add `skill_receipts[]` security fields:
   `credential_touch`, `safe_wrapper`, `secret_value_allowed`, and
   `rotation_approval_source`.
4. Add cross-orch transfer limits for skillos and peer orchestrators:
   schema/alias/template/redacted-evidence only.
5. Add close-validator forbidden actions:
   no credential rotation, no secret-store writes, no `.env` or MCP secret
   config overwrite, and no closure from unsanitized pane evidence.
6. Add legacy-mode rule:
   touched auth/credential/PII/customer-trust surfaces without negative
   invariants block readiness by default.

No runtime code mutation is required by this lens. These amendments belong in
the next plan/refine artifact or Phase 4 implementation bead set.

## 7. Verdict

audit_disposition: auto_advance
critical_findings: 0
high_findings: 1
phase3_security_lens_green_light: true

This lens does not find a critical blocker or a true Joshua-blocker class. The
plan is safe to continue through Phase 3 with the amendments above routed as
mechanical mitigation requirements. The high finding is packet-level secret
hygiene, already governed by L58; the plan needs to make that invariant
first-class in mission-lock and dispatch-author outputs before implementation.
