# Lock-In + Proven-Reliable NTM Recovery Plan

Date: 2026-05-01T14:05Z
Authors: picoz-pane0-orch (this orch) + RubyCreek (flywheel-p1)
Joshua mandate: "everything we're doing here locked into our entire system" + "recover ntm sessions in a way that is proven to be reliable"

## Part A — Lock-In Plan (turn designs into shipping substrate)

### A.0 Bead-graph (5 P0, 4 P1, 1 P2 — total ~16-20hr work, parallelizable to 3 calendar days)

```
P0  bd-codex-yaml-warning-silence   (~30min, replaces wrong-framed yaml-fix)
       - action: tweak codex config to suppress YAML noise OR pre-quote descriptions
       - owner: flywheel-p1 (already cancelled wrong dispatch)
       - proof: fresh codex pane startup shows 0 YAML warnings
P0  bd-npm-codex-install-safety-gate   (~1hr, mine-blast-radius)
       - action: pre-flight check refuses npm install -g @openai/codex if pgrep -f codex
       - owner: flywheel-p1
       - proof: rehearsal shows install blocked when codex panes alive
P0  bd-session-topology-registry        (~1-2hr, prereq for everything)
       - action: ship session-topology.jsonl + flywheel-loop register-session subcommand
       - owner: any worker
       - proof: probe reports 8/8 sessions registered, 0 ghosts unmasked
P0  bd-flywheel-init-interactive        (~3hr, replaces silent init)
       - deps: session-topology-registry
       - action: 8-step interactive /flywheel:init w/ Joshua confirmation per step
       - owner: any worker
       - proof: re-init zeststream-v2 from scratch with Joshua approving each step
P0  bd-ntm-config-coordinator-section   (~30min, fast win)
       - action: write [coordinator] section into ~/.config/ntm/config.toml; enable digest+conflict_negotiate
       - owner: any worker
       - proof: ntm coordinator status SESSION reports send_digests=true
P1  bd-ntm-fleet-health-launchd         (~3hr, the real auto-recovery primitive)
       - deps: session-topology-registry
       - action: launchd plist running ntm health <session> --json --auto-restart-stuck --threshold 10m every 60s for every registered session
       - owner: any worker
       - proof: kill a worker pane, watch it auto-respawn within 60s
P1  bd-team-roster-fleet-observatory    (~4-6hr, your enterprise reporting layer)
       - deps: session-topology-registry
       - action: team-roster.jsonl + team-pulse.jsonl + 5min heartbeat + flywheel-loop roster command
       - owner: any worker
       - proof: from any session, `flywheel-loop roster` shows all 8 sessions w/ status
P1  bd-fleet-skill-reporting-skillos-hq (~4-6hr)
       - deps: team-roster-fleet-observatory
       - action: skill-discoveries.jsonl + skillos coordinator tick + 3-strike auto-bead
       - owner: skillos session
       - proof: dispatch with skill-discovery duty -> 3 sightings -> auto-bead in skillos
P1  bd-worker-deep-liveness-probe       (~2-3hr, catches skillos-p1-style 9hr hangs)
       - action: detect codex hung at 0% CPU + counter advancing visually (UI shows "Working" forever)
       - owner: any worker
       - proof: deliberately hang a codex worker, doctor flags it within 1 tick
P2  bd-picoz-agentmail-onboarding       (~1hr)
       - action: register picoz session in agent-mail, install pre-commit guards
       - owner: picoz-p0 (me, after this session)
       - proof: picoz inbox active, contact policy set, fleet messages discoverable
```

### A.1 Lock-in mechanism (substrate edits)

The 4 design docs in `~/.local/state/flywheel/joint-deepdive-2026-05-01/picoz-p0-lane-A/` need to land at canonical paths so they survive sessions:

| Design doc | Canonical path |
|---|---|
| DESIGN-session-topology.md | `~/Developer/flywheel/.flywheel/PLANS/session-topology-2026-05-01.md` (PLAN scope) |
| DESIGN-team-roster-and-init-flow.md | `~/Developer/flywheel/.flywheel/PLANS/team-roster-2026-05-01.md` |
| DESIGN-fleet-skill-reporting.md | `~/Developer/flywheel/.flywheel/PLANS/fleet-skill-reporting-2026-05-01.md` |
| topology-gap-probe.sh | `~/Developer/flywheel/.flywheel/scripts/topology-gap-probe.sh` (executable) |

**Owner: flywheel-p1** (their repo, their substrate). My job is to DELIVER the design docs; they ship the canonical move.

### A.2 New canonical L-rule additions to ~/Developer/flywheel/AGENTS.md

Three new L-rules emerge from this session:

**L60 — Per-session topology must be declared, not assumed**
- Rule: Every session running /flywheel:loop MUST have a topology row in ~/.local/state/flywheel/session-topology.jsonl with verified orchestrator_pane and orchestrator_kind.
- Why: 2026-04-30 ghost-orchestrator class (vrtx p0 zsh receiving 70x M.NN callbacks; cfs+zeststream-v2 still GHOST today). Hardcoded pane=1 assumption breaks half the fleet.
- How: /flywheel:loop refuses to start in a session with no topology row or stale orchestrator pane.

**L61 — Cross-session comms use BOTH ntm send AND agent-mail**
- Rule: Every cross-session coord between orchestrators MUST use ntm send (real-time, in-band) AND agent-mail (asynchronous, audited, post-compact-survivable).
- Why: 2026-05-01 dual-channel coord between picoz-p0 + flywheel-p1 worked exactly as designed when a critical correction (RC1 invalidation) needed to land before a worker shipped wrong-framed work. flywheel-p1 acted on the ntm leg in seconds; agent-mail leg becomes the durable record.
- How: Worker template adds: "Critical cross-session findings emit BOTH a ntm send and an agent-mail send_message."

**L62 — Workers emit skill-discovery rows at every callback**
- Rule: Every worker callback envelope includes `sd_count=N sd_ids=...` field. Discoveries appended to ~/.local/state/flywheel/skill-discoveries.jsonl. Zero-discovery callbacks on >2hr tasks flag a doctor warning.
- Why: 3-strike skill promotion is currently session-local. Joshua's enterprise-reporting mandate requires fleet-wide observability. skillos coordinator picks up cross-session discoveries.
- How: Worker template adds a "SKILL DISCOVERY DUTY" reminder block; skillos tick reads discoveries.jsonl and auto-files beads at 3-strike threshold.

**Owner: flywheel-p1** for the AGENTS.md edit (their canonical doctrine path).

## Part B — Proven-Reliable NTM Recovery Plan

The Joshua bar: "recover our ntm sessions in a way that is proven to be reliable." Reliable means: rehearsable + idempotent + fails-loud + recoverable from a known good state. NOT a one-shot manual fix.

### B.0 Recovery rehearsal protocol (bead acceptance criterion for ALL recovery beads)

Every recovery action must satisfy:
1. **Pre-state capture**: read-only snapshot of all panes, processes, auth state, git state, write to `~/.local/state/flywheel/recovery/<session>-pre-<ts>.json`
2. **Action**: the recovery operation (respawn / re-auth / re-init)
3. **Post-state verification**: same probe, diff against pre-state, report what changed
4. **Liveness proof**: dispatch a no-op task to recovered pane, verify callback within 30s
5. **Rollback path**: if post-verify fails, restore-to-pre-state command must exist
6. **Idempotency**: running the same recovery twice must not break a recovered session

### B.1 Damage classification (from this incident)

| Damage class | Symptom | Recovery primitive | Verifiable? |
|---|---|---|---|
| D1 — Codex auth-token-rotated | "Your access token could not be refreshed..." | `caam activate codex <profile>` OR Ctrl-C + relaunch + browser login | YES — fetch a fresh prompt response |
| D2 — Codex hung at 0% CPU | UI shows "Working" forever, ps shows 0 CPU | `ntm respawn <session> --panes=N --force` + `codex resume <uuid>` | YES — hyperfine the prompt -> response latency |
| D3 — Pane dropped to bare zsh | `pane_current_command=zsh`, no agent | `ntm respawn` + verify orchestrator-kind matches topology | YES — topology probe re-passes |
| D4 — Session never bootstrapped | All panes bare zsh, never had agents | `/flywheel:init` interactive 8-step OR `ntm spawn` then init | YES — roster row appears |
| D5 — Whole loop died (autoloop drift) | Session has fresh callbacks but loop tier shows stale | `flywheel-loop start --tier=active_normal` + `ntm coordinator enable digest` | YES — pulse heartbeat resumes |

### B.2 Recovery rehearsal — TODAY'S FLEET STATE

Use the current damaged fleet AS the rehearsal:

| Session | Class | Recovery action (rehearsal-validated) |
|---|---|---|
| skillos pane 1 (codex hung 9h) | D2 | capture-pane-2000-lines -> ntm respawn skillos --panes=1 -> codex resume <uuid> -> verify with one-line prompt |
| picoz panes 2,3 (auth-rot earlier today) | D1 | already manually fixed by Joshua + npm rollback; backup auth files to caam profile NOW so future rotation is 50ms |
| vrtx panes 2,3,4 (codex died last night) | D2 or D1 | ntm respawn vrtx --panes=2,3,4 + verify each came up + agent-mail register identities |
| zeststream-v2 (whole session ghost) | D4 | decision: bootstrap or teardown? if bootstrap: /flywheel:init interactive |
| clutterfreespaces pane 1 (zsh, but pane 0 has cc) | D3 (false-positive — orch is on p0 not p1) | NO action — register topology row showing orch_pane=0 |
| 3 alpsinsurance dead workers | D2/D3 | already partially recovered overnight; verify status |

### B.3 Reliability proof — repeatable kill-and-recover drill

**Drill script** (`~/.claude/skills/.flywheel/scripts/kill-recover-drill.sh`):
1. Pick a test session (NEVER alpsinsurance, NEVER picoz active orchestrator)
2. Snapshot state via topology-gap-probe.sh
3. Inject damage (kill one worker pane via tmux Ctrl-C + Ctrl-D)
4. Wait 60s for ntm health daemon (once installed) to detect
5. Verify auto-recovery happened OR manual recovery primitive applied
6. Verify topology probe re-passes
7. Verify worker accepts a no-op dispatch and callbacks
8. Append drill row to `~/.local/state/flywheel/recovery-drill.jsonl`

**Acceptance for "proven reliable":** drill runs green 5 times in a row across 3 different damage classes. Each drill row includes pre-state-hash, post-state-hash, recovery-primitive, time-to-recovery, callback-verified=true|false.

### B.4 Lock-in for recovery itself

Recovery is not a script — it's a **canonical L-rule + canonical primitives + drill**:

**L63 — All recovery primitives must rehearse before claiming reliability**
- Rule: A recovery procedure cannot be marked "ready" without 5 green drill rows in `~/.local/state/flywheel/recovery-drill.jsonl` covering 3+ damage classes.
- Why: 2026-04-30 overnight collapse — every recovery primitive existed (ntm respawn, ntm rotate, codex resume) but none had a rehearsed runbook tied to a damage class. Operators reached for them ad-hoc and got partial recovery + new bugs.
- How: Each new recovery bead must include drill artifacts + pass `kill-recover-drill.sh --damage-class=<D1..D5>` 5x consecutively.

## Part C — Coordination protocol with flywheel-p1 going forward

This is HOW we (you and I, picoz-p0 + RubyCreek/flywheel-p1) ship Parts A+B together.

### C.1 Roles

| Lane | Owner | Why |
|---|---|---|
| Bead filing for the 10 beads above | **flywheel-p1** | Their repo's bead DB; their substrate authority |
| AGENTS.md L60-L63 edits | **flywheel-p1** | Their canonical doctrine file |
| Move design docs to canonical paths | **flywheel-p1** | Their PLANS dir |
| Recovery drill script | **EITHER** (file in ~/.claude/skills/.flywheel/scripts/) | Tooling shared |
| Topology probe -> canonical | **flywheel-p1** | Substrate file move |
| Picoz session agent-mail onboarding | **picoz-p0 (me)** | My session's local responsibility |
| Recovery rehearsal on skillos pane 1 | **WAIT FOR JOSHUA** | We agreed: I won't touch skillos again |
| Rehearsal on a sacrificial session | **EITHER + Joshua approval** | Need a non-active session |

### C.2 Ongoing dual-channel cadence

- **Every cross-orch directive**: ntm send (real-time) + agent-mail (durable)
- **Per-tick callbacks within session**: ntm send only (low value to log)
- **Cross-session findings (RC corrections, drift, gaps)**: ntm send + agent-mail with `ack_required=true`
- **Bead state changes that affect both repos**: agent-mail with `importance=high`
- **Joshua-only escalations**: ntm send to human pane + Pushover via notify CLI

### C.3 Compact-survivable handoff

flywheel-p1 just compacted from 95% -> 28% -> now 34% on Opus 4.7 1M. Their context survives much longer at 1M. But still: every cross-session decision lives in agent-mail (durable) AND in `~/.local/state/flywheel/joint-deepdive-2026-05-01/` (canonical), so neither orch's compaction can lose state.

## Acceptance criteria (whole plan)

1. All 10 beads above are filed (P0 first, P1 next, P2 last) — owner: flywheel-p1
2. L60-L63 land in ~/Developer/flywheel/AGENTS.md — owner: flywheel-p1
3. Design docs moved to canonical PLANS dir — owner: flywheel-p1
4. topology-gap-probe.sh installed at canonical scripts path — owner: flywheel-p1
5. session-topology.jsonl bootstrapped with all 8 sessions — owner: any worker after bd-session-topology-registry ships
6. ntm config.toml has [coordinator] section enabled — owner: any worker (P0)
7. ntm fleet health launchd plist running and verified — owner: any worker (P1)
8. kill-recover-drill.sh exists and has 5 green rows for 3 damage classes — owner: any worker (P1)
9. Picoz session has registered agent-mail identity AND is producing pulse rows — owner: me
10. Recovery rehearsal on skillos pane 1 completed with Joshua present — owner: WAIT

## Update 2026-05-01T14:42Z — launchctl modernization (flywheel-1o9)

ntm-fleet-health daemon migrated from `launchctl load` to modern `launchctl bootstrap/kickstart/bootout` sequence per zeststream-infra prior art (Joshua-authored, picoz-p3 synthesis msg 12). Install/uninstall scripts at `.flywheel/scripts/ntm-fleet-health-{install,uninstall}.sh`. PID verification baked in.

## Update 2026-05-01T14:46Z — skill version pinning (flywheel-1iy)

tick.md now declares `skill_version: 2`. Validator at `.flywheel/scripts/tick-skill-version-check.sh` refuses to run if loaded version doesn't match the design doc reference. Catches stale-skill drift mechanically. Future tick.md ships should bump version + update EXPECTED_VERSION constant in validator. Per picoz suggestion fleet-mail msg 7.
