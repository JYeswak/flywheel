# flywheel State

schema_version: 1
doc_type: state
status: locked
repo: /Users/josh/Developer/flywheel
repo_realpath: /Users/josh/Developer/flywheel
installed_from: /Users/josh/Developer/flywheel/templates/flywheel-install
template_version: "0.1.0"
template_hash: 1c262f716519326ffa0ba1fcc6ce0b8f8fd41236a0d885f2d4b70f878a852494
rendered_at: 20260501T052023Z
rendered_by: flywheel-loop-reconcile
lock_hash: d966bf77c91b729ac2c10a064d78345be4dc8fc216494b4dbaf3f61872d9f48f
locked_at: 2026-05-03T21:03:46Z
locked_by: flywheel-loop-reconcile
source_path: /Users/josh/Developer/flywheel/.flywheel/STATE.md
source_sha256: 388526164bd1d0c507cfd6ae930c87729a3ef291ea084171994bca1d24c34e77
source_section: existing .flywheel/STATE.md
provenance_note: Migrated by flywheel-loop init --reconcile from existing repo-local docs.

## Mission Anchor

Repo-local mission preserved from the existing .flywheel state.

## Success Definition

Strict doctor returns ok and lock-log records the reconcile apply.

## Resume Context

Latest handoff: `.flywheel/handoffs/2026-05-05T2130-wave-0-spine-complete-polish-converging.md` (wave-0 wire-or-explain spine 5/5 CLOSED — Zest Ledger/Press/Pour/Sorter + Peel Report doctor extension; 5-skill polish gate Phase 1 stamp Cluster A+B closed 9.0+, Cluster C + F01 README in flight; Phase 2 plan-arc shipped 9.57; Phase 3 pre-research in flight; bv-triage pre-computed for next wave starting flywheel-2ypj tick-close gate)
Prior: `.flywheel/handoffs/2026-05-05T2010-eod-pivot-wave-0-substrate-cleanup.md` (wave-0 substrate cleanup pivot; 12 quick-fixes + 215 stale-dispatches deleted)
Prior: `.flywheel/handoffs/2026-05-04-2330-eod.md` (data-decided paradigm shift; 2 plans Phase-1-converged with 6+ source convergence; /flywheel:plan rewritten data-decided; 6 TRUE-Joshua-blocker classes precise; mission-anchor-init template extended with license envelope)
Prior: `.flywheel/handoffs/2026-05-04-2030-eod.md` (81 commits today, 50 L-rules canonical L48→L102, fleet-shared META-RULEs at /Users/josh/.flywheel/canonical-meta-rules/, L98 architecture-health, L99 worker-recovery-SLO, L100 identity-primary-key, L101 productivity-ownership, L102 META-RULE-cache-on-tick, calling-in-sick policy, accretive fleet propagation LIVE)
Prior: `.flywheel/handoffs/2026-05-04-1933-compact-cross-fleet-paradigm-locked.md` (35+ commits today, L94+L95 canonical, 6 cross-fleet structural fixes, v2a1 Plan A unblocked, paradigm locked)
Earlier: `.flywheel/handoffs/2026-05-04-1738-eod-validator-v2-pipeline-shipped.md` (validator-v2 5-phase pipeline READY: 28 beads, 49/49 audit findings, 9.0/10 three-judges, 8/8 ready checklist)
Earlier: `.flywheel/handoffs/2026-05-03-2057-compact.md`
Earlier: `.flywheel/handoffs/2026-05-03-0231-eod.md`
Earlier: `.flywheel/handoffs/2026-05-03-0259-eod.md`

## Completed

- Bead isolation is complete across all 21 planned beads and all four phases.
- Phase 1 stopped recovery bleed in ntm: strict bead lookup, recovery bead gating, checkpoint validation, and workspace-scoped context.
- Phase 2 consolidated binaries and normalized repo authority: local `.beads` confirmed, `source_repo` backfilled, global vault frozen, and Developer `.beads` symlink tombstoned.
- Phase 3 hardened beads_rust SQL and discovery: repo filters, `--repo`, last-touched guards, symlink rejection, and `BEADS_STRICT_LOCAL`.
- Phase 4 added CI/runtime guardrails: symlink bleed regression, recovery provenance assertions, authority diagnostics, hook guards, and project-scoped checkpoints.
- Final validation on 2026-04-30: `br where` resolves to `/Users/josh/Developer/flywheel/.beads`.
- `br list` in flywheel shows only local flywheel beads; cross-repo leakage count is 0.
- Global vault remains archival only and is protected by tombstone/frozen behavior.
- All 8 known bead failure modes, FM-1 through FM-8, are addressed.
- Upstream evidence chain is preserved through local commits and filed GitHub issues.

## Current Mission: Flywheel Substrate Audit & Hardening

- Full ecosystem audit completed with 3 Codex workers and 3 reports:
  - `/tmp/flywheel-audit-hooks-and-repo.md`
  - `/tmp/flywheel-audit-skills-system.md`
  - `/tmp/flywheel-audit-tests-proposals-db.md`
- Comprehensive `README.md` is being written for the repo so new workers can understand the local flywheel substrate without reading scattered audit artifacts first.
- Upstream issues filed and subscribed:
  - `frankensqlite#85` — `Arc<[u8]>` Blob iteration break causing cargo install failure.
  - `beads_rust#269` — NULL notes constraint violation in `beads.db`.
  - `beads_rust#270` — WAL wedging under concurrent multi-agent SQLite access.
- Next phase is hardening the flywheel repo itself as the local authority for orchestration state, audits, tests, proposals, hooks, and bead-health automation.

## Ecosystem Inventory

- Hooks and commands: 8 active flywheel hooks and 16 flywheel slash commands.
- Executables: 30+ binaries under the flywheel `bin/` surface.
- Tests and proposals: 57 tests and 59 proposals.
- Capability inventory: 21 skill packs.
- `state.db` shape: 9 tables.
- `state.db` current counts: 11,776 events, 1,233 sources, 808 snapshots, 396 deltas.

## Gaps Found

- Top-level `README.md` now exists as a draft/substrate map, but still needs completion and tracking as the reliable repo entrypoint.
- `joshua_verdicts` is active: verdict capture is wired through `flywheel-loop verdict`, and rows now land in `state.db`.
- AM service investigation closed the apparent failure as a diagnostic mismatch; local Agent Mail is healthy, so the remaining work is probe/runbook alignment rather than service repair.
- Template/live doc alignment report has been produced and recommends backfilling live repo-local docs to the richer template contract.
- Beads DB health automation is now part of doctor coverage for repo-local integrity, WAL health, NULL-note damage, and cross-repo leakage sentinels.
- Backup files in `bin/` still create inventory noise and make the executable surface harder to audit.

## Next Actions

1. AGENTS.md doctrine drift repair across fleet: complete the active dispatch and reconcile repo-local doctrine snapshots.
2. Template/live doc backfill: apply the alignment report recommendations to live `.flywheel` docs and templates.
3. Flywheel repo `README.md` completion: finish and track the top-level entrypoint for new workers.
4. STATE.md relock via `/flywheel:relock-state` Q&A with Joshua: replace this mechanical refresh with reviewed state lock when Joshua is available.

## Active Work In Flight

Template reconciliation for portable flywheel loop docs.

## Confirmed Failure Modes

Older installs can drift from canonical templates.

## Current Decisions

Preserve existing frontmatter values where present.

## Next Actions

Review preview diff and apply the reconcile if acceptable.

## Key Files

.flywheel/MISSION.md, .flywheel/GOAL.md, .flywheel/STATE.md, .flywheel/loop.json

## Lock Receipt

Reconciled from existing .flywheel/STATE.md at 20260501T052023Z.

## Tick — 2026-05-04T20:45:22Z

DECISION: tick=observe-only; 3 observatory probes in flight (panes 2/3/4 THINKING); beads.db btree corruption (Tree49 p19317) detected — Workaround D queued post-callback-land per L94 (no concurrent SQLite writes while workers dispatched); fleet 5/5 productive; META-RULE-CACHE fresh; no source edits (workers in flight); next wake on probe callbacks ETA 21:09Z.

## Tick — 2026-05-04T20:56:34Z

DECISION: tick=observe+reap; pane 2 ✅ conformance-observatory DONE (W,12/12 tests,L103 3-surface,doctor min_score=80); pane 3 ✅ comms-observatory shipped (commits b626727+c9b4df3,L104 3-surface,doctor min_score=100); pane 4 still THINKING on process-gap (doctor reading 31 open gaps — system catching itself); pane 2 redispatched on observatory-dashboard (was queued-not-submitted, kicked — now Working). 2 new fuckups logged: meta-rule-cache-sync //.flywheel bug + br-create blocked by Tree-49 corruption. Storage 93%/69Gi (yellow). No source edits, no Workaround D yet (3 workers in flight per L94).

## Tick — 2026-05-04T21:02:00Z

DECISION: tick=reap+dispatch; pane 2 dashboard skill landed in catalog (flywheel:fleet-observatory visible) but commit/L106/callback pending — still THINKING; pane 4 process-gap-detector THINKING (32 open gaps surfacing, top=skillos 3-surface drift — system converging because skillos is actively repairing); pane 3 WAITING → dispatched shared-surface-reservation-patch (closes their own coordination-collision fuckup, eat-own-learning loop); fleet 5/5 productive; no Josh-blockers.

## Tick — 2026-05-04T21:04:24Z

DECISION: tick=reap+observe; pane 2 ✅ observatory-dashboard DONE (W, 8 spines, 15/15 tests, L106 3-surface, fleet_observatory_health_score=61 YELLOW LIVE) — Tesla command center reads single fleet number; pane 4 process-gap-detector still THINKING (32 gaps surfacing); pane 3 coordination-patch still THINKING; doctor reads composite 61 driven by process spine 0/100 (32 gaps). System catching itself at meta-level. No source edits, no Josh-blockers.

## Tick — 2026-05-04T21:07:31Z

DECISION: tick=reap; pane 4 ✅ process-gap-detector DONE (W, 7 signals, 34/34 tests, L105 3-surface, AUTO-FILED 3 fix-beads flywheel-3dhk/1r3a/1cxv, dedupe verified, callback delivery verified) — system caught itself + routed to action; pane 3 coordination-patch THINKING (L107 pending); pane 2 WAITING. fleet_observatory_health_score=61 YELLOW (process spine 0/100 driving). beads.db Tree-49 corruption blocks br show on fix-beads (bv ranking still works). Workaround D queued for safe-window when pane 3 lands. No source edits, no Josh-blockers.

## Tick — 2026-05-04T21:10:39Z

DECISION: tick=reap+dispatch; pane 3 commit 2621922 coordination-checker LANDED (still THINKING for tests/L107); pane 2+pane 4 WAITING (idle with work avail per L101) → dispatched: pane 4 → Workaround D apply on flywheel beads.db Tree-49 corruption (safe-window per L94 — no concurrent SQLite writers); pane 2 → dogfood audit of /flywheel:fleet-observatory + propose fix bead for worst spine (process gaps 32). Fleet 5/5 productive overall. No source edits, no Josh-blockers.

## Tick — 2026-05-04T21:11:07Z

DECISION: tick=observe; all 4 panes THINKING (pane 1 orch, pane 2 observatory-dogfood, pane 3 wrapping coordination-patch [a7a768b L107 3-surface ✅], pane 4 Workaround D in flight on flywheel beads.db); pane 3 ALREADY shipped coordination-checker (2621922) + L107 doctrine — formal callback pending. br show still fails (Workaround D not complete). No source edits, no Josh-blockers.

## Tick — 2026-05-04T21:11:34Z

DECISION: tick=observe; all 4 panes still THINKING (pane 4 Workaround D in progress, pane 2 dogfood audit, pane 3 coordination-patch wrap); 0 new commits this tick; br still Tree-49 corrupt (pane 4 not done); storage 93%/68Gi stable. No source edits, no Josh-blockers. Holding for callback land.

## Tick — 2026-05-04T21:11:55Z

DECISION: tick=observe; pane 3 WAITING (coordination-patch formal callback imminent, work already shipped per a7a768b/2621922); pane 2+4 THINKING (dogfood audit, Workaround D); 0 new commits this tick; br still corrupt. No dispatch yet — letting pane 3 emit formal callback first per L71 validate-then-close.

## Tick — 2026-05-04T21:12:22Z

DECISION: tick=observe; all 4 panes THINKING; 0 commits this tick; 0 callbacks; br still corrupt (Workaround D in flight). Nothing actionable; holding.

## Tick — 2026-05-04T21:12:42Z

DECISION: COORD ACK; pane 4 acquired single-writer lock for Workaround D — orch enforcing L94 fleet-wide pause-on-br-writes until DONE callback; ACK sent to pane 4; advisory sent to pane 2 (read-only OK, no br update/create/dep); pane 3 still THINKING on coordination wrap (no beads writes expected). Cross-orch ledger row written.

## Tick — 2026-05-04T21:14:17Z

DECISION: tick=reap; pane 3 ✅ shared-surface-reservation-patch DONE (9/9/9/8 four-lens, 14/14 tests, L107 3-surface ✅, doctor field added, dogfood-used-own-tool, identity MagentaPond, callback delivery verified); pane 2 ✅ observatory-dogfood DONE (W, 8/8 spines but score_matches=NO — bug logged, proposed fix-bead 'fix(process): route fleet process gap backlog'); pane 4 Workaround D PROGRESSING per multi-frame test — acquired lock + sent COORD + db/jsonl ready_count=393 symmetry (3min in, normal); ALIVE not frozen. L94 safe-window holding. Score-mismatch fuckup logged for follow-up.

## Tick — 2026-05-04T21:15:52Z

DECISION: tick=reap+dispatch; 🎉 WORKAROUND D WORKED — beads.db 92M corrupt → 6.0M clean, br show flywheel-3dhk SUCCEEDS, corrupt files preserved aside; pane 4 still holds lock + THINKING (probably commit/release); panes 2+3 WAITING → dispatched paired READ-ONLY investigation of three_surface_drift root cause (consumer audit + producer audit) for the 3 auto-filed fix-beads (skillos/alps/mobile-eats). Per L94 no concurrent beads writes. Per Donella #11 fix the gate not the leak.

## Tick — 2026-05-04T21:16:28Z

DECISION: tick=reap; pane 4 ✅ Workaround D DONE (W) — 917 rows imported zero-loss, integrity fail→ok, ready 393→393, br show works, backup preserved, 2 commits (1df9752+19f3ec5), lock+reservation properly released. System self-healed; substrate restored. Panes 2+3 THINKING on three-surface-drift root-cause audits. No source edits.

## Tick — 2026-05-04T21:19:16Z

DECISION: tick=reap; pane 2 ✅ three-surface-drift-consumer-audit DONE (W) — 6 sessions audited, 5/6 have cache+sync, ONLY picoz missing. KEY INSIGHT: cache freshness ≠ 3-surface convergence — separate stocks with incomplete gate (Donella #5/#6 leverage). Specific gaps: //.flywheel runtime bug, alps/vrtx no onboard receipts in STATE, no structured tick receipt for meta_rule_cache_sync. 5 recommendations for structural fix. Pane 3 producer audit still THINKING — synthesis after both land. Pane 4 WAITING (post-Workaround D); panes 2 done.

## Tick — 2026-05-04T21:21:41Z

DECISION: tick=reap+synthesize+dispatch; pane 3 ✅ producer-audit DONE (X) — alps missing 14, mobile-eats 5 (today's L103-L107), skillos 2, vrtx 4d-stale, picoz never-ticked; SYNTHESIS: 2 root causes (sync.sh doesn't enforce 3-surface convergence + many sessions don't tick); dispatched STRUCTURAL FIX to pane 4 (post-Workaround D, well-positioned) — sync.sh --check/apply-three-surface + tick/onboard wire + hourly launchd watchdog + L108 + doctor fields. Closes flywheel-3dhk/1r3a/1cxv when landed. Process gap count climbed 32→33 (system catching new gaps). No Josh-blockers.

## Tick — 2026-05-04T21:22:15Z

DECISION: data-decided flywheel-rx1t — option 3 (fold INCIDENTS distribution into canonical-meta-rules sync) wins because it reuses pane 4's in-flight structural fix. Action deferred until pane 4 lands; will extend sync.sh as 4th surface. Pane 4 still THINKING on structural fix (sync.sh --check/apply-three-surface + tick/onboard wire + L108); panes 2 WAITING, 3 THINKING. flywheel-rx1t left IN_PROGRESS pending pane 4 close.

## Tick — 2026-05-04T21:23:30Z

DECISION: tick=observe; pane 4 structural fix THINKING (~25min in, large multi-step: sync.sh extend + tick/onboard wire + launchd plist + L108 + doctor fields + tests); pane 2 WAITING idle but holding off dispatch — pane 4's work touches doctor fields + AGENTS.md surfaces, dispatching pane 2 risks coordination collision (L51/L107). Pane 3 THINKING. Single-tick idle per L101 acceptable while pane 4 completes structural pivot. No source edits.

## Tick — 2026-05-04T21:23:52Z

DECISION: tick=observe; all 4 panes THINKING; pane 4 structural fix continuing (~30min in, no commits yet — large 6-deliverable scope); no callbacks; no L108 surfaces yet. Holding.

## Tick — 2026-05-04T21:25:21Z

DECISION: tick=observe; pane 4 multi-frame ALIVE (hashes differ), reading existing probes (doctrine-3-surface-divergence-probe.sh, fleet-process-gap-detector.sh, fleet-conformance-probe.sh, fleet-l-rule-lag-probe.sh) — doing proper research before extending sync.sh. ~50min in, expected for 6-deliverable scope. No callbacks/commits/L108 yet. Holding.

## Tick — 2026-05-04T21:26:45Z

DECISION: tick=observe; pane 4 multi-frame ALIVE (hashes differ d5e6→16b8); ~1h+ on structural fix (6 deliverables: sync.sh extend + tick wire + onboard wire + launchd plist + tests + L108 + doctor fields). Long but progressing. No callbacks/commits/L108 yet. Holding.

## Tick — 2026-05-04T21:28:10Z

DECISION: tick=reap; flywheel-1lpv jeff-intel-network EPIC validation 10/11 ACs PASS — substrate complete (177/177 Jeff repos cloned+indexed, launchd loaded, helper+slash+tests 15/15), epic CORRECTLY left IN_PROGRESS pending first digest with ≥3 findings (child flywheel-1lpv.3 + new flywheel-keji cover gaps). Worker showed proper L71 discipline (no premature close). Pane 4 structural fix still THINKING; panes 2/3 THINKING. No source edits.

## Tick — 2026-05-04T21:31:07Z

DECISION: tick=reap; flywheel-b6js DONE 5/9 (validation; tests PASS, 3 gaps (skillos-350/15u + flywheel-668a) correctly NOT auto-fixed — proper L71 discipline; commit fa66400 not in flywheel repo (multi-repo). NEW REGRESSION: br show flywheel-b6js fails 'UNIQUE constraint failed: export_hashes.issue_id' post-Workaround-D — distinct from Tree-49, fresh issue. Logged fuckup. No br writes from orch (pane 4 still THINKING). Pane 2 WAITING idle but holding concurrent-write risk. Doctor timed out (busy beads.db).

# Latest handoff pointer (auto-appended by /flywheel:handoff)
- 2026-05-05T01:36Z eod → `.flywheel/handoffs/2026-05-05-0132-eod.md` (10 sections + B47 ship update)

**Latest handoff:** `.flywheel/handoffs/2026-05-06T1120-eod-wednesday-flywheel-day4.md` (2026-05-06 eod-wednesday-flywheel-day4)
