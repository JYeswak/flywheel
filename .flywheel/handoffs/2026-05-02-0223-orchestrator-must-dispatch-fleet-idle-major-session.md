# Handoff — 2026-05-02T02:23Z — reason: orchestrator-must-dispatch-fleet-idle-major-session

## Resume context for next session

- **Last commit:** `5f0aa06` "chore(beads): convert jeff-ecosystem master plan to 35 beads"
- **Branch:** `master`
- **Active session:** `flywheel` (5 panes — pane 0 user, pane 1 cc orchestrator, panes 2/3/4 codex workers)
- **Locked docs:** MISSION.md, GOAL.md, STATE.md (frontmatter status: locked; STATE.md has "Latest handoff" pointer in Resume Context section)
- **Fleet substrate state:** autoloop ALIVE + ticking; idle-spiral-alert.json shows alpsinsurance consecutive_idle_clean=19; 6 ntm internal-monitor processes running across sessions
- **CASS v2 mission target HIT** at gpu-optimization 02:04Z (picoz session led, INDEPENDENT but new canonical doctrine `mission-anchor-drift-sub-mission-promotion` shipped via `~/.claude/skills/.flywheel/INCIDENTS.md`)

## In-flight dispatches (do NOT redispatch — these are running)

| task_id | bead | worker | pane | started | expected_by |
|---|---|---|---|---|---|
| ylwk_drill_design | flywheel-ylwk | codex | 2 | 02:19Z | 02:49Z |
| tb6c_ru_repair_design | flywheel-tb6c | codex | 3 | 02:20Z | 02:50Z |
| xujl_doctor_extend_design | flywheel-xujl | codex | 4 | 02:21Z | 02:51Z |

Workers expected to write outputs at:
- `/tmp/ylwk_drill_design.md` (ALPS idle-spiral E2E drill, fleet-idle plan Bead 4)
- `/tmp/tb6c_ru_repair_design.md` + `/tmp/tb6c_ru_config.patch` (RU per-category PROJECTS_DIR repair)
- `/tmp/xujl_doctor_extend_design.md` + `/tmp/xujl_doctor.diff` (vc-doctor-extend, 3rd of vc-tentacle trio)

## Major session accomplishments

### Fleet-idle root cause LOCATED + 4-bead DAG ready for install

**Smoking gun:** `~/.claude/skills/.flywheel/bin/flywheel-loop` lines 2670-2693 — tick decision tree has 6 verbs, NONE dispatch beads. Autoloop is observe-only by construction. `idle-spiral-alert.json` written but no consumer reads it.

**4 beads filed + designed (all closed except E2E):**
- ✅ flywheel-z0wh: 18-line patch designed (`/tmp/z0wh_patch.diff`, applies clean) — adds `action=dispatch_bead` branch BEFORE dirty branch
- ✅ flywheel-fbgi: dispatch_bead packet consumer (502 lines, 7 rules, 10 failure modes) — `/tmp/fbgi_consumer_design.md`
- ✅ flywheel-3m6p: idle-spiral-alert consumer (675 lines, 4 actions, 4 selection rules, fbgi-race documented) — `/tmp/3m6p_idle_spiral_consumer_design.md`
- ⏳ flywheel-ylwk: ALPS E2E drill (in flight pane 2)

### `/flywheel:plan` v2 shipped

Replaced single-phase legacy at `~/.claude/commands/flywheel/plan.md` with full 5-phase pipeline: RESEARCH → REFINE → AUDIT → DECOMPOSE → POLISH. Includes state-machine durability, Joshua-disposes pause, dogfood proof referencing recovery system arc. v1 behavior preserved via `--phase=1`.

### Recovery plan (parallel topic) — paused for Joshua-disposes

`/Users/josh/Developer/flywheel/.flywheel/plans/recovery-system-2026-05-01/` contains:
- 00-RECOVERY-PLAN.md (867 lines, refined to 02-REFINE-r2.md at 900 lines, 3.8% delta = steady-state)
- 03-AUDIT-FINDINGS.md (776 lines): 13 Joshua-decisions, 11 deduped criticals, readiness=RED, recommendation=Option C (hybrid Joshua-disposes split)
- 3 audit lenses: cross-cutting (5 criticals), security (3 criticals + 3 cross-cutting), idempotency (4 criticals)

### Fleet-idle plan (current focus)

`/Users/josh/Developer/flywheel/.flywheel/plans/fleet-idle-2026-05-02/00-FLEET-IDLE-PLAN.md` (1,048 lines, ladder=yes, 4 beads min, 4 Joshua decisions, recommends NO consolidation with recovery plan)

### 10-tentacle wave COMPLETE

All 10 substrate-registry tentacle plans designed (vc/ntm/br/cass/AM/bv/dcg/frankensqlite/asupersync/pi). 259 signals, 3,500+ lines. Aggregate doctor (12j) + consumer sweep (kqw) designs done. vc-tentacle trio designed (3pil plist, vl57 probe, xujl doctor).

### RU broken fleet-wide — diagnosed

42 tracked repos, 0 at configured PROJECTS_DIR=/Users/josh/Desktop/Projects, 13 at /Users/josh/Developer, 20 iCloud-shadowed, 9 truly missing. Audit recommends Option B (per-category hierarchical roots). Design in flight (tb6c).

### CASS v2 cross-session win wired

picoz session HIT mission target at 02:04Z. New canonical doctrine `mission-anchor-drift-sub-mission-promotion` shipped via `~/.claude/skills/.flywheel/INCIDENTS.md`. Memory entry `project_cass_v2_mission_target_hit_2026_05_02.md` added.

### INCIDENTS.md grew 343→453 lines

3 new entries promoted this session:
- `jeff-watcher-false-positive-on-gh-auth-fail` (3 events in 2 min, GITHUB_TOKEN invalid causes UNKNOWN noise spiral)
- `orchestrator-substrate-blindness` (META-CLASS, 7-point breadth-first inventory rule)
- `documented-bug-not-actioned-self-recursion` (canonical L-rule candidate, ALPS self-bug beads 25h+ unactioned)

## Open beads (repo-scoped)

15+ ready beads. Highlights:
- **flywheel-ylwk** (P1) IN FLIGHT — ALPS E2E drill (final fleet-idle bead)
- **flywheel-tb6c** (P1) IN FLIGHT — RU repair
- **flywheel-xujl** (P2) IN FLIGHT — vc-doctor-extend
- **flywheel-i18f** (P2) — substrate-inventory checklist extension (waiting)
- **flywheel-sum** (P0) — Adopt v0.4 SESSION HANDOFF doctrine (older in_progress, may be ghost)
- **flywheel-1k7** (P1) — kill-recover-drill-script (older in_progress, may be ghost)
- **flywheel-3bk** (P2) — dynamic-ntm-session-coverage-heartbeat (older in_progress, may be ghost)
- **flywheel-3ul** (P2) — autoloop-anti-monoculture (older in_progress, may be ghost)

## Pending decisions for Joshua

1. **L48 install-approval queue (10+ designs ready):**
   - Recovery audit findings 13 decisions in `/Users/josh/Developer/flywheel/.flywheel/plans/recovery-system-2026-05-01/03-AUDIT-FINDINGS.md`
   - Fleet-idle Bead 1 patch: `/tmp/z0wh_patch.diff` (18 lines, applies clean — apply to `~/.claude/skills/.flywheel/bin/flywheel-loop`)
   - Fleet-idle Bead 2 consumer: `/tmp/fbgi_consumer_design.md` (install location TBD per architecture choice = standalone script)
   - Fleet-idle Bead 3 consumer: `/tmp/3m6p_idle_spiral_consumer_design.md`
   - Tentacle aggregate doctor: `/tmp/12j_aggregate_doctor_design.md` + `/tmp/12j_flywheel_aggregate_doctor.sh`
   - Tentacle consumer sweep: `/tmp/kqw_consumer_sweep_design.md` + `/tmp/kqw_flywheel_consumer_sweep.sh`
   - vc launchd plist: `/tmp/3pil_ai.zeststream.vc-daemon.plist` (lint passes — install via `launchctl bootstrap`)
   - vc PATH-shadow probe: `/tmp/vl57_probe.diff` (applies clean — apply to `~/.claude/skills/dicklesworthstone-stack/probes/vc-health-probe.sh`)
   - ALPS josh-1eo8p worker-tick design: `/tmp/alps_worker_tick_design.md` (ladder=NO with caveat — file existed at v0.1 stub, needs strengthening not creation)
   - ALPS josh-1s3ie loop-state-write fix: `/tmp/alps_loop_start_state_write_fix.md` (6 projects affected, 3 causes)
   - AM FD-leak Jeff issue: `/tmp/jeff_issue_draft_mcp_agent_mail_fd_leak.md` (HELD per "100% ready" bar — 3 doubts: source HEAD verification, repro reproducibility, repro section concrete enough)

2. **GITHUB_TOKEN refresh** — env var invalid (40 chars, gh rejects HTTP 401). Either `unset GITHUB_TOKEN` to fall back to keyring, OR refresh via Infisical. 3 watcher false-positives logged in 2 min.

3. **Decide Option A/B/C for recovery audit findings** — synthesis recommends Option C (hybrid Joshua-disposes split). 13 decisions surfaced in audit findings doc.

4. **Decide RU repair option** — audit recommends Option B (per-category PROJECTS_DIR). Awaiting tb6c worker design completion (in flight pane 3).

5. **Decide ALPS orchestrator pane restart** — alpsinsurance:0.1 wedged at 854.3k tokens with 💀 marker. Per `documented-bug-not-actioned-self-recursion` rule: needs Joshua-disposes pane-restart.

## Files Joshua needs to read on resume

**Primary (read first):**
1. This handoff
2. `/Users/josh/Developer/flywheel/.flywheel/plans/fleet-idle-2026-05-02/00-FLEET-IDLE-PLAN.md` — fleet-idle action plan + minimal source patch
3. `/tmp/z0wh_patch.diff` — the 18-line load-bearing fix
4. `/Users/josh/Developer/flywheel/INCIDENTS.md` lines 345-453 — 3 newly-promoted patterns (jeff-watcher / substrate-blindness / self-bug-recursion)
5. `/Users/josh/Developer/flywheel/.flywheel/plans/recovery-system-2026-05-01/03-AUDIT-FINDINGS.md` — 13 decisions for recovery plan

**Awaiting in-flight callbacks:**
6. `/tmp/ylwk_drill_design.md` (when ylwk callback lands ~02:49Z)
7. `/tmp/tb6c_ru_repair_design.md` (when tb6c callback lands ~02:50Z)
8. `/tmp/xujl_doctor_extend_design.md` (when xujl callback lands ~02:51Z)

**Reference:**
9. `~/.claude/commands/flywheel/plan.md` — `/flywheel:plan` v2 spec (5-phase pipeline)
10. `/Users/josh/Developer/flywheel/.flywheel/plans/recovery-system-2026-05-01/02-REFINE-r2.md` — 900-line converged recovery plan

## Learning state at handoff

### Unprocessed fuckup-log rows (since last triage)
5 unprocessed (down from 33 mid-session — bulk-triaged earlier).
Most recent classes: orchestrator-double-sent-same-packet-to-two-panes (own mistake, caught quickly), ntm-send-cass-dup-check-blocks-orchestrator (transport bug, fix=`--no-cass-check`).

### Promotion candidates ready
None pending promotion this turn — 3 patterns already promoted to INCIDENTS this session (jeff-watcher, orchestrator-substrate-blindness, documented-bug-not-actioned-self-recursion).

### INCIDENTS entries authored this session
- `/Users/josh/Developer/flywheel/INCIDENTS.md` lines 345-376: `jeff-watcher-false-positive-on-gh-auth-fail`
- `/Users/josh/Developer/flywheel/INCIDENTS.md` lines 377-419: `orchestrator-substrate-blindness` (META-CLASS, 7-point breadth-first inventory rule)
- `/Users/josh/Developer/flywheel/INCIDENTS.md` lines 421-453: `documented-bug-not-actioned-self-recursion` (canonical L-rule candidate)
- `~/.claude/skills/.flywheel/INCIDENTS.md` (cross-session, picoz authored): `mission-anchor-drift-sub-mission-promotion` (104KB file, distributes via flywheel-loop init)

### Memory entries written
- `feedback_breadth_first_substrate_inventory.md`
- `feedback_self_bug_recursion.md`
- `reference_alps_real_path.md`
- `feedback_orchestrator_must_dispatch.md`
- `reference_cass_vs_cassv2.md`
- `project_cass_v2_mission_target_hit_2026_05_02.md`

## Per-bead-DAG state

Fleet-idle DAG (z0wh→fbgi→3m6p→ylwk):
- z0wh ✅ closed (load-bearing patch designed)
- fbgi ✅ closed (consumer designed)
- 3m6p ✅ closed (idle-spiral consumer designed)
- ylwk ⏳ in flight (E2E drill, last bead)

vc-tentacle trio (3pil + vl57 + xujl):
- 3pil ✅ closed (launchd plist designed)
- vl57 ✅ closed (PATH-shadow probe designed)
- xujl ⏳ in flight (doctor extend)

Recovery plan: PAUSED at audit→decompose boundary. Joshua-disposes 13 decisions before Phase 4.

## Suggested resume sequence

1. `/flywheel:status` — pane state + ready bead count
2. Reap 3 in-flight callbacks if landed (ylwk / tb6c / xujl)
3. Read `INCIDENTS.md` 3 new entries + understand orchestrator-substrate-blindness rule
4. Joshua decides L48 install-approval queue (10+ designs ready, ranked by leverage):
   - Highest leverage: z0wh + fbgi + 3m6p apply → fleet-idle becomes flowing
   - High leverage: 3pil plist install → vc daemon survives reboot
   - Medium: vl57 + xujl → vc tentacle end-to-end
   - Lower priority: kqw consumer sweep, 12j aggregate doctor (test infrastructure)
5. Joshua decides recovery plan Option A/B/C (audit findings doc)
6. Refresh GITHUB_TOKEN (or unset to fall back to keyring) — stops watcher false-positive noise
7. Optional: address ALPS orchestrator pane wedge (pane restart)

## Critical-path next moves

1. ⏳ 3 callbacks land (ylwk + tb6c + xujl)
2. ⏸ Joshua decides L48 install queue (z0wh first = unblocks fleet-idle immediately)
3. ⏸ Joshua decides recovery plan A/B/C
4. ⏸ Refresh GITHUB_TOKEN
5. ⏸ Apply z0wh patch (18 lines, low blast radius, applies clean)
6. ⏸ Install fbgi+3m6p consumers (autoloop becomes self-driving)
7. ⏸ Run ylwk E2E drill (proves fleet-idle fixed)

## Step-away signal

State durable: dispatch-log.jsonl, INCIDENTS.md, beads DB, plan files, doctrine packets, all designs at /tmp + plan dirs. Workers can callback at their own pace. No active orchestrator burden.

The orchestrator-must-dispatch lesson is fully wired in (memory + this handoff). Future sessions inherit the meta-rule.

Resume with confidence.
