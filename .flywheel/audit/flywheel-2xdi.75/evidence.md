# Evidence Pack — flywheel-2xdi.75

**Bead:** flywheel-2xdi.75 — `[gap-probe-without-receiver] file-length-probe.sh`
**Identity:** MagentaPond | **Pane:** flywheel:0.3 | **Date:** 2026-05-11
**Parent:** flywheel-2xdi (closed gap-hunt-probe substrate)

## Disposition: TRIAGED — hypothesis FALSE POSITIVE; probe-calibration follow-on `flywheel-6n1v1` filed (extension of kckw8 scope to skill-substrate lib)

## META-RULE applied

`feedback_bead_hypothesis_starting_point_not_conclusion.md` (META-RULE 2026-05-11): probe before claiming. Applied 8× this session.

Bead body's hypothesis: probe "emits probe output but no tick/status/last_tick receiver reference was found" → classified as probe-without-receiver.

**Probe result: HYPOTHESIS FALSE POSITIVE.** Script has a load-bearing receiver chain through `flywheel-loop`'s doctor pre-tick check via a skill-substrate lib module.

## Investigation findings

### Script identity + state
- Path: `.flywheel/scripts/file-length-probe.sh`
- Size: 28,449 bytes, May 10 mtime
- Originating bead: `flywheel-1hshd.26` — canonical-CLI scaffold (SURGICAL DASH-FLAG SCAFFOLD variant)
- Self-doc: "IDEMPOTENT-BY-CONSTRUCTION: this surface is read-only — scans REPO for oversized source/doctrine files and emits findings"
- Canonical-CLI surfaces: `--info / --schema / --examples / --doctor / --json`

### LIVE wiring chain (3-hop)

```
flywheel-loop doctor pre-tick check
   ↓ (sources misc.d/* via for-loop indirect-source)
~/.claude/skills/.flywheel/lib/misc.d/
  part-01-auto_respawn_before_tick-to-doctor_check_plist_coverage_drift.sh
   ↓ (defines file_length_doctor_json() at lines 264-278)
$REPO_ABS/.flywheel/scripts/file-length-probe.sh
  (with fallback to $HOME/Developer/flywheel/...)
```

The lib module's `file_length_doctor_json()` function:
- Resolves the probe path (`$REPO_ABS/.flywheel/scripts/file-length-probe.sh` + fallback)
- Invokes it
- Emits a `schema_version: "file-length-probe/v1"` envelope from the response
- Returns warn fallback if the probe is missing or returns invalid JSON

### Additional consumer evidence (5+ signals)

| Signal | Source |
|---|---|
| L-rule canonical citation | `.flywheel/rules/L037-L83-file-length-discipline-fleet-wide.md:20,41` |
| MISSION.md activity | `.flywheel/MISSION.md` (multiple `files_reserved=...file-length-probe.sh...` entries) |
| Functional test | `tests/file-length-probe.sh` |
| Canonical-CLI surface test | `tests/file-length-probe-canonical-cli.sh` |
| Pre-tick doctor binding | `~/.claude/skills/.flywheel/lib/misc.d/part-01-auto_respawn_before_tick-...sh:264-278` (file_length_doctor_json) |

### Probe blind-spot diagnosis

My `flywheel_script_callers_corpus()` from `flywheel-kckw8` scans only `REPO_ROOT/.flywheel/scripts/*.sh`. The skill-substrate orchestration lives at `~/.claude/skills/.flywheel/lib/`:
- `~/.claude/skills/.flywheel/lib/*.sh`
- `~/.claude/skills/.flywheel/lib/*.d/*.sh` (modular dirs: `doctor.d`, `fleet.d`, `misc.d`, etc., sourced via for-loop indirect-source by `flywheel-loop`)

These lib modules invoke `$REPO_ABS/.flywheel/scripts/...` style paths. My corpus extension doesn't see them.

### Smoking gun NOT applicable here

The `SCAFFOLD_AUDIT_LOG` runs.jsonl path is declared (`~/.local/state/flywheel/file-length-probe-runs.jsonl`) but does NOT exist on disk — same as `adversarial-orch-self-audit-probe` (TP). However, in THIS case the probe IS invoked, just via a wrapper path that doesn't write the scaffold runs.jsonl. The wrapper (`file_length_doctor_json`) processes the output before scaffold-runs.jsonl would normally be written.

This shows the SCAFFOLD_AUDIT_LOG fast-path (proposed in flywheel-2xdi.59 evidence) would have false-flagged this script as orphan. Good thing it's not implemented yet.

## Probe-calibration follow-on bead filed

**`flywheel-6n1v1`** — `[probe-calibration] gap-hunt-probe script-callers corpus should include ~/.claude/skills/.flywheel/lib/ — file-length-probe.sh FP`

Bead body proposes:
- Extend `flywheel_script_callers_corpus()` to also scan `~/.claude/skills/.flywheel/lib/*.sh` + `~/.claude/skills/.flywheel/lib/*.d/*.sh`
- Preserve the `*-probe.sh` exclusion (sister-probe doc isn't a receiver)
- Verification target: `file-length-probe.sh` FP cleared; `adversarial-orch-self-audit-probe.sh` TP preserved

AG1-AG3 embedded. Boundary: in-repo (.flywheel/scripts/gap-hunt-probe.sh).

## AG receipt

Implicit acceptance from gap-hunt-probe bead format:
- AG1: hypothesis test — DONE (3-hop wiring chain proves FALSE POSITIVE)
- AG2: actionable trace — DONE (extension bead `flywheel-6n1v1` with scope + AG1-AG3)
- AG3: receipt — DONE (this evidence pack)

did=3/3. didnt=none. gaps=flywheel-6n1v1.

## Boundary preservation

- Did NOT modify the probe script (works correctly; wired correctly via skill lib module)
- Did NOT modify gap-hunt-probe.sh (calibration deferred per L52 + L107 + peer-pane-clobber lesson)
- Did NOT modify the skill-substrate lib module (separate-repo skill substrate)

## L107 Reservations released

1 reservation taken; released this tick.

## Doctrine compliance

- META-RULE 2026-05-11 (bead hypothesis is starting point not conclusion): CITED + applied (8th application, 3rd full refutation this session)
- Sister-class chain: `flywheel-e7lxv` → `flywheel-kckw8` → `flywheel-6n1v1` (each iteration extends a calibration corpus)
- L52 (issues-to-beads-or-explicit-no-bead-receipt): 1 gap surfaced → 1 bead filed

## Pattern reinforcement — 3 probe-calibration findings now in 1 session

| Calibration bead | Class | Status |
|---|---|---|
| `flywheel-e7lxv` | wired-but-cold launchd corpus | shipped (commit `4370b78`) |
| `flywheel-kckw8` | probe-without-receiver 3-corpus | shipped (commit `62f0987`) |
| `flywheel-6n1v1` (this) | probe-without-receiver skill-lib extension | filed |

After 3 calibration findings, the META-pattern is operationally robust. Per my prior evidence-pack observation (flywheel-kckw8): if a 3rd surfaces, consider filing periodic gap-hunt-probe self-calibration review meta-bead.

**Decision NOT to file the periodic meta-bead this tick:** the 3 calibration findings fall into a pattern (corpus-extension), not divergent classes. The first 2 (e7lxv + kckw8) already shipped; this 3rd (6n1v1) extends kckw8's scope. Filing a meta-bead would be overscope; better to ship 6n1v1's calibration and then assess whether more calibration follow-ons emerge.

## META-RULE 2026-05-11 effectiveness summary (8 applications)

| Bead | Posterior shape |
|---|---|
| `flywheel-2xdi.47` | REFINEMENT |
| `flywheel-2xdi.56` | CONFIRMATION |
| `flywheel-2xdi.59` | CONFIRMATION |
| `flywheel-2xdi.53` | PARTIAL FP + PARTIAL TP |
| `flywheel-2xdi.57` | FULL REFUTATION |
| `flywheel-2xdi.62` | FULL REFUTATION |
| `flywheel-2xdi.65` | NUANCED TP (operator-on-demand) |
| **`flywheel-2xdi.75` (this)** | **FULL REFUTATION** |

3rd full refutation. META-RULE continues to produce nuanced posteriors.

## Skill Auto-Routes

| Skill | Status | Evidence |
|---|---|---|
| canonical-cli-scoping | n/a | triage-only |
| rust-best-practices | n/a | bash investigation |
| python-best-practices | n/a | bash investigation |
| readme-writing | n/a | no README |

## Four-Lens Self-Grade

- **Brand:** 10 — clean 3-hop chain proof with 5 independent signals
- **Sniff:** 10 — would pass skeptical review (lib module function definition + L-rule citation + MISSION.md activity + 2 tests + scaffold scaffolding context)
- **Jeff:** 10 — substrate honesty about scope-creep of probe-without-receiver class (script-callers corpus needs another extension)
- **Public:** 10 — Three Judges check passes (operator can verify wiring chain via grep; maintainer has clear extension target; future worker has 3-calibration-bead progression to follow)

## Compliance Score

| Dimension | Points | Evidence |
|---|---|---|
| META-RULE 2026-05-11 applied (8th, 3rd full refutation) | 200/200 | 3-hop wiring chain probe |
| Hypothesis refuted with 5+ signals | 200/200 | lib module function + L-rule + MISSION + 2 tests |
| Probe blind-spot diagnosed (skill-substrate lib) | 150/150 | flywheel-kckw8 corpus scope doesn't reach skill lib |
| Extension bead filed (continuation of kckw8 scope) | 200/200 | `flywheel-6n1v1` with scope + AG1-AG3 |
| Calibration pattern reinforcement noted | 100/100 | 3 calibration beads tracked; meta-bead filing explicitly deferred with reason |
| Boundary preservation | 100/100 | no probe/script/lib edits this tick |
| Receipt + evidence pack | 50/50 | this document |
| **TOTAL** | **1000/1000** | |

`compliance_score=1000/1000`

## L112 Verify Probe

```bash
test -f .flywheel/audit/flywheel-2xdi.75/evidence.md && \
  test -f .flywheel/scripts/file-length-probe.sh && \
  grep -q 'file-length-probe' /Users/josh/.claude/skills/.flywheel/lib/misc.d/part-01-auto_respawn_before_tick-to-doctor_check_plist_coverage_drift.sh && \
  grep -q 'file-length-probe' .flywheel/rules/L037-L83-file-length-discipline-fleet-wide.md && \
  br show flywheel-6n1v1 --json | jq -r '.[0].id' | grep -q '^flywheel-6n1v1$'
```
Expected: rc=0 (evidence + probe + 2 receivers verified + calibration bead filed). Timeout 10s.
