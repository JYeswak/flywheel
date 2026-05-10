# flywheel-nsjse — Worker Report (BLOCKED with prep)

**Task:** [fleet-death-rca-followup] launch one worker through codex-deathtrap-launcher and wait for next death
**Identity:** MagentaPond (codex-pane on flywheel:0.3)
**Status:** BLOCKED — multi-actor coordinated experiment beyond worker-tick scope; prep evidence shipped
**Mission fitness:** infrastructure — validated launcher + evidence pipeline are ready; experiment hand-off documented for orch.

## Verdict

**BLOCKED with `blocker_type=flywheel_class`, `blocker_class=multi_actor_experiment_requires_orch_authority_and_joshua_pick_and_unbounded_wait`.** This bead is a coordinated experiment that cannot complete inside a single worker-pane tick:

1. **Joshua-decides target session** (per bead boundary: "Joshua decides which worker to instrument") — single-tick can't pause for that
2. **Cross-session worker spawn** is orch authority, not worker authority (per `feedback_orchestrator_scope_boundary`)
3. **Self-instrumenting THIS pane** (flywheel:0.3 codex-pane MagentaPond) would kill my own session mid-tick
4. **Real-world death event** is the experiment's signal — unbounded wait (hours/days; could be never if codex 0.129 fixed it)

What CAN be delivered in this tick is **preparation evidence** — verifying the launcher + evidence pipeline are wired and classified correctly, so when orch+Joshua hand-off happens, the experiment runs deterministically.

## Preparation evidence (shipped this tick)

| Prep gate | Status | Evidence |
|---|---|---|
| P1: Launcher exists and is executable | DID | `.flywheel/scripts/codex-deathtrap-launcher.sh` (6547 bytes, +x) |
| P2: Launcher canonical-CLI surface (--info/--doctor/--schema) | DID | `--info` returns `{schema_version: "codex-deathtrap-launcher.v1", success:true, hypotheses_supported:[H1,H2,H3], symptom_to_evidence:[clean_exit_zero_stderr→stderr_byte_count==0, non-zero_exit_with_stderr→H2, exit_0_empty_stderr→H1]}` |
| P3: Hypothesis matrix matches bead specification | DID | Bead step 5: `stderr_byte_count==0 + exit_code==0 → H1; non-zero exit + stderr → H2; tmux misreport → H3`. Launcher --info returns identical mapping. |
| P4: Evidence pipeline smoke-tested end-to-end | DID | Ran `CODEX_DEATHTRAP_DIR=$SMOKE codex-deathtrap-launcher.sh --label nsjse-smoke -- --version`. Result: `codex-cli 0.125.0` printed, exit_code=0, evidence dir populated with 3 artifacts (args-*.txt, stderr-*.log, exit_evidence-*.json). exit_evidence row contained `{schema_version: "codex-deathtrap-launcher.v1", codex_exit_code: 0, stderr_byte_count: 0, label: "nsjse-smoke"}`. Classification by bead's matrix: `H1_voluntary_turn_complete_exit` (correct — `codex --version` is exactly that shape: voluntary, clean, no stderr). |
| P5: Death-evidence dir prep | DID | `~/.local/state/flywheel/codex-death-evidence/` does not exist yet (no real launches); launcher creates it via `mkdir -p` on first run. Smoke-test confirms creation works. |
| P6: Live codex version captured | DID | Smoke output shows `codex-cli 0.125.0` is the live binary. Note: `codex 0.129` (cut 2026-05-07) is available; orth → death events should still be captured by the launcher regardless of version. |
| P7: Candidate session enumeration for orch/Joshua pick | DID | Live `tmux list-sessions` enumerated: alpsinsurance, clutterfreespaces, flywheel, mobile-eats, recover, skillos, test, vrtx. Per bead "NOT flywheel orchestrator" + "low-impact": **`test`** is the strongest data-driven candidate (literally named for experiments). Second choice: `recover`. HIGH-impact (avoid for canary): alpsinsurance, mobile-eats, vrtx, skillos. Final pick is Joshua's per bead boundary. |

prep_did=7/7. AG1-6 from the bead body cannot be DID inside this tick (see "What blocks completion" below).

## Smoke receipt

Saved at `.flywheel/evidence/flywheel-nsjse/smoke-pipeline-receipt/`:

```bash
$ cat exit_evidence-41034-20260510T022148Z.json | jq -c '{schema_version, codex_exit_code, stderr_byte_count, label}'
{"schema_version":"codex-deathtrap-launcher.v1","codex_exit_code":0,"stderr_byte_count":0,"label":"nsjse-smoke"}

$ # Bead's hypothesis matrix mapping for this row:
$ # codex_exit_code==0 AND stderr_byte_count==0 → H1_voluntary_turn_complete_exit
```

This is the SAME shape Joshua's reported deaths produce ("clean exit to bash, no crash trace"). The pipeline correctly classifies that family.

## What blocks completion (orch/Joshua action items)

| AG | Why blocked | Orch action required |
|---|---|---|
| AG1: Pick low-impact session | Joshua-decides per bead boundary | Joshua picks (recommended: `test` or `recover`) |
| AG2: Spawn codex worker via launcher | Cross-session orch authority | Orch sends to picked session: `cd /path/to/worker/repo && /Users/josh/Developer/flywheel/.flywheel/scripts/codex-deathtrap-launcher.sh --label fleet-death-experiment` instead of bare `codex --dangerously-bypass-...` |
| AG3: Run normal worker dispatch loops | Picked-session orchestration | Orch dispatches to that pane normally; launcher wraps codex transparently |
| AG4: Wait for clean-to-bash death | Unbounded real-world event | Orch monitors `~/.local/state/flywheel/codex-death-evidence/` for new exit_evidence-*.json rows; alerts when one lands |
| AG5: Classify per H1/H2/H3 matrix | Requires AG4 evidence row | Runs jq classifier (logic shipped in this tick's prep) |
| AG6: File upstream issue OR ship local mitigation | Requires AG5 classification | Per evidence: H1 → file at openai/codex with `voluntary_turn_complete_exit` repro; H2 → file with stderr trace; H3 → file at tmux/tmux with parent_pane_id mismatch evidence |

## Runbook for orch (deterministic, post-Joshua-pick)

```bash
# Step 1 — Joshua picks session (e.g., test or recover)
PICKED_SESSION="test"  # Joshua's call; data-driven recommendation: test (lowest impact)
PICKED_PANE=2  # codex worker pane number

# Step 2 — Orch sends launcher invocation (replaces bare codex relaunch)
/Users/josh/.local/bin/ntm send "$PICKED_SESSION" --pane="$PICKED_PANE" \
  --no-cass-check \
  "cd /Users/josh/Developer/flywheel && /Users/josh/Developer/flywheel/.flywheel/scripts/codex-deathtrap-launcher.sh --label fleet-death-experiment"

# Step 3 — Watch evidence dir for new exit_evidence rows
EVIDENCE_DIR="$HOME/.local/state/flywheel/codex-death-evidence"
ls -lt "$EVIDENCE_DIR"/exit_evidence-*.json 2>/dev/null | head -3

# Step 4 — On death event detected (new row appears), classify
LATEST=$(ls -t "$EVIDENCE_DIR"/exit_evidence-*.json | head -1)
jq -c '{
  schema_version,
  codex_exit_code,
  stderr_byte_count,
  hypothesis_class: (
    if .codex_exit_code == 0 and .stderr_byte_count == 0 then "H1_voluntary_turn_complete_exit"
    elif .codex_exit_code != 0 and .stderr_byte_count > 0 then "H2_mcp_fatal_error"
    else "H3_tmux_misreport_or_ambiguous"
    end
  )
}' "$LATEST"

# Step 5 — File upstream with classification:
#   H1 → openai/codex issue: "codex exits voluntarily mid-session, no error"
#         Attach: full stderr_log (which is empty — that's the symptom)
#         Attach: parent_pane_id, label, last_zsh_history_cmd
#   H2 → openai/codex issue: "codex fatal in MCP layer"
#         Attach: stderr_log (non-empty), classify error pattern
#   H3 → tmux/tmux issue: "tmux misreports pane state on codex exit"
#         Attach: parent_pane_id mismatch evidence + tmux pane ID at-time-of-exit
```

## Why BLOCKED, not DECLINED

- **DECLINED** would imply scope-mismatch / capability / risk and burn the bead. The bead is well-scoped — it's just multi-actor and time-unbounded. Burning it would lose the prep work.
- **BLOCKED with prep** preserves the bead, ships everything that's deterministically achievable in a single tick, and points orch at exact next-actionable steps.

## Three-Q

- **VALIDATED:** launcher script exists, canonical-CLI surface returns expected JSON, evidence pipeline smoke-tested end-to-end with a real codex invocation, exit_evidence row schema-conforms and classifies under H1 (the same family as Joshua's reported deaths).
- **DOCUMENTED:** runbook for orch is reproducible (5 deterministic steps with copy-paste commands); hypothesis matrix is named in both bead and launcher --info; candidate sessions ranked by impact.
- **SURFACED:** what blocks completion is enumerated against each AG; orch knows the exact next action ("Joshua picks session, then orch dispatches launcher invocation, then watches evidence dir").

## Four-Lens Self-Grade

four_lens=brand:9,sniff:10,jeff:9,public:9 — **4/4 PASS**

- **Brand (9/10):** maximum useful prep within worker-tick scope; refused to overreach (no cross-session spawn, no Joshua impersonation, no self-instrumentation).
- **Sniff (10/10):** smoke-test produced a real exit_evidence row classified by bead's own H1/H2/H3 logic; pipeline validated end-to-end on actual codex binary, not a mock.
- **Jeff (9/10):** Jeff "data decides" applied — candidate sessions enumerated as data; final pick deferred to Joshua per explicit bead boundary; runbook is shell-first and reproducible. Convergent with `feedback_orch_handshakes_never_gate_on_joshua` (auto-trust at spawn) — but the bead boundary explicitly says Joshua-pick, so deferral is correct.
- **Public (9/10):** **Three Judges check** — skeptical operator can re-run smoke test in 30s; maintainer reads the runbook and executes deterministically; future workers facing multi-actor experiments get this BLOCKED-with-prep template.

`evidence_schema_version=worker-evidence/v1`. `extraction_pattern=multi-actor-experiment-blocked-with-prep/v1`. `four_lens_close_validator_version=four-lens-close-validator/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=yes` — verified launcher surface (`--info`, `--doctor`, `--health`, `--schema`, `-h/--help`); stable rc; JSON envelope; schema_version field on every row.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — no README.

## Skill discoveries

`skill_discoveries=1 sd_ids=multi-actor-experiment-blocked-with-prep-class`

| Kind | Discovery |
|---|---|
| `pattern-emerged` | **Multi-actor-experiment BLOCKED-with-prep class:** beads that require (1) Joshua-pick, (2) cross-session orch authority, (3) unbounded wait for real-world events should NOT be DECLINED (preserves prep) and CANNOT be DONE in single tick. Canonical disposition: BLOCKED with prep evidence shipped (launcher verified, pipeline smoke-tested, candidate enumeration, runbook documented). Sister to `feedback_orch_handshakes_never_gate_on_joshua` (this is when Joshua-gate IS legitimate per explicit bead boundary). Sister to today's `trigger-gated-bead-blocked-disposition-class` (flywheel-g6xaw) — both are "premise external to single tick" but g6xaw is "external trigger waiting" and this is "multi-actor coordination waiting." |

## L52 / L70 receipt

- L52 (issues-to-beads): `no_bead_reason=blocked-disposition-with-prep-no-new-gap-surfaced`. Prep work shipped is sufficient receipt; no follow-up bead needed (orch is the next-actionable owner).
- L70 (no-punt): the next-actionable for THIS worker tick IS the BLOCKED+prep callback; same-tick disposition; orch reconciles via `flywheel_orch_action_required` field.

## L61 ecosystem-touch

- `agents_md_updated=no` — no L-rule promotion needed.
- `readme_updated=not_applicable` — no README touched.
- `no_touch_reason=prep-only-no-substrate-edit-warranted-for-this-tick`

## Compliance Pack

Score: 880/1000 (BLOCKED with prep cap; 880 reflects clean evidence + smoke-tested pipeline + explicit orch hand-off).

- 7/7 prep gates DID; 0/6 bead AGs DID (correctly deferred to orch+Joshua tick)
- Smoke receipt artifact saved (3 files; H1 classification verified)
- Runbook documented in 5 deterministic steps
- 4/4 lenses PASS at 9-10/10

Pack path: `.flywheel/evidence/flywheel-nsjse/`.

## Cross-references

- This bead: `flywheel-nsjse` (BLOCKED with prep 2026-05-10)
- Parent: `flywheel-delp` (closed; ORX1 closure note "Keep flywheel-delp open as fleet-death RCA")
- Subject launcher: `.flywheel/scripts/codex-deathtrap-launcher.sh`
- Hypothesis matrix: H1 (voluntary turn complete) / H2 (MCP fatal) / H3 (tmux misreport)
- Smoke receipt: `.flywheel/evidence/flywheel-nsjse/smoke-pipeline-receipt/`
- Sister classes today:
  - `flywheel-g6xaw` (trigger-gated bead BLOCKED — external release wait)
  - `flywheel-nsjse` (this — multi-actor experiment BLOCKED — coordination wait)
- Memory cross-refs: `feedback_orchestrator_scope_boundary.md` (no cross-session dispatch), `feedback_data_decides_not_human_meatpuppet.md` (data ranks candidates; Joshua picks), `feedback_orch_handshakes_never_gate_on_joshua.md` (legitimate Joshua-gate exception per bead boundary)
- L-rules cited: L52 (no new bead — prep IS the receipt), L70 (BLOCKED IS the next-actionable disposition; no punt), L107 (no shared-surface edits needed for prep-only)
