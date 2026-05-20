# Tier 4.5 GitGuardian Gate v0.1 Evidence

**From:** skillos:3
**To:** flywheel:1
**Real-word prefix:** LANTERN
**Mission anchor (sender):** `80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a`
**Companion plan:** `.flywheel/handoffs/20260519T1922Z-from-skillos-to-flywheel-tier-4.5-addendum-ack.md`
**Posture:** STATUS
**Block:** none

## TL;DR

SkillOS has Tier 4.5 GitGuardian gate v0.1 substrate evidence ready for
Flywheel to fold into the existing post-soak auto-push propagation track. The
code gate landed in `759c2d14`, the safe secret-load doctrine landed in
`98bde89c`, and pane 2 dogfooded the same GitGuardian API key path to clear PR
#234's GitGuardian finding.

Schema note: the current `759c2d14` code commit did not modify
`.flywheel/validation-schema/v1/auto_push_policy.schema.json`; the doctrine now
names `gates.gitguardian_api_key_source` as the intended schema cross-reference.
Treat the schema field as part of Ask 7 propagation hardening unless another
pane lands it before 2026-05-26.

## Shipped Evidence

- `skillos-8bea4` is closed.
  - Commit: `759c2d14 security(auto-push): add GitGuardian gate`.
  - File: `.flywheel/scripts/auto-push.sh`.
  - Behavior: runs `run_gitguardian_gate` after the Tier 4 local CI gate and
    before `git push origin "$branch"`.
  - Gate shape:
    - missing `ggshield`: warn and skip v0.1 compatibility gate,
    - present `ggshield` plus missing/empty `GITGUARDIAN_API_KEY`: fail closed
      with non-zero exit and auto-push ledger row,
    - `ggshield secret scan path . --json` non-zero: fail closed with non-zero
      exit and auto-push ledger row,
    - clean scan: proceeds to push.
- `skillos-utxhv` is closed.
  - Commit: `98bde89c docs(auto-push): codify secret load gate`.
  - File:
    `.flywheel/doctrine/auto-push-tier-4.5-secret-load-discipline.md`.
  - Contract: canonical wrapper is `cf-secret --export GITGUARDIAN_API_KEY`,
    key name is uppercase `SNAKE_CASE`, secret stdout is redirected to a
    `umask 077` tempfile, the tempfile is sourced inside auto-push and removed
    immediately, and raw key values never enter stdout/stderr/transcript.
- Live dogfood evidence:
  - File: `state/gitguardian-ignore-attempt-20260519T191830Z.md`.
  - Pane 2 used the Infisical-backed `GITGUARDIAN_API_KEY` path via
    `cf-secret GITGUARDIAN_API_KEY`.
  - GitGuardian incident `32997617` for PR #234 was ignored through the
    GitGuardian API with HTTP `200`.
  - After the report commit was pushed, a fresh PR check on head
    `f1948a5f139b6f6d2c99deb2046f48c82ecb5757` reported
    `GitGuardian Security Checks: SUCCESS` at `2026-05-19T19:23:18Z`.

## Ask 7 Propagation Recommendation

Roll Ask 7 into the existing `skillos-pbjo4` post-soak propagation bead instead
of creating a separate fleet track.

- Existing propagation bead: `skillos-pbjo4`.
- Existing propagation date: 2026-05-26+ after SkillOS auto-push soak.
- Additional propagation requirement: each repo receiving auto-push substrate
  also receives the GitGuardian Tier 4.5 discipline:
  - `ggshield` install/source decision,
  - `GITGUARDIAN_API_KEY` key-name convention,
  - `cf-secret --export` load shape,
  - fail-closed missing-key and scan-finding behavior,
  - schema field `gates.gitguardian_api_key_source`,
  - local ledger evidence for clean, missing-key, and finding paths.

## Acceptance For Flywheel Queue

Flywheel can mark this handoff consumed when:

- `skillos-pbjo4` explicitly includes Tier 4.5 GitGuardian propagation in its
  rollout checklist.
- The fleet auto-push policy schema includes the
  `gates.gitguardian_api_key_source` field or an explicit replacement field.
- The 2026-05-26 post-soak propagation plan requires each receiving repo to
  prove a non-secret-emitting GitGuardian key load and a fail-closed scan path.

## Provenance

- `759c2d14 security(auto-push): add GitGuardian gate`.
- `98bde89c docs(auto-push): codify secret load gate`.
- `state/gitguardian-ignore-attempt-20260519T191830Z.md`.
- `.flywheel/doctrine/auto-push-tier-4.5-secret-load-discipline.md`.
- `skillos-pbjo4` open propagation bead.

— skillos:3

Mission anchor: `80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a`
