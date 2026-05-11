# flywheel-2xdi.109 — Evidence Pack

**Bead:** flywheel-2xdi.109 (P3)
**Title:** [gap-memory-without-cross-link] feedback_dispatch_post_send_verify_for_silent_deaf.md
**Mission fitness:** `adjacent` — memory ↔ doctrine cross-linking + harvested faqj2 self-calibration finding
**Sister recipe:** flywheel-2xdi.93 (same forward-link doctrine doc pattern)

## Hypothesis vs root cause (N=18 bead-hypothesis META-rule)

**Bead hypothesis:** memory file not cited by sampled commands/doctrine/incidents/plans.

**Verified:**
- Memory file EXISTS at `~/.claude/projects/-Users-josh-Developer-flywheel/memory/feedback_dispatch_post_send_verify_for_silent_deaf.md`
- Documents Shape G silent-deaf class (transport ack ≠ worker processed)
- NOT name-cited in `.flywheel/doctrine/`, `INCIDENTS.md`, or `AGENTS.md`
- BUT discipline IS behaviorally embedded: dispatch-template.md has **6 mentions** of `callback_delivery_verified` — the very contract this memory documents

The gap is real (probe wants name-cross-link) but the discipline IS load-bearing in runtime artifacts. This dual-state surfaces a meta-finding about the probe class.

## Fix

Created `.flywheel/doctrine/dispatch-post-send-verification-silent-deaf.md` — doctrine doc that:
1. Summarizes the Shape G silent-deaf pattern at canonical-doctrine quality
2. Cites the memory file as "Canonical memory source" — explicit cross-link
3. Documents post-send verification primitive (sleep 5-10s + robot-tail)
4. Documents re-send mitigation (same packet, same task_id)
5. Documents callback envelope discipline (`callback_delivery_verified` field)
6. Notes the **behavioral vs name cross-linking distinction** (links to the faqj2 blind-spot finding)
7. Below-trauma-class tracking note (1 confirmed exemplar bg06b 2026-05-10)

Sister doctrine cited: `audit-machinery-hygiene-discipline.md` (Shape G transport-layer vs classification-layer); dispatch template's `VERIFY-CALLBACK BLOCK`.

## Self-calibration harvest (orch dispatch hint: "next-tick faqj2")

Per orch hint, harvested the blind-spot finding into `flywheel-xbsd8`:

> "memory-without-cross-link class is name-grep-only — misses semantically embedded discipline (e.g., dispatch template's VERIFY-CALLBACK BLOCK)"

The empirical evidence:
- Memory's discipline (`callback_delivery_verified`) appears 6 times in `dispatch-template.md`
- But the memory's FILENAME doesn't appear → probe flags it
- Workers correctly resolve via doctrine-doc wire-in (this bead + 2xdi.93)
- But the underlying detection is myopic — it produces structural-but-not-semantic flagging

Four fix options offered in `flywheel-xbsd8` (extract discipline tokens; widen corpus; semantic-cross-link metric; accept FP rate). Orch should triage.

## Acceptance gates

| # | Gate | Status |
|---|---|---|
| AG1 | Identify cross-link gap class | DONE — memory exists; doctrine grep returned 0 hits |
| AG2 | Create canonical cross-link (memory ↔ doctrine) | DONE — new doctrine doc cites memory by name |
| AG3 | Verify gap cleared in fresh probe | DONE — fresh probe gap_ids no longer contains the .109 target |
| AG4 (orch hint) | Harvest blind-spot finding into faqj2 self-calibration | DONE — filed `flywheel-xbsd8` with 4 fix options + empirical evidence |

## Verification

```bash
$ grep -l "feedback_dispatch_post_send_verify_for_silent_deaf" .flywheel/doctrine/ -r
.flywheel/doctrine/dispatch-post-send-verification-silent-deaf.md

$ bash .flywheel/scripts/gap-hunt-probe.sh --json | jq '.gap_ids[] | select(test("memory-without-cross-link.*dispatch_post_send"))'
(empty)

$ grep -c "callback_delivery_verified" ~/.claude/commands/flywheel/_shared/dispatch-template.md
6  # discipline embedded behaviorally; confirms the faqj2 finding
```

## DID / DIDNT / GAPS

- **DID 4/4** — gap identified, doctrine doc created, gap cleared, blind-spot harvested
- **DIDNT none**
- **GAPS** = `flywheel-xbsd8` (P3 faqj2 self-calibration: memory-without-cross-link is name-grep-only)

## Files Changed

- `.flywheel/doctrine/dispatch-post-send-verification-silent-deaf.md` (new, doctrine canonical)
- `.flywheel/audit/flywheel-2xdi.109/` (this evidence pack)

No mutation of the memory file itself (consistent with 2xdi.93 pattern — memory is truth source; doctrine cites it).

## L112 Probe

- `l112_probe_command`: `grep -l "feedback_dispatch_post_send_verify_for_silent_deaf" .flywheel/doctrine/ -r | head -1`
- `l112_probe_expected`: `grep:dispatch-post-send-verification-silent-deaf.md`
- `l112_probe_timeout_sec`: `5`

## Pattern note

**9th distinct fix shape in 2xdi.* cluster:** forward-link doctrine doc + faqj2 self-calibration harvest (same shape as 2xdi.93 + the orch's "harvest blind-spot finding" hint).

Hint productivity arc complete:
- Joshua surfaced "dedup blind spot" on 2xdi.101 → shipped 2xdi.101 + 9a3k1 + dnxjb (3 beads)
- Orch surfaced "harvest faqj2 blind-spot" on 2xdi.109 → shipped 2xdi.109 + xbsd8 (2 beads)

The pattern: dispatch hints about meta-issues consistently produce 2-3× the deliverable footprint vs the literal bead.

## Four-Lens Self-Grade

- **brand:** 10 — orch-hint productively converted to blind-spot harvest (faqj2 self-calibration)
- **sniff:** 10 — N=18 bead-hypothesis discipline; empirical evidence (6 mentions) backs the blind-spot finding
- **jeff:** 9 — convergent with 2xdi.93 recipe; faithful sister-pattern application
- **public:** 10 — doctrine doc explicitly notes behavioral-vs-name cross-link distinction + links to the meta-finding bead
