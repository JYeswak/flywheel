# Convergence Bead Plan — Autoloop Diagnose-Then-Repair + Fleet Coverage

Generated: 2026-05-01
Source: jeff-convergence-audit Phase 1 (3 surfaces, 10 findings)
Audit outputs:
- `/tmp/convergence_audit_pane2_autoloop.md` — autoloop script audit
- `/tmp/convergence_audit_pane3_fleet.md` — fleet state-doc gaps
- `/tmp/convergence_audit_pane4_gates.md` — gate/dispatch trauma patterns

## Convergence Status

Round 1 complete (3 parallel auditors). No Round 2 adversarial yet — proceeding
to bead synthesis per Joshua's instruction ("create beads following /planning-workflow,
dispatch using /flywheel:dispatch to panes 2, 3, and 4").

## Bead Graph (7 beads, 3 dispatch packets)

### Bead 1: autoloop-diagnose-repair (P0, dispatch to pane 2)

**What:** Replace skip-and-idle negative cache with diagnose-then-repair loop in
`flywheel-autoloop`. Three changes:
1. Widen jq selection filter from `status == "ready"` to `status IN("ready","warn","fail","interrupt")` with priority scoring (fail=100, interrupt=90, warn=70, ready=50)
2. Replace `doctor_failed` exit path with `diagnose_and_repair_doctor_failure()` that reads doctor JSON, maps `action:docs_state` to repair functions, retries doctor after repair, only caches if repair itself fails
3. Replace `tick_failed` exit path with `diagnose_and_repair_tick_failure()` that checks for missing dirs, malformed overrides, and permission issues

**Acceptance:** `bash -n` passes. Dry-run with `FLYWHEEL_AUTOLOOP_STATE_DIR=/tmp/test-state` selects a failing repo and attempts repair instead of skipping. Negative cache writes `repair_failed` or `repair_not_available`, never `doctor_failed` directly.

**Deps:** none
**Files:** `~/.claude/skills/.flywheel/bin/flywheel-autoloop`
**Phase 0 safe:** yes — deterministic, no LLM, no agent wakeups

### Bead 2: fleet-lock-repair-tool (P1, dispatch to pane 3)

**What:** Create `flywheel-loop lock-repair --repo <path> --json` subcommand (or
standalone script `flywheel-lock-repair`) that:
1. Reads `.flywheel/MISSION.md`, `GOAL.md`, `STATE.md`
2. Computes sha256 of body (minus YAML frontmatter)
3. Adds/updates `lock_hash` in frontmatter
4. Appends per-file rows to `.flywheel/lock-log.jsonl`
5. Backs up originals to `.flywheel/*.bak.<ts>`

This is the repair function that bead 1's `diagnose_and_repair_doctor_failure()` calls
for `docs_state=drift_detected`.

**Acceptance:** Running lock-repair on a repo with `drift_detected` then running
`doctor --strict --json` returns `status=ok`. Content is byte-identical minus
frontmatter hash field.

**Deps:** none (bead 1 calls it, but can be built independently)
**Files:** `~/.claude/skills/.flywheel/bin/flywheel-lock-repair` (new) or added
as subcommand to `flywheel-loop`
**Phase 0 safe:** yes — writes only `.flywheel/` metadata, backs up first

### Bead 3: fleet-state-docs-repair (P1, dispatch to pane 3)

**What:** Run lock-repair on the 4 drifted repos (flywheel, picoz, vrtx,
zeststream-procurement). For each:
1. Run `flywheel-lock-repair --repo <path> --dry-run --json` (preview)
2. Review diff (automated: confirm content unchanged, only hash added)
3. Apply: `flywheel-lock-repair --repo <path> --json`
4. Verify: `flywheel-loop doctor --strict --repo <path> --json` → status=ok
5. Refresh stale `loop.json` fields from doctor output

**Acceptance:** `flywheel-loop fleet --root ~/Developer --json` shows ready_count >= 5.
All 4 repos pass `doctor --strict`.

**Deps:** bead 2
**Files:** per-repo `.flywheel/MISSION.md`, `.flywheel/GOAL.md`, `.flywheel/STATE.md`,
`.flywheel/lock-log.jsonl`, `.flywheel/loop.json`

### Bead 4: dispatch-gate-narrow (P1, dispatch to pane 4)

**What:** Patch `~/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh` to:
1. Split compound commands on `;|` before matching
2. Skip `tmux send-keys -X` control-mode commands
3. Match dispatch tokens only within the tmux-send segment, not the whole line
4. Add explicit comment that `ntm send` is canonical and not blocked here

**Acceptance:** Test cases:
- `tmux send-keys -t vrtx:0.2 "Read /tmp/dispatch..."` → DENY (true positive)
- `tmux send-keys -X cancel; ntm send vrtx --pane 2 "..."` → ALLOW (was false positive)
- `ntm send picoz --pane=2 "Body mentions tmux send-keys"` → ALLOW (was false positive)
- `ntm assign picoz --auto --watch` → DENY (true positive, retired)

**Deps:** none
**Files:** `~/.claude/hooks/flywheel-loop-dispatch-transport-gate.sh`

### Bead 5: skillos-validation-command (P2, included in pane 3 packet)

**What:** Add a structural validation command to `/Users/josh/Developer/skillos/.flywheel/loop.json`.
Command: `test -s .flywheel/MISSION.md && test -s .flywheel/GOAL.md && test -s .flywheel/STATE.md && test -s state/kernel.json`
Then verify with doctor.

**Acceptance:** `flywheel-loop doctor --repo ~/Developer/skillos --json` returns
`status=ok`, `action=ready_for_tick`.

**Deps:** none
**Files:** `/Users/josh/Developer/skillos/.flywheel/loop.json`

### Bead 6: incidents-md-creation (P2, included in pane 4 packet)

**What:** Create `~/Developer/flywheel/INCIDENTS.md` with entries for the 3
promotion-ready fuckup classes:
1. `autoloop-skip-instead-of-fix` — Forever-Rule: loops diagnose and repair, never skip
2. `agent-fighting-gate` — Forever-Rule: never retry a denied command verbatim
3. `repeat-gate-deny-dispatch_transport` — mixed true/false positive analysis, gate narrowing applied

Each entry includes: class, event count, cost citation, Forever-Rule, fix applied.

**Acceptance:** File exists with 3 entries. `flywheel-loop fuckup triage` shows
these classes as "processed."

**Deps:** beads 1, 4 (references their fixes)
**Files:** `~/Developer/flywheel/INCIDENTS.md` (new)

### Bead 7: canonical-doctrine-snapshot (P2, included in pane 3 packet)

**What:** Copy `~/Developer/flywheel/AGENTS.md` to `.flywheel/AGENTS-CANONICAL.md`
in the 4 repos that are missing it (flywheel, picoz, vrtx, zeststream-procurement).
Include source hash and timestamp in a comment header.

**Acceptance:** `flywheel-loop doctor --json` no longer reports
`canonical_doctrine_state=canonical_doctrine_missing` for these repos.

**Deps:** none
**Files:** 4x `<repo>/.flywheel/AGENTS-CANONICAL.md`

## Dispatch Packets

### Packet A → Pane 2: Autoloop diagnose-then-repair
- Bead 1: autoloop-diagnose-repair

### Packet B → Pane 3: Fleet coverage repair
- Bead 2: fleet-lock-repair-tool
- Bead 3: fleet-state-docs-repair (deps bead 2)
- Bead 5: skillos-validation-command
- Bead 7: canonical-doctrine-snapshot

### Packet C → Pane 4: Gate + doctrine
- Bead 4: dispatch-gate-narrow
- Bead 6: incidents-md-creation

## Success Criteria

1. `flywheel-loop fleet --root ~/Developer --json` shows `ready_count >= 5` (up from 1)
2. `flywheel-autoloop` dry-run selects a failing repo and attempts repair
3. Dispatch gate passes compound `tmux -X cancel; ntm send` commands
4. `INCIDENTS.md` exists with 3 promoted fuckup classes
5. All opted-in repos pass `flywheel-loop doctor --json` with `status=ok`
