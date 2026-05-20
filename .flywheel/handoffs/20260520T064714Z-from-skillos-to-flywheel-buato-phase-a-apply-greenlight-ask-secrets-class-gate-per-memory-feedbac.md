# buato Phase A --apply GREENLIGHT ASK — secrets-class gate per memory feedback_secrets_class_skip_3_strike

**From:** skillos:1
**To:** flywheel
**Real-word prefix:** BUATO
**Mission anchor (sender):** `unknown`
**Companion plan:** none
**Posture:** RATIFICATION-REQUEST
**Block:** skillos-buato Phase A --apply gated on explicit Flywheel/Joshua greenlight
**Schema version:** `cross_orch_handoff.v1`

## TL;DR

SkillOS is asking Flywheel for an explicit greenlight before running the secrets-class Phase A `--apply` for `skillos-buato` against the six READY orchs.

This is a request to stage canonical files only. It does not run `ggshield`, does not enable hooks, and does not change any auto-sweep behavior.

## Dry-run evidence

Source commit: `f49e7963 chore(secrets): prep secret-load propagation [skillos-buato]`.

Latest `skillos-buato` dry-run result:

- Six READY orchs passed dry-run: `mobile-eats`, `picoz`, `clutterfreespaces`, `alpsinsurance`, `vrtx`, `terratitle`.
- Three payload files would be new in all six target repos:
  - `.flywheel/scripts/auto-push.sh`
  - `.flywheel/doctrine/auto-push-tier-4.5-secret-load-discipline.md`
  - `.flywheel/validation-schema/v1/auto_push_policy.schema.json`
- Existing `.flywheel/auto-push-policy.yaml` files are already present from `skillos-lnt5r`.
- Existing secret gate status is missing in all six target repos.
- GitGuardian marker counts are in the 0-2 range per orch: `mobile-eats=0`, `picoz=0`, `clutterfreespaces=0`, `alpsinsurance=1`, `vrtx=2`, `terratitle=1`.

## Secrets-class gate

Per memory `feedback_secrets_class_skip_3_strike_gate`, secrets-class trauma requires explicit Joshua-greenlight at N=1. That overrides the default 3-strike promotion posture.

Because `skillos-buato` is a secrets-class propagation, SkillOS is not treating the clean dry-run as apply authorization.

## Ask

Flywheel:1, please greenlight or reject:

- Should SkillOS execute `scripts/skillos_propagate_secret_load_discipline.sh --apply` against the six READY orchs?

Expected Phase A effect if approved:

- Creates the three NEW canonical files listed above in each of the six READY repos.
- Performs no overwrites.
- Does not run `ggshield`.
- Does not enable hooks.
- Does not enable auto-sweep.

## Scope boundary

Phase A `--apply` only stages canonical files needed for later secrets-class enforcement.

These remain separate Joshua-greenlight gates after Phase A:

- `ggshield` execution in each target repo.
- Hook enablement or any change that makes the secret-load gate active in normal workflow.
- Any claim that the 11-repo `skillos-buato` acceptance criteria are complete.

## Reciprocal commitment

If greenlit, SkillOS commits to the same post-apply notification pattern used for `skillos-96x73` and `skillos-lnt5r`:

- Rerun dry-run immediately before apply.
- Execute Phase A apply only for the six READY orchs.
- Verify target file SHAs and no-overwrite posture.
- Send per-orch post-apply STATUS handoffs naming the new files and the remaining non-enabled gates.
- Comment `skillos-buato` with the apply receipt and keep ggshield/hook enablement gated separately.
