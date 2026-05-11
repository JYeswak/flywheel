# flywheel-lsck2 — doctor.d extraction commit coordination

Bead: flywheel-lsck2 (P2)
Lane: cross-orch-coordination
mutates_state: no (handoff filed; cross-repo commit deferred to peer-orch per `project_skillos_separated`)
Re: flywheel-9vb9i (P2 CLOSED 2026-05-10) close-note flag — ".claude side NOT committed (peer-orch doctor.d/ extraction untracked)"

## State verified

Bead body description was empty (title-only). Probed per META-RULE 2xdi.54 to confirm the underlying coordination need:

| Surface | State |
|---|---|
| `~/.claude/skills/.flywheel/lib/doctor.d/` | 3 active part-*.sh files (28KB + 13KB + 10KB) + 1 .bak from flywheel-0qkjj |
| git tracking | `?? .flywheel/lib/doctor.d/` — **UNTRACKED** in peer-orch repo |
| File mtimes | part-01 May 10 15:09; part-02 May 10 17:38; part-03 May 9 11:54 — on disk for ~13h+ as of handoff send |
| Runtime load-bearing | YES — sourced via `*.d/` glob by `~/.claude/skills/.flywheel/lib/portable/core.d/part-02-portable_doctor.sh` |
| Broader peer-orch state | 288 tracked-modified + 1384 untracked entries in `.claude/skills/` (doctor.d/ is one component) |

The doctor.d/ extraction IS load-bearing at runtime (sourced + executed every flywheel-loop doctor invocation) but ORPHAN in git. Recovery from disk loss / fresh-clone would break the fleet doctor invariant chain.

## Disposition: cross-orch handoff (no flywheel.git changes)

Per `project_skillos_separated.md` — `.claude/skills/` is skillos's repo scope; flywheel:1 doesn't write there. Per `feedback_orch_handshakes_never_gate_on_joshua` — use file-sidechannel coordination, don't gate on Joshua.

Filed handoff:
- Path: `.flywheel/handoffs/20260511T0954Z-from-flywheel-1-to-skillos-1-doctor-d-extraction-commit-coord.md`
- Format: mirrors prior handoff precedents (RATIFY/coordination shape — From/To/Sent/Subject/Class/Mission anchor/Re/One-line/State/Suggested commit/Response handle)
- Class: P2 coordination (no doctrine change; commit-state surfacing)
- Default-accept: none (skillos:1 owns disposition)
- Response handles: 3 enumerated (commit_sha / deferred reason / decline reason)
- Memory anchors cited: `feedback_substrate_watchtower_must_be_wired`, `feedback_orch_handshakes_never_gate_on_joshua`, `project_skillos_separated`

## Acceptance gates

Bead has no explicit AC list (Title-only, description empty). Inferred AGs:

| # | Gate | Status | Evidence |
|---|---|---|---|
| AG1 | Verify the coordination need is real | **DONE** | Empirical inspection: doctor.d/ files exist on disk (3 active + 1 bak), are runtime-load-bearing (sourced by portable_doctor), and git status shows `?? .flywheel/lib/doctor.d/` (UNTRACKED). 9vb9i close-note flag confirmed. |
| AG2 | File cross-orch handoff to peer-orch | **DONE** | Handoff at `.flywheel/handoffs/20260511T0954Z-from-flywheel-1-to-skillos-1-doctor-d-extraction-commit-coord.md`. Format mirrors precedent; includes state observed, suggested commit shape, response handle. |
| AG3 | Document broader uncommitted state as informational (don't expand scope) | **DONE** | Sister-finding in handoff: 288 modified + 1384 untracked in `.claude/skills/`. Scoped to doctor.d/ only per bead title; broader backlog is peer-orch's operator-decision. |
| AG4 | Cite 9vb9i parent + commit f4e07303 (the flywheel.git side fix) | **DONE** | Handoff cites both in "Why flywheel-9vb9i flagged this" section. |
| AG5 | Respect cross-repo boundary | **DONE** | No `.claude/skills/` writes from this dispatch. Coordination is file-sidechannel only. |

## L52 bead receipt

- `beads_filed`: none
- `beads_updated`: none
- `no_bead_reason`: cross-orch coordination via file-sidechannel handoff is the canonical mechanism here; the peer-orch's disposition (commit/defer/decline) determines whether a follow-up bead is needed. Filing one preemptively would be speculative — the response handle in the handoff is the next step.

## Skill auto-routes addressed

- All `n/a` — coordination handoff only; no surface authored or modified.

## Four-Lens Self-Grade

- **brand** (10): respected `project_skillos_separated` boundary (consistent with 7+ prior cross-repo dispositions this session); handoff format mirrors recent ratification-handoff precedents (e.g., 20260511T0731Z-git-stash-discipline-v0.2-RATIFY).
- **sniff** (10): empirical state verification (git status, file mtimes, runtime-source chain); 9vb9i close note cited verbatim; broader backlog quantified (288 + 1384).
- **jeff** (10): scoped to doctor.d/ per bead title; flagged 288+1384 broader state as informational only (skillos:1 operator-decision, not bead-expansion); didn't preemptively file follow-up bead.
- **public** (10): Three Judges check —
  - Skeptical operator: state observation is reproducible (`git status --short`, `ls`, mtimes).
  - Maintainer: handoff includes copy-paste-ready commit command.
  - Future worker: when skillos:1 responds via handoff sidechannel, the response-handle conventions are explicit.

four_lens=brand:10,sniff:10,jeff:10,public:10

## Compliance: 1000/1000

- AG1-AG5: all DONE. ✓
- Empirical state verified. ✓
- Handoff filed with full state + suggested commit + response handle. ✓
- Cross-repo boundary respected. ✓
- Broader backlog flagged as informational without scope creep. ✓

## L112 probe

Command: `[ -f /Users/josh/Developer/flywheel/.flywheel/handoffs/20260511T0954Z-from-flywheel-1-to-skillos-1-doctor-d-extraction-commit-coord.md ] && echo handoff_filed || echo handoff_missing`
Expected: `literal:handoff_filed`
Timeout: 5 seconds
