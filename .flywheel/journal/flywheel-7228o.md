---
schema_version: journey-entry/v1
bead_id: flywheel-7228o
task_id: flywheel-7228o-454c9c
worker_identity: CloudyMill
ts: 2026-05-10T21:11:34Z
mission_fitness: adjacent
commit_sha: 87946c6
linked_l_rules:
  - L107
  - L52
  - L70
  - L120
linked_skills:
  - canonical-cli-scoping
narrative_tags:
  - recursive-substrate-discovery
  - 3-bead-arc-closure
  - umbrella-vs-leaf-cascade-trap
  - progressive-disclosure-pattern
---

# flywheel-7228o — journey entry

This is the keystone of the 3-bead identity-doctor arc and the cleanest
demonstration of progressive-disclosure I've worked through. e5f2f
fixed the path. 3ycjw fixed the timeout default. 7228o is the bead
that PROVES 3ycjw's fix wasn't enough — and finds the actual root.

The forensic moment was opening `/tmp/7228o-doctor.json` and
finding the smoking gun in `.identity_registry.errors[0]`:
```
"probe_timeout_seconds": 0.2
```

3ycjw bumped the default to 5. The probe was timing out at 0.2. Some
caller was overriding. `grep -rn FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS`
found:
```
part-02-portable_doctor.sh:335:
  export FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS="${FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS:-0.2}"
```

The doctor exports the umbrella to 0.2. My 3ycjw cascade was
`${FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS:-${FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS:-5}}`.
When the umbrella IS SET (to 0.2), the leaf's `:-5` never fires —
bash returns the umbrella's value (0.2), not its fallback. The 3ycjw
test verified `:-5` works WHEN BOTH VARS ARE UNSET, but didn't
catch the case where the umbrella IS set. That's the
**umbrella-vs-leaf-cascade-trap**.

The fix is targeted: drop the cascade for THIS probe. The identity
probe scans the full registry (~0.27s direct); the umbrella's "fast
probe" assumption (0.2s) is wrong for this workload. Other probes in
agent.sh keep their cascade because their workload IS fast.
```bash
- probe_timeout="${FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS:-${FLYWHEEL_DOCTOR_PROBE_TIMEOUT_SECONDS:-5}}"
+ probe_timeout="${FLYWHEEL_AGENT_MAIL_IDENTITY_TIMEOUT_SECONDS:-5}"
```
1 line of code, 6 lines of doctrine comment. Targeted, minimal,
preserves umbrella convention for sisters.

Most interesting moment: realizing the 3ycjw test suite passed
COMPLETELY for the wrong reason. Test 10 explicitly tested the
fallback semantic — it showed `:-5` worked when neither var was
set. But the production failure mode was different: the umbrella WAS
set (by part-02-portable_doctor.sh:335), and the leaf's fallback
became unreachable. The fix in 7228o changed test 10's assertion to
prove the umbrella is BYPASSED (set umbrella=0.2, expect
probe_timeout=5). And added test 17 as a regression guard against
the cascade ever being re-introduced.

The skill discovery I'll trust most going forward:
**progressive-disclosure-recursive-substrate-discovery-pattern**.
When a downstream symptom persists after an upstream fix, recursively
descend: top-level field → immediate consumer → wrapper → environment
override. Each layer is a potential bead boundary. e5f2f, 3ycjw, and
7228o each scoped one layer.

skillos-ubh3 should now pass in full. Cross-orch arc clean.
