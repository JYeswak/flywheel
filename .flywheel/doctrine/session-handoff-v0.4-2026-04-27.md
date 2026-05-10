---
title: "usession handoff v0.4 2026 04 27"
type: doctrine
created: 2026-05-04
frontmatter_source: scaffold-doc-frontmatter
---

================================================================
SESSION HANDOFF — v0.4 (2026-04-27 evening)
Pairs with: orchestrator-post-compact-prompt-v3.txt (v3.4+)
Goal: every session ends with a clean orchestrator-state handoff
that the next-session orchestrator can read in 60 seconds and
start dispatching. Workers DO NOT pause for this.
================================================================

DELTA v0.4 vs v0.3 (cause: 2026-04-27 evening session-22 trauma —
orchestrator misread the handoff doctrine and fired STATUS-PROBE
at workers, asking them to halt mid-build. Joshua corrected:
"the handoff for you — the orchestrator — is to ensure your
docs are all updated before I compact your pane. It has nothing
to do with where workers are at. They need to keep operating
without a halt during a handoff."):

  PRIME RULE — HANDOFF IS ORCHESTRATOR-ONLY
  =========================================
  A handoff is the orchestrator preparing its OWN documents
  (.continue-here.md, MEMORY.md, project memory, skill updates)
  before /compact reclaims its context. Workers continue building
  the entire time. Their state is captured BY OBSERVATION
  (`tmux capture-pane`, `git log`, file inspection) — never by
  interrupting them.

  Workers DO NOT halt. STATUS-PROBE is FORBIDDEN during handoff.
  Step 2 ("Worker Wind-Down") is REPLACED with "Worker Observation"
  in v0.4.

  Why: workers building a 30-45min research arc don't lose context
  on /compact. THEY are not the orchestrator pane. Halting them
  loses real work for no benefit. The orchestrator's /compact
  doesn't touch worker panes; their codex sessions persist.

  Validated v0.4 trauma 2026-04-27 session-22: orchestrator
  wrongly fired STATUS-PROBE during handoff to dual-lens research
  (~3 min into 30-45min wall). Joshua overrode in real-time
  ("don't halt - continue"). Codified now to prevent recurrence.

DELTA v0.3 vs v0.2 (preserved for history):
  1. Flywheel ecosystem (~/.claude/skills/.flywheel/) is now load-
     bearing autonomy. Step 1 verifies launchd plists are loaded.
  2. CLAUDE.md split: Step 6 scans for Step-5/8-worthy patterns
     that should be promoted into ~/.claude/references/claude-md-*.md.
  3. Petal 9 separation: handoff feeds /petal9-close (Sunday), it
     does NOT run it. Step 5 cm learn entries become Sunday-mining
     candidates. Don't dispose this session — let Petal 9 do it.
  4. Notify channel: Step 9 banner triggers `notify` on completion
     (Pushover ping to Joshua's phone) so handoff lands even if
     Joshua's away from the terminal.

DELTA v0.2 vs v0.1 (preserved for history — 2026-04-27 morning):
  1. Pre-staged dispatch packets (/tmp/dispatch_*.txt) are session
     artifacts that evaporate on /tmp purge — handoff must list
     them explicitly so next session can resume without rewriting.
  2. File-overlap collision rule: orchestrator checks active
     dispatches' touched files vs candidate next-bead before
     dispatching.
  3. ALREADY_DONE-via-pre-check is a first-class success outcome.
  4. bv queue can lag git HEAD by minutes; cross-check via
     `git log --since=`.
  5. Step 1 verifies session commits referenced socraticode_queries=K
     in their callbacks (Axiom 9 audit at handoff time).

PRINCIPLE: a handoff is the petal-9 capture of the session. If the
next session has to ask "where were we?" — handoff failed.

Run when: ~85% context, OR end of work-block, OR before /compact.

================================================================
THE 9 STEPS (sequential — do not skip ahead)
================================================================

----------------------------------------------------------------
STEP 1 — STATE FREEZE (read-only, observation only)
----------------------------------------------------------------
Snapshot of truth before any action. NO worker interrupts.

  git log --oneline -10
  git status --short | head -20
  git rev-parse --abbrev-ref HEAD
  git log @{u}..HEAD --oneline    # unpushed commits
  for pane in 2 3; do
    echo "--- pane $pane ---"
    tmux capture-pane -t <session>:0.$pane -p -S -40 | tail -40
  done
  br list --status=in_progress --json | jq -r '.issues[] | "\(.id) \(.title)"'

  # bv-stale cross-check (v0.2): bv queue lags git HEAD by minutes.
  git log --since='6 hours ago' --grep='\[bd-X\]' --oneline

  # Axiom 9 audit (v0.2): every commit this session referenced
  # socraticode_queries=K in its callback. Verify:
  for sha in $(git log @{u}..HEAD --format=%h); do
    grep -q "socraticode_queries" <(git log -1 --format=%B $sha) \
      || echo "WARN: $sha lacks socraticode evidence"
  done

  # Pre-staged dispatch packet inventory (v0.2):
  ls -lt /tmp/dispatch_*.txt 2>/dev/null | head -10

  # Flywheel ecosystem state (v0.3): verify autonomy plists loaded
  ~/.claude/skills/.flywheel/bin/flywheel doctor 2>&1 | tail -8
  launchctl list | grep -E 'flywheel-(weekly-refresh|digest)' | wc -l

----------------------------------------------------------------
STEP 2 — WORKER OBSERVATION (v0.4 — replaced "wind-down")
----------------------------------------------------------------
NO STATUS-PROBE. NO HALT. Workers keep building.

For each active worker pane, observe-only:
  - Capture last 80 lines of scrollback (already done in Step 1)
  - Note current phase / file / sub-step from observation alone
  - Note ETA from worker's own progress messages (if visible)
  - Document in Step 7's "In flight RIGHT NOW" section verbatim
    from observation

If a worker is genuinely hung (>40min no scrollback change AND
no commit AND no callback): file as bead via `br create -p N`,
let next session decide whether to interrupt. The handoff itself
does NOT interrupt — it captures the hung state.

If a worker is mid-callback (committing right now): wait 30-60
seconds for the commit to land, then snapshot again. Don't write
the handoff with stale git state.

Output: per-pane observation logged. NO ntm send. NO STATUS-PROBE.

----------------------------------------------------------------
STEP 3 — COMMIT + PUSH GATE (orchestrator-side only)
----------------------------------------------------------------
Atomic commits for orchestrator-side work this session:
  - .continue-here.md (always — but write it in step 7 first)
  - MEMORY.md (if step 5/8 added an entry)
  - Any ad-hoc docs / .planning/* additions ORCHESTRATOR wrote
    (NOT worker-authored — they're already committed by worker)

Skip orchestrator-side commits if no orchestrator work happened
(pure dispatch sessions where workers did all commits).

Then push EVERYTHING:
  git push origin <branch>

Why push: next-session orchestrator pulls latest at startup.
If this session's commits aren't on origin, the next session
runs from stale code and may re-do work.

EXCEPTION: if force-push or main-branch commit needed,
escalate to Joshua per Prime Directive (b). If push fails due to
known cause (binary backlog, etc.): document in Step 7 + Step 9
banner; do NOT block handoff on it.

----------------------------------------------------------------
STEP 4 — GRADE (7-axis with evidence)
----------------------------------------------------------------
Per CLAUDE.md §8 rubric. One tight paragraph per axis.
Each axis cites a SHA, filename, count, or measurable outcome.

Format:

  | Axis | Score | Evidence |
  |------|-------|----------|
  | Flywheel Compatibility | N/10 | what compounded |
  | Accretive Leverage | N/10 | reusable artifacts produced |
  | Planning/Bead Rigor | N/10 | beads polished, deps mapped |
  | Safety/Auditability | N/10 | DCG/SLB/UBS engaged? rollback? |
  | Performance & Agent-Ergo | N/10 | speed, JSON, parallelism |
  | Taste & De-Slopify | N/10 | clean? Joshua-approve? |
  | Operationalization | N/10 | runnable, documented |

  Composite: N.N/10. Verdict: A+ / A / B / C / D / F.

Auto-reject (any one → grade caps at C):
  - Hardcoded secrets shipped
  - Skipped beads for multi-file changes
  - Deployed without SLB on prod
  - Non-trivial commit without socraticode K≥10
  - Fictional output passed process gates (Axiom 10 fail)
  - File-overlap collision shipped (two panes raced same file)
  - Workers interrupted during handoff (v0.4 auto-fail)

ALREADY_DONE wins (v0.2): a worker that returns
verdict=ALREADY_DONE after STOP-pre-check is a top-grade outcome.
Composite grade celebrates already_done parity with shipped.
Step 9 banner: report both counts.

----------------------------------------------------------------
STEP 5 — CASS PETAL-9 (cm learn)
----------------------------------------------------------------
Capture 1-3 patterns surfaced this session that meet ONE of:
  (a) 3-strike threshold — same anti-pattern hit 3+ times.
  (b) Genuinely novel — one-off but load-bearing.
  (c) Confirmation memory — non-obvious approach Joshua validated.

For each: write a memory file at
  ~/.claude/projects/-Users-josh-Developer-<repo>/memory/<type>-<topic>-<date>.md

Then prepend MEMORY.md with one-line index entry (under 200 chars).

Skip if session was routine bead-grinding with no new patterns.
NEVER add filler memories just to fill the step.

Petal 9 separation (v0.3): cm learn entries become Sunday-mining
candidates for `/petal9-close`. Just capture; don't dispose.

----------------------------------------------------------------
STEP 6 — SKILL UPDATES (audit pass)
----------------------------------------------------------------
"Did anything fall through that should be encoded into a global
skill?" — sweep, not mandatory rewrite.

Most healthy sessions: skip step 6 entirely. Edits happen inline
during work. This step is the safety net.

----------------------------------------------------------------
STEP 7 — .continue-here.md (THE handoff document)
----------------------------------------------------------------
Overwrite. Single source of truth for next session.

Required sections (in order):

  # .continue-here.md — <date> <round> close

  **Branch:** <branch> @ <SHA> (<PUSHED|UNPUSHED N commits>)
  **Status:** <one-sentence summary>

  ## Session grade — N.N/10
  [copy table from step 4]

  ## What this session shipped (N commits)
  [SHA → one-line description]

  ## In flight RIGHT NOW (workers continue building during handoff — v0.4)
  [pane → bead/dispatch → observed file/phase → ETA from scrollback]
  [Workers keep operating. Next session reaps callbacks normally.]
  [If empty: "No workers in flight; pane 2 + 3 idle."]

  ## Pre-staged dispatch packets (v0.2)
  [List unconsumed /tmp/dispatch_*.txt files. If a packet matters
   for tomorrow, MOVE it: `cp /tmp/dispatch_X.txt
   .planning/queued-dispatches/dispatch_X.txt`. Empty if none.]

  ## File-overlap rule (v0.2 — orchestrator dispatch invariant)
  [active dispatches' touched files; defer if non-empty intersect]

  ## Hard rules learned this session
  [bullet list of trauma codifications + permanent guards]

  ## Tomorrow's First 3 (ranked, executable)
  1. <concrete command or bead-id> — why it's first
  2. ...
  3. ...

  ## Ship gate (north star — unchanged unless mission flipped)
  [one paragraph + ETA in sessions]

  ## Open questions / Tier-3 escalations
  [if any items genuinely need Joshua attention next session]

Quality bar: a fresh-eyes orchestrator must be able to read this
file post-compact and dispatch within 60 seconds without asking
Joshua anything.

----------------------------------------------------------------
STEP 8 — PROJECT MEMORY (conditional)
----------------------------------------------------------------
Write project-<repo>-<date>-<topic>.md ONLY if this session
shipped a structurally-important arc.

Routine sessions: SKIP. Don't bloat MEMORY.md past truncation cap.

----------------------------------------------------------------
STEP 9 — PRE-COMPACT BANNER
----------------------------------------------------------------
Print to stdout. Format:

  ════════════════════════════════════════
  HANDOFF COMPLETE — <date> <round>
  ════════════════════════════════════════

  Grade: <N.N/10> (<verdict>)
  Commits this session: <count> (<all PUSHED | N unpushed>)
  Beads closed: <count> — <comma-separated bead-ids>
  Workers in flight: <count> (<roles>) — continue building during /compact
  Ship-gate delta: <e.g. "Wave D 1/6 → 2/6">
  Skills updated: <count>: <comma-separated skill names>
  Project memory: <wrote project-X.md | skipped — routine>

  ── Tomorrow's First 3 ──
  1. <action>
  2. <action>
  3. <action>

  ── Ready ──
  Run /compact when ready.
  v3 post-compact prompt resumes from .continue-here.md @ <SHA>.
  Workers continue building — next session reaps their callbacks.

  ════════════════════════════════════════

After printing: stop. Do NOT continue working. Joshua decides
when to /compact.

Notify ping (v0.3): after printing, fire ONE notify call:
  notify "Handoff <date> <round>" "Grade <X.X>/10. <commits>
  commits, <beads> beads closed. Run /compact when ready."

Default priority (0). Do NOT use --priority 1+ unless session
was a Tier-3 escalation.

================================================================
QUICK MODE (if context is at 95%+ and you must wrap fast)
================================================================
Only steps 1, 3, 7, 9. Skip:
  - Step 2 observation (just `tmux capture-pane` once, paste it)
  - Step 4 grade (defer to next session)
  - Step 5 cm learn (defer)
  - Step 6 skill audit (defer)
  - Step 8 project memory (defer)

Add a line to .continue-here.md: "QUICK HANDOFF used — full
grade/audit deferred to next session step 1."

================================================================
ANTI-PATTERNS (failure modes — auto-grade D)
================================================================
- "Want me to /compact now?" — Joshua decides, not you.
- Skipping step 7 because "the situation is obvious" — IT IS NEVER
  OBVIOUS post-compact. Always overwrite .continue-here.md.
- Inventing CASS memories to fill step 5 — bloats memory db.
- Inflating grade — every axis must cite evidence.
- Listing 10 items in Tomorrow's First 3 — must be 3 ranked.
- Forgetting to push in step 3 — next session reads stale origin.
- INTERRUPTING WORKERS DURING HANDOFF (v0.4 auto-fail) — workers
  keep building; observe-only.
- Writing the handoff while a worker is mid-commit — wait 30-60s,
  re-snapshot, then write. Don't capture stale git state.

================================================================
END
================================================================
