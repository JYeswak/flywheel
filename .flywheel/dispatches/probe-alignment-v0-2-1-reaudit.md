# Probe Alignment to v0.2.1 + Type 2 Re-Audit

## Context

Skillos:1 disposition handoff (.flywheel/handoffs/20260520T011004Z-...): all 6 divergence findings from flywheel-kq8go Type 2 audit dispositioned. v0.2 canonical wins — flywheel probe must align (no flywheel-side variant ratified).

Commitments handoff (.flywheel/handoffs/20260520T011500Z-...): all 3 commitments shipped ahead of T1+48h. Canonical classifier at commit 52df5469. SHA: f84795dca8eaae3463b9d85dc362be53498a43c966522894baf23d28a9ca16a7 (verified matching skillos /Users/josh/Developer/skillos/.flywheel/scripts/pane-work-signal-classify.sh).

## Deliverables

### Step 1: Read skillos canonical
- /Users/josh/Developer/skillos/.flywheel/scripts/pane-work-signal-classify.sh (the 10-detection-state classifier)
- /Users/josh/Developer/skillos/.flywheel/specs/pane-work-signal-taxonomy-v0.2.md (spec)
- /Users/josh/Developer/skillos/tests/unit/test_pane_work_signal_classify.sh (canary suite 9/9 PASS)

### Step 2: Align flywheel probe to v0.2.1
Edit .flywheel/scripts/codex-goal-mode-monitor-probe.sh — update regexes + trauma mappings to MATCH skillos canonical:

| State | Canonical regex | Current probe | Action |
|---|---|---|---|
| goal-in-progress | `Pursuing goal \(([0-9]+[ms]\|[0-9]+m [0-9]+s)\)` | `Worked for...` (stale) | REPLACE |
| goal-completing | `Worked for [0-9]+m [0-9]+s` (POST-completion suppression) | conflated with active | SEPARATE |
| goal-completed | `Goal achieved \([0-9]+[ms]?\)` OR `Goal complete\.` | stale | REPLACE |
| replace-goal-dialog | `Replace current goal` literal | absent | ADD |
| goal-in-progress composite | `Goal active Objective:` + `Working (Ns)` within 3s | absent | ADD (priority 2.5) |
| idle-chat sub | `Goal active Objective:` standalone | absent | ADD with suppression_reason |
| working-non-goal trauma | fires `codex-goal-mode-bypassed` (NOT abandoned) | wrong mapping | CORRECT |
| error-state | `Conversation interrupted` OR `Application not found` OR codex error | less anchored | TIGHTEN |

### Step 3: Run skillos canary suite against flywheel probe
- Copy skillos canary fixtures to tests/codex-goal-mode-monitor-probe-canary-fixtures/
- Adapt skillos test runner pattern for flywheel probe
- Verify all 9 canary patterns classify correctly under flywheel probe (expect 9/9 PASS)

### Step 4: Extend flywheel smoke fixture
- tests/codex-goal-mode-monitor-probe-smoke.sh: add 5 new assertions covering the canary patterns above
- Total assertions: 19 (current) + 5 = 24 PASS

### Step 5: Re-write conformance audit
Replace .flywheel/audits/probe-vs-taxonomy-v0.2-conformance-20260520.md with re-audit results:
- "0 divergences confirmed post-alignment"
- shasum match recorded
- canary suite results recorded
- Per-state regex alignment table verified

## Acceptance

- Flywheel probe regexes match v0.2.1 canonical (string equality on regex patterns OR shasum match if probe is direct copy)
- Skillos canary suite 9/9 PASS when run against flywheel probe classifier
- Flywheel smoke fixture: 24+ assertions PASS
- Re-audit document confirms 0 divergences
- shellcheck PASS
- Bead closed

## Loop contract

- Track 3 only
- mcp-agent-mail file_reservation_paths before edits to monitor-probe.sh + smoke fixture
- Bridge daemon LIVE — auto-routes callback. Belt+suspenders: ntm send flywheel --pane=1.
- SCR event: C7_verification_density + C6_trauma_outflow (probe regression fix)
- STOP on Track 1/2 breach, BLOCKED, >3h hard cap
- DEEP-WORK: validate (smoke fixture + canary suite + 1 live probe run on real pane state), clean tree
- DO NOT modify the activation primitive (codex-goal-activate.sh) — that's separate concern
- DO NOT modify the wrapper (flywheel-dispatch-wrapper.sh) — flywheel-zynit owns that

## FIRST ACTION

1. br show <this bead id>.
2. Read all 3 skillos canonical files listed in Step 1.
3. Read .flywheel/scripts/codex-goal-mode-monitor-probe.sh end-to-end.
4. ACK row.
5. Make alignment edits.
6. Self-validate (smoke + canary suite).
7. Re-write audit document.
8. Commit + close bead + DIRECT pane-1 ntm send + truth-verify status=closed.
