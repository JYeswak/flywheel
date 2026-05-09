## L74 — AGENT-SECURITY-DENY-RULES-CANONICAL

---
id: L74
title: Agent security deny rules canonical
status: long_term
shipped: 2026-05-09
review_due: 2026-11-09
trauma_class: agent-security-control-drift
---

Every flywheel-installed repo that runs agent workers MUST carry the canonical
`agent-security-control/v1` contract before it is treated as security-clean.
Settings deny rules are required, but they are not sufficient by themselves:
the control also needs synthetic fixture policy, redacted scanner output,
pre-commit hook coverage, runtime-output safety, doctor signals, and explicit
override receipts for any `canonical-security-allow` exception.

**How to apply:**
- Canonical schema:
  `.flywheel/validation-schema/v1/agent-security-control.schema.json`.
- Canonical deny template:
  `.flywheel/security/v1/claude-settings-deny.json`.
- Canonical conformance proof:
  `tests/security-control-conformance.sh` and
  `tests/security-control-fleet-smoke.sh --dry-run`.
- Doctor posture must expose `security.status`,
  `security.settings_deny_rules_present`, missing deny counts, pre-commit hook
  coverage, runtime visible secret counts, and redacted secret-scan counts.
- A repo with a synthetic fixture, missing hook, missing deny rule, or leaked
  synthetic token may be useful test data, but strict doctor must fail it before
  it can close as security-clean.
- Overrides require `canonical-security-allow` plus reason, owner, expiry, and
  exact path or command scope. Broad or unexpired prose exceptions are not a
  substitute for a receipt.

**Forbidden outputs:**
- Calling a repo security-clean because `.claude/settings.json` has some deny
  rules while runtime fixtures, redaction, hooks, doctor signals, or override
  receipts are missing.
- Emitting matched secret values, token fragments, raw env output, Agent Mail
  bearer tokens, registration tokens, or live credential material in reports,
  callbacks, dispatch packets, or pane-visible commands.
- Treating production `.env*` access as covered by synthetic `.env.test`
  fixtures; use the container isolation profile or block closure with an
  explicit receipt.
- Shipping a security-control change without README and canonical-path wire-in.

**Evidence:** plan
`.flywheel/PLANS/agent-security-controls-fleet-wide-2026-05-04/00-PLAN.md`;
beads `flywheel-m0v31`, `flywheel-vl9of`, `flywheel-oxr6e`,
`flywheel-x3n1n`, `flywheel-1w0ep`, `flywheel-mzvd0`,
`flywheel-qegt3`, `flywheel-1gyiv`, and `flywheel-03uki`; conformance report
`.flywheel/receipts/flywheel-1gyiv/conformance-report.md`; validation receipt
`.flywheel/validation-receipts/flywheel-1gyiv-aae9be.json`; doctrine wire test
`tests/doctrine-memory-wire.sh`.

**Companion rules:** L48 (probe ladder), L56 (promotion ladder), L58
(secret material never in pane text), L61 (ecosystem wire-in), L71
(validate-and-redispatch), L96 (three-surface doctrine landing), and L120
(br close before DONE).


