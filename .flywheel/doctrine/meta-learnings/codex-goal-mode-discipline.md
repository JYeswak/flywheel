# Codex /goal-mode Discipline

**Status:** ratified per Joshua-direct 2026-05-20T00:25Z (T1)
**Authored:** skillos:1 (canonical-doctrine lane)
**Schema:** `skillos.codex_goal_mode_discipline.v1`

## Genesis Note

Joshua-direct 2026-05-20T00:05Z:

> "codex workers now ONLY get disptached using /goal <task> format - if they aren't racking up on their goal, persueing goal in their pane, its done wrong - this is a new requirement - let skillos know and figure out how to ensrue that this new rule is baked across our ecosystems."

Joshua-direct 2026-05-20T00:25Z (T1 ratification):

> "yes proceed - make sure that you both know how to do this and get it fucking settled system wide"

Joint codesign packet between skillos:1 + flywheel:1: 4-layer enforcement design + 5 trauma classes + 8-state pane-work-signal taxonomy (later expanded to 9 states post-canary, then 10 states with `codex_session_interrupted`). Single Joshua-ratification covered all components.

## Activation Mechanism (LOAD-BEARING)

`/goal` is codex's SLASH COMMAND, engaged keystroke-by-keystroke. Three mistakes that have all been observed today:

1. **Sending `/goal <text>` as paste content** (`ntm send --file packet.txt` or `tmux paste-buffer` without `-p`): content lands as chat text, palette never engages, codex sees `/goal ...` literally as a chat message. Pane chevron may show `/goal complete task above` primed but never submits without Enter.
2. **Using unbracketed paste-buffer** (no `-p` flag): codex slash-command palette greedily eats every `/` char in pasted content → file paths corrupt (e.g. `.flywheel/dispatches/...` becomes `.flywheeldispatches...`) → `Conversation interrupted` error fires.
3. **Treating `Working (Ns)` as goal-in-progress**: it is NOT. `Working` without `Pursuing goal` line is `working-non-goal` state — Joshua-rule violation.

Canonical activation primitive: `.flywheel/scripts/codex-goal-activate.sh` (7-step sequence). See [pane-work-signal taxonomy v0.2](../../specs/pane-work-signal-taxonomy-v0.2.md) for activation contract details.

## 6 Canonical Trauma Classes

### 1. codex-goal-entry-failed

**Trigger:** Layer 2 monitor detects no `Pursuing goal (Ns)` text within 30s post-dispatch.

**Detection:** `pane-work-signal-classify.sh` returns `idle-chat` state >30s after dispatch event in dispatch-log.

**Remediation:**
- First failure: empty submit-poke (Enter to fire any queued chevron content)
- Second failure: respawn via `/flywheel:respawn`
- Evidence path: `~/.local/state/flywheel/codex-goal-mode-ratification-evidence.jsonl`

**Sister:** codex-goal-mode-bypassed (similar symptom different timing — entry-failed = never started; bypassed = started + callback without ever entering goal mode)

### 2. codex-goal-abandoned

**Trigger:** Layer 3 monitor detects mode-regression from `goal-in-progress` → `goal-paused` or `idle-chat` WITHOUT a corresponding callback in dispatch-log.

**Detection:** state transition observed over consecutive 60s polls; no `callback` event in dispatch-log within the same window.

**Remediation:**
- Operator-resume command: send `/goal resume` keystrokes via codex-goal-activate.sh resume-mode
- After 2 failed resumes: respawn

**Sister:** codex-goal-resume-stuck (related but distinct — abandoned = goal entered then dropped; resume-stuck = paused state persisting without auto-resume)

### 3. codex-goal-mode-bypassed

**Trigger:** Layer 4 monitor detects callback received in dispatch-log but pane state never showed `goal-in-progress` at any point between dispatch-ts and callback-ts.

**Detection:** retrospective inspection of pane-work-signal history from dispatch-ts to callback-ts.

**Remediation:**
- Flag as Joshua-rule violation in evidence corpus
- File bead with full pane scrollback + dispatch text + classifier history
- Review prompt structure for /goal-mode-defeating patterns

**Severity:** RED FLAG — indicates dispatcher path bypassed activation primitive OR codex internal bug.

### 4. codex-goal-resume-stuck

**Trigger:** `goal-paused` state persists >120s without auto-resume or operator intervention.

**Detection:** consecutive `goal-paused` classifications across 2+ polls (60s polling cadence).

**Remediation:**
- First attempt: empty submit-poke
- After 2 failed pokes: respawn
- Evidence: scrollback snapshot before respawn

**Sister:** codex-goal-abandoned (resume-stuck is the paused-state-persisting subset)

### 5. codex-goal-mode-flapping

**Trigger:** ≥3 transitions between `goal-in-progress` ↔ `goal-paused` within a single dispatch window.

**Detection:** transition count from classifier history.

**Remediation:**
- Indicates prompt-structure problem, NOT codex bug
- Halt dispatch loop for the offending bead
- Prompt refactor: simplify, remove ambiguity, single clear AC
- Re-dispatch via activation primitive after refactor

**Severity:** prompt-structural; not a respawn class.

### 6. codex-synchronous-internal-crash-mid-task

**Trigger:** `>=2` panes in the same session show `codex_session_interrupted` within a 120s window.

**Detection:** pane-work-signal classifier returns `codex_session_interrupted` for multiple same-session panes, with evidence from one of the session-abort literals: `Conversation interrupted`, `Something went wrong`, `Hit /feedback`, or `Application not found`.

**Remediation:**
- Snapshot scrollback before state is overwritten
- Respawn both affected panes
- File trauma bead with session/pane ids, dispatch prompt hash, classifier evidence, and available Codex TUI log context

**Severity:** Codex synchronous internal crash; sister to single-pane `codex_session_interrupted`, distinct from post-callback ghost stalls.

## Bracketed Paste Discipline (CRITICAL)

`tmux paste-buffer -p` (bracketed paste) is REQUIRED for ALL content with `/` chars piped to codex panes, NOT just /goal activation. Without `-p`:

- File paths corrupt (`/` eaten by slash-command palette)
- `codex_session_interrupted` fires when Codex emits the session-abort literals
- Pane enters respawn-required interrupted state

Verified empirically by flywheel:1 canary 2026-05-20T00:30Z. Both fleets MUST use `-p` flag.

## Evidence Corpus Path

`~/.local/state/flywheel/codex-goal-mode-ratification-evidence.jsonl`

All 8 active orchs log goal-mode-failure events here during T1+0..72h ratification window. Format:

```json
{"schema_version":"codex_goal_mode_evidence.v1","ts":"<UTC>","session":"<name>","pane":<N>,"class":"<trauma_class>","evidence":"<line>","dispatch_text_sha":"<sha256>","bead":"<id>"}
```

## Cross-references

- pane-work-signal taxonomy v0.2.2: `.flywheel/specs/pane-work-signal-taxonomy-v0.2.md`
- Activation primitive: `.flywheel/scripts/codex-goal-activate.sh`
- Reference classifier: `.flywheel/scripts/pane-work-signal-classify.sh`
- Joint codesign packet: `.flywheel/handoffs/20260520T000351Z-from-skillos-to-flywheel-joint-codesign-packet-draft-codex-goal-mode-4-layer-enforcement-awaiting.md`
- Flywheel T1 deliverables (closed): flywheel-701fi (probe primitive + classifier daemon) + flywheel-rrrqk (/flywheel:dispatch v2 wrapper)
- Skillos T1 deliverables: skillos-ore7m (this spec + impl), skillos-xrwgg (this doctrine), skillos-96x73 (T1+48..72h fleet propagation)

## L160 Promotion Threshold

Promote to MP-NN candidate at next mp-authoring-cadence window after fleet-wide compliance hits ≥80% for 1 week post-T1. Track via:

- Compliance rate from `scripts/skillos_codex_goal_format_audit.py` (per-orch goal_prefixed/total ratio)
- Trauma-class fire rate (rolling 1wk avg) <5% per dispatch
- Zero `codex-goal-mode-bypassed` fires for 1wk (this is the strictest gate — bypassed = direct Joshua-rule violation)

## Version History

- v1 (2026-05-20T00:45Z): initial canonical doctrine; 5 trauma classes ratified per joint codesign packet; bracketed-paste discipline documented
- v1.1 (this doc, 2026-05-20T02:05Z): trauma class 6 `codex-synchronous-internal-crash-mid-task` added for same-session `codex_session_interrupted` coalescing
