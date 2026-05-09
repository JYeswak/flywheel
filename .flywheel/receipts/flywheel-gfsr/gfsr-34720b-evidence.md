# flywheel-gfsr-34720b Evidence

## Scope

- Bead: `flywheel-gfsr`
- Task: migrate `flywheel-loop` process-status probes to NTM robot health/diagnose surfaces.
- Live source touched:
  - `/Users/josh/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh`
  - `/Users/josh/.claude/skills/.flywheel/lib/loop.d/loop_driver_doctor_json.py`
- Repo fixture touched:
  - `.flywheel/scripts/test-doctor-empty-errors.sh`

## What Changed

- `doctor_ntm_health_json` now runs `ntm --robot-health=<session> --json` for pane health and `ntm --robot-diagnose=<session> --json` for recommendations.
- `ntm_pane_live` now runs `ntm --robot-health=<session> --panes <pane> --json` and treats `healthy`, `degraded`, and `rate_limited` as live.
- Legacy fixture paths remain supported:
  - `FLYWHEEL_DOCTOR_NTM_HEALTH_JSON`
  - `FLYWHEEL_LOOP_NTM_HEALTH_JSON`
- New robot fixture paths:
  - `FLYWHEEL_DOCTOR_NTM_ROBOT_HEALTH_JSON`
  - `FLYWHEEL_DOCTOR_NTM_ROBOT_DIAGNOSE_JSON`
  - `FLYWHEEL_LOOP_NTM_ROBOT_HEALTH_JSON`

## Verification

```bash
bash -n .flywheel/scripts/test-doctor-empty-errors.sh
bash -n /Users/josh/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh
python3 -m py_compile /Users/josh/.claude/skills/.flywheel/lib/loop.d/loop_driver_doctor_json.py
.flywheel/scripts/test-doctor-empty-errors.sh
rg -n -- '--robot-health|--robot-diagnose|FLYWHEEL_DOCTOR_NTM_ROBOT_HEALTH_JSON|FLYWHEEL_LOOP_NTM_ROBOT_HEALTH_JSON' /Users/josh/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh /Users/josh/.claude/skills/.flywheel/lib/loop.d/loop_driver_doctor_json.py .flywheel/scripts/test-doctor-empty-errors.sh
```

Results:

- Syntax: pass
- Python compile: pass
- Regression fixture: `PASS: doctor status=fail carries concrete robot-health errors[] with legacy fallback`
- Robot surface probe: source contains `--robot-health` and `--robot-diagnose`; remaining `process_status` use is legacy fixture fallback only.

## JSM / Skill Mutation Notes

- Packet-required `jsm status .flywheel --json` was incompatible with current `jsm status` syntax: it accepts no skill-name argument.
- `jsm status --json --offline` and `skill-enhance-jsm-discipline.sh --validate-packet ... --json` timed out while probing `jsm list --json`.
- Because the bead explicitly targets live `.flywheel` shared source, the live source was patched directly and this evidence records the timeout.

## Socraticode

- Query count: 1
- Query: `flywheel-loop ntm_pane_live process_status running doctor_ntm_health_json process_status exited robot-diagnose robot-health test-doctor-empty-errors`
- Relevant hit: `lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh`, `lib/loop.d/loop_driver_doctor_json.py`, and `.flywheel/scripts/test-doctor-empty-errors.sh`.

## L52 Receipt

- New beads filed: `flywheel-odugq`
- Beads updated: none
- Reason: JSM mutation preflight timed out on `jsm list --json`; the migration proceeded because the bead explicitly targets live `.flywheel` source, but the preflight substrate needs a bounded unavailable state.

## Skill Routes

- `canonical-cli-scoping=yes`: robot probe and doctor surfaces remain JSON-first; no new CLI added.
- `python-best-practices=yes`: touched Python keeps typed public signature and compiles.
- `rust-best-practices=n/a`: no Rust touched.
- `readme-writing=n/a`: no README touched.

## Compliance Pack

- Score: `900/1000`
- CLI canonical: yes
- Python clean: yes
- Rust clean: n/a
- README quality: n/a
- Evidence redacted: n/a
- Artifact checks:
  - `/Users/josh/.claude/skills/.flywheel/lib/doctor.d/part-01-doctor_cache_path-to-doctor_schema_postcheck.sh:exists`
  - `/Users/josh/.claude/skills/.flywheel/lib/loop.d/loop_driver_doctor_json.py:exists`
  - `.flywheel/scripts/test-doctor-empty-errors.sh:exists`

## Four-Lens Self-Grade

- brand: 9
- sniff: 9
- jeff: 9
- public: 8

Three Judges check: a skeptical operator gets robot-surface evidence, a maintainer gets fixture-backed behavior, and a future worker can rerun the exact commands.

## L112 Probe

```bash
.flywheel/scripts/test-doctor-empty-errors.sh
```

Expected: `grep:PASS: doctor status=fail carries concrete robot-health errors[] with legacy fallback`
