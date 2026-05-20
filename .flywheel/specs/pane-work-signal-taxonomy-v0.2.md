# pane-work-signal Taxonomy v0.2.2

**Status:** v0.2.2 extension shipped per skillos-z7y0k closed diagnosis 2026-05-20T02:05Z
**Authored:** skillos:1 (canonical-detector lane)
**Canonical regex source:** canary-verified 2026-05-20T00:25-00:42Z by flywheel:1 + skillos:1
**Schema:** `skillos.pane_work_signal.v0.2.2`

## Genesis

Joshua-directive 2026-05-20T00:05Z: codex workers must enter `/goal` mode AND accumulate runtime in pane — dispatch-time prefix alone is insufficient. Taxonomy v0.2 provided the 9 states needed to classify codex pane state for Layer 2-4 monitor-probe enforcement.

Codesigned skillos+flywheel; ratified by Joshua 2026-05-20T00:25Z.

v0.2.2 adds `codex_session_interrupted` from skillos-z7y0k closed diagnosis 2026-05-20T02:05Z. Proposed detection primitive comment: classify `Conversation interrupted | Something went wrong | Hit /feedback | Application not found` as `codex_session_interrupted`, then coalesce `>=2` panes in the same session within 120s as `CODEX-SYNCHRONOUS-INTERNAL-CRASH-MID-TASK`.

## Mechanism note (critical for any classifier impl)

`/goal` is codex's SLASH COMMAND, engaged keystroke-by-keystroke in the chevron palette. Dispatchers MUST use `.flywheel/scripts/codex-goal-activate.sh` (or equivalent) — see [codex-goal-mode-discipline.md](../doctrine/meta-learnings/codex-goal-mode-discipline.md) for the activation contract. Raw `ntm send --file` does NOT engage /goal mode; the file content lands as chat text and codex shows the chevron primed but never submits.

Canary-verified detection regexes below supersede any earlier guesses in the joint codesign packet 2026-05-20T00:18Z.

## 10 States

| State | Canonical regex | Description | Layer-monitor behavior |
|---|---|---|---|
| `goal-in-progress` | `Pursuing goal \(([0-9]+[ms]\|[0-9]+m [0-9]+s)\)` | Codex actively pursuing /goal with visible runtime accumulator | Layer 3 PASS |
| `goal-paused` | `Goal paused` | Codex /goal entered paused state; awaits resume | Layer 3 FAIL after 120s → fires `codex-goal-resume-stuck` |
| `goal-completing` | `Worked for [0-9]+m [0-9]+s` | POST-completion summary line (transient, NOT active) | SUPPRESS Layer 2/3 (false-fire trap) |
| `goal-completed` | `Goal achieved \([0-9]+[ms]?\)` OR `Goal complete\.` | Terminal completion state | Transitions to Layer 4 verify |
| `replace-goal-dialog` | `Replace current goal` literal | Confirmation dialog when activating new goal over existing | Dispatcher Enter to confirm; not a trauma state |
| `idle-chat` | prompt-only, no Goal box, no `Working` line, no `Pursuing goal` line | Codex ready but no goal mode | Layer 2 FAIL post-dispatch → fires `codex-goal-entry-failed`; or `codex-goal-mode-bypassed` if callback already received |
| `working-non-goal` | `Working \([0-9]+s • esc to interrupt\)` AND no `Pursuing goal` line | Codex working OUTSIDE /goal mode — RED FLAG (Joshua-rule violation) | Layer 3 FAIL → fires `codex-goal-mode-bypassed` |
| `error-state` | generic codex error/exception text | Generic Codex error or exception state not covered by the session-interrupted literals | Distinct handler; not Layer 2/3 fire; inspect/respawn as needed |
| `codex_session_interrupted` | `Conversation interrupted` OR `Something went wrong` OR `Hit /feedback` OR `Application not found` | Codex UI/session abort literal class, including rendered `Hit \`/feedback\` to report` text | Distinct respawn-required handler; eligible for 120s same-session crash coalescing |
| `respawn-residue` | <15s post-respawn window (state-machine context) | Stale scrollback patterns possible | SUPPRESS all classifiers |

### Notes on transient states

- `goal-completing` is the 2-5s window between callback-fire and Goal-box-clear. Layer 2/3 must suppress during this window or false-fire as `codex-goal-mode-bypassed`. Detect by presence of `Worked for Nm Ns` line.
- Early-stage transient label `Goal active Objective:` (observed during first 0-3s post-activation) is treated as part of `goal-in-progress` state. Skillos canary 2026-05-20T00:22Z showed transition `Goal active Objective` → `Working (Ns)` → `Pursuing goal (Ns)` within ~3s.

## Bracketed-paste requirement

`tmux paste-buffer -p` (bracketed paste) is REQUIRED for codex content containing `/` chars. Without `-p`, codex's slash-command palette greedily eats every `/` → file paths corrupt (e.g. `.flywheel/dispatches/...` becomes `.flywheeldispatches...`) → `codex_session_interrupted` fires when Codex emits the session-abort literals.

This is canonical for ALL paste operations into codex panes, not just `/goal` activation.

## Activation contract reference

For the 7-step canonical activation primitive that engages /goal mode, see `.flywheel/scripts/codex-goal-activate.sh`:

1. tmux send-keys keystroke-by-keystroke `/`, `g`, `o`, `a`, `l` → engages palette
2. Probe primed-blue state via `›[[:space:]]+/goal( |$)` regex
3. tmux send-keys leading space (commits slash-command argument mode)
4. tmux load-buffer + `tmux paste-buffer -p` (bracketed — preserves `/` chars)
5. tmux send-keys Enter → submit
6. Auto-handle `Replace current goal` dialog via Enter
7. Verify `Pursuing goal \(Ns\)` within max-entry-wait-s window

## Reference impl

`.flywheel/scripts/pane-work-signal-classify.sh` — single-pane classifier using the 10-state regex table above. JSON envelope output: `{schema_version, ts, session, pane, state, evidence, confidence, suppression_reason}`. See `tests/unit/test_pane_work_signal_classify.sh` for fixture-based assertions.

## Cross-references

- Joint codesign packet: `.flywheel/handoffs/20260520T000351Z-from-skillos-to-flywheel-joint-codesign-packet-draft-codex-goal-mode-4-layer-enforcement-awaiting.md`
- Flywheel activation primitive: `.flywheel/scripts/codex-goal-activate.sh` (synced commit 22bd7942)
- Trauma class doctrine: `.flywheel/doctrine/meta-learnings/codex-goal-mode-discipline.md`
- Joshua-direct quote: "we cannot afford not using /goal — you AHVE to figure out how to get this workihng reliably" + "no goal persuit, no codex"

## Version history

- v0.1 (deprecated): initial 8-state guess, regex set INCORRECT for codex 0.130
- v0.2 (ratified 2026-05-20T00:25Z): 9 states with canary-verified regex set; bracketed-paste requirement documented; activation contract referenced
- v0.2.2 (this doc, shipped 2026-05-20T02:05Z): 10th state `codex_session_interrupted`; four-literal canaries; z7y0k crash-coalescing primitive cited
