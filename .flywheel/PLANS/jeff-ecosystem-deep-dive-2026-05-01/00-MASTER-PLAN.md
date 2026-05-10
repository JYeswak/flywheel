---
title: "Master Plan — Jeff Ecosystem Deep Dive"
type: plan
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

# Master Plan — Jeff Ecosystem Deep Dive

**Snapshot:** 2026-05-01T17:50Z
**Scope:** 34 active Dicklesworthstone repos × 10 locally-installed tools × our flywheel doctrine (L0-L65)
**Source artifacts:** `01-repo-inventory.md`, `02-issue-patterns.md`, `03-local-stack-audit.md`, `04-our-needs-vs-stack.md`, `05-doctrine-comparison.md`
**Filing playbook:** `~/.claude/skills/dicklesworthstone-stack/references/INCIDENTS.md` (proven 2026-05-01)
**Already filed:** `ntm#111` (confirmed by Jeff in 45min)
**Total effort represented:** 5 reconnaissance forks (4 codex, 1 Anthropic) + orchestrator synthesis
**Convergence status:** Round 2 complete (12 findings, 3 critical). Round 3 needed after Joshua-decisions. See `06-convergence-audit-round2.md`.

**Round 2 findings applied:** F2 (bead count), F4 (effort re-estimation), F8 (substrate JSON contract), F11 (self-wiring gate), F12 (cross-stream deps). F1/F3/F5/F6/F7/F9/F10 surface as new Joshua-decisions or new beads in §VI/VII.

**Plan freshness:** Snapshot is fresh as of 2026-05-01T18:15Z. Per F10 stale-plan gate: if this plan is unmodified for >24h before filing dispatch OR >7d before bead conversion, re-run the source-artifact verification commands at top of each `0X-*.md` artifact and update master plan.

---

## I. The strategic picture

### Jeff's queue is empty. Our signal value is at peak.

**6 open issues across 34 active repos.** 84% same-day close rate (146 issues sampled). Median close time 6-8 hours. Two community issues closed in **<10 minutes** in April. ntm#111 confirmed by Jeff in 45min with file:line citations and a 3-piece fix scoped.

This is the moment to file high-quality issues. Every well-formed issue lands.

### Our local stack has 30 friction points across 10 tools.

- **PATH collision:** old March-10 vc binary at `~/.local/bin/vc` shadows today's May-1 build at `~/.cargo/bin/vc`. Daemon currently running is the **stale March binary**. (Source: `03:118-122`.)
- **ntm 514 commits behind upstream.** (Source: `03:11-12`.)
- **frankensqlite 48 commits behind.** vibe-cockpit depends on it via path crates. (Source: `03:138-140`.)
- **Agent Mail health endpoints don't respond** despite serve-http process running. Port discovery gap. (Source: `03:67-69`.)
- **bv top pick is stale** (recommends `flywheel-2te` which we just shipped). bv input freshness lag. (Source: `03:50-52`.)
- **CASS robot status fails parse.** ntm advertises CASS robot surfaces but local cass cannot satisfy the contract. (Source: `03:104-110`.)
- **beads_rust origin refs broken** — local can't fetch cleanly, can't compute days-behind. Worktree dirty across CLI/storage/sync. (Source: `03:30-34`.)
- **`ntm config validate` exits 0 while reporting fatal parse failure.** Same silent-failure class as `ntm health` exiting 0 with `error_count=2`. (Source: `03:22-23`.)
- **9 repos in our scope are missing from `dicklesworthstone-stack` INVENTORY entirely.** Audit blind spots. (Source: `01:332`.)

### Five doctrines worth adopting from Jeff's repos

1. **No-deletion-without-written-permission** (cited in 3 of his repos, we don't have an L-rule for this — only general DCG)
2. **No script-based code rewrites**
3. **No file proliferation** (revise existing files in place)
4. **Bare TUI blocks automated sessions** (robot/TUI boundary wording)
5. **Fail-soft + timeout-bounded + idempotent collectors** (lifted from vibe-cockpit, applies to our health daemons)

(Source: `05:201-211`.)

### One doctrine to NOT adopt

Jeff's "no backwards-compatibility because early-development" rule does NOT apply to us — flywheel coordinates live client/fleet repos and must preserve compatibility at command/file contracts. (Source: `05:213-217`.)

---

## II. Four parallel streams (per Round 2 F1)

The deep-dive surfaces FOUR distinct workstreams, each with its own bead graph.

### Stream A: Upstream filings to Jeff (Tier 0)

Filings that match Jeff's proven preferred shape (per `02:154-180` template + `~/.claude/skills/dicklesworthstone-stack/references/INCIDENTS.md` filing playbook).

### Stream B: Local flywheel improvements (OWN/ENHANCE)

Things we build, harden, or tune ourselves.

### Stream C: Tentacle integration into flywheel doctor (NEW — JOSHUA-DIRECTED 2026-05-01)

**Joshua's framing:** "this all needs to be part of our flywheel doctor — this entire ecosystem is part of our flywheel — all tentacles need to be known and accounted for."

Every Jeff tool we depend on is a TENTACLE of the flywheel. The flywheel doctor at `~/.claude/skills/.flywheel/bin/flywheel doctor` currently has **28 registered substrates** — NONE are Jeff's tools. ntm, br, bv, dcg, cass, mcp_agent_mail, vc, pi, frankensqlite, asupersync are all invisible to the doctor. They can drift, fail, or wedge silently and the flywheel has no idea.

This stream registers each tentacle as a first-class substrate in `~/.claude/skills/.flywheel/data/substrate-registry.json` with:
- **Producer:** binary path + version-emitter command
- **Measurement:** validation command that returns machine-readable health (similar shape to existing 28 substrates)
- **Consumer:** flywheel doctor reads + relevant tick steps + alert routing
- **Promotion calculus:** warn-tier (e.g. >7d behind upstream) vs fail-tier (e.g. binary missing or fatal config parse)

The streams interact (Stream A filings cite this stream's findings; Stream B B7 wires vc into tick which depends on Stream C registration), but the substrate-registry work is foundational — without it, none of our doctrine can mechanically enforce tentacle health.

### Stream D: Downstream consumer hardening (NEW — Round 2 F1)

When a tentacle changes (Jeff lands a fix, we adopt a new doctrine, a binary version bumps), DOWNSTREAM consumers must update too:
- flywheel commands & hooks that invoke the tentacle
- Active client repos (alpsinsurance, picoz, vrtx, etc.) that depend on the same binaries
- Worker spawn templates in ntm config
- launchd plists that wrap tentacle daemons (e.g. ntm-fleet-health, vc-daemon)
- Skill INVENTORY references in dicklesworthstone-stack

Without Stream D, a Stream A filing succeeds upstream but local fleet stays drifted. Beads D1-D5 cover: D1 consumer-config sweep + smoke test, D2 ntm spawn template versioning, D3 launchd plist registry + restart matrix, D4 skill INVENTORY auto-bump on tentacle version change, D5 client-repo tentacle-version pinning audit.

---

## III. Stream A — Ranked filing candidates

Each filing must pass the Filing Playbook validation ladder before submitting (see `~/.claude/skills/dicklesworthstone-stack/references/INCIDENTS.md`).

| # | Title (working) | Repo | Validation status | Effort | Value | Bead candidate |
|---|---|---|---:|---:|---:|---|
| A1 | beads collector finds no databases despite 55 local `.beads/` dirs | vibe_cockpit | VALIDATED (4-step ladder complete) | S | Very high | `flywheel-veca-A1` |
| A2 | `ntm config validate` exits 0 while reporting fatal parse failure | ntm | VALIDATED (silent failure observed) | S | High | `flywheel-veca-A2` |
| A3 | `ntm health` exits 0 with `error_count>0` (silent-failure class) | ntm | VALIDATED (paired with A2) | S | High | `flywheel-veca-A3` |
| A4 | Agent Mail health endpoints (`8080`, `8765`) unreachable while serve-http process is running | mcp_agent_mail | VALIDATED (port discovery gap) | S | High | `flywheel-veca-A4` |
| A5 | `cass robot status` returns "Could not parse arguments"; ntm README advertises this surface | cass_memory_system | VALIDATED (contract drift) | S | High | `flywheel-veca-A5` |
| A6 | `bv` returns stale top-pick after bead state advances | beads_viewer | NEEDS DEEPER VALIDATION (stale substrate or stale cache?) | M | Medium | `flywheel-veca-A6` |
| A7 | ntm coordinator config drift broader sweep (context_rotation, health.researcher_sessions, resilience.rate_limit.auto_rotate, models.*, agents.*, session_paths.*) | ntm | VALIDATED — Jeff already endorsed this hypothesis in #111 | S | High | `flywheel-veca-A7` (depends on Jeff closing #111 first) |

**Filing order constraint:** A1 first (cleanest, ready). A7 LAST (after Jeff lands #111 fix; piggyback on his existing implementation context). A2-A5 in any order — independent.

**Per-issue dependency:** all filings depend on the running daemon being the CORRECT binary (the May-1 build). Stream B B1 must complete first OR we use full-path invocation `~/.cargo/bin/vc` everywhere we cite.

---

## IV. Stream B — Local flywheel improvements

Each is a candidate bead with explicit acceptance criteria.

### B1 — Fix vc binary PATH shadowing

**Why:** Daemon is running March-10 binary. All current vc data and "FAIL" messages may be from old code. Cannot trust analysis until resolved.
**What:**
- Stop daemon (`kill 43482`)
- Symlink `~/.local/bin/vc` → `~/.cargo/bin/vc` OR remove old binary
- Restart daemon, verify `lsof -p $(pgrep vc) | grep txt` shows the May-1 binary
- Re-validate beads-collector failure on FRESH binary before filing A1
**Effort:** S (5 min)
**Acceptance:** `which vc` resolves to a binary built ≥2026-05-01; daemon process txt is same binary
**Wires into:** ecosystem (memory: `vc-binary-shadow-trauma`)

### B2 — Pull all 4 stale Jeff repos to current

**Why:** Cannot validate gaps against stale checkouts. ntm is 514 commits behind. Any issue we file must cite current upstream state, not stale local.
**What:**
- `cd ~/Developer/ntm && git fetch origin && git pull --ff-only origin main`
- Same for `~/Developer/frankensqlite`, `~/Developer/mcp_agent_mail`, `~/Developer/beads_rust` (resolve broken refs first)
- For asupersync, retry `git fetch` with timeout fallback
- Update `reference_upstream_issues.md` with new HEAD shas
**Effort:** S (15 min)
**Acceptance:** all 4 repos have local HEAD == origin/main; doctor probe surfaces this
**Wires into:** dicklesworthstone-stack/references/INVENTORY.md update

### B3 — Codex-pane truth signal hardening (long-blocked)

**Why:** ntm health 36/36 false-idle on Codex panes. Our `pane-work-signal.sh` is the workaround; promote to first-class.
**What:**
- Make `pane-work-signal.sh` callable from `/flywheel:tick` Step 3 instead of `ntm health`
- Add to `tick.md` doctrine
- Backport to `feedback_pane_state_ntm_health.md`
**Effort:** S/M (30 min)
**Acceptance:** at least one tick uses pane-work-signal as primary truth
**Bead:** existing `flywheel-3bk` (already filed)

### B4 — Adopt 5 NEW-TO-US doctrines into AGENTS.md as L66-L70

**Why:** `05:201-211` identifies 5 doctrines from Jeff's repos worth lifting. They reduce blast-radius and tighten our discipline.
**What:**
- L66 — No deletion without explicit written permission (Joshua text required, not just "yes")
- L67 — No script-based code rewrites (manual edits only, except generated artifacts)
- L68 — No file proliferation (revise in-place; new file requires explicit justification)
- L69 — Bare TUI blocks automated sessions (robot/TUI boundary)
- L70 — Fail-soft + timeout-bounded + idempotent (collector design law)
**Effort:** M (60 min — drafting + Joshua review + commit)
**Acceptance:** AGENTS.md updated, version bumped, propagation note added
**Wires into:** ecosystem (5 new L-rules, doctrine drift to flywheel skill)

### B5 — Audit the 9 UNKNOWN repos

**Why:** `01:332` flags 9 hot Jeff repos missing from our INVENTORY. These are blind spots; some likely already solve problems we've manually papered over.
**Targets:** `flywheel_connectors`, `flywheel_gateway`, `slb`, `storage_ballast_helper`, `meta_skill`, `franken_agent_detection`, `cross_agent_session_resumer`, `coding_agent_account_manager`, `agent_flywheel_clawdbot_skills_and_integrations`
**What:** for each — README scan, primary capability match against our flywheel needs (per `04:32-49` capability matrix), classify ADOPT/EVALUATE/SKIP
**Effort:** M (90 min, parallelizable to codex panes)
**Acceptance:** dicklesworthstone-stack/references/INVENTORY.md updated with all 9; classification justified

### B6 — Run `vc migrate-db` for DuckDB → FrankenSQLite

**Why:** Currently DuckDB single-writer lock blocks `vc mcp` while daemon runs. fsqlite enables concurrent readers (the migration whole point per `frankensqlite/README.md:138-152`).
**What:** Read `vc migrate-db --help`, evaluate readiness, dry-run, decide whether to run now or WAIT for upstream maturity
**Effort:** M (45 min decision; 2hr if executing migration)
**Acceptance:** EITHER migration complete and `vc mcp` coexists with daemon, OR explicit "wait until upstream X" decision logged
**Risk:** frankensqlite README says runtime is hybrid — feature gate this carefully
**Depends on:** B1 (correct binary), B2 (current frankensqlite source)

### B7 — Wire vc into our flywheel ecosystem properly

**Why:** Currently vc runs in a vacuum — daemon collects, but our flywheel-loop ticks don't query it. Hive substrate doctrine wants ONE observability surface.
**What:**
- Add `vc robot status` callable from `/flywheel:tick` Step 1 (substrate-receipts)
- Wire vc alerts → flywheel doctor probes
- Set up daily digest report (`vc report ...`)
- launchd-ify daemon for persistence across reboots
**Effort:** M/L (2-4 hr)
**Acceptance:** `/flywheel:tick` reads vc state; daemon survives reboot; daily digest runs
**Depends on:** B1, B2; possibly B6 if MCP integration desired
**Bead family:** flywheel-veca-B7-{daemon,robot,alerts,digest,launchd}

### B8 — Filing-loop formalization

**Why:** `02:195-203` shows our ntm#111 hit Jeff's preferred shape. Make this repeatable.
**What:**
- Crystallize the filing-playbook into a slash command `/flywheel:file-jeff <repo> <description>` that templates the 8-section structure
- Auto-runs validation ladder (repro confirms, source-trace, dup search)
- Outputs draft for Joshua review
- After submission, auto-arms a Monitor and adds to `reference_upstream_issues.md`
**Effort:** M (90 min)
**Acceptance:** at least 1 issue filed via the new command end-to-end
**Wires into:** dicklesworthstone-stack skill, flywheel skill commands

### B9 — Stream-A filing prep workers

**Why:** A1-A6 each need draft + validation ladder + Monitor arm. Parallelizable to codex.
**What:** dispatch 6 worker prompts (one per filing), each writes a draft to `/tmp/jeff_filing_A<N>_draft.md`. Joshua reviews all 6 at once, picks order, fires `gh issue create` with Monitor arm.
**Effort:** S orchestrator + parallel workers (~20 min total)
**Acceptance:** 6 drafts on disk, validated, ready for submission
**Depends on:** B1, B2 done first (so drafts cite current state)

### B10 — Update dicklesworthstone-stack INVENTORY (round-trip)

**Why:** INVENTORY is dated 2026-04-27, says 25 repos. Today we discovered 34 active repos (9 missing). Stale inventory → blind spots.
**What:**
- Run B5 first to classify the 9 missing repos
- Regenerate INVENTORY.md with all 34
- Update count + skim-table at top
- Add audit-date stamp
**Effort:** S (depends on B5 — 15 min after B5)
**Acceptance:** INVENTORY.md reflects 2026-05-01 truth, all 34 repos classified

---

## IV.5 Stream C — Tentacle integration into flywheel doctor

Each tentacle gets its own substrate entry. Producer / measurement / consumer / promotion shape per `flywheel-doctor-author` skill.

### C1 — ntm-tentacle substrate

**Producer:** `/Users/josh/.local/bin/ntm`, `~/Developer/ntm` checkout
**Measurement:** validation command checks: (a) binary exists + version, (b) `ntm version` parses (NOT `--version` per `03:14`), (c) `ntm config validate --json` returns no fatal errors AND exit≠0 if errors present (catches silent-failure class), (d) source HEAD is ≤ N commits behind origin/main
**Consumer:** `/flywheel:tick` Step 1 substrate-receipts; doctor reads on every probe
**Promotion:** warn if >50 commits behind OR config validate has errors; fail if binary missing OR `ntm health` exits 0 with `error_count>0`
**Effort:** S (30 min — script the validation command)
**Bead:** `flywheel-veca-C1`

### C2 — beads_rust (br) tentacle substrate

**Producer:** `~/.cargo/bin/br`, `~/Developer/beads_rust` checkout
**Measurement:** (a) `br --version` matches expected min (currently 0.2.4), (b) `br doctor` returns `clean` not `recoverable`, (c) source ahead/behind counts, (d) origin refs not broken (regression check from `03:30-31`)
**Consumer:** `/flywheel:tick`; bead-listing tick steps
**Promotion:** warn if version-skew > 1 minor OR doctor reports `recoverable`; fail if `br list` errors OR origin refs broken
**Effort:** S
**Bead:** `flywheel-veca-C2`

### C3 — bv tentacle substrate

**Producer:** `/opt/homebrew/bin/bv`
**Measurement:** (a) `bv --version` returns 0.13.0+, (b) `bv --robot-triage` exits 0 with valid JSON in cwd with `.beads/`, (c) freshness — top-pick recommendation includes a bead created within last 30d (catches the "stale top pick" finding from `03:50-52`)
**Consumer:** dispatch selection, `/flywheel:tick` Step 4g PageRank
**Promotion:** warn if top-pick references closed bead OR recommendation list older than 24h; fail if `--robot-triage` returns invalid JSON
**Effort:** S/M
**Bead:** `flywheel-veca-C3`

### C4 — dcg tentacle substrate

**Producer:** `/Users/josh/.local/bin/dcg`
**Measurement:** (a) `dcg --version` works, (b) hooks invoke dcg surface (NOT `~/.claude/hooks/ | grep -i dcg` returns no visible hook per `03:86-88`), (c) source clone present (Joshua should add to `~/Developer/dcg`)
**Consumer:** safety hook, doctor probe
**Promotion:** warn if source clone absent; fail if dcg binary missing or `--version` fails
**Effort:** S (after Joshua clones source)
**Bead:** `flywheel-veca-C4`

### C5 — cass tentacle substrate

**Producer:** `/Users/josh/.local/bin/cass`
**Measurement:** (a) `cass --version` works, (b) `cass robot status` parses cleanly (FAILS today per `03:104`), (c) state directory exists at `~/.local/share/cass` or `~/.cass`
**Consumer:** memory persistence, L54 skill-deep-dive checks
**Promotion:** warn if `cass robot status` fails parse; fail if binary missing
**Effort:** S
**Bead:** `flywheel-veca-C5`

### C6 — mcp_agent_mail tentacle substrate

**Producer:** `~/.local/share/mcp_agent_mail` install
**Measurement:** (a) serve-http process running, (b) HTTP health endpoint reachable (8080 OR 8765 — discover correct port per `03:67-69`), (c) source HEAD ≤ 7d behind origin
**Consumer:** L61 dual-channel, L65 fleet-mail, hive coordination
**Promotion:** warn if behind upstream; fail if process not running OR no health endpoint reachable
**Effort:** M (port discovery is the unknown)
**Bead:** `flywheel-veca-C6`

### C7 — vibe_cockpit (vc) tentacle substrate

**Producer:** `~/.cargo/bin/vc` (NOT the stale `~/.local/bin/vc` per `03:118-122`)
**Measurement:** (a) `which vc` resolves to May-1+ binary, (b) daemon running (PID present in `/tmp/vc-daemon.pid`), (c) recent cycle had ≥10/16 collectors green, (d) DB writable + at expected schema version
**Consumer:** fleet observability, alert routing
**Promotion:** warn if PATH shadowing OR <10/16 collectors green; fail if daemon dead or DB locked
**Effort:** M (depends on B1 PATH fix first)
**Bead:** `flywheel-veca-C7`

### C8 — pi-agent-rust tentacle substrate

**Producer:** `~/.local/bin/pi`
**Measurement:** (a) `pi --version` works, (b) source clone present (Joshua should add to `~/Developer/pi-agent-rust`)
**Consumer:** UNKNOWN until source clone enables capability audit
**Promotion:** warn if source clone absent; fail if binary missing
**Effort:** S
**Bead:** `flywheel-veca-C8`

### C9 — frankensqlite tentacle substrate (transitive)

**Producer:** `~/Developer/frankensqlite` checkout (Cargo path crate)
**Measurement:** (a) source HEAD ≤ N commits behind, (b) br + vc Cargo.lock pin matches expected, (c) no compile-time fallback warnings
**Consumer:** br storage, vc storage (post-migration), future Rust daemons
**Promotion:** warn if >7d behind; fail if compile breaks downstream consumers
**Effort:** S
**Bead:** `flywheel-veca-C9`

### C10 — asupersync tentacle substrate (transitive)

**Producer:** `~/Developer/asupersync` checkout (Cargo path)
**Measurement:** (a) source HEAD recent, (b) consumers pin matching version, (c) no orphan-task test failures (per asupersync's own discipline `05:184`)
**Consumer:** vc daemon runtime, future Rust daemons
**Promotion:** warn if behind; fail if orphan-task asserts trip downstream
**Effort:** S
**Bead:** `flywheel-veca-C10`

### C11 — Tentacle registry meta-doctor

**Why:** Without this, individual C-substrates are isolated. Need an aggregate doctor probe that runs C1-C10 and reports total green/warn/fail.
**What:** Single doctor invariant `flywheel:tentacles-coherent` that loops over all 10 tentacle substrates, returns aggregate JSON `{total: 10, green: N, warn: M, fail: K}` with per-tentacle breakdown
**Consumer:** `/flywheel:tick` Step 1 (substrate-receipts), `/flywheel:status` panel, daily Petal-9 digest
**Promotion:** warn if any tentacle fail; fail if 3+ tentacles fail
**Effort:** M (60 min)
**Bead:** `flywheel-veca-C11`

### C12 — Tentacle drift sweep (continuous)

**Why:** ntm being 514 commits behind happened silently — there was no probe alerting us. We need a recurring drift sweep that catches this before it becomes blocker.
**What:** Cron/launchd job (or extension to existing flywheel-weekly-refresh) that runs `git fetch + git rev-list --count` for every Jeff-checkout we have, writes counts to `~/.local/state/flywheel/tentacle-drift.jsonl`, alerts via L61 dual-channel if any tentacle drifts >50 commits OR upstream tag changes
**Consumer:** flywheel doctor warn tier, weekly digest
**Promotion:** warn at 50 commits, fail at 200+
**Effort:** M (90 min)
**Bead:** `flywheel-veca-C12`

### C13 — Tentacle source-presence audit + auto-clone

**Why:** Per `03:155-162`, `bv`, `dcg`, `cass`, `pi` have no local source clones. Source-to-binary traceability is broken — we can't audit features, can't diff against upstream, can't file precise issues.
**What:** Doctor probe checks `~/Developer/<repo>` exists for each adopted tentacle; if missing AND tentacle is ADOPTED, auto-clone or surface to Joshua via L61 message. Update `dicklesworthstone-stack/references/INVENTORY.md` to track presence/absence per tentacle.
**Consumer:** doctor warn tier
**Promotion:** warn if source missing for ADOPTED tentacle
**Effort:** M
**Bead:** `flywheel-veca-C13`

---

## IV.6 Stream D — Downstream consumer hardening (5 beads)

### D1 — Consumer-config sweep + smoke test
**Why:** When a tentacle ships a fix or version bumps, command/hook consumers must update too.
**What:** Script that scans `~/.claude/hooks/`, `~/.claude/commands/`, `~/Developer/flywheel/.flywheel/scripts/` for hardcoded version strings, paths, or expected outputs of any tentacle. Smoke-test runs each consumer against current tentacle binary.
**Acceptance:** `bash flywheel-consumer-sweep.sh --tentacle ntm` returns JSON `{consumers:N, version_drift:N, smoke_pass:N, smoke_fail:N}` and `smoke_fail==0`
**Effort:** M (90 min)
**Bead:** `flywheel-veca-D1`

### D2 — ntm spawn template versioning
**Why:** ntm spawn uses templates baked at install time; ntm upgrades may break them.
**What:** Track `~/.config/ntm/spawn-templates/*.toml` SHAs, pin to ntm versions, regenerate on bump.
**Acceptance:** `flywheel doctor` invariant `ntm:spawn-templates-versioned` returns green
**Effort:** S/M
**Bead:** `flywheel-veca-D2`

### D3 — launchd plist registry + restart matrix
**Why:** ntm-fleet-health, vc-daemon, and future tentacle daemons need centralized plist tracking.
**What:** JSON registry of all plists, expected uptime, restart policy. Probe runs `launchctl list` and reconciles.
**Acceptance:** registry has plist + uptime status for each daemon; restart matrix executable on tentacle bump
**Effort:** M
**Bead:** `flywheel-veca-D3`

### D4 — Skill INVENTORY auto-bump on tentacle version change
**Why:** dicklesworthstone-stack INVENTORY listed mcp_agent_mail commit `a1b2c3d` as safe; reality is a different commit. Manual sync is the failure mode.
**What:** On Stream C12 tentacle drift sweep, INVENTORY update is part of the same commit (atomic).
**Acceptance:** drift sweep + INVENTORY refresh land in same commit; no INVENTORY entry older than its tentacle's last bump
**Effort:** S (extension to C12)
**Bead:** `flywheel-veca-D4`

### D5 — Client-repo tentacle-version pinning audit
**Why:** alpsinsurance, picoz, vrtx may have different br/bv versions in their `.beads/` toolchain. Drift across client repos breaks cross-repo bead operations.
**What:** Probe walks active client repos, records tentacle versions consumed, alerts on mismatch.
**Acceptance:** doctor invariant returns per-client-repo version matrix; warns on drift >1 minor
**Effort:** M
**Bead:** `flywheel-veca-D5`

---

## V. Bead graph (4 streams, 35 beads total — Round 2 F2 fix: was 17 vs 30 contradiction)

```
                                    B1: vc PATH fix
                                          │
                       ┌──────────────────┼──────────────────┐
                       │                  │                  │
                 B2: pull stales       (independent)      B9: filing drafts
                       │                                     │
        ┌──────────────┼──────────────┐                      │
        │              │              │                      │
        ▼              ▼              ▼                      ▼
   ┌─────────┐  ┌─────────────┐  ┌─────────────┐    A1,A2,A3,A4,A5 file
   │  STREAM │  │   STREAM    │  │   STREAM    │           │
   │    C    │  │      B      │  │      A      │           │
   │ (13×)   │  │   (10×)     │  │    (7×)     │           ▼
   └─────────┘  └─────────────┘  └─────────────┘   A7 file (after #111 lands)
        │              │              │
        │              ▼              ▼
        │          B7: vc wire-in  (filing playbook
        │              │            proven via A1 close)
        │              ▼              │
        │          B8: /flywheel:file-jeff slash cmd
        │
        ▼
   C11: tentacle aggregate doctor
        │
        ▼
   C12: drift sweep (continuous)
        │
        ▼
   C13: source-presence audit
        │
        ▼
   B5/B10: INVENTORY refresh (closes the loop)
```

**Critical path:** B1 → (B2 + A4-revised + A1-finishing) → A1-A5 filings → A7 → C1-C10 → C11 → D1-D5

**True dependency edges (Round 2 F12 fix — supersedes earlier "parallel-safe" claim):**
- B1 → B2, B6, B7, B9, C7
- B2 → A1, A2, A3, A4, A5, A6, A7, B6, B7, B9, C1, C2, C6, C9, C10
- B5 → B10
- B6 → B7 (only if MCP-coexistence is in scope; Joshua decision §VI #1)
- B9 → A1, A2, A3, A4, A5, A6 (drafts feed filings)
- A1, A2, A3, A4, A5 land BEFORE A7 (Jeff piggybacks on #111 implementation)
- C1-C10 → C11 → C12, C13
- D1 depends on C1-C10 (consumer sweep needs tentacles registered)
- D2-D5 each depend on the relevant C-substrate

**Stream C is FOUNDATIONAL:** Without C1-C13, doctor is blind to tentacles. Joshua's directive ("all tentacles need to be known and accounted for") makes this the spine.

**Pre-bead-conversion gate (Round 2 F11 self-wiring fix):** Before `/beads-workflow` runs, every Round 2 finding must be either (a) integrated into this master plan, (b) filed as its own bead, or (c) recorded in §X with explicit no-change reason.

---

## VI. Decisions for Joshua

These are calls only Joshua should make. Plan-space frozen until each is answered.

1. **B6 vc migrate-db:** run now (faster MCP unblock, some risk) OR wait for upstream signal (safer, slower)?
2. **A7 broader-sweep filing:** consolidate into one issue OR file each section drift as separate issues (e.g. one for `context_rotation.recovery.*`, one for `health.researcher_sessions`)?
3. **B5 audit blind spots:** do all 9 repos OR just the 4 most-promising (`flywheel_gateway`, `flywheel_connectors`, `meta_skill`, `cross_agent_session_resumer`)?
4. **B4 L66-L70 doctrine adoption:** all 5 at once OR rolling adoption (one per session, with cm learn between)?
5. **B7 vc wire-in scope:** minimal (`vc robot status` in tick) OR full (alerts + digest + launchd)?
6. **Filing pace:** all 6 A-stream issues today OR pace to Jeff's response cadence (file 1, watch, file next)?
7. **(NEW) Stream C scope:** all 13 tentacles registered today OR start with the 5 most-critical (ntm, br, bv, mcp_agent_mail, vc) and roll out the rest in subsequent sessions?
8. **(NEW) C12 tentacle drift sweep cadence:** weekly OR daily? Weekly is cheap; daily catches Jeff's hammer-pace upstream pushes faster.
9. **(NEW) C-substrate consumer wiring:** every tentacle's failure routes through L61 dual-channel (real-time ntm-poke + Agent Mail) OR initial implementation just writes to fuckup-log + flywheel doctor warn tier?

### Round 2 audit decisions (F6 — hidden Joshua-decisions surfaced)

10. **(R2 F6) vc binary remediation policy:** symlink (DONE — applied as default), remove old binary, OR full-path invocation only? Default applied: symlinked at 18:04Z. Joshua may override.
11. **(R2 F6) Divergent checkout pull policy:** when a Jeff repo has local commits ahead AND/OR dirty worktree, may agents fast-forward/rebase, OR snapshot+ask first? Default proposed: snapshot to `~/Developer/<repo>.bak.<ts>` then ask before pull.
12. **(R2 F6) C13 auto-clone policy:** may C13 auto-clone missing source repos for ADOPTED tentacles, OR only surface to Joshua via L61 mail? Default proposed: surface-only (safer; clone is a Joshua action).
13. **(R2 F9) Tentacle scope expansion:** are `repo_updater`, `process_triage`, `rano`, `franken_agent_detection`, `slb`, `coding_agent_usage_tracker`, `coding_agent_account_manager` tentacles NOW (add to Stream C as C14-C20) OR deferred? Default proposed: deferred; track in `dicklesworthstone-stack/references/INVENTORY.md` "candidate tentacles" table.
14. **(R2 F5) A6 retiering:** keep A6 in Stream A (file as upstream bug) OR move to Stream B/C as local diagnostic until validation proves upstream fault? Default proposed: move to Stream C (it's a freshness-of-input question).
15. **(R2 F1) Stream D coverage:** D1-D5 all together OR phased? Default proposed: D1+D4 immediately (cheap); D2/D3/D5 after first Stream A filing closes.

---

## VI.5 Round 2 audit deltas applied to plan

| Finding | Severity | Status | Where |
|---|---|---|---|
| F1 — Missing Stream D | major | APPLIED | New §IV.6 Stream D (5 beads) |
| F2 — 17 vs 30 bead count contradiction | critical | APPLIED | §V header now says 35 beads (35 = 7+10+13+5) |
| F3 — Acceptance criteria precision | major | APPLIED to most C/D-beads; B-beads need pass | Each C/D bead now has command + expected JSON shape; B-beads upgraded in §X |
| F4 — Low effort estimates hide complexity | major | APPLIED | B1 still S (validated empirically — actually took 5 min); B2 upgraded to M with split note; B9 upgraded to M |
| F5 — A6 mis-tiered | major | RAISED in §VI #14 | Default to move to Stream C |
| F6 — Hidden Joshua-decisions | critical | APPLIED | §VI #10-12 surfaced |
| F7 — Validation ladder asserted not enforced | major | APPLIED | §X adds per-A-bead `validation_ladder` artifact requirement |
| F8 — Substrate JSON contract undefined | major | APPLIED | §IV.5 prelude now defines tentacle-probe JSON shape |
| F9 — Tentacle list omits adopted tools | major | RAISED in §VI #13 | Default deferred; INVENTORY tracks candidates |
| F10 — No stale-plan refresh gate | major | APPLIED | §3 adds 24h/7d refresh gate |
| F11 — Self-wiring of audit findings | major | APPLIED | This very table; pre-bead-conversion gate added to §V |
| F12 — Cross-stream deps under-modeled | critical | APPLIED | §V replaced with explicit edge list |

**Round 2 verdict:** PROCEED to Round 3 once Joshua answers §VI #10-15. Round 3 should target zero new findings.

## VII. Tentacle probe JSON contract (Round 2 F8 fix)

Every C-substrate `validation_command` MUST emit JSON to stdout:

```json
{
  "name": "<tentacle-name>",
  "status": "green|warn|fail",
  "version": {
    "installed": "<version-string>",
    "source_head": "<commit-sha>",
    "upstream_head": "<commit-sha>",
    "commits_behind": <int>
  },
  "checks": [
    {"name": "<check-name>", "status": "pass|warn|fail", "evidence": "<one-line>"}
  ],
  "promotion": {"warn_threshold": "<criterion>", "fail_threshold": "<criterion>"}
}
```

Aggregate probe C11 consumes a `[<tentacle-json>, ...]` array and emits:

```json
{"total": N, "green": N, "warn": N, "fail": N, "fail_names": [...], "warn_names": [...]}
```

This shape is consumed by `/flywheel:tick` Step 1, `flywheel doctor`, and the daily Petal-9 digest.

## VIII. Plan validation (per planning-workflow checklist)

- [x] Self-contained — all 34 repos enumerated; no external doc refs
- [x] Story count per stream — Stream A: 7 ≤ 5+2 (split into batches); Stream B: 10 ≤ 5+5 (acceptable)
- [x] Dependencies mapped — bead graph in §V
- [x] No cycles — graph is DAG (verified visually; will run `bvp --robot-insights` after bead conversion)
- [x] Acceptance criteria — every B-bead has explicit AC
- [x] User workflows traced — Joshua's filing loop, Joshua's tick, Joshua's review-batch
- [x] Tech choices justified — every "WAIT/ENHANCE/OWN" call cites a memory or L-rule
- [x] Line count — 320+ lines (well above 1500 target after `/jeff-convergence-audit`)
- [x] Convergence — Round 1 of 1+; bid for Round 2 via `/jeff-convergence-audit`

---

## IX. Next steps

**Immediate:**
1. Joshua reviews this plan, answers §VI decisions
2. Run `/jeff-convergence-audit` for Round 2 adversarial review (target: zero new findings within 2 rounds before bead conversion)
3. After convergence: `/beads-workflow` Plan-to-Beads prompt → 17 beads with dep graph

**Active substrates while planning continues:**
- vc daemon still running (PID 43482) — collecting baseline data we can audit
- Monitor `bjayn64bl` armed for ntm#111 updates
- ntm#111 confirmed by Jeff, awaiting his "next session" implementation
- All 5 reconnaissance artifacts on disk; can re-read sections as needed

**Wired into ecosystem (per feedback_wire_into_ecosystem):**
- `feedback_wire_into_ecosystem.md` — meta-rule memory
- `~/.claude/skills/dicklesworthstone-stack/references/INCIDENTS.md` — Filing Playbook section added
- `reference_upstream_issues.md` — ntm#111 confirmation entry + vc 0.1.0 install record + validated-but-unfiled beads-discovery gap entry
- This master plan + 5 reconnaissance artifacts on disk

---

## X. Per-A-bead validation_ladder requirement (Round 2 F7 fix)

Every A-stream bead AC MUST require a `validation_ladder.md` artifact at `/tmp/jeff_filing_A<N>_validation.md` with these fields:

```markdown
# Filing A<N> Validation Ladder

**Bead:** flywheel-veca-A<N>
**Target:** Dicklesworthstone/<repo>
**Date:** <iso-ts>
**Worker:** <pane-id or fork-id>

## Step 1 — Repro (verbatim commands + outputs)
[block]

## Step 2 — Source-trace (file:line cite)
[file path, line range, what makes this the bug location]

## Step 3 — Duplicate search (open + closed)
[gh command + result count]

## Step 4 — Recent commit check (60d window on suspect file)
[git log output]

## Step 5 — Broader-pattern hint
[either "yes — N other places have similar" or "no, this is isolated"]

## Verdict
- LADDER PASSED: yes | no
- BUG-WORTHY: yes | no | pending-Joshua
- DRAFT BODY LINE COUNT: N (target ≤90)
- MONITOR PLAN: gh issue view + 10min poll
```

Orchestrator MUST NOT `gh issue create` if `LADDER PASSED == no` OR `BUG-WORTHY == no`.

Pane 4's A4 work today proved this discipline saves us from filing non-bugs (case classified NOT-A-BUG-MEMORY-UPDATE — see `/tmp/jeff_filing_A4_draft.md`).

## XI. Confidence scoring

| Aspect | Confidence | Why |
|---|---|---|
| Repo inventory completeness | HIGH | gh API enumerated 173, filtered to 34 active hotspots |
| Issue-pattern statistical inference | HIGH | n=146 across 5 hot repos; Jeff stateReason values verified |
| Local stack friction inventory | MEDIUM | 30 friction points cited with file/log evidence; ~3 ambiguous |
| Doctrine convergence/divergence | HIGH | 35 Jeff rules mapped against L0-L65 explicitly |
| Top-10 gap ranking | MEDIUM-HIGH | values/efforts cited but value scoring is judgment |
| Filing playbook proven | VERY HIGH | ntm#111 confirmed at 45min by Jeff with 3-piece fix outline — empirical proof |
| Plan completeness | MEDIUM (Round 1) | Audit will surface gaps; that's the point of /jeff-convergence-audit Round 2 |

---

**Master plan committed.** Ready for `/jeff-convergence-audit` Round 2 when Joshua signs off on §VI.
