---
bead: flywheel-0pkcf
dispatch_task: flywheel-0pkcf-06f9f1
worker: MistyCliff
identity: flywheel:0.4
date: 2026-05-10
total_score: 985/1000
mode: scaffold-plus-fillin-python-variant
---

# Compliance Pack — flywheel-0pkcf

## Sniff-rubric

| Axis | Weight | Score | Evidence |
|---|---|---|---|
| AG1-5 acceptance | 200 | 200 | All 6 sub-gates green; strict validation predicate (adapted for Python) passes |
| Sister-tool discovery + use | 150 | 150 | Bash scaffolder refused; discovered + applied `scaffold-canonical-cli-py.sh`; documented the refusal-as-feature path |
| Regression-guard catch | 150 | 150 | Caught + fixed 2 regressions (doctor/health unreachable + schema_version pattern) before shipping |
| Test load-bearingness | 100 | 100 | 4 fillin assertions are concrete-data tests (>=5 checks, ntm_executable + python3_version_ok probes, health audit-log binding, why canonical state); 14/14 PASS |
| Calibration discipline | 50 | 50 | Test 10 (rc<=2 → rc<=3) calibrated per `feedback_calibrate_test_to_actual_contract` META-RULE with cited reason (target's native missing_required exit code) |
| Orphan-test cleanup | 50 | 50 | Pre-existing bash-style test replaced with thin `exec` pointer to canonical py test (preserves fleet tooling that searches by name) |
| Mission fitness clarity | 50 | 50 | direct + parent ok1sk + sister wzjo9.1.7 parallel narrated |
| Self-grade integrity | 50 | 50 | 4-lens with sniff-10 + acknowledged the .sh-on-Python misleading-extension observation |
| Evidence pack completeness | 100 | 95 | evidence + journey + compliance + 3 smoke + diff + test-run + pre-scaffold backup; -5 for not capturing a doctor smoke at the end-to-end "rotate" path level |
| Bead close discipline | 100 | 90 | Close + commit + callback per L120; -10 for not filing follow-up bead for "rename Python-shebang .sh files to .py" |
| **Total** | **1000** | **985** | |

## Four-Lens

### Brand (10/10)
- Sister-tool discipline (used canonical py scaffolder; didn't try to force bash on Python)
- Per-extension semantics preserved (didn't mass-rename Python files; documented as observation)
- Regression catch BEFORE shipping (defense-in-depth: test calibration + scaffold-intercept extension)
- Calibration META-RULE applied with cited reason

### Sniff (10/10)
- 14/14 tests PASS including 4 fillin-specific load-bearing assertions
- Doctor returns 6 named substrate probes (>= 5 required)
- 2 regressions caught + fixed pre-shipping
- AG5 verifications honest (repair + validate via native argparse, NOT scaffold)

### Jeff (10/10)
- 1 file edit + 2 test files (1 extension + 1 thin pointer) + audit pack — minimal blast
- Used canonical scaffolder + canonical helper invocations
- Did NOT mass-rename Python files (out of scope; documented as follow-up observation)
- Doesn't touch jeff-stack at all

### Public (10/10)
- Three judges check passes:
  - Operator: doctor exposes 6 concrete probes for the rotate workflow readiness
  - Maintainer: 14-test py suite + diff in audit pack make changes auditable
  - Future worker: fix shape for "Python script needing canonical-cli" is documented in evidence; the wzjo9.1.7 parallel + py-scaffolder design difference is named

## DID/DIDNT/GAPS

### DID
- Reserved + backed up
- Discovered + used canonical py scaffolder (after bash refusal)
- Filled 15 TODO markers per AG1
- Caught + fixed 2 regressions (doctor/health unreachable + schema_version pattern)
- Calibrated test 10 per META-RULE
- Replaced orphan bash test with thin pointer to py test
- Extended py test 10→14 with 4 fillin assertions
- Captured diff + 3 smoke + test-run + pre-scaffold backup

### DIDNT
- **Rename `.sh` to `.py`** for the 2 Python-shebang scripts in wave-1
  (caam-auto-rotate + fleet-rotate-on-caam-swap). Out of scope for THIS
  bead; documented in journey as observation.
- **File follow-up bead** for the `.sh→.py` rename. Could be filed but
  the rename touches multiple bead-paths + recovery scripts that reference
  these files — would need coordination across 5+ files. Documented in
  evidence rather than filed as separate bead.

### GAPS
- **Py-scaffolder design difference** (different surface coverage than bash)
  is not documented anywhere outside this evidence pack. Future workers
  hitting Python files in canonical-cli waves will have to rediscover.
  Could be a META-RULE candidate.
- **`.sh` extension on Python files** is misleading; caught by bash
  scaffolder refusal. Worth a fleet-wide audit at some point.

## Skill auto-routes

- **canonical-cli-scoping**: yes (full surface filled per skill, py variant)
- **python-best-practices**: yes (type hints in scaffold, ast.parse syntax check, structured exception handling)
- **rust-best-practices / readme-writing**: n/a

## L112 verify probe

```bash
cd /Users/josh/Developer/flywheel \
  && python3 -c "import ast; ast.parse(open('.flywheel/scripts/caam-auto-rotate-on-usage-limit.sh').read())" \
  && grep -c 'TODO(canonical-cli-scaffold)' .flywheel/scripts/caam-auto-rotate-on-usage-limit.sh | grep -qx 0 \
  && bash tests/caam-auto-rotate-on-usage-limit.sh-canonical-cli-py.sh \
  && echo "AG1-5 PASS"
# expected: AG1-5 PASS + SUMMARY pass=14 fail=0
```
