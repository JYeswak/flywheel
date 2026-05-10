# flywheel-u4fmq — Worker Report (BLOCKED)

**Task:** [ntm-binary-rebuild + L87 sunset] Joshua-gated rebuild + retire stale-error workaround
**Identity:** MagentaPond (codex-pane on flywheel:0.3)
**Status:** BLOCKED — fleet-impacting binary swap is orchestrator-class action, not worker tick
**Mission fitness:** infrastructure — premise verified; orch action documented; no fleet substrate touched.

## Verdict

**BLOCKED with `blocker_type=flywheel_class`, `blocker_class=fleet_impacting_binary_swap_orchestrator_authority_required`.** The bead body itself names the constraint: "rebuilding `/Users/josh/.local/bin/ntm` is a fleet-shared 54MB binary swap that affects every active pane; per Joshua-disposes axiom and `feedback_calling_in_sick_policy_flywheel_owns_orch_failures.md` the orchestrator owns substrate maintenance of this class." Step 1 of the action checklist requires "coordinate with peer orchs that no active worker is mid-dispatch on `/Users/josh/.local/bin/ntm`" — a worker pane (me) cannot ntm-send to peer sessions to verify quiescence; that's orchestrator authority.

What I CAN ship in this tick is **premise verification + runbook** — confirming the upstream fix is in HEAD, the installed binary lacks commit metadata, and the fallback test still passes — so the orch can execute the swap deterministically when Joshua approves the fleet-quiesce window.

## Premise verification (deterministic)

| Claim from bead body | Status | Evidence |
|---|---|---|
| Upstream ntm fix #118 commit 4c176e92 is in HEAD | VERIFIED | `git -C ~/Developer/ntm merge-base --is-ancestor 4c176e92 HEAD` → rc=0 ("fix is in HEAD"). HEAD = `7d1fc78ebf19af12b193c972d25016ec707d8f87` (7d1fc78e). |
| Installed binary reports `version=dev commit=none built=unknown` | VERIFIED | `/Users/josh/.local/bin/ntm version` → `ntm version dev / commit: none / built: unknown`. |
| L87 stale-error-auto-ping fallback still passes 7/7 | VERIFIED | `bash tests/stale-error-auto-ping.sh` → `Summary: 7 passed, 0 failed`. Fallback is operational. |
| Installed binary metadata | VERIFIED | size=54884370 bytes (54.8 MB), mtime=May 7 18:24:48 2026 (built 2 days ago). |
| Fleet activity (proxy for swap-window risk) | VERIFIED | 6 active sessions, ~21 panes total: alpsinsurance(5), mobile-eats(4), vrtx(2), skillos(3), flywheel(5), test(2). All potentially using ntm. |

Premise is intact: the rebuild is the right move, the L87 sunset will follow naturally, but the swap window is non-trivial.

## Why BLOCKED, not DONE

I considered three execution paths and rejected each for this tick:

1. **Full execute (steps 1-8)**: Step 1 (peer-orch coordination) requires orchestrator authority. Step 4 (binary swap with backup) is fleet-impacting — any active worker mid-dispatch could be affected by a mid-call binary replacement. Joshua-disposes axiom is explicit.
2. **Partial execute (steps 2-3 only: build dist/ntm without installing)**: This would prove the build works and produces a real commit hash, but ~30-60s of CPU and produces a candidate binary that nobody installs. The orch can do this themselves in their own context with full atomic install.
3. **DECLINED reason=risk**: rejected because the bead is well-scoped, the action is reachable, just not by me. DECLINED would imply scope-mismatch which isn't true.

BLOCKED with `flywheel_orch_action_required` is the correct shape. Sister to today's `multi-actor-experiment-blocked-with-prep-class` (flywheel-nsjse) but more conservative on the prep (premise-verification only, no compute-burn build).

## What blocks completion

| Step | Why blocked | Action required |
|---|---|---|
| 1: coordinate peer-orch quiesce | Cross-session orch authority | Orch sends pause-dispatch heartbeat to peer-orch panes; waits for ACK |
| 2: build (cd ~/Developer/ntm && make build) | Compute + build artifact would be unused if orch builds in own context | Orch runs `make build` on flywheel:0.1 directly |
| 3: verify dist/ntm reports real commit hash | Requires step 2 output | `~/Developer/ntm/dist/ntm version` should show commit=7d1fc78e (or HEAD short SHA) |
| 4: install with backup | Fleet-impacting binary swap | Orch performs: `cp /Users/josh/.local/bin/ntm /Users/josh/.local/bin/ntm.bak.$(date -u +%Y%m%dT%H%M%SZ) && cp ~/Developer/ntm/dist/ntm /Users/josh/.local/bin/ntm` |
| 5: re-run stale-error-auto-ping test | Post-install validation | `bash tests/stale-error-auto-ping.sh` should still PASS 7/7 (regression check) |
| 6: replay stale-error-auto-ping fixture | Confirm Jeff's debounce kicks in | Manual or scripted observation in a controlled pane |
| 7: flip L87 status temporary→deprecated | Doctrine edit | Joshua-gated edit to L87 rule file: add `sunset_at` and `binary_commit_pin=7d1fc78e` |
| 8: remove stale-error fallback README paragraph | Doctrine cleanup | README edit; reduce recovery layer to deprecated migration block |

## Recommended runbook for orch (post-Joshua approval)

```bash
# Phase 1 — Quiesce (orch responsibility)
# Send pause-dispatch heartbeat to peer-orch panes; wait ACK before proceeding.

# Phase 2 — Build (orch executes)
cd /Users/josh/Developer/ntm
git rev-parse --short HEAD  # confirm 7d1fc78e
make build
./dist/ntm version  # expect commit=7d1fc78e (real hash, not "none")

# Phase 3 — Backup + atomic swap (orch executes; <100ms swap window)
cp /Users/josh/.local/bin/ntm /Users/josh/.local/bin/ntm.bak.$(date -u +%Y%m%dT%H%M%SZ)
cp /Users/josh/Developer/ntm/dist/ntm /Users/josh/.local/bin/ntm
/Users/josh/.local/bin/ntm version  # verify commit metadata is now real

# Phase 4 — Validate (orch executes)
cd /Users/josh/Developer/flywheel
bash tests/stale-error-auto-ping.sh  # expect 7/7 still PASS

# Phase 5 — Doctrine flip (orch + Joshua)
# - Edit .flywheel/rules/L087-* to add sunset_at + binary_commit_pin
# - Edit README to reduce stale-error fallback paragraph to deprecated migration block
# - File a small flywheel-* bead to track L87 deprecation timeline

# Phase 6 — Resume (orch responsibility)
# Resume peer-orch dispatch; monitor for any anomalies in next 15-30 minutes.
```

## Three-Q

- **VALIDATED:** five premise claims from the bead body all probed and confirmed; fix-in-HEAD ancestry check rc=0; fallback test 7/7 PASS; binary metadata captured.
- **DOCUMENTED:** 6-phase runbook for orch is reproducible; rollback path is implicit (the .bak file from step 3 of phase 3); risks named at each phase.
- **SURFACED:** orch knows the next-actionable is fleet-quiesce → build → atomic-swap; Joshua approval gates phases 1, 3, and 5.

## Four-Lens Self-Grade

four_lens=brand:9,sniff:10,jeff:9,public:9 — **4/4 PASS**

- **Brand (9/10):** narrowest correct disposition — refused to execute fleet-impacting binary swap from a worker pane; refused to compute-burn a build that the orch should do in its own context; verified bead premise without touching the substrate.
- **Sniff (10/10):** five distinct probes (installed binary metadata, repo HEAD, fix #118 ancestry check, fallback test rc, fleet activity proxy) all deterministic and reproducible.
- **Jeff (9/10):** Jeff "data decides" applied — bead body explicitly names orchestrator authority + Joshua-disposes; data agrees (21 active panes, fix verified in HEAD, fallback operational). Convergent with `feedback_orchestrators_kill_panes_without_respawn` (workers don't do orch-class actions) and `feedback_calling_in_sick_policy_flywheel_owns_orch_failures` (cited by the bead itself).
- **Public (9/10):** **Three Judges check** — skeptical operator can re-run the 5 premise probes in <10s; maintainer reads the 6-phase runbook and executes phase-by-phase deterministically; future workers facing fleet-impacting substrate beads get this BLOCKED-with-premise-verification template (sister to nsjse's BLOCKED-with-prep but lighter on the prep work).

`evidence_schema_version=worker-evidence/v1`. `extraction_pattern=fleet-impacting-substrate-swap-blocked-with-premise-verification-class/v1`. `four_lens_close_validator_version=four-lens-close-validator/v1`.

## Skill auto-routes addressed

- `canonical-cli-scoping=n/a` — no CLI surface authored.
- `rust-best-practices=n/a` — no Rust.
- `python-best-practices=n/a` — no Python.
- `readme-writing=n/a` — README edit (step 8) deferred to orch.

## Skill discoveries

`skill_discoveries=1 sd_ids=fleet-impacting-substrate-swap-blocked-with-premise-verification-class`

| Kind | Discovery |
|---|---|
| `pattern-emerged` | **Fleet-impacting substrate swap BLOCKED-with-premise-verification class:** beads that require swapping a fleet-shared file/binary affecting many active panes belong to the orchestrator. Worker disposition is BLOCKED with premise-verification (probe the bead's claims to confirm they're current) plus a 6-phase orch runbook. NOT DECLINED (bead is well-scoped). NOT BLOCKED-with-build-prep (compute-burns produce a candidate binary the orch will rebuild anyway). The right prep is premise-only: verify upstream fix presence, installed binary state, fallback operational, fleet activity proxy. Sister to today's other BLOCKED-with-prep classes (nsjse multi-actor, fqsmx cohort, g6xaw trigger-gated) but distinguished by the binary-swap risk signature. |

## L52 / L70 receipt

- L52 (issues-to-beads): `no_bead_reason=BLOCKED-with-runbook-no-new-gap-orch-is-next-actionable-owner`. Filing a separate bead for "orch should rebuild ntm binary" would be redundant — this bead IS that bead, just routed to wrong actor.
- L70 (no-punt): the BLOCKED + runbook IS the next-actionable for THIS worker tick; orch reconciles via `flywheel_orch_action_required`.

## L61 ecosystem-touch

- `agents_md_updated=no` — no L-rule promotion needed (L87 sunset is step 7, deferred to orch).
- `readme_updated=not_applicable` — no README touched (step 8 deferred to orch).
- `no_touch_reason=blocked-on-orch-authority-no-doctrine-edit-warranted-this-tick`

## Compliance Pack

Score: 875/1000 (BLOCKED with premise-verification cap).

- 0/8 action checklist steps DID; 5/5 premise claims VERIFIED
- 6-phase orch runbook documented
- Fleet activity probed (21 panes across 6 sessions = real risk signal)
- 4/4 lenses with 9-10/10 self-grades

Pack path: `.flywheel/evidence/flywheel-u4fmq/`.

## Cross-references

- This bead: `flywheel-u4fmq` (BLOCKED 2026-05-10)
- Source: `flywheel-vkw88` (closed; surfaced the version-mismatch gap)
- Subject binary: `/Users/josh/.local/bin/ntm` (54.8 MB, version=dev commit=none)
- Subject repo: `~/Developer/ntm` HEAD `7d1fc78e` (fix #118 verified in ancestry)
- L-rule pending sunset: L87 (stale-error-auto-ping recovery, fallback test 7/7 PASS today)
- Sister BLOCKED classes today (5 distinct external/cross-actor disposition shapes shipped this session):
  - `flywheel-g6xaw` — trigger-gated (external release wait)
  - `flywheel-nsjse` — multi-actor experiment (orch + Joshua + unbounded wait)
  - `flywheel-fqsmx` — cohort-policy-not-met (producer cadence not active)
  - `flywheel-ze4xv` — cross-repo cohort partial-DONE (skillos repo + Joshua-gate split)
  - `flywheel-u4fmq` (this) — fleet-impacting substrate swap (orch authority + Joshua-disposes)
- Memory cross-refs: `feedback_orchestrators_kill_panes_without_respawn.md`, `feedback_calling_in_sick_policy_flywheel_owns_orch_failures.md` (cited by bead body), `feedback_data_decides_not_human_meatpuppet.md`, `feedback_orchestrator_scope_boundary.md`
- L-rules cited: L52 (no new bead — BLOCKED with runbook IS the receipt), L70 (BLOCKED + runbook IS the next-actionable; no punt), L107 (no edits — no reservation needed)
