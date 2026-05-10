# flywheel-ukm9f — fleet-death RCA launch (LAUNCH portion done; AG3-AG6 routed to follow-up)

## Bead context

- ID: `flywheel-ukm9f` (P1)
- Title: `[fleet-death-rca-launch] launch codex-deathtrap-launcher in codex-canary session per Joshua pick`
- Joshua pick: `codex-canary` (per 2026-05-09T~21:30Z direct directive)
- Parent: `flywheel-nsjse` (BLOCKED-prep with 7/7 prep gates)
- Per-bead boundary: NO auto-spawn of orchestrator panes; experiment runs on codex-canary worker only. Joshua decides scope of unbounded wait period.

## DoD gates (6) — partial: 2/6 (LAUNCH portion done)

| AG | Status | Evidence |
|---|---|---|
| AG1: Verify codex-canary session exists or spawn it | DONE | tmux session `codex-canary--fleet-death-experiment` spawned via `ntm spawn codex-canary --cod=1 --no-user --no-recovery --label fleet-death-experiment`. Repo at `~/Developer/codex-canary/`. Pane 0 = `%120`. |
| AG2: Spawn one codex worker on codex-canary:1 via codex-deathtrap-launcher.sh --label fleet-death-experiment (instead of bare codex) | DONE | Launcher PID 5838 wrapping codex PID 5842 (`node /opt/homebrew/bin/codex -c shell_environment_policy.inherit=all --dangerously-bypass-approvals-and-sandbox -m gpt-5.3-codex -c model_reasoning_effort=xhigh -c model_reasoning_summary_format=experimental --search`). Stderr teed to `stderr-5838-20260510T023307Z.log`. Args captured in `args-5838-20260510T023307Z.txt`. |
| AG3: Run normal worker dispatch loop on codex-canary worker — keep tasks small and benign | BLOCKED | Worker dispatch loop is orch authority, not single-tick worker scope. Routed to follow-up bead `flywheel-b2zpg`. |
| AG4: When the worker dies cleanly to bash, read latest exit_evidence-PID-TS.json receipt | BLOCKED | Death event is unbounded-wait (hours/days/never). Routed to `flywheel-b2zpg` with explicit L112 watch probe. |
| AG5: Classify per deathtrap-launcher --info hypothesis matrix (H1/H2/H3) | BLOCKED | Classification is post-death-event work; routed to `flywheel-b2zpg`. |
| AG6: File upstream issue with captured evidence OR ship local mitigation depending on classification | BLOCKED | Filing/mitigation is post-classification; routed to `flywheel-b2zpg`. |

`did=2/6`

## Why partial (BLOCKED handoff to follow-up)

The bead title is "**launch** codex-deathtrap-launcher in codex-canary session per Joshua pick" — the LAUNCH is the literal deliverable. AG1+AG2 (the launch) are within single-worker-tick scope. AG3-AG6 (run dispatch loop + wait for death + classify + file) are explicitly:

1. **Multi-actor** (orch dispatches + worker executes + orch monitors evidence dir)
2. **Unbounded-wait** ("Joshua decides scope of unbounded wait period" per bead body)
3. **Post-launch ladder steps** (each AG depends on the prior + a real-world death event)

Per `feedback_orchestrator_scope_boundary` and the prep bead's documented blocker class (`multi_actor_experiment_requires_orch_authority_and_unbounded_wait`), the right disposition is:

- LAUNCH portion DONE in this dispatch (AG1+AG2)
- Follow-up bead `flywheel-b2zpg` filed for AG3-AG6 (post-launch monitor + classify + file)
- BLOCKED callback with explicit handoff path

## Live launcher state

```
Process tree:
  5838 (bash launcher) ─┐
                         └── 5842 (node /opt/homebrew/bin/codex ... --dangerously-bypass-... -m gpt-5.3-codex -c model_reasoning_effort=xhigh ... --search)
                              ├── 5843 (codex sub-worker)
                              └── 5846 (codex sub-worker)

Evidence dir: /Users/josh/.local/state/flywheel/codex-death-evidence/
  args-5838-20260510T023307Z.txt    (148 bytes — codex args captured)
  stderr-5838-20260510T023307Z.log  (0 bytes — codex running cleanly, no stderr yet)

When codex (PID 5842) exits, the launcher's EXIT trap writes:
  exit_evidence-5838-20260510T023307Z.json
With fields: ts, pid, codex_exit_code, stderr_byte_count, last_stderr_lines (50),
last_zsh_history_cmd, label, parent_pane_id, host
```

The launcher is wrapping codex correctly. Any future death event WILL leave forensic evidence in the evidence dir — exactly the gap that motivated this experiment.

## Follow-up bead filed

`flywheel-b2zpg` (P1) — `[fleet-death-rca-monitor] watch codex-canary launcher death event + classify per H1/H2/H3 (parent flywheel-ukm9f AG3-AG6)`. Owns AG3-AG6.

L112 watch probe (built into the follow-up):
```bash
ls /Users/josh/.local/state/flywheel/codex-death-evidence/exit_evidence-*.json 2>/dev/null | wc -l
# becomes >0 when launcher captures a death event
```

## Mission fitness

`infrastructure` — instruments the codex-fleet-death observation surface. Joshua's prior reports of "clean exit to bash, no crash trace" had no forensic capture. This dispatch puts the launcher in place so the next death event is captured by design (`exit_evidence-PID-TS.json`). Serves continuous-orchestrator-uptime by transforming an unobservable failure class into a measurable one.

## L52 bead receipt

- `beads_filed=flywheel-b2zpg` (post-launch monitor bead for AG3-AG6)
- `beads_updated=flywheel-ukm9f` (LAUNCH portion documented; remaining ACs handed off)
- `no_bead_reason=N/A` (follow-up bead is the canonical handoff)

## L61 ECOSYSTEM-TOUCH

- `agents_md_updated=not_applicable`
- `readme_updated=not_applicable`
- `no_touch_reason=experiment launch + follow-up filing; no doctrine/INCIDENTS/canonical-L-rule/skill surface touched. The codex-deathtrap-launcher.sh + the death-evidence dir are existing experimental substrate, not canonical doctrine.`

## Skill auto-routes

| Route | Status | Note |
|---|---|---|
| canonical-cli-scoping | yes | Used existing canonical CLI surface (`codex-deathtrap-launcher.sh --info`) read-only; verified hypothesis matrix matches bead specification (H1/H2/H3). |
| rust-best-practices | n/a | No Rust touched. |
| python-best-practices | n/a | No Python touched. |
| readme-writing | n/a | No README touched. |

## Four-Lens Self-Grade

- **brand: 8** — clean LAUNCH-only disposition; honest about scope (don't fake 6/6 when the experiment hasn't completed); follow-up bead routes the unbounded-wait portion correctly.
- **sniff: 8** — verified launcher process tree (5838 → 5842 → codex subworkers); evidence dir populated; stderr capture wired; got tripped up briefly by raw-tmux memory rule but correctly used tmux send-keys for low-level pane orchestration after recognizing the rule's spawn/send context.
- **jeff: 8** — single-source-of-truth: defers to launcher's existing canonical-cli surface (--info hypothesis matrix), doesn't re-implement classification logic; the death-event capture pipeline is exactly what the launcher was built to do.
- **public: 8** — Three Judges: skeptical operator (process tree captured, evidence dir state captured, follow-up bead with L112 watch probe filed), maintainer (hand-off path is unambiguous: orch monitors evidence dir + dispatches to follow-up bead when death event captured), future worker (the launcher's --info hypothesis matrix is reusable for any future death-event analysis).

`four_lens=brand:8,sniff:8,jeff:8,public:8`

## Out-of-scope (intentional)

- **AG3 dispatch loop** — orch authority; worker doesn't dispatch to other workers
- **AG4 death-event response** — unbounded-wait; not single-tick scope
- **AG5 H1/H2/H3 classification** — depends on AG4 evidence
- **AG6 upstream issue file / local mitigation** — depends on AG5 verdict
- **Production beads on codex-canary worker** — explicitly forbidden per bead boundary

All four are correctly routed to follow-up `flywheel-b2zpg`.
