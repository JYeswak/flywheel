# Cross-reference: codex#21241 vs shipped flywheel freeze subclasses (2026-05-06)

**Bead:** `flywheel-codex-21241-stuck-on-every-prompt-cross-ref-2026-05-06` (P1, docs-only)
**Mission anchor:** `80a15c4368187483a6ba91a904248e10266233fb4d14f301b277f9a6c1a12d0a`
**Co-ownership:** skillos:1 second cross-orch co-own delivery (sibling to
`oom_killed_pane`, commit `ebf44878`).
**Detector under triage:** `.flywheel/scripts/codex-template-stuck-detector.sh`
(VERSION `codex-stuck-detector.v1.2.0`).

## Upstream report (codex#21241)

| Field | Value |
|---|---|
| Title | codex-cli stucks on every prompt |
| State | OPEN |
| Reporter | vladon (Vlad Yaroslavlev) |
| Codex CLI | 0.128.0 |
| Subscription | Pro |
| Model | gpt-5.5 |
| Platform | Linux 6.6.87.2-microsoft-standard-WSL2 x86_64 |
| Terminal | Windows Terminal (WSL) |
| Labels | bug, CLI, TUI, windows-os |
| Repro | Uploaded thread `019df9e4-80ce-7831-8ff9-d87e8ffe2a4b` (not publicly viewable) |
| Steps | None provided |
| Expected | None provided |
| Additional | None provided |

**Information available:** signature is the bare claim "stucks on every prompt"
plus an opaque thread id. No scrollback, no two-frame capture, no chevron-vs-no-chevron
distinction, no Working/Waiting timer evidence, no Killed/OOM marker, no capacity
text, no queued-prompt evidence. Triage must therefore be **shape-only**, not
empirical match against the detector's regex bank.

## Coverage matrix vs 9 shipped subclasses (8 stuck + `alive`)

| Subclass | Detector signature (verbatim from `codex-template-stuck-detector.sh`) | Match against #21241 | Verdict |
|---|---|---|---|
| `alive` | hash drift between t0/t1 frames; recovery `none` | "stucks on every prompt" implies *not* alive (no progress per turn) | **excluded** |
| `buffer_stuck` | stable hash + `Implement {feature}` / `Run /review` / `Use /skills` placeholder visible at chevron; recovery `enter_newline_then_respawn_if_still_stuck` | Plausible if pane shows stable Codex template at chevron after every Enter; matches "every prompt" in the sense that Enter→template-redraw with no submission | **partial** |
| `post_completion` | stable hash + `Working >=600s` (10m+ stuck timer); recovery `/flywheel:respawn_after_snapshot` | "Every prompt" suggests fast-recurring per-turn freeze, not a single stuck 10-minute Working timer | **unlikely** |
| `input_deaf` | placeholder remains stable after `ntm send` reports success (Enter not consumed); recovery `/flywheel:respawn_after_peer_orch_recovery_gate` | **Strongest shape match.** Sibling of `#12645` (kitty-keyboard + tmux Enter drop on WSL/Linux Codex CLI). Reporter is Windows Terminal + WSL2, same family as the documented `frozen-codex-spinner-misclassified-as-thinking` trauma class (INCIDENTS.md line 185). "Stucks on every prompt" is the canonical phenomenology of TUI keyboard-protocol Enter drop. | **partial / primary** |
| `post_callback_reminder_template_with_stale_spinner` | reminder prompt template (`Implement {feature}` etc.) at chevron + `Working` or `Waiting for background terminal` spinner aged >90s, OR `Done.`/`Changed:` evidence in tail | No spinner-age evidence reported; "every prompt" phenomenology doesn't fit post-callback re-emergence | **unlikely** |
| `model_at_capacity_halt` | chevron prompt + `selected model is at capacity` / `please try a different model` text in tail | No capacity text in report; gpt-5.5 capacity halt would surface the upstream string and reporter would have quoted it | **excluded** |
| `codex_queued_not_submitted` | Working/background spinner + queued chevron prompt with user text (not a static reminder template) | No evidence of queued-prompt-with-text; recovery would be bare Enter, sibling of #12645 alps:1 17:15Z reproducer | **unlikely (but adjacent)** |
| `oom_killed_pane` | no chevron prompt + no capacity text + OS-killed marker (`Killed`/`out of memory`/`[Process completed]`/`oom-kill`) in tail | No process-death markers reported; reporter says "every prompt" implying the CLI is still alive and accepting prompts visually | **excluded** |
| `unknown_stable` | stable hash + no other signature matches; recovery `recapture_then_manual_review`; emits fuckup-log row + `/tmp/codex-stuck-unknown-stable-...json` snapshot | Fallback bucket; would catch #21241 if nothing else fired | **catch-all (no novel pattern asserted)** |

## Verdict: **partial coverage — `input_deaf` primary, `buffer_stuck` secondary**

codex#21241 is shape-isomorphic with the documented `#12645` family
(`frozen-codex-spinner-misclassified-as-thinking`, INCIDENTS.md L185-225):

- WSL2 + Windows Terminal is the same OS family that produced the original
  Linux/tmux Enter-drop pattern.
- "Stucks on every prompt" is the canonical phenomenology of a TUI keyboard
  protocol (kitty-keyboard / extended-keys) regression where Enter is captured
  by the terminal but the Codex TUI does not advance the conversation.
- codex-cli 0.128.0 is three minor versions past the 0.125.0 #12645 baseline;
  the reporter's silence on workarounds suggests a regression, not a config
  problem.

**The shipped detector covers this shape via `input_deaf`** (post-Enter stable
hash) and falls back to `buffer_stuck` if a static template placeholder is
visible. Recovery routing is correct: both branches escalate to
`/flywheel:respawn_after_peer_orch_recovery_gate`, which is the canonical
remedy for the #12645 family per INCIDENTS.md L207-211.

**No wholly novel pattern is asserted.** Without scrollback or a two-frame
capture from the upstream thread, any claim of a new subclass would be
speculation-on-speculation. The detector's `unknown_stable` bucket is the
correct landing pad if a future #21241 reproducer surfaces a signature outside
the eight shipped regexes; it auto-emits a fuckup-log row and a JSON snapshot
that would feed the next subclass authoring cycle.

## Donella read (Meadows leverage)

- **#12 Constants/Numbers:** N/A — no thresholds change.
- **#5 Rules:** existing rules (subclass-gated recovery, no auto-respawn for
  `input_deaf`/`post_completion`) already correctly fence the #21241 shape.
- **#6 Information Flows:** the gap, if any, is *upstream* — the Codex issue
  lacks scrollback. We cannot author a subclass without a sample. The right
  information loop is `unknown_stable` → snapshot → fuckup-log → manual review →
  new fixture → new subclass. That loop is already wired (detector lines
  581-601 `write_unknown_snapshot`, lines 753-769 `fuckup_row`).
- **#3 Goals:** the system goal of "every stuck pane has a subclass and a
  recovery" is preserved by the catch-all; #21241 does not threaten it.

## Follow-up bead: **none filed**

Per dispatch packet rule ("if uncovered pattern surfaces: file follow-up bead;
do NOT implement"). No uncovered pattern surfaces here — coverage is partial-
by-design (input_deaf is the right bucket, evidence is just thin upstream).
Filing a speculative `flywheel-codex-21241-new-subclass-*` bead would violate
the canonical-cli-scoping discipline (no executable code without a fixture)
and would also violate axiom 9 (Socraticode-First — author from evidence, not
from issue titles).

If a future #21241 reproducer ships scrollback, recapture this triage and
re-evaluate. The detector's `unknown_stable` snapshot path is the canonical
collector for that evidence.

## Cross-references

- Upstream: <https://github.com/openai/codex/issues/21241>
- Sibling family: <https://github.com/openai/codex/issues/12645> (#12645
  kitty-keyboard+tmux Enter drop, INCIDENTS.md L185-225).
- Sibling cross-orch co-own delivery: `oom_killed_pane` (commit `ebf44878`,
  bead `flywheel-codex-oom-killed-subclass-2026-05-06`).
- Detector source: `.flywheel/scripts/codex-template-stuck-detector.sh` (subclasses
  enumerated at line 144 of `info_json`).
- Recovery primitive for `input_deaf`: `/flywheel:respawn` skill; boot-wait
  patch INCIDENTS.md L3076-3122.
- INCIDENTS catch-all class ancestry: `frozen-codex-spinner-misclassified-as-thinking`
  (INCIDENTS.md L189).

## Skills consulted

- `~/.claude/skills/canonical-cli-scoping/SKILL.md` (no new CLI authored —
  docs-only triage).
- `~/.claude/skills/readme-writing/SKILL.md` (INCIDENTS additive section
  follows existing entry shape: Date / Class / Root Cause / Forever-Rule /
  Fix Status / Evidence).
- `~/.claude/skills/donella-meadows-systems-thinking/SKILL.md` (leverage
  read above; #5 Rules + #6 Information Flows).
