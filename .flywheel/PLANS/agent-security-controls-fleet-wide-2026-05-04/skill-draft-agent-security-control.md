# Skill Draft: agent-security-control

Status: `draft_for_skillos_publication`
Owner: `skillos`
Origin bead: `flywheel-03uki`
Plan: `.flywheel/PLANS/agent-security-controls-fleet-wide-2026-05-04/00-PLAN.md`

## Purpose

Package the reusable practice for adopting `agent-security-control/v1` across
flywheel-installed repos without copying flywheel-specific implementation
details into every dispatch.

## When To Use

Use this skill when a worker, orchestrator, or repo install task touches agent
worker security posture, `.claude/settings.json` deny rules, synthetic secret
fixtures, redacted scanner reports, pre-commit secret hooks, runtime-output
redaction, container isolation for prod credentials, or
`canonical-security-allow` override receipts.

## Exact Pattern

1. Confirm the repo carries the canonical schema and deny template:
   `.flywheel/validation-schema/v1/agent-security-control.schema.json` and
   `.flywheel/security/v1/claude-settings-deny.json`.
2. Apply or validate `.claude/settings.json` deny rules from the canonical
   template; preserve local allow/ask rules.
3. Verify synthetic fixtures only use fake markers such as `CANARY_TEST_`,
   `FIXTURE_`, `SYNTHETIC_`, or `EXAMPLE_`.
4. Run the redacted scanner and assert raw matched values are not emitted.
5. Verify committed pre-commit secret hook coverage.
6. Run `flywheel-loop doctor --strict --repo <repo> --json` and check the
   `security` object.
7. For flywheel itself, run:

   ```bash
   bash tests/security-control-conformance.sh
   bash tests/security-control-fleet-smoke.sh --dry-run
   ```

## Anti-Patterns

- Treating deny rules as complete without fixture, scanner, hook, doctor, and
  override evidence.
- Printing matched secret values or token fragments in callbacks, evidence, or
  dispatch packets.
- Using synthetic `.env.test` proof to justify production `.env*` access.
- Accepting broad or non-expiring security exceptions instead of
  `canonical-security-allow` receipts with owner, reason, expiry, and exact
  scope.

## Tests And Fixtures

- `tests/security-control-conformance.sh`
- `tests/security-control-fleet-smoke.sh --dry-run`
- `tests/doctor-security-posture.sh`
- `tests/security-settings-propagation.sh`
- `tests/security-precommit-hook.sh`
- `tests/security-env-test-runtime.sh`
- `tests/security-container-isolation.sh`

## Publication Notes

This is a plan-local draft. Skillos owns final skill publication and may split
repo-specific command examples from the general agent-security practice during
publication.
