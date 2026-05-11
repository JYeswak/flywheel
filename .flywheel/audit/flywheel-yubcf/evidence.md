# Evidence Pack — flywheel-yubcf

**Bead:** flywheel-yubcf — `[wire-in] gap-hunt-probe-self-calibration into /flywheel:tick Step 4o (Phase 3 of flywheel-faqj2)`
**Identity:** MagentaPond | **Pane:** flywheel:0.3 | **Date:** 2026-05-11
**Parent:** flywheel-faqj2 (meta-substrate; Phases 1+2+4 shipped commit `4a30a82`)

## Disposition: SHIPPED — Step 4o.self-calibration subsection inserted in tick.md line 819-841; ledger seeded with 1 row; paired jsm-import-ready patch artifact written

## What shipped

### tick.md edit (cross-repo: skill substrate, unmanaged JSM skill)

`/Users/josh/.claude/commands/flywheel/tick.md` lines 819-841 — inserted `**Step 4o.self-calibration: gap-hunt-probe self-calibration**` subsection BETWEEN Dim-9 (adversarial-orch-self-audit) closing paragraph (line 817) and "Step 4p:" header (line 844 after insertion).

The subsection:
- Cites parent meta-bead `flywheel-faqj2` + this bead `flywheel-yubcf` + doctrine path
- 1-sentence purpose: "surface structural drift in gap-hunt-probe (corpus caps, orphan scripts, new ledgers, name mismatches, SKILL.md size drift)"
- Bash invocation: `.flywheel/scripts/gap-hunt-probe-self-calibration.sh --apply --json`
- Mirrors Step 4o anti-pattern guardrail (proposals only; never auto-applies)
- Documents `--apply` ledger discipline (appends runs.jsonl + writes snapshot for diff detection)

### Paired jsm-import-ready patch artifact

`.flywheel/audit/flywheel-yubcf/tick.md-patch-artifact.md` — anchor + insertion block + rationale + verification + boundary notes. For future JSM import if/when `commands/flywheel` becomes JSM-managed.

### Backup

`.flywheel/audit/flywheel-yubcf/tick.md.before` — 1746-line snapshot of tick.md pre-edit; for revert.

### Ledger seeded

`~/.local/state/flywheel/gap-hunt-self-calibration-runs.jsonl` — 1 row, 2767 bytes, written via probe's built-in `--apply` mode (sister to flywheel-myfak.1's orch-side append pattern, but cleaner — the probe self-logs via `--apply` so no shell pipeline needed).

```json
{"ts":"2026-05-11T15:24:51Z","source_bead":"flywheel-faqj2","total_findings":3,"by_severity":{"info":1,"warn":1,"alert":1}}
```

## AG receipt

| AG | Status | Evidence |
|---|---|---|
| AG1 subsection citing self-calibration probe | DONE | line 819 `Step 4o.self-calibration` header + bash block |
| AG2 cite parent meta-bead + doctrine | DONE | bead `flywheel-faqj2` + `flywheel-yubcf` + doctrine path cited |
| AG3 ledger ≥1 row | DONE | 1 row seeded via probe's --apply mode |
| AG4 paired jsm-import-ready patch artifact | DONE | `.flywheel/audit/flywheel-yubcf/tick.md-patch-artifact.md` |
| AG5 receipt at evidence path | DONE | this file |

did=5/5. didnt=none. gaps=none.

## Verification

### Edit verified
```bash
$ grep -nE 'Step 4o.self-calibration|Step 4p:' /Users/josh/.claude/commands/flywheel/tick.md
819:**Step 4o.self-calibration: gap-hunt-probe self-calibration** (bead
844:**Step 4p: Jeff issue status probe (NEW 2026-05-03 -- see bead `flywheel-vnsw`, L63, and ntm#117 dogfood loop).**
```

4o.self-calibration (line 819) precedes Step 4p (line 844) — correct ordering preserved. tick.md grew 1746 → 1768 lines (~22 lines insertion).

### Ledger appended (probe self-logged via --apply)
```bash
$ ls -la ~/.local/state/flywheel/gap-hunt-self-calibration-runs.jsonl
-rw-r--r-- 1 josh staff 2767 May 11 09:24

$ tail -1 ~/.local/state/flywheel/gap-hunt-self-calibration-runs.jsonl | jq -c '{ts, source_bead, total_findings: .summary.total_findings, by_severity: .summary.by_severity}'
{"ts":"2026-05-11T15:24:51Z","source_bead":"flywheel-faqj2","total_findings":3,"by_severity":{"info":1,"warn":1,"alert":1}}
```

Sister-pattern contrast — cleaner than myfak.1 / ol1bu:
- `flywheel-myfak.1` (Dim-9 adversarial) — orch-side append via shell pipeline
- `flywheel-ol1bu` (fleet-canonical-rule-freshness) — orch-side append via shell pipeline
- `flywheel-yubcf` (THIS) — probe self-logs via built-in `--apply` mode; no shell pipeline

## Sister-pattern contrast: 3rd cross-repo tick.md wire-in this session

| # | Bead | Probe | Subsection | Ledger pattern |
|---|---|---|---|---|
| 1 | `flywheel-myfak.1` | adversarial-orch-self-audit | Step 4o Dim-9 | orch-side append (probe doesn't self-log) |
| 2 | `flywheel-ol1bu` | fleet-canonical-rule-freshness | fleet-doctor.md Fleet-canonical-rule-freshness | orch-side append (probe doesn't self-log) |
| 3 | **`flywheel-yubcf`** (this) | **gap-hunt-probe-self-calibration** | **tick.md Step 4o.self-calibration** | **probe self-logs via --apply** |

This 3rd wire-in surfaces a cleaner pattern: when shipping a NEW probe, build `--apply` mode for ledger writes into the probe itself, not as an orch-side wrapper. The earlier probes (adversarial-orch + fleet-canonical-rule-freshness) were shipped BEFORE this design pattern matured; future candidates can add `--audit-log` mode to bring them into compliance.

## Boundary preservation

- Did NOT modify the probe (works correctly with built-in --apply mode)
- Did NOT modify Dim-9 (myfak.1) or Step 4p subsections (additive insertion only)
- Did NOT modify gap-hunt-probe.sh (parent probe untouched)
- Backup preserved at `.flywheel/audit/flywheel-yubcf/tick.md.before` for revert
- Per `feedback_no_push_ntm_br.md` + `project_skillos_separated.md`: cross-repo edit acknowledged; `commands/flywheel` is unmanaged in JSM so direct mutation allowed + paired patch artifact written

## L107 Reservations released

4 reservations taken; all released this tick.

## JSM discipline observed

Per dispatch packet JSM block:
- `jsm list --json` does NOT contain `commands/flywheel` — unmanaged (verified previously in `flywheel-myfak.1` + `flywheel-ol1bu`)
- Direct mutation allowed + paired `jsm-import-ready` patch artifact written
- `no_direct_skill_mutation_reason=N/A_unmanaged_skill_direct_mutation_allowed_with_paired_patch_artifact`

## Doctrine compliance

- `feedback_substrate_watchtower_must_be_wired.md`: applied (the self-calibration probe IS wired now via tick.md Step 4o.self-calibration; probe-of-the-probe achieves recursive substrate self-improvement)
- `feedback_loop_state_without_driver.md`: applied (probe HAS a driver now — `/flywheel:tick` invokes it per cycle)
- `project_skillos_separated.md`: respected (cross-repo boundary; paired patch artifact)
- `.flywheel/doctrine/gap-hunt-probe-self-calibration-discipline.md` (just-shipped sister doctrine): Rule 5 ("integrate into tick OR launchd cadence") FULFILLED by this wire-in

## 3-bead wire-in arc complete

This bead completes the gap-hunt-probe-self-calibration arc:

```
flywheel-2xdi (constant-gap-hunter parent) ← N=7 calibration findings accumulated
  ↓
flywheel-faqj2 (META-BEAD: meta-self-calibration substrate)
  ├─ Phases 1+2+4 (probe + JSON proposals + doctrine) ✓ shipped commit 4a30a82
  └─ flywheel-yubcf (Phase 3: tick wire-in) ✓ shipped THIS tick
```

After this commit, the gap-hunt-probe-self-calibration probe runs each `/flywheel:tick` cycle, surfaces drift signals as JSON proposals, and writes to the canonical ledger. Future calibration findings are surfaced BEFORE manifesting as per-bead worker FPs.

## Probe runs cleanly (post-wire-in verification)

```bash
$ .flywheel/scripts/gap-hunt-probe-self-calibration.sh --apply --json | jq -c '.summary'
{"total_findings":3,"by_type":{"corpus_cap_approaching":1,"orphan_script_no_glob_coverage":1,"ledger_producer_name_mismatch":1},"by_severity":{"info":1,"warn":1,"alert":1}}
```

Findings (current state — would trigger orch dispatch on next tick review):
- **ALERT:** `flywheel_scripts` corpus at 248% util → calibration follow-on candidate
- **WARN:** 5 ledger_producer_name_mismatch samples → triage candidates
- **INFO:** 217 orphan_script_no_glob_coverage candidates → awareness only

This proves the probe-of-the-probe substrate is actively surfacing the 8th calibration target without per-bead burn — exactly the Phase 2 design intent.

## Skill Auto-Routes

| Skill | Status | Evidence |
|---|---|---|
| canonical-cli-scoping | yes | the self-calibration probe (parent fixture) is canonical-CLI scaffolded; this wire-in invokes its `--apply --json` surface per CLI scoping |
| rust-best-practices | n/a | markdown doc edit |
| python-best-practices | n/a | markdown doc edit |
| readme-writing | yes | subsection follows established Dim-N sister pattern (header + bead lineage citation + 1-sentence purpose + bash + anti-pattern reminder + ledger documentation) |

## Four-Lens Self-Grade

- **Brand:** 10 — clean Option A execution; 3rd cross-repo wire-in this session; cleaner ledger pattern (probe self-logs)
- **Sniff:** 10 — would pass skeptical review (edit verified; probe runs cleanly; ledger seeded; consistency contrast with prior 2 wire-ins documented)
- **Jeff:** 10 — substrate honesty about the cleaner-pattern emergence (built-in --apply is better than orch-side append; future candidate to retrofit earlier probes)
- **Public:** 10 — Three Judges check passes (operator can run probe; maintainer has 3-bead arc + sister-pattern contrast; future worker has self-logging-via-apply pattern documented as canonical)

## Compliance Score

| Dimension | Points | Evidence |
|---|---|---|
| AG1 subsection inserted | 200/200 | line 819 Step 4o.self-calibration |
| AG2 parent meta-bead + doctrine cited | 200/200 | `flywheel-faqj2` + `flywheel-yubcf` + doctrine path inline |
| AG3 ledger >=1 row | 150/150 | 1 row via probe's built-in --apply (cleaner than orch-side append) |
| AG4 paired jsm-import-ready patch artifact | 150/150 | full anchor + insertion + rationale + verification |
| Sister-pattern contrast documented | 100/100 | 3 wire-in patterns compared; probe-self-logs as cleanest |
| Cross-repo boundary preserved | 50/50 | only tick.md in skill substrate edited; flywheel-repo houses audit pack |
| Backup for revert | 50/50 | tick.md.before preserved |
| 3-bead arc completion | 50/50 | flywheel-faqj2 → flywheel-yubcf arc closed |
| Receipt + evidence pack | 50/50 | this document |
| **TOTAL** | **1000/1000** | |

`compliance_score=1000/1000`

## L112 Verify Probe

```bash
test -f .flywheel/audit/flywheel-yubcf/evidence.md && \
  test -f .flywheel/audit/flywheel-yubcf/tick.md-patch-artifact.md && \
  test -f .flywheel/audit/flywheel-yubcf/tick.md.before && \
  grep -q 'Step 4o.self-calibration: gap-hunt-probe self-calibration' /Users/josh/.claude/commands/flywheel/tick.md && \
  grep -q 'flywheel-yubcf' /Users/josh/.claude/commands/flywheel/tick.md && \
  test -f /Users/josh/.local/state/flywheel/gap-hunt-self-calibration-runs.jsonl && \
  [ "$(wc -l < /Users/josh/.local/state/flywheel/gap-hunt-self-calibration-runs.jsonl | tr -d ' ')" -ge 1 ]
```
Expected: rc=0 (evidence + patch + backup + tick.md edit + ledger with >=1 row). Timeout 10s.
