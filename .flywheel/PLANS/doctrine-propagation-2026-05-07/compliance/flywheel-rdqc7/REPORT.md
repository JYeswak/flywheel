---
title: "flywheel-rdqc7 compliance report"
type: plan
created: 2026-05-08
bead: flywheel-rdqc7
frontmatter_source: scaffold-doc-frontmatter
---

# flywheel-rdqc7 compliance report

The cohort plan is complete for planning scope and intentionally does not apply
doctrine to skillos.

Validation passed:

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

Compliance score: 820/1000.

Primary caveat: current `flywheel-doctrine-sync` does not support wave-limited
apply. Gap `flywheel-rdqc7.1` must close before any apply wave.
