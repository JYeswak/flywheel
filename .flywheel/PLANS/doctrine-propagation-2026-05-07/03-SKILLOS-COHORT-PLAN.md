---
title: "skillos doctrine cohort plan"
type: plan
created: 2026-05-08
frontmatter_source: scaffold-doc-frontmatter
---

# skillos doctrine cohort plan

Bead: `flywheel-rdqc7`
Target: `/Users/josh/Developer/skillos`
Origin: `doctrine-propagation-2026-05-07`
Source receipt: `01-VERIFY-PASS.json`

## Summary

`01-VERIFY-PASS.json` reports skillos at `status=DRIFT`, proposed version
`2026-05-07.L126`, and `missing_l_rules_count=75`. The drift is asymmetric:
`/Users/josh/Developer/skillos/.flywheel/AGENTS-CANONICAL.md` exists and is
missing 9 recent rules, while `/Users/josh/Developer/skillos/AGENTS.md` is
absent in the receipt and therefore accounts for all 75 missing rules.

This plan does not apply doctrine. It defines a four-wave review/apply protocol
that prevents a 75-rule bulk mutation and gives `skillos:1` veto authority at
every wave boundary.

## Tool Precondition

Current command surface:

```bash
/Users/josh/.local/bin/flywheel-doctrine-sync --help
```

It supports `--target-repo`, `--dry-run|--apply`, `--idempotency-key`, and
`--json`, but no per-rule allowlist. A plain `--apply` would append all missing
rules and violate this bead's hard rule.

Gap filed: `flywheel-rdqc7.1`

Required before Wave 1 apply: add a per-rule allowlist such as
`--l-rules L29,L35,L48,...` or an equivalent wave-plan input. Until that exists,
only dry-runs and review handoffs are allowed.

## Wave 1: Foundation

Rules: `L29`, `L35`, `L48`, `L50`, `L51`, `L52`, `L53`, `L54`, `L55`, `L56`,
`L57`.

Count: 11. Requested range was `L48-L57`; `L49` is not present in the
verify-pass missing list.

Agent Mail handoff subject:
`[doctrine-prop wave 1] skillos foundation L-rule conflict review`

Apply idempotency key:
`skillos-doctrine-20260507-L126-wave1-foundation`

Apply gate:
`skillos:1` must ack conflict review first. Any individual veto becomes a
documented deferral; flywheel never overrides a local skillos doctrine conflict.

Post-apply verification:

- `flywheel-doctrine-sync --target-repo /Users/josh/Developer/skillos --dry-run --json`
  no longer reports Wave 1 rules in the relevant missing surface.
- `skillos:1` confirms no local conflict on its next tick.
- Wave 1 compliance pack exists.

## Wave 2: Substrate

Rules: `L58`, `L59`, `L60`, `L61`, `L62`, `L63`, `L64`, `L65`, `L66`, `L67`,
`L68`, `L69`, `L70`, `L71`, `L72`, `L73`.

Count: 16.

Agent Mail handoff subject:
`[doctrine-prop wave 2] skillos substrate L-rule conflict review`

Apply idempotency key:
`skillos-doctrine-20260507-L126-wave2-substrate`

Post-apply verification:

- L107 shared-surface reservation is clean.
- `canonical-meta-rules-sync` three-surface watchdog passes.
- `skillos:1` confirms no substrate conflict.
- Wave 2 compliance pack exists.

## Wave 3: Recovery and Dispatch

Rules: `L75` through `L99`.

Count: 25.

Agent Mail handoff subject:
`[doctrine-prop wave 3] skillos recovery+dispatch L-rule conflict review`

Apply idempotency key:
`skillos-doctrine-20260507-L126-wave3-recovery-dispatch`

Post-apply verification:

- Dispatch callback contract remains valid for skillos.
- Three-surface watchdog passes.
- `skillos:1` confirms no dispatch doctrine conflict.
- Wave 3 compliance pack exists.

## Wave 4: Recent

Rules: `L100`, `L101`, `L102`, `L103`, `L104`, `L105`, `L106`, `L107`, `L108`,
`L110`, `L111`, `L115`, `L116`, `L117`, `L118`, `L119`, `L120`, `L121`,
`L122`, `L123`, `L124`, `L125`, `L126`.

Count: 23.

Agent Mail handoff subject:
`[doctrine-prop wave 4] skillos recent L-rule conflict review`

Apply idempotency key:
`skillos-doctrine-20260507-L126-wave4-recent`

Post-apply verification:

- `skillos` doctrine_version stamps `2026-05-07.L126`.
- L125 and L126 are present on required skillos surfaces.
- `skillos:1` confirms no conflict on its next tick.
- Wave 4 compliance pack exists.

## Agent Mail Handoff Template

```text
to: skillos:1
subject: <wave agent_mail_subject>

Please review the attached L-rule wave before flywheel runs doctrine-sync apply.
Target repo: /Users/josh/Developer/skillos
Wave: <N>
Rules: <comma-separated L-rule ids>
Apply idempotency key: <wave key>

Please reply ACK with:
- accepted_rules=<ids>
- vetoed_rules=<ids-or-none>
- veto_reasons=<id:reason-or-none>
- local_conflicts=<summary-or-none>
- post_apply_verification_owner=skillos:1

No flywheel apply will run until this ACK lands.
```

## Compliance Pack Contract

Each wave gets its own pack:

```text
.flywheel/PLANS/doctrine-propagation-2026-05-07/compliance/skillos-wave-<N>/
  spec.json
  evidence.json
  compliance.json
  theater.json
  test_depth.json
  scorecard.md
  REPORT.md
```

This closeout includes a plan-level pack at
`.flywheel/PLANS/doctrine-propagation-2026-05-07/compliance/flywheel-rdqc7/`.

## Final Success Criteria

- All four waves have skillos ACK before apply.
- Each wave uses a distinct idempotency key.
- Any vetoed rule has a documented deferral.
- L107 and the three-surface watchdog pass after each wave.
- Final skillos doctrine_version is `2026-05-07.L126`.

## Validation

```bash
python3 - <<'PY'
import json
from pathlib import Path
plan = json.loads(Path('.flywheel/PLANS/doctrine-propagation-2026-05-07/03-SKILLOS-COHORT-PLAN.json').read_text())
assert plan['missing_l_rules_total'] == 75
assert len(plan['waves']) == 4
assert sum(w['count'] for w in plan['waves']) == 75
assert plan['hard_rules']['bulk_apply_allowed'] is False
assert all(w['handoff_required'] and w['apply_requires_ack'] for w in plan['waves'])
assert len({w['apply_idempotency_key'] for w in plan['waves']}) == 4
assert plan['tool_precondition']['gap_bead'] == 'flywheel-rdqc7.1'
print('skillos cohort plan validation PASS')
PY
```

Result: PASS.

## Close Receipt

- AG1: Plan artifact and compliance pack created.
- AG2: JSON validator command passes.
- AG3: `br show flywheel-rdqc7` stayed open until this artifact existed.

Mission fitness: adjacent; this directly supports safe doctrine propagation for
continuous orchestrator uptime without overwhelming a peer orchestrator.
