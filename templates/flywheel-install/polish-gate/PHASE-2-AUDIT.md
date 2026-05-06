# Phase 2 Audit Verdict

audit_ts: 2026-05-05T23:50:38Z
auditor_pane: flywheel:2
auditor_orch: codex
bead: flywheel-p2-12
socraticode_queries: 12
indexed_chunks_observed: 905
scope: audit-only; no P2-01..P2-11 surface mutation

## Phase 2 bead inventory

Audited 11 Phase 2 implementation surfaces from P2-01 through P2-11. The live
test surface passes, but Beads SQLite is malformed, so P2-12 and audit findings
were filed through JSONL fallback. JSONL inventory has 9 closed P2 rows by
`phase2-p2-*` title, P2-11 still `in_progress`, and no discoverable P2-07 close
row. That receipt drift is tracked as `flywheel-p2-12-f4`.

| P2 | Bead ID | Surface | Status evidence |
|---|---|---|---|
| P2-01 | flywheel-4h6c8 | Manifest and core schemas | closed; `templates/flywheel-install/polish-gate/v1/manifest.schema.json:1` |
| P2-02 | flywheel-3uaa5 | Surface discovery | closed; `templates/flywheel-install/polish-gate/discover-surfaces.py:11` |
| P2-03 | flywheel-3g6xh | Runner and grade receipts | closed; `templates/flywheel-install/polish-gate/run-grader.py:16` |
| P2-04 | flywheel-31bhc | Operator docs | closed; `templates/flywheel-install/polish-gate/README.md:1` |
| P2-05 | flywheel-9xuom | MISSION/STATE/loop fields | closed; `templates/flywheel-install/schema.json:300` |
| P2-06 | flywheel-1oruh | Template integration tests | closed; `templates/flywheel-install/tests/test_polish_gate_integration.sh:262` |
| P2-07 | flywheel-p2-12-f1 | Doctor `polish_gate` fields | missing from doctor JSON; follow-up filed |
| P2-08 | flywheel-3jq6y | Close validator fifth lens | closed; `templates/flywheel-install/validate-callback-before-close.sh.tmpl:18` |
| P2-09 | flywheel-5jq48 | Reconcile/backcompat | closed; `templates/flywheel-install/scripts/reconcile-polish-gate.sh:23` |
| P2-10 | flywheel-ok0yd | Scope allowlist fixtures | closed; `templates/flywheel-install/polish-gate/v1/scope-allowlist.schema.json:1` |
| P2-11 | flywheel-p2-11 | Ledger replay adapter | JSONL says in_progress; files/tests pass; `templates/flywheel-install/polish-gate/replay-to-ledger.py:15` |

## 1. Five-skill grades

Bar: every skill should be >=9.0. A sub-bar surface creates a severity-mapped
audit finding, but does not ask Joshua to decide.

| Surface | UBS | Simplify | Extreme-opt | README | Canonical CLI | Composite | Finding |
|---|---:|---:|---:|---:|---:|---:|---|
| P2-01 schemas | 9.1 | 9.2 | 9.2 | 9.0 | 8.8 | 9.06 | flywheel-p2-12-f2 |
| P2-02 discovery | 8.6 | 9.1 | 9.0 | 9.1 | 9.2 | 9.00 | flywheel-p2-12-f3 |
| P2-03 runner/receipts | 9.2 | 9.1 | 9.1 | 9.0 | 9.1 | 9.10 | none |
| P2-04 docs | 9.1 | 9.2 | 9.1 | 9.3 | 9.2 | 9.18 | none |
| P2-05 templates | 9.1 | 9.1 | 9.1 | 9.2 | 9.1 | 9.12 | none |
| P2-06 tests | 9.1 | 9.1 | 9.1 | 9.0 | 9.2 | 9.10 | none |
| P2-07 doctor fields | 7.6 | 8.0 | 7.7 | 8.0 | 7.4 | 7.74 | flywheel-p2-12-f1 |
| P2-08 close validator | 9.1 | 9.0 | 9.0 | 9.1 | 9.2 | 9.08 | none |
| P2-09 reconcile | 9.2 | 9.2 | 9.2 | 9.2 | 9.2 | 9.20 | none |
| P2-10 scope allowlist | 9.3 | 9.3 | 9.3 | 9.3 | 9.3 | 9.30 | none |
| P2-11 ledger replay | 9.2 | 9.2 | 9.2 | 9.2 | 9.3 | 9.22 | none |

Evidence anchors:
- Schema contracts: `templates/flywheel-install/polish-gate/v1/*.schema.json`.
- Discovery scope logic: `templates/flywheel-install/polish-gate/discover-surfaces.py:163`.
- Runner receipt and summary logic: `templates/flywheel-install/polish-gate/run-grader.py:194`.
- Close validator fifth lens: `templates/flywheel-install/validate-callback-before-close.sh.tmpl:224`.
- Reconcile idempotence and rollback: `templates/flywheel-install/scripts/reconcile-polish-gate.sh:328`.
- Ledger replay chain behavior: `templates/flywheel-install/polish-gate/replay-to-ledger.py:265`.

## 2. Three-judges verdict

| Surface | Jeff | Donella | Joshua | Verdict |
|---|---:|---:|---:|---|
| P2-01 schemas | 8.8 | 9.2 | 9.0 | follow-up: schema inventory drift |
| P2-02 discovery | 8.7 | 9.0 | 9.0 | follow-up: malformed-manifest error shape |
| P2-03 runner/receipts | 9.1 | 9.0 | 9.0 | pass |
| P2-04 docs | 9.1 | 9.2 | 9.1 | pass |
| P2-05 templates | 9.0 | 9.1 | 9.0 | pass |
| P2-06 tests | 9.2 | 9.1 | 9.0 | pass |
| P2-07 doctor fields | 7.4 | 7.8 | 8.0 | follow-up: missing feedback loop |
| P2-08 close validator | 9.2 | 9.1 | 9.0 | pass |
| P2-09 reconcile | 9.2 | 9.2 | 9.1 | pass |
| P2-10 scope allowlist | 9.3 | 9.4 | 9.2 | pass |
| P2-11 ledger replay | 9.1 | 9.3 | 9.1 | pass |

three_judges_pass_count: 8/11
lens_disagreement_max: 1

Jeff lens is the only sub-bar lens on P2-01, P2-02, and P2-07. Donella and
Joshua agree the system shape is coherent, so the lens spread stays below the
auto-advance threshold. Missing doctor surfacing is a feedback-loop gap, not a
human-disposes blocker.

## 3. Seven-facet publishability bar

Facet keys: F1 README front-door, F2 doctrine clarity, F3 doctor/health/repair,
F4 executable tests, F5 idempotent install/uninstall, F6 code aesthetic,
F7 demo-ability.

| Surface | Facets | Result |
|---|---|---|
| P2-01 schemas | F1 YES, F2 NO, F3 YES, F4 YES, F5 YES, F6 YES, F7 YES | 6/7 |
| P2-02 discovery | F1 YES, F2 YES, F3 YES, F4 YES, F5 YES, F6 NO, F7 YES | 6/7 |
| P2-03 runner/receipts | F1 YES, F2 YES, F3 YES, F4 YES, F5 YES, F6 YES, F7 YES | 7/7 |
| P2-04 docs | F1 YES, F2 YES, F3 YES, F4 YES, F5 YES, F6 YES, F7 YES | 7/7 |
| P2-05 templates | F1 YES, F2 YES, F3 YES, F4 YES, F5 YES, F6 YES, F7 YES | 7/7 |
| P2-06 tests | F1 YES, F2 YES, F3 YES, F4 YES, F5 YES, F6 YES, F7 YES | 7/7 |
| P2-07 doctor fields | F1 YES, F2 YES, F3 NO, F4 YES, F5 YES, F6 YES, F7 NO | 5/7 |
| P2-08 close validator | F1 YES, F2 YES, F3 YES, F4 YES, F5 YES, F6 YES, F7 YES | 7/7 |
| P2-09 reconcile | F1 YES, F2 YES, F3 YES, F4 YES, F5 YES, F6 YES, F7 YES | 7/7 |
| P2-10 scope allowlist | F1 YES, F2 YES, F3 YES, F4 YES, F5 YES, F6 YES, F7 YES | 7/7 |
| P2-11 ledger replay | F1 YES, F2 YES, F3 YES, F4 YES, F5 YES, F6 YES, F7 YES | 7/7 |

seven_facet_pass_count: 8/11

## 4. Cross-cutting findings

Substrate amplification risk: mostly controlled. The template has versioned
schemas, render fixtures, fresh-install coverage, existing-repo reconcile, and
scope allowlists. Remaining amplification risk is metadata drift: the install
schema declares only 7 of the 9 current v1 polish-gate schemas, so downstream
template consumers may miss `discovery-output` and `reconcile-output` unless
they inspect the directory.

Install-time friction: acceptable for Phase 3. Bootstrap mode is visibility-first
and tests prove render/discovery/reconcile without applying strict scoring during
initial install. The discovery malformed-manifest traceback is the one friction
gap because a bad JSON manifest produces a Python stack trace instead of a stable
operator error.

False-positive rate: controlled by fail-closed allowlists. The ALPS/default
fixtures prove domain paths are excluded before operator words such as doctor,
ledger, worker, dispatch, tick, and router are interpreted.

Doctor feedback: not ready. `flywheel-loop doctor --repo /Users/josh/Developer/flywheel --json | jq '.polish_gate // {missing:true}'`
returns `{"missing": true}`. That means the stock exists, but the main loop
cannot see it yet.

## 5. Severity-mapped findings

| ID | Severity | Root class | Summary | Bead |
|---|---|---|---|---|
| F-HIGH-001 | high | doctor-feedback-loop-missing | Phase 2 P2-07 doctor surface is absent from doctor JSON. | flywheel-p2-12-f1 |
| F-HIGH-002 | high | schema-inventory-drift | `schema.json` omits `discovery-output.schema.json` and `reconcile-output.schema.json` from `polish_gate.schemas`. | flywheel-p2-12-f2 |
| F-HIGH-003 | high | operator-error-shape | `discover-surfaces.py` tracebacks on malformed JSON manifests instead of returning a controlled operator error. | flywheel-p2-12-f3 |
| F-MED-001 | medium | bead-receipt-drift | P2 closure inventory is not fully machine-auditable: no P2-07 row, P2-11 remains `in_progress`. | flywheel-p2-12-f4 |
| F-LOW-001 | low | aggregate-test-coverage | Aggregate schema test does not enumerate every v1 schema in one command. | flywheel-p2-12-f5 |

findings_critical: 0
findings_high: 3
findings_medium: 1
findings_low: 1

## 6. Composite verdict

composite_score: 9.01
lens_disagreement_max: 1
critical_findings: 0
audit_disposition: AUTO_ADVANCE

Decision rule: composite >=7.0, zero critical findings, and lens spread <2.
This audit meets the rule. The high findings are P0 follow-up beads, not Phase 3
broadcast blockers, because none maps to a true Joshua-blocker class.

## 7. Phase 3 broadcast disposition

phase_3_broadcast_green_light: true
flag_emitted: `templates/flywheel-install/polish-gate/PHASE-3-BROADCAST-READY.flag`

Do not fire the broadcast from the worker pane. Flywheel:1 owns Phase 3
dispatch. This audit emits only the readiness flag and the severity-mapped
follow-up beads.

Validation observed:

```text
PASS: polish gate schemas and fixtures
PASS: polish gate runner cases=13 assertions=18
PASS: polish gate close validator cases=9
PASS: polish gate reconcile cases=7
PASS: polish gate ledger replay cases=9 assertions=14
SUMMARY pass=7 fail=0
PASS: render templates, frontmatter, and strict doctor smoke
```
